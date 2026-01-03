# Parse Raw Data sheet from Maine DOE Excel

The Raw Data sheet contains long-format data with columns: School Year,
SAU ID, Attending SAU Name, School ID, Attending School Name, Grade,
Attending Student Count

## Usage

``` r
parse_raw_data_sheet(df, end_year)
```

## Arguments

- df:

  Data frame from Raw Data sheet

- end_year:

  School year end

## Value

List with school and district data frames
