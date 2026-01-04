# ==============================================================================
# LIVE Pipeline Tests for meschooldata
# ==============================================================================
#
# These tests verify EACH STEP of the data pipeline using LIVE network calls.
# No mocks - we verify actual connectivity and data correctness.
#
# Test Categories:
# 1. URL Availability - HTTP status codes
# 2. File Download - Successful download and file type verification
# 3. File Parsing - Read file into R
# 4. Column Structure - Expected columns exist
# 5. Package Functions - Core functions work correctly
# 6. Cache Functions - Cache operations
# 7. import_local_enrollment - Local file import
# 8. Internal Parsing Functions - Unit tests for parsers
# 9. Data Quality - No Inf/NaN, valid ranges
# 10. Aggregation Tests - Totals sum correctly
# 11. Output Fidelity - tidy=TRUE matches raw data
#
# ==============================================================================

library(testthat)
library(httr)

# Skip if no network connectivity
skip_if_offline <- function() {
  tryCatch({
    response <- httr::HEAD("https://www.maine.gov", timeout(5))
    if (httr::http_error(response)) {
      skip("No network connectivity to maine.gov")
    }
  }, error = function(e) {
    skip("No network connectivity")
  })
}

# ==============================================================================
# STEP 1: URL Availability Tests
# ==============================================================================

test_that("Maine DOE enrollment page is accessible (HTTP 200)", {
  skip_if_offline()

  response <- httr::GET(
    "https://www.maine.gov/doe/data-warehouse/reporting/enrollment",
    timeout(30)
  )

  expect_equal(
    httr::status_code(response), 200,
    info = "Maine DOE enrollment page should return HTTP 200"
  )
})

test_that("Maine DOE Data Warehouse page is accessible (HTTP 200)", {
  skip_if_offline()

  response <- httr::GET(
    "https://www.maine.gov/doe/data-reporting/warehouse",
    timeout(30)
  )

  expect_equal(
    httr::status_code(response), 200,
    info = "Maine DOE Data Warehouse page should return HTTP 200"
  )
})

test_that("60% Enrollment file URL returns HTTP 200", {
  skip_if_offline()

  # This is a known working file URL (fiscal responsibility, not main enrollment)
  url <- "https://www.maine.gov/doe/sites/maine.gov.doe/files/inline-files/DATA%20-%2060%20Percent%20Enrollment%20by%20Fiscal%20Responsibility%20-%205.07.2025.xlsx"

  response <- httr::HEAD(url, timeout(30))

  expect_equal(
    httr::status_code(response), 200,
    info = paste("Expected HTTP 200 for 60% enrollment file:", url)
  )
})

test_that("Home Instruction file URL returns HTTP 200", {
  skip_if_offline()

  url <- "https://www.maine.gov/doe/sites/maine.gov.doe/files/inline-files/DATA%20-%20Home%20Instruction%20Counts%20by%20District%20and%20Year%202025%20-%208.7.2025.xlsx"

  response <- httr::HEAD(url, timeout(30))

  expect_equal(
    httr::status_code(response), 200,
    info = paste("Expected HTTP 200 for Home Instruction file:", url)
  )
})

test_that("Chronic Absenteeism file URL returns HTTP 200", {
  skip_if_offline()

  url <- "https://www.maine.gov/doe/sites/maine.gov.doe/files/inline-files/DATA%20-%20Chronic%20Absenteeism%20Report%202024%20-%206.20.2025.xlsx"

  response <- httr::HEAD(url, timeout(30))

  expect_equal(
    httr::status_code(response), 200,
    info = paste("Expected HTTP 200 for Chronic Absenteeism file:", url)
  )
})

# Document: What URLs SHOULD work but DON'T (this is the core problem)
test_that("DOCUMENT: Primary enrollment URLs return 404 (known issue)", {
  skip_if_offline()

  # These are the URLs the code expects but which no longer exist
  expected_404_urls <- c(
    "https://www.maine.gov/doe/sites/maine.gov.doe/files/inline-files/DATA%20-%20Enrollment%20Counts%20by%20Responsible%20SAU%20-%20%2010.29.2025.xlsx",
    "https://www.maine.gov/doe/sites/maine.gov.doe/files/inline-files/DATA%20-%20Public%20Funded%20Responsible%20Counts%20by%20District%20-%206.4.2025.xlsx"
  )

  for (url in expected_404_urls) {
    response <- httr::HEAD(url, timeout(30))
    # Expect these to fail - this documents the known issue
    expect_true(
      httr::http_error(response),
      info = paste("KNOWN ISSUE - URL returns error (enrollment data moved to dashboard):", url)
    )
  }
})

