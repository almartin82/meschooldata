# Get download instructions for Maine enrollment data

Since Maine DOE enrollment data is not available for automated download,
this function provides instructions for manually downloading data from
the QuickSight dashboard.

## Usage

``` r
get_download_instructions()
```

## Value

Invisibly returns the Maine DOE data URL

## Examples

``` r
get_download_instructions()
#> ============================================================
#> Maine DOE Enrollment Data - Manual Download Required
#> ============================================================
#> 
#> Maine DOE has migrated enrollment data to interactive dashboards.
#> Direct Excel file downloads are no longer available.
#> 
#> To obtain enrollment data:
#> 
#> 1. Visit the Maine DOE enrollment page:
#>    https://www.maine.gov/doe/data-warehouse/reporting/enrollment
#> 
#> 2. Access the QuickFacts dashboard:
#>    https://p20w.slds.maine.gov/QuickFacts
#> 
#> 3. Export data from the dashboard (if available) or
#>    contact Maine DOE for custom data requests:
#>    medms.helpdesk@maine.gov
#> 
#> 4. Once you have a downloaded file, use:
#>    import_local_enrollment('path/to/your/file.xlsx')
#> 
#> ============================================================
```
