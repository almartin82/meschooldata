# ==============================================================================
# Raw Enrollment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw enrollment data from Maine DOE.
# Data comes from the Maine DOE Data Warehouse (2016-present).
#
# Maine DOE provides enrollment data through the Data Warehouse with Excel files
# containing multiple years of data based on Annual October 1 certified data sets.
#
# Data Source: https://www.maine.gov/doe/data-warehouse/reporting/enrollment
#
# STATUS: As of January 2026, the primary enrollment data files are NOT available
# via direct download. Maine DOE has migrated to QuickSight/Tableau dashboards.
# The package provides import_local_enrollment() for manually downloaded data.
#
# ==============================================================================

#' Get download instructions for Maine enrollment data
#'
#' Since Maine DOE enrollment data is not available for automated download,
#' this function provides instructions for manually downloading data from
#' the QuickSight dashboard.
#'
#' @return Invisibly returns the Maine DOE data URL
#' @export
#' @examples
#' get_download_instructions()
get_download_instructions <- function() {
  url <- "https://www.maine.gov/doe/data-warehouse/reporting/enrollment"

  message("============================================================")
  message("Maine DOE Enrollment Data - Manual Download Required")
  message("============================================================")

  message("")
  message("Maine DOE has migrated enrollment data to interactive dashboards.")
  message("Direct Excel file downloads are no longer available.")
  message("")
  message("To obtain enrollment data:")
  message("")
  message("1. Visit the Maine DOE enrollment page:")
  message("   ", url)
  message("")
  message("2. Access the QuickFacts dashboard:")
  message("   https://p20w.slds.maine.gov/QuickFacts")
  message("")
  message("3. Export data from the dashboard (if available) or")
  message("   contact Maine DOE for custom data requests:")
  message("   medms.helpdesk@maine.gov")
  message("")
  message("4. Once you have a downloaded file, use:")
  message("   import_local_enrollment('path/to/your/file.xlsx')")
  message("")
  message("============================================================")

  invisible(url)
}


#' Download raw enrollment data from Maine DOE
#'
#' Downloads enrollment data from Maine DOE's Data Warehouse.
#' Data is available from 2016 to present.
#'
#' NOTE: As of January 2026, direct download is not available. Maine DOE
#' has migrated to QuickSight dashboards. Use import_local_enrollment()
#' with manually downloaded data instead.
#'
#' @param end_year School year end (2023-24 = 2024)
#' @return List with school and district data frames
#' @keywords internal
get_raw_enr <- function(end_year) {

  validate_year(end_year)

  message(paste("Downloading Maine DOE enrollment data for", end_year, "..."))
  download_maine_doe(end_year)
}