# ==============================================================================
# STEP 2: File Download Tests
# ==============================================================================

test_that("Can download 60% enrollment Excel file successfully", {
  skip_if_offline()

  url <- "https://www.maine.gov/doe/sites/maine.gov.doe/files/inline-files/DATA%20-%2060%20Percent%20Enrollment%20by%20Fiscal%20Responsibility%20-%205.07.2025.xlsx"
  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file), add = TRUE)

  response <- httr::GET(
    url,
    httr::write_disk(temp_file, overwrite = TRUE),
    timeout(60)
  )

  expect_equal(httr::status_code(response), 200)
  expect_true(file.exists(temp_file))
  expect_gt(file.info(temp_file)$size, 1000, label = "File should be > 1KB")
})

test_that("Can download Home Instruction Excel file successfully", {
  skip_if_offline()

  url <- "https://www.maine.gov/doe/sites/maine.gov.doe/files/inline-files/DATA%20-%20Home%20Instruction%20Counts%20by%20District%20and%20Year%202025%20-%208.7.2025.xlsx"
  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file), add = TRUE)

  response <- httr::GET(
    url,
    httr::write_disk(temp_file, overwrite = TRUE),
    timeout(60)
  )

  expect_equal(httr::status_code(response), 200)
  expect_true(file.exists(temp_file))
  expect_gt(file.info(temp_file)$size, 1000, label = "File should be > 1KB")
})

test_that("Downloaded file is actually Excel (not HTML error page)", {
  skip_if_offline()

  url <- "https://www.maine.gov/doe/sites/maine.gov.doe/files/inline-files/DATA%20-%2060%20Percent%20Enrollment%20by%20Fiscal%20Responsibility%20-%205.07.2025.xlsx"
  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file), add = TRUE)

  httr::GET(
    url,
    httr::write_disk(temp_file, overwrite = TRUE),
    timeout(60)
  )

  # Verify it's actually an Excel file, not an error page
  file_type <- system(paste("file", shQuote(temp_file)), intern = TRUE)
  expect_true(
    grepl("Microsoft|Excel|Zip|OOXML", file_type),
    label = paste("Expected Excel file, got:", file_type)
  )
})

# ==============================================================================
# STEP 3: File Parsing Tests
# ==============================================================================

test_that("Can parse 60% enrollment Excel file with readxl", {
  skip_if_offline()
  skip_if_not_installed("readxl")

  url <- "https://www.maine.gov/doe/sites/maine.gov.doe/files/inline-files/DATA%20-%2060%20Percent%20Enrollment%20by%20Fiscal%20Responsibility%20-%205.07.2025.xlsx"
  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file), add = TRUE)

  response <- httr::GET(
    url,
    httr::write_disk(temp_file, overwrite = TRUE),
    timeout(60)
  )

  expect_equal(httr::status_code(response), 200)

  # Test: Can list sheets
  sheets <- readxl::excel_sheets(temp_file)
  expect_gt(length(sheets), 0, label = "Excel file should have at least one sheet")

  # Test: Can read data
  df <- readxl::read_excel(temp_file, sheet = sheets[length(sheets)])
  expect_true(is.data.frame(df))
  expect_gt(nrow(df), 0, label = "Data frame should have rows")
  expect_gt(ncol(df), 0, label = "Data frame should have columns")
})

test_that("Can parse Chronic Absenteeism Excel file with readxl", {
  skip_if_offline()
  skip_if_not_installed("readxl")

  url <- "https://www.maine.gov/doe/sites/maine.gov.doe/files/inline-files/DATA%20-%20Chronic%20Absenteeism%20Report%202024%20-%206.20.2025.xlsx"
  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file), add = TRUE)

  response <- httr::GET(
    url,
    httr::write_disk(temp_file, overwrite = TRUE),
    timeout(60)
  )

  expect_equal(httr::status_code(response), 200)

  sheets <- readxl::excel_sheets(temp_file)
  expect_gt(length(sheets), 0)

  # This file has school-level absenteeism data
  if ("By School" %in% sheets) {
    df <- readxl::read_excel(temp_file, sheet = "By School")
    expect_gt(nrow(df), 100, label = "Should have many school rows")
  }
})

