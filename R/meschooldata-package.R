#' meschooldata: Fetch and Process Maine School Data
#'
#' Downloads and processes school data from the Maine Department of Education
#' (DOE). Provides functions for fetching enrollment data from the Data Warehouse
#' and transforming it into tidy format for analysis.
#'
#' @section Main functions:
#' \describe{
#'   \item{\code{\link{fetch_enr}}}{Fetch enrollment data for a school year}
#'   \item{\code{\link{fetch_enr_multi}}}{Fetch enrollment data for multiple years}
#'   \item{\code{\link{tidy_enr}}}{Transform wide data to tidy (long) format}
#'   \item{\code{\link{id_enr_aggs}}}{Add aggregation level flags}
#'   \item{\code{\link{enr_grade_aggs}}}{Create grade-level aggregations}
#'   \item{\code{\link{get_available_years}}}{List years with available data}
#' }
#'
#' @section Cache functions:
#' \describe{
#'   \item{\code{\link{cache_status}}}{View cached data files}
#'   \item{\code{\link{clear_cache}}}{Remove cached data files}
#' }
#'
#' @section ID System:
#' Maine uses School Administrative Units (SAUs) to organize schools:
#' \itemize{
#'   \item SAU IDs: 4 digits (e.g., 1000 = Lewiston)
#'   \item School IDs: 4 digits within each SAU
#'   \item Combined IDs: SAU_ID + School_ID (8 characters)
#' }
#'
#' @section Data Sources:
#' Data is sourced from the Maine Department of Education Data Warehouse:
#' \itemize{
#'   \item Data Warehouse: \url{https://www.maine.gov/doe/data-reporting/warehouse}
#'   \item Enrollment Data: \url{https://www.maine.gov/doe/data-warehouse/reporting/enrollment}
#' }
#'
#' @section Data Availability:
#' \itemize{
#'   \item Years: 2003-2025 (October 1 counts)
#'   \item Aggregation levels: State, SAU (District), School
#'   \item Demographics: Race/ethnicity (limited categories pre-2011)
#'   \item Grade levels: PK through 12
#' }
#'
#' @section Known Caveats:
#' \itemize{
#'   \item Maine is predominantly white; small n for some demographic groups
#'   \item Pre-2011 data may combine Asian and Pacific Islander
#'   \item Some rural schools have very small enrollments (suppression possible)
#'   \item Maine has many SAUs with only 1-2 schools
#' }
#'
#' @docType package
#' @name meschooldata-package
#' @aliases meschooldata
#' @keywords internal
"_PACKAGE"

#' Pipe operator
#'
#' See \code{magrittr::\link[magrittr:pipe]{\%>\%}} for details.
#'
#' @name %>%
#' @rdname pipe
#' @keywords internal
#' @export
#' @importFrom dplyr %>%
#' @usage lhs \%>\% rhs
#' @param lhs A value or the magrittr placeholder.
#' @param rhs A function call using the magrittr semantics.
#' @return The result of calling `rhs(lhs)`.
NULL
