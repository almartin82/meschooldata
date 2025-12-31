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
#' Returns a vector of years for which enrollment data is available from the
#' Maine Department of Education. Data is available from 2003 to present.
#'
#' @return Integer vector of available years
#' @export
#' @examples
#' get_available_years()
get_available_years <- function() {
  # Maine DOE Data Warehouse has data from approximately 2003 onward

  # The Excel files contain historical data with year columns
  # Most complete data is from 2003 to current year
  current_year <- as.integer(format(Sys.Date(), "%Y"))

  # If we're past October, include current school year
  current_month <- as.integer(format(Sys.Date(), "%m"))
  if (current_month >= 10) {
    max_year <- current_year + 1
  } else {
    max_year <- current_year
  }

  # Maine DOE has reliable data from 2003 (earlier data may be inconsistent)
  2003:max_year
}


#' Validate year parameter
#'
#' Checks if the provided year is within the available range.
#'
#' @param end_year School year end
#' @return TRUE if valid, otherwise throws an error
#' @keywords internal
validate_year <- function(end_year) {
  available <- get_available_years()
  min_year <- min(available)
  max_year <- max(available)

  if (!end_year %in% available) {
    stop(paste0(
      "end_year must be between ", min_year, " and ", max_year, ". ",
      "Got: ", end_year
    ))
  }

  TRUE
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
