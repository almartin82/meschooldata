# Download raw enrollment data from Maine DOE

Downloads enrollment data from Maine DOE's Data Warehouse. Data is
available from 2016 to present.

## Usage

``` r
get_raw_enr(end_year)
```

## Arguments

- end_year:

  School year end (2023-24 = 2024)

## Value

List with school and district data frames

## Details

NOTE: As of January 2026, direct download is not available. Maine DOE
has migrated to QuickSight dashboards. Use import_local_enrollment()
with manually downloaded data instead.
