# =============================================================================
# Core Function Tests for meschooldata
# =============================================================================
#
# Since Maine DOE data requires manual download from a QuickSight dashboard,
# these tests focus on:
# 1. Proper error handling when data is unavailable
# 2. Correct function behavior
# 3. Data validation utilities
#
# =============================================================================

test_that("get_available_years returns correct structure", {
  result <- get_available_years()

  expect_type(result, "list")
  expect_true("min_year" %in% names(result))
  expect_true("max_year" %in% names(result))
  expect_true("source" %in% names(result))

  expect_gte(result$min_year, 2016)
  expect_lte(result$max_year, 2030)  # Reasonable future limit
  expect_lt(result$min_year, result$max_year)
})


test_that("get_download_instructions prints correctly", {
  # Should return URL invisibly
  result <- suppressMessages(get_download_instructions())
  expect_type(result, "character")
  expect_match(result, "maine\\.gov")
})


test_that("fetch_enr fails gracefully when data unavailable", {
  # Clear cache first to ensure we test the download path
  suppressMessages(clear_cache())

  # Should error with helpful message about manual download
  expect_error(
    fetch_enr(2024, use_cache = FALSE),
    regexp = "not available for automated download|QuickSight"
  )
})


test_that("import_local_enrollment errors on missing file", {
  expect_error(
    import_local_enrollment("/nonexistent/file.csv"),
    regexp = "File not found"
  )
})


test_that("import_local_enrollment errors on unsupported file type", {
  # Create a temp file with wrong extension
  temp_file <- tempfile(fileext = ".txt")
  writeLines("test", temp_file)
  on.exit(unlink(temp_file))

  expect_error(
    import_local_enrollment(temp_file),
    regexp = "Unsupported file type"
  )
})


test_that("validate_year rejects invalid years", {
  years <- get_available_years()

  # Too old
  expect_error(meschooldata:::validate_year(2000))

  # Too new
  expect_error(meschooldata:::validate_year(2050))

  # Valid year should not error
  expect_silent(meschooldata:::validate_year(years$min_year))
  expect_silent(meschooldata:::validate_year(years$max_year))
})


test_that("safe_numeric handles various inputs", {
  # Normal numbers
  expect_equal(meschooldata:::safe_numeric(c("1", "2", "3")), c(1L, 2L, 3L))

  # NA handling
  expect_equal(meschooldata:::safe_numeric(c("1", NA, "3")), c(1L, NA_integer_, 3L))

  # Non-numeric becomes NA
  result <- suppressWarnings(meschooldata:::safe_numeric(c("1", "abc", "3")))
  expect_true(is.na(result[2]))
})


test_that("cache functions work correctly", {
  # Clear cache should not error (but may print messages)
  expect_no_error(suppressMessages(clear_cache()))

  # Cache status should return data frame (but may print messages)
  status <- suppressMessages(cache_status())
  expect_s3_class(status, "data.frame")
})


# =============================================================================
# CSV Import Tests with Mock Data
# =============================================================================

test_that("import_local_enrollment parses basic CSV correctly", {
  # Create mock CSV data similar to QuickSight export
  mock_csv <- tempfile(fileext = ".csv")
  on.exit(unlink(mock_csv))

  mock_data <- data.frame(
    `School Year` = c("2023-24", "2023-24", "2023-24"),
    `SAU ID` = c("001", "002", "003"),
    `SAU Name` = c("District A", "District B", "District C"),
    `Total` = c(1000, 500, 750),
    `White` = c(800, 400, 600),
    `Black` = c(100, 50, 75),
    `Hispanic` = c(50, 25, 40),
    `Asian` = c(30, 15, 20),
    `Male` = c(520, 260, 380),
    `Female` = c(480, 240, 370),
    check.names = FALSE
  )

  write.csv(mock_data, mock_csv, row.names = FALSE)

  result <- import_local_enrollment(mock_csv, end_year = 2024)

  expect_s3_class(result, "data.frame")
  expect_gt(nrow(result), 0)

  # Should have State row
  state_rows <- result[result$type == "State", ]
  expect_gt(nrow(state_rows), 0)

  # State total should match sum of inputs
  state_total <- state_rows$row_total[state_rows$subgroup == "total_enrollment" &
                                        state_rows$grade_level == "TOTAL"]
  if (length(state_total) > 0 && !is.na(state_total)) {
    expect_equal(state_total, 2250)  # 1000 + 500 + 750
  }
})


test_that("import_local_enrollment produces no Inf or NaN", {
  mock_csv <- tempfile(fileext = ".csv")
  on.exit(unlink(mock_csv))

  # Include zeros to test division edge cases
  mock_data <- data.frame(
    `SAU ID` = c("001", "002"),
    `Total` = c(100, 0),  # Include zero total
    `White` = c(80, 0),
    `Male` = c(50, 0),
    `Female` = c(50, 0),
    check.names = FALSE
  )

  write.csv(mock_data, mock_csv, row.names = FALSE)

  result <- import_local_enrollment(mock_csv, end_year = 2024)

  # Check for Inf
  numeric_cols <- sapply(result, is.numeric)
  for (col in names(result)[numeric_cols]) {
    expect_false(
      any(is.infinite(result[[col]]), na.rm = TRUE),
      info = paste("Inf found in column:", col)
    )
  }

  # Check for NaN - pct column specifically
  if ("pct" %in% names(result)) {
    expect_false(
      any(is.nan(result$pct)),
      info = "NaN found in pct column"
    )
  }
})


test_that("demographic totals sum correctly", {
  mock_csv <- tempfile(fileext = ".csv")
  on.exit(unlink(mock_csv))

  mock_data <- data.frame(
    `SAU ID` = c("001"),
    `Total` = c(100),
    `White` = c(40),
    `Black` = c(20),
    `Hispanic` = c(15),
    `Asian` = c(10),
    `American Indian` = c(5),
    `Pacific Islander` = c(3),
    `Two or More` = c(7),
    `Male` = c(52),
    `Female` = c(48),
    check.names = FALSE
  )

  write.csv(mock_data, mock_csv, row.names = FALSE)

  result <- import_local_enrollment(mock_csv, end_year = 2024)

  state_data <- result[result$type == "State", ]

  # Get total enrollment
  total_row <- state_data[state_data$subgroup == "total_enrollment" &
                            state_data$grade_level == "TOTAL", ]

  if (nrow(total_row) > 0 && !is.na(total_row$n_students)) {
    total_enrollment <- total_row$n_students

    # Sum of race categories
    race_subgroups <- c("white", "black", "hispanic", "asian",
                        "native_american", "pacific_islander", "multiracial")
    race_sum <- 0
    for (sg in race_subgroups) {
      row <- state_data[state_data$subgroup == sg & state_data$grade_level == "TOTAL", ]
      if (nrow(row) > 0 && !is.na(row$n_students)) {
        race_sum <- race_sum + row$n_students
      }
    }

    # Race sum should equal total
    expect_equal(race_sum, total_enrollment,
                 info = paste("Race sum:", race_sum, "Total:", total_enrollment))

    # Sum of sex categories
    male_row <- state_data[state_data$subgroup == "male" & state_data$grade_level == "TOTAL", ]
    female_row <- state_data[state_data$subgroup == "female" & state_data$grade_level == "TOTAL", ]

    if (nrow(male_row) > 0 && nrow(female_row) > 0) {
      sex_sum <- male_row$n_students + female_row$n_students
      expect_equal(sex_sum, total_enrollment,
                   info = paste("Sex sum:", sex_sum, "Total:", total_enrollment))
    }
  }
})
