# Getting Started with meschooldata

## Introduction

The `meschooldata` package provides access to Maine Department of
Education (DOE) school enrollment data. This vignette shows how to
download and work with the data.

### Data Source

Maine DOE provides enrollment data through an interactive QuickSight
dashboard. Unlike some other states, the data is not available for
direct programmatic download. You must:

1.  Manually export data from the dashboard
2.  Import it using the
    [`import_local_enrollment()`](https://almartin82.github.io/meschooldata/reference/import_local_enrollment.md)
    function

## Downloading Data

### Step 1: Visit the Dashboard

Run this to get detailed instructions:

``` r
library(meschooldata)
get_download_instructions()
```

The enrollment dashboard is at:
<https://www.maine.gov/doe/data-warehouse/reporting/enrollment>

### Step 2: Export Data

1.  In the dashboard, select your desired filters:

    - School Year (e.g., 2023-24)
    - Demographic group (All Students, or specific groups)
    - Geographic level (State, SAU, School)

2.  Click the “…” menu icon in the upper right of the visualization

3.  Select “Export to CSV” or “Export to Excel”

4.  Save the file to your computer

### Step 3: Import the Data

``` r
# Import the downloaded file
enrollment <- import_local_enrollment("~/Downloads/enrollment_export.csv")

# View the data
head(enrollment)
```

## Working with the Data

Once imported, the data is in a tidy format with these key columns:

- `end_year`: School year end (e.g., 2024 for 2023-24)
- `type`: “State”, “District”, or “Campus”
- `district_id`, `campus_id`: Identifiers
- `subgroup`: Demographic category (e.g., “total_enrollment”, “white”,
  “male”)
- `grade_level`: Grade level or “TOTAL”
- `n_students`: Number of students
- `pct`: Percentage of total

### Example: Get State Totals

``` r
library(dplyr)

# State-level total enrollment
state_totals <- enrollment %>%
  filter(type == "State",
         subgroup == "total_enrollment",
         grade_level == "TOTAL")

print(state_totals)
```

### Example: Compare Demographics

``` r
# Get demographic breakdown for state
demographics <- enrollment %>%
  filter(type == "State",
         grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian",
                          "native_american", "pacific_islander", "multiracial"))

print(demographics)
```

### Example: Grade-Level Analysis

``` r
# Get enrollment by grade
by_grade <- enrollment %>%
  filter(type == "State",
         subgroup == "total_enrollment",
         grade_level != "TOTAL")

print(by_grade)
```

## Available Years

Check what years are available using
[`get_available_years()`](https://almartin82.github.io/meschooldata/reference/get_available_years.md):

``` r
get_available_years()
```

## Caching

Imported data is not automatically cached. If you want to save processed
data for later use, save it yourself:

``` r
# Save for later use
saveRDS(enrollment, "maine_enrollment_2024.rds")

# Load later
enrollment <- readRDS("maine_enrollment_2024.rds")
```

## Data Quality Notes

When working with this data, be aware of:

1.  **Suppression**: Small counts may be suppressed to protect student
    privacy
2.  **Rounding**: Some percentages may not sum exactly to 100% due to
    rounding
3.  **Missing data**: Some schools or years may have incomplete data

Always verify totals when aggregating:

``` r
# Verify race totals sum to total enrollment
state_data <- enrollment %>% filter(type == "State", grade_level == "TOTAL")

total_enr <- state_data$n_students[state_data$subgroup == "total_enrollment"]

race_sum <- state_data %>%
  filter(subgroup %in% c("white", "black", "hispanic", "asian",
                          "native_american", "pacific_islander", "multiracial")) %>%
  summarize(sum = sum(n_students, na.rm = TRUE)) %>%
  pull(sum)

cat("Total enrollment:", total_enr, "\n")
cat("Sum of races:", race_sum, "\n")
cat("Match:", total_enr == race_sum, "\n")
```
