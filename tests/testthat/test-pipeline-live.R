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
# 6. Data Quality - No Inf/NaN, valid ranges
# 7. Aggregation Tests - Totals sum correctly
# 8. Output Fidelity - tidy=TRUE matches raw data
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
    regexp = "not available for automated download|QuickSight|dashboard",
    info = "get_raw_enr should fail with informative message about data migration"
  )
})

test_that("fetch_enr fails gracefully when data unavailable", {
  skip_if_offline()

  # Clear cache first to ensure we test the download path
  suppressMessages(meschooldata::clear_cache())

  # Should error with helpful message about manual download
  expect_error(
    meschooldata::fetch_enr(2024, use_cache = FALSE),
    regexp = "not available for automated download|QuickSight|dashboard"
  )
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

# ==============================================================================
# STEP 8: Data Quality Tests (when data available)
# ==============================================================================

# These tests are skipped until data source is fixed, but document what we test

test_that("Processed data has no Inf or NaN values", {
  skip("Skipped until Maine DOE data source is fixed")

  # When working:
  # data <- fetch_enr(2024, tidy = TRUE)
  # numeric_cols <- sapply(data, is.numeric)
  # for (col in names(data)[numeric_cols]) {
  #   expect_false(any(is.infinite(data[[col]])), info = paste("No Inf in", col))
  #   expect_false(any(is.nan(data[[col]])), info = paste("No NaN in", col))
  # }
})

test_that("Enrollment counts are non-negative", {
  skip("Skipped until Maine DOE data source is fixed")

  # When working:
  # data <- fetch_enr(2024, tidy = FALSE)
  # expect_true(all(data$row_total >= 0, na.rm = TRUE))
})

test_that("Percentages are in valid range 0-1", {
  skip("Skipped until Maine DOE data source is fixed")

  # When working:
  # data <- fetch_enr(2024, tidy = TRUE)
  # pct_col <- data$pct[!is.na(data$pct)]
  # expect_true(all(pct_col >= 0 & pct_col <= 1))
})

# ==============================================================================
# STEP 9: Aggregation Tests (when data available)
# ==============================================================================

test_that("District totals sum to state total", {
  skip("Skipped until Maine DOE data source is fixed")

  # When working:
  # data <- fetch_enr(2024, tidy = FALSE)
  # state_total <- data$row_total[data$type == "State"]
  # district_sum <- sum(data$row_total[data$type == "District"], na.rm = TRUE)
  # expect_equal(state_total, district_sum, tolerance = state_total * 0.01)
})

test_that("School totals sum to district totals", {
  skip("Skipped until Maine DOE data source is fixed")

  # When working:
  # data <- fetch_enr(2024, tidy = FALSE)
  # for each district, sum of schools should equal district total
})

# ==============================================================================
# STEP 10: Output Fidelity Tests (when data available)
# ==============================================================================

test_that("tidy=TRUE maintains fidelity to raw data", {
  skip("Skipped until Maine DOE data source is fixed")

  # When working:
  # raw <- fetch_enr(2024, tidy = FALSE)
  # tidy <- fetch_enr(2024, tidy = TRUE)
  #
  # For each entity in raw:
  #   total_enrollment in raw should equal sum of n_students where
  #   subgroup == "total_enrollment" and grade_level == "TOTAL" in tidy
})
