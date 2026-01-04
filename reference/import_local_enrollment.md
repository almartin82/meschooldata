# Import enrollment data from a local file

Reads enrollment data from a locally downloaded Excel or CSV file. Use
this function when automatic download is not available (e.g., when Maine
DOE has moved data to a dashboard).

## Usage

``` r
import_local_enrollment(file_path, end_year = NULL, tidy = TRUE)
```

## Arguments

- file_path:

  Path to the local Excel (.xlsx) or CSV file

- end_year:

  School year end (e.g., 2024 for 2023-24). If not provided, the
  function will attempt to detect it from the file.

- tidy:

  If TRUE (default), returns data in long (tidy) format.

## Value

Data frame with enrollment data

## Examples

``` r
if (FALSE) { # \dontrun{
# Import from manually downloaded Excel file
enr <- import_local_enrollment("~/Downloads/maine_enrollment.xlsx", end_year = 2024)

# Import from CSV export
enr <- import_local_enrollment("~/Downloads/quicksight_export.csv", end_year = 2024)
} # }
```