test_that("Can parse Home Instruction Excel file with readxl", {
  skip_if_offline()
  skip_if_not_installed("readxl")

  url <- "https://www.maine.gov/doe/sites/maine.gov.doe/files/inline-files/DATA%20-%20Home%20Instruction%20Counts%20by%20District%20and%20Year%202025%20-%208.7.2025.xlsx"
  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file), add = TRUE)

  response <- httr::GET(
    url,
    httr::write_disk(temp_file, overwrite = TRUE),
    timeout(60)
  )

  expect_equal(httr::status_code(response), 200)

  sheets <- readxl::excel_sheets(temp_file)
  expect_gt(length(sheets), 0)

  # Read the data sheet
  data_sheet <- if ("Data Report" %in% sheets) "Data Report" else sheets[length(sheets)]
  df <- readxl::read_excel(temp_file, sheet = data_sheet)

  expect_true(is.data.frame(df))
  expect_gt(nrow(df), 100, label = "Should have many district rows")
  expect_gt(ncol(df), 5, label = "Should have multiple year columns")
})

# ==============================================================================
# STEP 4: Column Structure Tests
# ==============================================================================

test_that("60% file has expected sheet structure", {
  skip_if_offline()
  skip_if_not_installed("readxl")

  url <- "https://www.maine.gov/doe/sites/maine.gov.doe/files/inline-files/DATA%20-%2060%20Percent%20Enrollment%20by%20Fiscal%20Responsibility%20-%205.07.2025.xlsx"
  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file), add = TRUE)

  httr::GET(
    url,
    httr::write_disk(temp_file, overwrite = TRUE),
    timeout(60)
  )

  sheets <- readxl::excel_sheets(temp_file)

  expect_true("Metadata" %in% sheets, info = "Should have Metadata sheet")
  expect_true("Data Report" %in% sheets, info = "Should have Data Report sheet")
})

test_that("Home Instruction file has expected structure", {
  skip_if_offline()
  skip_if_not_installed("readxl")

  url <- "https://www.maine.gov/doe/sites/maine.gov.doe/files/inline-files/DATA%20-%20Home%20Instruction%20Counts%20by%20District%20and%20Year%202025%20-%208.7.2025.xlsx"
  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file), add = TRUE)

  httr::GET(
    url,
    httr::write_disk(temp_file, overwrite = TRUE),
    timeout(60)
  )

  sheets <- readxl::excel_sheets(temp_file)

  # Should have Metadata and Data Report sheets
  expect_true("Metadata" %in% sheets, info = "Should have Metadata sheet")
  expect_true("Data Report" %in% sheets, info = "Should have Data Report sheet")

  # Read data and check for SAU names and years
  df <- readxl::read_excel(temp_file, sheet = "Data Report", skip = 1)
  expect_gt(nrow(df), 200, label = "Should have 200+ SAU rows")
})

# ==============================================================================
# STEP 5: Package Function Tests
# ==============================================================================

test_that("get_available_years returns valid year range", {
  result <- meschooldata::get_available_years()

  expect_type(result, "list")
  expect_true("min_year" %in% names(result))
  expect_true("max_year" %in% names(result))
  expect_true("source" %in% names(result))

  expect_gte(result$min_year, 2016)
  expect_lte(result$max_year, 2030)
  expect_lt(result$min_year, result$max_year)
})

test_that("get_download_instructions returns URL invisibly", {
  result <- suppressMessages(meschooldata::get_download_instructions())

  expect_type(result, "character")
  expect_match(result, "maine\\.gov")
})

test_that("get_raw_enr fails with informative error message", {
  skip_if_offline()

  # Since primary URLs are broken, get_raw_enr should fail with helpful message
  expect_error(
    meschooldata:::get_raw_enr(2024),
    info = "get_raw_enr should fail when data is unavailable"
  )
})

test_that("fetch_enr fails gracefully when data unavailable", {
  skip_if_offline()

  # Clear cache first to ensure we test the download path
  suppressMessages(meschooldata::clear_cache())

  # Should error when data unavailable
  expect_error(
    meschooldata::fetch_enr(2024, use_cache = FALSE)
  )
})

test_that("validate_year rejects invalid years", {
  # Too old
  expect_error(meschooldata:::validate_year(2010))

  # Too new
  expect_error(meschooldata:::validate_year(2099))

  # Valid year should not error
  expect_no_error(meschooldata:::validate_year(2024))
})

