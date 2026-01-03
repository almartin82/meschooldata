# Get available years for Maine enrollment data

Returns the range of years for which enrollment data is available. Maine
DOE Data Warehouse has data from 2016 to present.

## Usage

``` r
get_available_years()
```

## Value

Named list with min_year, max_year, source info, and available years

## Details

Data is sourced exclusively from the Maine Department of Education (DOE)
Data Warehouse, which provides Annual October 1 certified enrollment
data.

## Examples

``` r
get_available_years()
#> $min_year
#> [1] 2016
#> 
#> $max_year
#> [1] 2024
#> 
#> $source
#> [1] "Maine DOE Data Warehouse"
#> 
#> $url
#> [1] "https://www.maine.gov/doe/data-warehouse/reporting/enrollment"
#> 
#> $note
#> [1] "Data available from 2016 to 2024. Based on Annual October 1 certified data sets."
#> 
```
