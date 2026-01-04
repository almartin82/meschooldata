# ==============================================================================
# Enrollment Data Processing Functions
# ==============================================================================
#
# This file contains functions for processing raw Maine DOE enrollment data into
# a clean, standardized format.
#
# ==============================================================================

#' Process raw Maine DOE enrollment data
#'
#' Transforms raw data into a standardized schema combining school
#' and district data.
#'
#' @param raw_data List containing school and district data frames from get_raw_enr
#' @param end_year School year end
#' @return Processed data frame with standardized columns
#' @keywords internal
process_enr <- function(raw_data, end_year) {

  # Process school data
  school_processed <- process_school_enr(raw_data$school, end_year)

  # Process district data
  district_processed <- process_district_enr(raw_data$district, end_year)

  # Create state aggregate
  state_processed <- create_state_aggregate(district_processed, school_processed, end_year)

  # Combine all levels
  result <- dplyr::bind_rows(state_processed, district_processed, school_processed)

  result
}


#' Process school-level enrollment data
#'
#' @param df Raw school data frame
#' @param end_year School year end
#' @return Processed school data frame
#' @keywords internal
process_school_enr <- function(df, end_year) {

  if (is.null(df) || nrow(df) == 0) {
    return(create_empty_enrollment_df(end_year, "Campus"))
  }

  cols <- names(df)
  n_rows <- nrow(df)

  # Helper to find column by pattern (case-insensitive)
  find_col <- function(patterns) {
    for (pattern in patterns) {
      matched <- grep(paste0("^", pattern, "$"), cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  # Build result dataframe with same number of rows as input
  result <- data.frame(
    end_year = rep(end_year, n_rows),
    type = rep("Campus", n_rows),
    stringsAsFactors = FALSE
  )

  # School ID - Maine DOE may use various formats
  school_id_col <- find_col(c("SCHOOL_ID", "school_id", "SCH_ID", "SCHID", "campus_id", "NCESSCH", "ncessch"))
  if (!is.null(school_id_col)) {
    result$campus_id <- trimws(as.character(df[[school_id_col]]))
  } else {
    result$campus_id <- rep(NA_character_, n_rows)
  }

  # District ID (Maine uses SAU - School Administrative Unit)
  district_id_col <- find_col(c("LEAID", "leaid", "LEA_ID", "DISTRICT_ID", "district_id", "SAU_ID", "sau_id"))
  if (!is.null(district_id_col)) {
    result$district_id <- trimws(as.character(df[[district_id_col]]))
  } else {
    result$district_id <- rep(NA_character_, n_rows)
  }

  # School name
  school_name_col <- find_col(c("SCH_NAME", "school_name", "SCHNAM", "SCHOOL_NAME", "NAME", "campus_name"))
  if (!is.null(school_name_col)) {
    result$campus_name <- clean_names(as.character(df[[school_name_col]]))
  } else {
    result$campus_name <- rep(NA_character_, n_rows)
  }

  # District name (SAU name in Maine)
  district_name_col <- find_col(c("LEA_NAME", "lea_name", "LEANM", "DISTRICT_NAME", "district_name", "SAU_NAME", "sau_name", "Attending"))
  if (!is.null(district_name_col)) {
    result$district_name <- clean_names(as.character(df[[district_name_col]]))
  } else {
    result$district_name <- rep(NA_character_, n_rows)
  }

  # County
  county_col <- find_col(c("COUNTY", "county", "CNTY", "CONAME"))
  if (!is.null(county_col)) {
    result$county <- clean_names(as.character(df[[county_col]]))
  } else {
    result$county <- rep(NA_character_, n_rows)
  }

  # Total enrollment
  total_col <- find_col(c("TOTAL", "total", "MEMBER", "enrollment", "ENROLLMENT", "STUDENTS", "row_total"))
  if (!is.null(total_col)) {
    result$row_total <- safe_numeric(df[[total_col]])
  } else {
    result$row_total <- rep(NA_integer_, n_rows)
  }

  # Demographics - support various naming conventions
  demo_map <- list(
    white = c("WH", "white", "WHITE", "RACE_WHITE"),
    black = c("BL", "black", "BLACK", "RACE_BLACK", "RACE_AFRICAN_AMERICAN"),
    hispanic = c("HI", "hispanic", "HISPANIC", "RACE_HISPANIC"),
    asian = c("AS", "asian", "ASIAN", "RACE_ASIAN"),
    pacific_islander = c("HP", "pacific_islander", "PACIFIC_ISLANDER", "RACE_PACIFIC"),
    native_american = c("AM", "native_american", "AMERICAN_INDIAN", "RACE_NATIVE"),
    multiracial = c("TR", "multiracial", "TWO_OR_MORE", "RACE_TWO_OR_MORE")
  )

  for (name in names(demo_map)) {
    col <- find_col(demo_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    } else {
      result[[name]] <- rep(NA_integer_, n_rows)
    }
  }

  # Gender
  gender_map <- list(
    male = c("MALE", "male", "M"),
    female = c("FEMALE", "female", "F")
  )

  for (name in names(gender_map)) {
    col <- find_col(gender_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    } else {
      result[[name]] <- rep(NA_integer_, n_rows)
    }
  }

  # Grade levels - support various naming conventions
  grade_map <- list(
    grade_pk = c("PK", "pk", "PREKINDERGARTEN", "PRE_K", "grade_pk"),
    grade_k = c("KG", "kg", "K", "KINDERGARTEN", "grade_k"),
    grade_01 = c("G01", "g01", "GRADE_1", "GR01", "grade_01", "1"),
    grade_02 = c("G02", "g02", "GRADE_2", "GR02", "grade_02", "2"),
    grade_03 = c("G03", "g03", "GRADE_3", "GR03", "grade_03", "3"),
    grade_04 = c("G04", "g04", "GRADE_4", "GR04", "grade_04", "4"),
    grade_05 = c("G05", "g05", "GRADE_5", "GR05", "grade_05", "5"),
    grade_06 = c("G06", "g06", "GRADE_6", "GR06", "grade_06", "6"),
    grade_07 = c("G07", "g07", "GRADE_7", "GR07", "grade_07", "7"),
    grade_08 = c("G08", "g08", "GRADE_8", "GR08", "grade_08", "8"),
    grade_09 = c("G09", "g09", "GRADE_9", "GR09", "grade_09", "9"),
    grade_10 = c("G10", "g10", "GRADE_10", "GR10", "grade_10", "10"),
    grade_11 = c("G11", "g11", "GRADE_11", "GR11", "grade_11", "11"),
    grade_12 = c("G12", "g12", "GRADE_12", "GR12", "grade_12", "12")
  )

  for (name in names(grade_map)) {
    col <- find_col(grade_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    } else {
      result[[name]] <- rep(NA_integer_, n_rows)
    }
  }

  result
}


#' Process district-level enrollment data
#'
#' @param df Raw district data frame
#' @param end_year School year end
#' @return Processed district data frame
#' @keywords internal
process_district_enr <- function(df, end_year) {

  if (is.null(df) || nrow(df) == 0) {
    return(create_empty_enrollment_df(end_year, "District"))
  }

  cols <- names(df)
  n_rows <- nrow(df)

  # Helper to find column by pattern (case-insensitive)
  find_col <- function(patterns) {
    for (pattern in patterns) {
      matched <- grep(paste0("^", pattern, "$"), cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  # Build result dataframe
  result <- data.frame(
    end_year = rep(end_year, n_rows),
    type = rep("District", n_rows),
    stringsAsFactors = FALSE
  )

  # District ID (SAU in Maine)
  district_id_col <- find_col(c("LEAID", "leaid", "LEA_ID", "DISTRICT_ID", "district_id", "SAU_ID"))
  if (!is.null(district_id_col)) {
    result$district_id <- trimws(as.character(df[[district_id_col]]))
  } else {
    result$district_id <- rep(NA_character_, n_rows)
  }

  # Campus ID is NA for district rows
  result$campus_id <- rep(NA_character_, n_rows)

  # District name
  district_name_col <- find_col(c("LEA_NAME", "lea_name", "LEANM", "DISTRICT_NAME", "district_name", "SAU_NAME", "NAME"))
  if (!is.null(district_name_col)) {
    result$district_name <- clean_names(as.character(df[[district_name_col]]))
  } else {
    result$district_name <- rep(NA_character_, n_rows)
  }

  result$campus_name <- rep(NA_character_, n_rows)

  # County
  county_col <- find_col(c("COUNTY", "county", "CNTY", "CONAME"))
  if (!is.null(county_col)) {
    result$county <- clean_names(as.character(df[[county_col]]))
  } else {
    result$county <- rep(NA_character_, n_rows)
  }

  # Total enrollment
  total_col <- find_col(c("TOTAL", "total", "MEMBER", "enrollment", "ENROLLMENT", "row_total"))
  if (!is.null(total_col)) {
    result$row_total <- safe_numeric(df[[total_col]])
  } else {
    result$row_total <- rep(NA_integer_, n_rows)
  }

  # Demographics
  demo_map <- list(
    white = c("WH", "white", "WHITE"),
    black = c("BL", "black", "BLACK"),
    hispanic = c("HI", "hispanic", "HISPANIC"),
    asian = c("AS", "asian", "ASIAN"),
    pacific_islander = c("HP", "pacific_islander", "PACIFIC_ISLANDER"),
    native_american = c("AM", "native_american", "AMERICAN_INDIAN"),
    multiracial = c("TR", "multiracial", "TWO_OR_MORE")
  )

  for (name in names(demo_map)) {
    col <- find_col(demo_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    } else {
      result[[name]] <- rep(NA_integer_, n_rows)
    }
  }

  # Gender
  gender_map <- list(
    male = c("MALE", "male"),
    female = c("FEMALE", "female")
  )

  for (name in names(gender_map)) {
    col <- find_col(gender_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    } else {
      result[[name]] <- rep(NA_integer_, n_rows)
    }
  }

  # Grade levels
  grade_map <- list(
    grade_pk = c("PK", "pk", "PREKINDERGARTEN", "grade_pk"),
    grade_k = c("KG", "kg", "K", "KINDERGARTEN", "grade_k"),
    grade_01 = c("G01", "g01", "GRADE_1", "grade_01"),
    grade_02 = c("G02", "g02", "GRADE_2", "grade_02"),
    grade_03 = c("G03", "g03", "GRADE_3", "grade_03"),
    grade_04 = c("G04", "g04", "GRADE_4", "grade_04"),
    grade_05 = c("G05", "g05", "GRADE_5", "grade_05"),
    grade_06 = c("G06", "g06", "GRADE_6", "grade_06"),
    grade_07 = c("G07", "g07", "GRADE_7", "grade_07"),
    grade_08 = c("G08", "g08", "GRADE_8", "grade_08"),
    grade_09 = c("G09", "g09", "GRADE_9", "grade_09"),
    grade_10 = c("G10", "g10", "GRADE_10", "grade_10"),
    grade_11 = c("G11", "g11", "GRADE_11", "grade_11"),
    grade_12 = c("G12", "g12", "GRADE_12", "grade_12")
  )

  for (name in names(grade_map)) {
    col <- find_col(grade_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    } else {
      result[[name]] <- rep(NA_integer_, n_rows)
    }
  }

  result
}


#' Create state-level aggregate from district/school data
#'
#' @param district_df Processed district data frame
#' @param school_df Processed school data frame
#' @param end_year School year end
#' @return Single-row data frame with state totals
#' @keywords internal
create_state_aggregate <- function(district_df, school_df, end_year) {

  # Use district data if available, otherwise school data
  source_df <- if (nrow(district_df) > 0) district_df else school_df

  if (is.null(source_df) || nrow(source_df) == 0) {
    # Return empty state row
    state_row <- data.frame(
      end_year = end_year,
      type = "State",
      district_id = NA_character_,
      campus_id = NA_character_,
      district_name = NA_character_,
      campus_name = NA_character_,
      county = NA_character_,
      row_total = NA_integer_,
      stringsAsFactors = FALSE
    )
    return(state_row)
  }

  # Columns to sum
  sum_cols <- c(
    "row_total",
    "white", "black", "hispanic", "asian",
    "pacific_islander", "native_american", "multiracial",
    "male", "female",
    "grade_pk", "grade_k",
    "grade_01", "grade_02", "grade_03", "grade_04",
    "grade_05", "grade_06", "grade_07", "grade_08",
    "grade_09", "grade_10", "grade_11", "grade_12"
  )

  # Filter to columns that exist
  sum_cols <- sum_cols[sum_cols %in% names(source_df)]

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
    if (col %in% names(source_df)) {
      state_row[[col]] <- sum(source_df[[col]], na.rm = TRUE)
    }
  }

  state_row
}