#' Download from Maine DOE Data Warehouse
#'
#' Downloads enrollment data from the Maine DOE Data Warehouse Excel files.
#' The files contain multiple years of data (2016+).
#'
#' Maine DOE provides several enrollment files:
#' - Public Funded Attending Counts by District
#' - Public Funded Responsible Counts by District
#' - Public Funded Residential Counts by Town and County
#'
#' @param end_year School year end
#' @return List with school and district data
#' @keywords internal
download_maine_doe <- function(end_year) {

  message("  Downloading from Maine DOE Data Warehouse...")

  # Maine DOE enrollment file URLs
  # Source: https://www.maine.gov/doe/data-warehouse/reporting/enrollment
  # Files contain multi-year data based on Annual October 1 certified data sets
  base_url <- "https://www.maine.gov"

  # Primary enrollment file - Public Funded Responsible Counts by District
  # This file contains enrollment by SAU (district) with school year breakdown
  primary_url <- paste0(
    base_url,
    "/doe/sites/maine.gov.doe/files/inline-files/",
    "DATA%20-%20Enrollment%20Counts%20by%20Responsible%20SAU%20-%20%2010.29.2025.xlsx"
  )

  # Alternative file - Public Funded Attending Counts
  alt_url <- paste0(
    base_url,
    "/doe/sites/maine.gov.doe/files/inline-files/",
    "DATA%20-%20Public%20Funded%20Responsible%20Counts%20by%20District%20-%206.4.2025.xlsx"
  )

  temp_file <- tempfile(fileext = ".xlsx")

  # Try primary URL first
  download_success <- FALSE

  for (url in c(primary_url, alt_url)) {
    tryCatch({
      response <- httr::GET(
        url,
        httr::write_disk(temp_file, overwrite = TRUE),
        httr::config(connecttimeout = 60, timeout = 300),
        httr::user_agent("meschooldata R package")
      )

      if (!httr::http_error(response) && file.info(temp_file)$size > 1000) {
        download_success <- TRUE
        message("  Successfully downloaded from Maine DOE")
        break
      }
    }, error = function(e) {
      # Try next URL
    })
  }

  if (!download_success) {
    unlink(temp_file)
    stop(paste0(
      "Maine DOE enrollment data is not available for automated download.\n",
      "Maine DOE has migrated to QuickSight dashboards.\n\n",
      "To obtain data:\n",
      "1. Run get_download_instructions() for guidance\n",
      "2. Download data manually from the dashboard\n",
      "3. Use import_local_enrollment('path/to/file.xlsx')\n\n",
      "Data source: https://www.maine.gov/doe/data-warehouse/reporting/enrollment"
    ))
  }

  # Parse the Excel file
  raw_data <- tryCatch({
    parse_maine_doe_excel(temp_file, end_year)
  }, error = function(e) {
    unlink(temp_file)
    stop(paste0(
      "Error parsing Maine DOE Excel file: ", e$message, "\n",
      "The file format may have changed. Please report this issue."
    ))
  })

  unlink(temp_file)

  raw_data
}


#' Parse Maine DOE Excel file
#'
#' Extracts school and district data for a specific year from the
#' multi-year Maine DOE Excel file.
#'
#' @param file_path Path to downloaded Excel file
#' @param end_year School year end to extract
#' @return List with school and district data frames
#' @keywords internal
parse_maine_doe_excel <- function(file_path, end_year) {

  # The Maine DOE file has multiple sheets:
  # - Metadata: Report info
  # - State Level: State totals by grade and year
  # - School Level: School/district-level data by grade and year (wide format)
  # - Raw Data: Detailed raw records (long format - preferred)

  sheets <- readxl::excel_sheets(file_path)

  # Prefer "Raw Data" sheet (long format) for easier processing
  if ("Raw Data" %in% sheets) {
    raw_df <- readxl::read_excel(file_path, sheet = "Raw Data")

    # Check for expected columns
    cols <- names(raw_df)

    # Look for School Year column to filter by year
    year_col <- grep("School.?Year", cols, value = TRUE, ignore.case = TRUE)
    if (length(year_col) > 0) {
      # Filter to requested year
      raw_df <- raw_df[raw_df[[year_col[1]]] == end_year, ]
    }

    if (nrow(raw_df) == 0) {
      # Check what years are available
      full_df <- readxl::read_excel(file_path, sheet = "Raw Data")
      if (length(year_col) > 0) {
        available_years <- sort(unique(full_df[[year_col[1]]]))
        stop(paste0(
          "Year ", end_year, " not found in Maine DOE data.\n",
          "Available years: ", paste(available_years, collapse = ", "), "\n"
        ))
      }
    }

    # Parse from long format
    result <- parse_raw_data_sheet(raw_df, end_year)
    return(result)
  }

  # Fallback: try State Level sheet (wide format)
  if ("State Level" %in% sheets) {
    state_df <- readxl::read_excel(file_path, sheet = "State Level", skip = 2)
    cols <- names(state_df)
    year_col <- as.character(end_year)

    if (!year_col %in% cols) {
      available_years <- grep("^20[0-9]{2}$", cols, value = TRUE)
      stop(paste0(
        "Year ", end_year, " not found in Maine DOE data.\n",
        "Available years in file: ", paste(sort(available_years), collapse = ", "), "\n",
        "Maine DOE data is available from 2016 to present."
      ))
    }

    school_data <- transform_state_level_data(state_df, end_year)
    return(list(
      school = school_data,
      district = create_empty_enrollment_df(end_year, "District")
    ))
  }

  stop("Could not find expected data sheets in Maine DOE file")
}


