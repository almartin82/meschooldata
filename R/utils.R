# ==============================================================================
# Utility Functions
# ==============================================================================

#' Convert to numeric, handling suppression markers
#'
#' Maine DOE uses various markers for suppressed data (*, <5, N/A, etc.)
#' and may use commas in large numbers.
#'
#' @param x Vector to convert
#' @return Numeric vector with NA for non-numeric values
#' @keywords internal
safe_numeric <- function(x) {
  # Handle NULL or empty input
  if (is.null(x) || length(x) == 0) return(numeric(0))

  # If already numeric, return as-is
  if (is.numeric(x)) return(x)


  # Remove commas and whitespace
  x <- gsub(",", "", x)
  x <- trimws(x)

  # Handle common suppression markers
  x[x %in% c("*", ".", "-", "-1", "<5", "<10", "N/A", "NA", "", "S", "n/a")] <- NA_character_

  suppressWarnings(as.numeric(x))
}


#' Standardize grade level names
#'
#' Converts various grade level formats to standard form (PK, K, 01-12).
#'
#' @param grade Character vector of grade names
#' @return Character vector of standardized grade names
#' @keywords internal
standardize_grade <- function(grade) {
  grade <- toupper(trimws(grade))

  # Map common variations
  grade <- gsub("^PRE-?K(INDERGARTEN)?$", "PK", grade)
  grade <- gsub("^KINDERGARTEN$", "K", grade)
  grade <- gsub("^GRADE\\s*", "", grade)
  grade <- gsub("^(\\d)$", "0\\1", grade)  # Single digit to double digit

  grade
}


#' Get available years for Maine enrollment data
#'
#' Returns the range of years for which enrollment data is available.
#' Maine DOE Data Warehouse has data from 2016 to present.
#'
#' Data is sourced exclusively from the Maine Department of Education (DOE)
#' Data Warehouse, which provides Annual October 1 certified enrollment data.
#'
#' @return Named list with min_year, max_year, source info, and available years
#' @export
#' @examples
#' get_available_years()
get_available_years <- function() {
  # Maine DOE Data Warehouse has data from 2016 onward
  # (metadata shows "SchoolYearCode > 2015")
  # Data source: https://www.maine.gov/doe/data-warehouse/reporting/enrollment

  current_year <- as.integer(format(Sys.Date(), "%Y"))

  # If we're past October, current school year data may be available
  current_month <- as.integer(format(Sys.Date(), "%m"))
  max_year <- if (current_month >= 10) current_year + 1 else current_year

  list(
    min_year = 2016L,
    max_year = max_year,
    source = "Maine DOE Data Warehouse",
    url = "https://www.maine.gov/doe/data-warehouse/reporting/enrollment",
    note = "Data available from 2016 to present. Based on Annual October 1 certified data sets."
  )
}


#' Validate year parameter
#'
#' Checks if the provided year is within the available range.
#'
#' @param end_year School year end
#' @return TRUE if valid, otherwise throws an error
#' @keywords internal
validate_year <- function(end_year) {
  avail <- get_available_years()

  if (!is.numeric(end_year) || length(end_year) != 1) {
    stop("end_year must be a single numeric value")
  }

  if (end_year < avail$min_year || end_year > avail$max_year) {
    stop(paste0(
      "end_year must be between ", avail$min_year, " and ", avail$max_year,
      "\nAvailable years: ", avail$min_year, "-", avail$max_year,
      "\nNote: ", avail$note
    ))
  }

  TRUE
}




#' Clean school/district names
#'
#' Standardizes school and district names by removing extra whitespace.
#'
#' @param x Character vector of names
#' @return Cleaned character vector
#' @keywords internal
clean_names <- function(x) {
  x <- trimws(x)
  x <- gsub("\\s+", " ", x)  # Multiple spaces to single
  x
}


#' Clean district/SAU names
#'
#' Standardizes SAU (School Administrative Unit) names.
#'
#' @param names Character vector of names
#' @return Cleaned character vector
#' @keywords internal
clean_sau_names <- function(names) {
  names <- trimws(names)
  # Remove extra whitespace
  names <- gsub("\\s+", " ", names)
  names
}