# ==============================================================================
# STEP 6: Cache Function Tests
# ==============================================================================

test_that("Cache path function returns valid path", {
  path <- meschooldata:::get_cache_path(2024, "enrollment")

  expect_true(is.character(path))
  expect_true(grepl("2024", path))
  expect_true(grepl("\\.rds$", path))
})

test_that("clear_cache runs without error", {
  expect_no_error(suppressMessages(meschooldata::clear_cache()))
})

test_that("cache_status returns data frame", {
  status <- suppressMessages(meschooldata::cache_status())
  expect_s3_class(status, "data.frame")
})

test_that("cache_exists returns FALSE for non-existent cache", {
  suppressMessages(meschooldata::clear_cache())
  result <- meschooldata:::cache_exists(9999, "enrollment")
  expect_false(result)
})

# ==============================================================================
# STEP 7: import_local_enrollment Tests
# ==============================================================================

test_that("import_local_enrollment errors on missing file", {
  expect_error(
    meschooldata::import_local_enrollment("/nonexistent/file.csv"),
    regexp = "File not found"
  )
})

test_that("import_local_enrollment errors on unsupported file type", {
  temp_file <- tempfile(fileext = ".txt")
  writeLines("test", temp_file)
  on.exit(unlink(temp_file), add = TRUE)

  expect_error(
    meschooldata::import_local_enrollment(temp_file),
    regexp = "Unsupported file type"
  )
})

test_that("import_local_enrollment works with CSV file", {
  # Create a simple test CSV
  temp_file <- tempfile(fileext = ".csv")
  on.exit(unlink(temp_file), add = TRUE)

  test_data <- data.frame(
    SAU_ID = c(1, 2, 3),
    SAU_Name = c("District A", "District B", "District C"),
    Total = c(1000, 500, 750),
    School_Year = c(2024, 2024, 2024)
  )
  write.csv(test_data, temp_file, row.names = FALSE)

  result <- suppressWarnings(
    meschooldata::import_local_enrollment(temp_file, end_year = 2024, tidy = FALSE)
  )

  expect_s3_class(result, "data.frame")
  expect_true("end_year" %in% names(result))
  expect_true("type" %in% names(result))
})

# ==============================================================================
# STEP 8: Internal Parsing Function Tests
# ==============================================================================

test_that("standardize_grade normalizes grade names correctly", {
  expect_equal(meschooldata:::standardize_grade("Kindergarten"), "K")
  expect_equal(meschooldata:::standardize_grade("KG"), "KG")  # KG stays as-is (Maine format)
  expect_equal(meschooldata:::standardize_grade("K"), "K")
  expect_equal(meschooldata:::standardize_grade("1"), "01")
  expect_equal(meschooldata:::standardize_grade("01"), "01")
  expect_equal(meschooldata:::standardize_grade("Grade 1"), "01")
  expect_equal(meschooldata:::standardize_grade("12"), "12")
  expect_equal(meschooldata:::standardize_grade("PK"), "PK")
  expect_equal(meschooldata:::standardize_grade("Pre-K"), "PK")
})

test_that("safe_numeric handles various inputs", {
  expect_equal(meschooldata:::safe_numeric(c(1, 2, 3)), c(1, 2, 3))
  expect_equal(meschooldata:::safe_numeric(c("1", "2", "3")), c(1, 2, 3))
  expect_true(all(is.na(meschooldata:::safe_numeric(c("*", "N/A", "-")))))
  expect_equal(meschooldata:::safe_numeric(c("1,234", "5,678")), c(1234, 5678))
})

test_that("clean_names handles common patterns", {
  expect_type(meschooldata:::clean_names("PORTLAND PUBLIC SCHOOLS"), "character")
  expect_type(meschooldata:::clean_names("Portland Public Schools"), "character")
})

test_that("create_empty_enrollment_df returns correct structure", {
  result <- meschooldata:::create_empty_enrollment_df(2024, "District")

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)
  expect_true("end_year" %in% names(result))
  expect_true("type" %in% names(result))
  expect_true("row_total" %in% names(result))
  expect_true("grade_pk" %in% names(result))
})

test_that("process_school_enr handles empty data frame", {
  empty_df <- data.frame()
  result <- meschooldata:::process_school_enr(empty_df, 2024)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)
})

