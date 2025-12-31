# meschooldata - Maine School Data Package

## Data Source

**Maine Department of Education (DOE) Data Warehouse ONLY**

This package uses ONLY data from the Maine DOE. Do NOT use:
- Urban Institute Education Data API
- NCES Common Core of Data (CCD)
- Any other federal data sources

## Maine DOE Data Warehouse

- **URL**: https://www.maine.gov/doe/data-warehouse/reporting/enrollment
- **Data Type**: Annual October 1 certified enrollment data
- **Available Years**: 2016 to present
- **Format**: Excel files with multi-year data

### Enrollment Files Available

The Maine DOE provides these enrollment reports:

1. **Public Funded Attending Counts by District** - Enrollment by attending SAU
2. **Public Funded Responsible Counts by District** - Enrollment by responsible SAU
3. **Public Funded Residential Counts by Town and County** - Geographic breakdown
4. **60% School Enrollment Counts by Fiscal Responsibility**
5. **Home Instruction Students by District**
6. **Home Instruction by Reported Age**

### File URL Pattern

Files are hosted at:
```
https://www.maine.gov/doe/sites/maine.gov.doe/files/inline-files/DATA%20-%20[FILENAME].xlsx
```

File names include dates (e.g., `6.4.2025`) and may change when updated.

## Package Architecture

- `fetch_enr()` - Main function to get enrollment data for a year
- `fetch_enr_multi()` - Get multiple years of data
- `get_raw_enr()` - Downloads raw data from Maine DOE
- `process_enr()` - Standardizes the raw data format
- `tidy_enr()` - Converts to long (tidy) format

## Maine-Specific Terminology

- **SAU** = School Administrative Unit (equivalent to district)
- **Responsible SAU** = The SAU financially responsible for the student
- **Attending SAU** = The SAU where the student physically attends

## Data Limitations

- Data only available from 2016 forward
- Pre-2016 historical data is NOT available through this package
- File URLs may change when Maine DOE updates their data files

## Maintenance Notes

If downloads fail:
1. Check https://www.maine.gov/doe/data-warehouse/reporting/enrollment for current file URLs
2. Update the URLs in `R/get_raw_enrollment.R` (download_maine_doe function)
3. File names typically include a date suffix that changes with each update