#' Parse Raw Data sheet from Maine DOE Excel
#'
#' The Raw Data sheet contains long-format data with columns:
#' School Year, SAU ID, Attending SAU Name, School ID, Attending School Name, Grade, Attending Student Count
#'
#' @param df Data frame from Raw Data sheet
#' @param end_year School year end
#' @return List with school and district data frames
#' @keywords internal
parse_raw_data_sheet <- function(df, end_year) {

  cols <- names(df)

  # Find column names (Maine DOE uses various naming conventions)
  sau_id_col <- grep("SAU.?ID", cols, value = TRUE, ignore.case = TRUE)[1]
  sau_name_col <- grep("SAU.?Name|Attending.?SAU", cols, value = TRUE, ignore.case = TRUE)[1]
  school_id_col <- grep("School.?ID", cols, value = TRUE, ignore.case = TRUE)[1]
  school_name_col <- grep("School.?Name|Attending.?School", cols, value = TRUE, ignore.case = TRUE)[1]
  grade_col <- grep("^Grade$", cols, value = TRUE, ignore.case = TRUE)[1]
  count_col <- grep("Count|Enrollment|Students", cols, value = TRUE, ignore.case = TRUE)[1]

  if (is.na(count_col)) {
    # Find any numeric column as fallback
    num_cols <- cols[sapply(df, is.numeric)]
    count_col <- tail(num_cols, 1)
  }

  # Aggregate to school level (sum across grades)
  school_data <- df |>
    dplyr::group_by(
      sau_id = if (!is.na(sau_id_col)) .data[[sau_id_col]] else NA,
      district_name = if (!is.na(sau_name_col)) .data[[sau_name_col]] else NA,
      campus_id = if (!is.na(school_id_col)) .data[[school_id_col]] else NA,
      campus_name = if (!is.na(school_name_col)) .data[[school_name_col]] else NA
    ) |>
    dplyr::summarize(
      row_total = sum(.data[[count_col]], na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      end_year = end_year,
      type = "Campus",
      district_id = as.character(sau_id),
      campus_id = as.character(campus_id)
    ) |>
    dplyr::select(-sau_id)

  # Also create grade-level columns by pivoting
  if (!is.na(grade_col)) {
    grade_pivot <- df |>
      dplyr::group_by(
        sau_id = if (!is.na(sau_id_col)) .data[[sau_id_col]] else NA,
        district_name = if (!is.na(sau_name_col)) .data[[sau_name_col]] else NA,
        campus_id_orig = if (!is.na(school_id_col)) .data[[school_id_col]] else NA,
        campus_name = if (!is.na(school_name_col)) .data[[school_name_col]] else NA,
        grade = .data[[grade_col]]
      ) |>
      dplyr::summarize(
        count = sum(.data[[count_col]], na.rm = TRUE),
        .groups = "drop"
      ) |>
      dplyr::mutate(
        grade_std = standardize_grade(grade)
      ) |>
      tidyr::pivot_wider(
        id_cols = c(sau_id, district_name, campus_id_orig, campus_name),
        names_from = grade_std,
        values_from = count,
        values_fill = 0
      )

    # Map grade columns
    grade_map <- c(
      "PK" = "grade_pk", "K" = "grade_k",
      "01" = "grade_01", "02" = "grade_02", "03" = "grade_03", "04" = "grade_04",
      "05" = "grade_05", "06" = "grade_06", "07" = "grade_07", "08" = "grade_08",
      "09" = "grade_09", "10" = "grade_10", "11" = "grade_11", "12" = "grade_12"
    )

    for (from in names(grade_map)) {
      to <- grade_map[from]
      if (from %in% names(grade_pivot)) {
        school_data[[to]] <- grade_pivot[[from]][match(
          paste(school_data$district_id, school_data$campus_id),
          paste(grade_pivot$sau_id, grade_pivot$campus_id_orig)
        )]
      } else {
        school_data[[to]] <- NA_integer_
      }
    }
  }

  # Create district aggregate
  district_data <- school_data |>
    dplyr::group_by(district_id, district_name) |>
    dplyr::summarize(
      row_total = sum(row_total, na.rm = TRUE),
      dplyr::across(dplyr::starts_with("grade_"), ~sum(.x, na.rm = TRUE)),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      end_year = end_year,
      type = "District",
      campus_id = NA_character_,
      campus_name = NA_character_
    )

  list(
    school = as.data.frame(school_data),
    district = as.data.frame(district_data)
  )
}


#' Transform State Level data to standard format
#'
#' @param df Data frame from State Level sheet
#' @param end_year Year to extract
#' @return Data frame with state-level enrollment
#' @keywords internal
transform_state_level_data <- function(df, end_year) {

  cols <- names(df)
  year_col <- as.character(end_year)

  # State-level format: Grade column + year columns with enrollment counts
  result <- df |>
    dplyr::select(Grade = 1, enrollment = dplyr::all_of(year_col)) |>
    dplyr::filter(!is.na(Grade), !grepl("Grand|Total", Grade, ignore.case = TRUE)) |>
    dplyr::mutate(
      enrollment = safe_numeric(enrollment)
    )

  # Build state row
  state_row <- data.frame(
    end_year = end_year,
    type = "State",
    district_id = NA_character_,
    campus_id = NA_character_,
    district_name = NA_character_,
    campus_name = NA_character_,
    row_total = sum(result$enrollment, na.rm = TRUE),
    stringsAsFactors = FALSE
  )

  # Add grade columns
  grade_map <- c(
    "PK" = "grade_pk", "KG" = "grade_k",
    "1" = "grade_01", "2" = "grade_02", "3" = "grade_03", "4" = "grade_04",
    "5" = "grade_05", "6" = "grade_06", "7" = "grade_07", "8" = "grade_08",
    "9" = "grade_09", "10" = "grade_10", "11" = "grade_11", "12" = "grade_12"
  )

  for (from in names(grade_map)) {
    to <- grade_map[from]
    grade_val <- result |>
      dplyr::filter(Grade == from) |>
      dplyr::pull(enrollment)

    state_row[[to]] <- if (length(grade_val) > 0) grade_val[1] else NA_integer_
  }

  state_row
}


#' Create empty enrollment data frame
#'
#' @param end_year School year end
#' @param type "Campus", "District", or "State"
#' @return Empty data frame with expected columns
#' @keywords internal
create_empty_enrollment_df <- function(end_year, type) {
  data.frame(
    end_year = integer(),
    type = character(),
    district_id = character(),
    campus_id = character(),
    district_name = character(),
    campus_name = character(),
    county = character(),
    row_total = integer(),
    white = integer(),
    black = integer(),
    hispanic = integer(),
    asian = integer(),
    pacific_islander = integer(),
    native_american = integer(),
    multiracial = integer(),
    male = integer(),
    female = integer(),
    grade_pk = integer(),
    grade_k = integer(),
    grade_01 = integer(),
    grade_02 = integer(),
    grade_03 = integer(),
    grade_04 = integer(),
    grade_05 = integer(),
    grade_06 = integer(),
    grade_07 = integer(),
    grade_08 = integer(),
    grade_09 = integer(),
    grade_10 = integer(),
    grade_11 = integer(),
    grade_12 = integer(),
    stringsAsFactors = FALSE
  )
}


# ==============================================================================
# Local File Import Functions
# ==============================================================================

#' Import enrollment data from a local file
#'
#' Reads enrollment data from a locally downloaded Excel or CSV file.
#' Use this function when automatic download is not available (e.g., when
#' Maine DOE has moved data to a dashboard).
#'
#' @param file_path Path to the local Excel (.xlsx) or CSV file
#' @param end_year School year end (e.g., 2024 for 2023-24). If not provided,
#'   the function will attempt to detect it from the file.
#' @param tidy If TRUE (default), returns data in long (tidy) format.
#' @return Data frame with enrollment data
#' @export
#' @examples
#' \dontrun{
#' # Import from manually downloaded Excel file
#' enr <- import_local_enrollment("~/Downloads/maine_enrollment.xlsx", end_year = 2024)
#'
#' # Import from CSV export
#' enr <- import_local_enrollment("~/Downloads/quicksight_export.csv", end_year = 2024)
#' }
import_local_enrollment <- function(file_path, end_year = NULL, tidy = TRUE) {

  # Check file exists

  if (!file.exists(file_path)) {
    stop("File not found: ", file_path)
  }

  # Determine file type
  ext <- tolower(tools::file_ext(file_path))

  if (!ext %in% c("xlsx", "xls", "csv")) {
    stop("Unsupported file type: .", ext, "\n",
         "Please provide an Excel (.xlsx, .xls) or CSV (.csv) file.")
  }

  # Read file based on type
  if (ext %in% c("xlsx", "xls")) {
    raw_df <- read_local_excel(file_path, end_year)
  } else {
    raw_df <- read_local_csv(file_path, end_year)
  }

  # Detect year if not provided
  if (is.null(end_year)) {
    end_year <- detect_year_from_data(raw_df)
    if (is.null(end_year)) {
      stop("Could not detect year from data. Please provide end_year parameter.")
    }
    message("Detected year: ", end_year)
  }

  # Process to standard schema
  processed <- process_local_data(raw_df, end_year)

  # Create state aggregate
  state_row <- create_state_from_districts(processed, end_year)
  processed <- dplyr::bind_rows(state_row, processed)

  # Optionally tidy
  if (tidy) {
    processed <- tidy_enr(processed) |>
      id_enr_aggs()
  }

  processed
}


#' Read local Excel file
#'
#' @param file_path Path to Excel file
#' @param end_year School year end
#' @return Data frame
#' @keywords internal
read_local_excel <- function(file_path, end_year) {
  sheets <- readxl::excel_sheets(file_path)

  # Try to find data sheet
  data_sheet <- NULL
  for (sheet_name in c("Data Report", "Raw Data", "Data", sheets[length(sheets)])) {
    if (sheet_name %in% sheets) {
      data_sheet <- sheet_name
      break
    }
  }

  if (is.null(data_sheet)) {
    data_sheet <- sheets[1]
  }

  # Read with some flexibility for header rows
  df <- readxl::read_excel(file_path, sheet = data_sheet)

  # Check if first row looks like headers (non-numeric)
  if (nrow(df) > 0 && all(is.na(as.numeric(df[1, ])))) {
    # Skip potential header row
  }

  df
}


#' Read local CSV file
#'
#' @param file_path Path to CSV file
#' @param end_year School year end
#' @return Data frame
#' @keywords internal
read_local_csv <- function(file_path, end_year) {
  readr::read_csv(file_path, show_col_types = FALSE)
}


#' Detect year from data
#'
#' @param df Data frame
#' @return Integer year or NULL
#' @keywords internal
detect_year_from_data <- function(df) {
  cols <- names(df)

  # Look for School Year column
  year_col <- grep("School.?Year|Year", cols, value = TRUE, ignore.case = TRUE)

  if (length(year_col) > 0) {
    year_vals <- unique(df[[year_col[1]]])
    year_vals <- year_vals[!is.na(year_vals)]

    # Parse year from "2023-24" format or numeric
    for (val in year_vals) {
      if (is.numeric(val) && val >= 2016 && val <= 2030) {
        return(as.integer(val))
      }
      if (is.character(val)) {
        # Try "2023-24" format
        match <- regmatches(val, regexpr("20\\d{2}", val))
        if (length(match) > 0) {
          year <- as.integer(match[1])
          # If format is "2023-24", the end year is 2024
          if (grepl("-\\d{2}$", val)) {
            year <- year + 1L
          }
          return(year)
        }
      }
    }
  }

  NULL
}


#' Process local data to standard schema
#'
#' @param df Raw data frame
#' @param end_year School year end
#' @return Processed data frame
#' @keywords internal
process_local_data <- function(df, end_year) {
  cols <- names(df)
  n_rows <- nrow(df)

  # Helper to find column by pattern (case-insensitive)
  find_col <- function(patterns) {
    for (pattern in patterns) {
      matched <- grep(pattern, cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  # Build result dataframe
  result <- data.frame(
    end_year = rep(end_year, n_rows),
    type = rep("District", n_rows),  # Assume district level by default
    stringsAsFactors = FALSE
  )

  # District ID
  district_id_col <- find_col(c("SAU.?ID", "District.?ID", "LEA.?ID"))
  if (!is.null(district_id_col)) {
    result$district_id <- trimws(as.character(df[[district_id_col]]))
  } else {
    result$district_id <- paste0("ME", sprintf("%03d", seq_len(n_rows)))
  }

  # Campus ID (NA for district data)
  result$campus_id <- NA_character_

  # District name
  district_name_col <- find_col(c("SAU.?Name", "District.?Name", "Name"))
  if (!is.null(district_name_col)) {
    result$district_name <- clean_names(as.character(df[[district_name_col]]))
  } else {
    result$district_name <- NA_character_
  }

  result$campus_name <- NA_character_
  result$county <- NA_character_

  # Total enrollment
  total_col <- find_col(c("^Total$", "Enrollment", "Students", "Count"))
  if (!is.null(total_col)) {
    result$row_total <- safe_numeric(df[[total_col]])
  } else {
    result$row_total <- NA_integer_
  }

  # Demographics
  demo_map <- list(
    white = c("White"),
    black = c("Black", "African"),
    hispanic = c("Hispanic", "Latino"),
    asian = c("Asian"),
    pacific_islander = c("Pacific", "Hawaiian"),
    native_american = c("American Indian", "Native", "Indian"),
    multiracial = c("Two or More", "Multi", "Two")
  )

  for (name in names(demo_map)) {
    col <- find_col(demo_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    } else {
      result[[name]] <- NA_integer_
    }
  }

  # Gender
  male_col <- find_col(c("^Male$", "^M$"))
  if (!is.null(male_col)) {
    result$male <- safe_numeric(df[[male_col]])
  } else {
    result$male <- NA_integer_
  }

  female_col <- find_col(c("^Female$", "^F$"))
  if (!is.null(female_col)) {
    result$female <- safe_numeric(df[[female_col]])
  } else {
    result$female <- NA_integer_
  }

  # Filter out rows with zero or NA total
  result <- result[!is.na(result$row_total) & result$row_total > 0, ]

  result
}


#' Create state row from district data
#'
#' @param df Processed district data
#' @param end_year School year end
#' @return Single-row data frame with state totals
#' @keywords internal
create_state_from_districts <- function(df, end_year) {

  if (nrow(df) == 0) {
    return(create_empty_enrollment_df(end_year, "State"))
  }

  # Columns to sum
  sum_cols <- c(
    "row_total",
    "white", "black", "hispanic", "asian",
    "pacific_islander", "native_american", "multiracial",
    "male", "female"
  )
  sum_cols <- sum_cols[sum_cols %in% names(df)]

  # Create state row
  state_row <- data.frame(
    end_year = end_year,
    type = "State",
    district_id = NA_character_,
    campus_id = NA_character_,
    district_name = NA_character_,
    campus_name = NA_character_,
    county = NA_character_,
    stringsAsFactors = FALSE
  )

  # Sum each column
  for (col in sum_cols) {
    if (col %in% names(df)) {
      state_row[[col]] <- sum(df[[col]], na.rm = TRUE)
    }
  }

  state_row
}