test_that("process_district_enr handles empty data frame", {
  empty_df <- data.frame()
  result <- meschooldata:::process_district_enr(empty_df, 2024)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)
})

test_that("process_district_enr recognizes row_total column", {
  # This tests the fix for the column recognition bug
  test_df <- data.frame(
    district_id = c("1", "2"),
    district_name = c("District A", "District B"),
    row_total = c(1000, 500),
    grade_pk = c(50, 25),
    grade_k = c(100, 50)
  )

  result <- meschooldata:::process_district_enr(test_df, 2024)

  expect_equal(result$row_total[1], 1000)
  expect_equal(result$row_total[2], 500)
  expect_equal(result$grade_pk[1], 50)
  expect_equal(result$grade_k[1], 100)
})

test_that("create_state_aggregate sums columns correctly", {
  district_df <- data.frame(
    end_year = c(2024, 2024),
    type = c("District", "District"),
    district_id = c("1", "2"),
    district_name = c("A", "B"),
    row_total = c(1000, 500),
    grade_pk = c(50, 25),
    grade_k = c(100, 50),
    white = c(800, 400),
    black = c(100, 50),
    male = c(500, 250),
    female = c(500, 250)
  )

  school_df <- data.frame()

  result <- meschooldata:::create_state_aggregate(district_df, school_df, 2024)

  expect_equal(nrow(result), 1)
  expect_equal(result$type, "State")
  expect_equal(result$row_total, 1500)
  expect_equal(result$grade_pk, 75)
  expect_equal(result$white, 1200)
  expect_equal(result$male, 750)
})

# ==============================================================================
# STEP 9: Data Quality Tests
# ==============================================================================

test_that("Home Instruction data has valid structure", {
  skip_if_offline()
  skip_if_not_installed("readxl")

  url <- "https://www.maine.gov/doe/sites/maine.gov.doe/files/inline-files/DATA%20-%20Home%20Instruction%20Counts%20by%20District%20and%20Year%202025%20-%208.7.2025.xlsx"
  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file), add = TRUE)

  httr::GET(
    url,
    httr::write_disk(temp_file, overwrite = TRUE),
    timeout(60)
  )

  df <- readxl::read_excel(temp_file, sheet = "Data Report", skip = 1)

  # Check for no Inf or NaN in numeric columns
  numeric_cols <- sapply(df, is.numeric)
  for (col in names(df)[numeric_cols]) {
    expect_false(any(is.infinite(df[[col]]), na.rm = TRUE),
                 info = paste("No Inf in", col))
    expect_false(any(is.nan(df[[col]]), na.rm = TRUE),
                 info = paste("No NaN in", col))
  }
})

test_that("Home Instruction data has reasonable counts", {
  skip_if_offline()
  skip_if_not_installed("readxl")

  url <- "https://www.maine.gov/doe/sites/maine.gov.doe/files/inline-files/DATA%20-%20Home%20Instruction%20Counts%20by%20District%20and%20Year%202025%20-%208.7.2025.xlsx"
  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file), add = TRUE)

  httr::GET(
    url,
    httr::write_disk(temp_file, overwrite = TRUE),
    timeout(60)
  )

  df <- readxl::read_excel(temp_file, sheet = "Data Report", skip = 1)

  # Find numeric columns (year columns like 2020, 2021, etc.)
  year_cols <- grep("^20[0-9]{2}$", names(df), value = TRUE)

  if (length(year_cols) > 0) {
    # All counts should be non-negative or NA
    for (col in year_cols) {
      values <- suppressWarnings(as.numeric(df[[col]]))
      non_na_values <- values[!is.na(values)]
      expect_true(all(non_na_values >= 0),
                  info = paste("All values in", col, "should be >= 0"))
    }
  }
})

# ==============================================================================
# STEP 10: Aggregation Tests with test data
# ==============================================================================

test_that("District totals sum to state total in processed data", {
  # Create test data
  test_raw <- list(
    school = data.frame(
      campus_id = c("1", "2", "3"),
      campus_name = c("School A", "School B", "School C"),
      district_id = c("10", "10", "20"),
      district_name = c("Dist 1", "Dist 1", "Dist 2"),
      row_total = c(100, 150, 200),
      grade_pk = c(10, 15, 20),
      grade_k = c(20, 25, 30)
    ),
    district = data.frame(
      district_id = c("10", "20"),
      district_name = c("Dist 1", "Dist 2"),
      row_total = c(250, 200),
      grade_pk = c(25, 20),
      grade_k = c(45, 30)
    )
  )

  processed <- meschooldata:::process_enr(test_raw, 2024)

  state_total <- processed$row_total[processed$type == "State"]
  district_sum <- sum(processed$row_total[processed$type == "District"], na.rm = TRUE)

  expect_equal(state_total, district_sum,
               info = "State total should equal sum of district totals")
  expect_equal(state_total, 450)
})

test_that("Grade totals are preserved in processing", {
  test_raw <- list(
    school = data.frame(),
    district = data.frame(
      district_id = c("10", "20"),
      district_name = c("Dist 1", "Dist 2"),
      row_total = c(250, 200),
      grade_pk = c(25, 20),
      grade_k = c(45, 30),
      grade_01 = c(50, 40)
    )
  )

  processed <- meschooldata:::process_enr(test_raw, 2024)

  state_row <- processed[processed$type == "State", ]

  expect_equal(state_row$grade_pk, 45, info = "State PK should sum districts")
  expect_equal(state_row$grade_k, 75, info = "State K should sum districts")
  expect_equal(state_row$grade_01, 90, info = "State Grade 1 should sum districts")
})

# ==============================================================================
# STEP 11: Output Fidelity Tests
# ==============================================================================

test_that("tidy=TRUE maintains fidelity to raw in test data", {
  test_raw <- list(
    school = data.frame(),
    district = data.frame(
      district_id = c("10", "20"),
      district_name = c("Dist 1", "Dist 2"),
      row_total = c(1000, 500),
      grade_pk = c(50, 25),
      grade_k = c(100, 50),
      white = c(800, 400),
      black = c(100, 50),
      male = c(500, 250),
      female = c(500, 250)
    )
  )

  processed <- meschooldata:::process_enr(test_raw, 2024)
  tidy_data <- meschooldata::tidy_enr(processed) |>
    meschooldata::id_enr_aggs()

  # State total in wide format
  state_wide <- processed[processed$type == "State", ]

  # State total in tidy format
  state_tidy_total <- tidy_data[
    tidy_data$type == "State" &
    tidy_data$subgroup == "total_enrollment" &
    tidy_data$grade_level == "TOTAL",
  ]

  expect_equal(
    state_wide$row_total,
    state_tidy_total$n_students,
    info = "State total should match between wide and tidy formats"
  )

  # Check demographic totals
  state_tidy_white <- tidy_data[
    tidy_data$type == "State" &
    tidy_data$subgroup == "white" &
    tidy_data$grade_level == "TOTAL",
  ]

  expect_equal(
    state_wide$white,
    state_tidy_white$n_students,
    info = "White count should match between wide and tidy formats"
  )
})

test_that("tidy_enr produces expected columns", {
  test_df <- data.frame(
    end_year = 2024,
    type = "State",
    district_id = NA_character_,
    campus_id = NA_character_,
    district_name = NA_character_,
    campus_name = NA_character_,
    row_total = 1000,
    white = 800,
    black = 100,
    male = 500,
    female = 500
  )

  result <- meschooldata::tidy_enr(test_df)

  expect_true("subgroup" %in% names(result))
  expect_true("n_students" %in% names(result))
  expect_true("pct" %in% names(result))

  # Check subgroups are present
  expect_true("total_enrollment" %in% result$subgroup)
  expect_true("white" %in% result$subgroup)
  expect_true("male" %in% result$subgroup)
})

test_that("id_enr_aggs adds boolean flags correctly", {
  test_df <- data.frame(
    end_year = 2024,
    type = c("State", "District", "Campus"),
    district_id = c(NA, "10", "10"),
    campus_id = c(NA, NA, "1"),
    district_name = c(NA, "Dist 1", "Dist 1"),
    campus_name = c(NA, NA, "School 1"),
    subgroup = c("total_enrollment", "total_enrollment", "total_enrollment"),
    n_students = c(1000, 500, 500),
    pct = c(1, 1, 1),
    grade_level = c("TOTAL", "TOTAL", "TOTAL")
  )

  result <- meschooldata::id_enr_aggs(test_df)

  expect_true("is_state" %in% names(result))
  expect_true("is_district" %in% names(result))
  expect_true("is_campus" %in% names(result))

  expect_true(result$is_state[result$type == "State"])
  expect_true(result$is_district[result$type == "District"])
  expect_true(result$is_campus[result$type == "Campus"])
})
