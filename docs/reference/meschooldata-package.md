# meschooldata: Fetch and Process Maine School Data

Downloads and processes school data from the Maine Department of
Education (DOE). Provides functions for fetching enrollment data from
the Data Warehouse and transforming it into tidy format for analysis.

## Main functions

- [`fetch_enr`](https://almartin82.github.io/meschooldata/reference/fetch_enr.md):

  Fetch enrollment data for a school year

- [`fetch_enr_multi`](https://almartin82.github.io/meschooldata/reference/fetch_enr_multi.md):

  Fetch enrollment data for multiple years

- [`tidy_enr`](https://almartin82.github.io/meschooldata/reference/tidy_enr.md):

  Transform wide data to tidy (long) format

- [`id_enr_aggs`](https://almartin82.github.io/meschooldata/reference/id_enr_aggs.md):

  Add aggregation level flags

- [`enr_grade_aggs`](https://almartin82.github.io/meschooldata/reference/enr_grade_aggs.md):

  Create grade-level aggregations

- [`get_available_years`](https://almartin82.github.io/meschooldata/reference/get_available_years.md):

  List years with available data

## Cache functions

- [`cache_status`](https://almartin82.github.io/meschooldata/reference/cache_status.md):

  View cached data files

- [`clear_cache`](https://almartin82.github.io/meschooldata/reference/clear_cache.md):

  Remove cached data files

## ID System

Maine uses School Administrative Units (SAUs) to organize schools:

- SAU IDs: 4 digits (e.g., 1000 = Lewiston)

- School IDs: 4 digits within each SAU

- Combined IDs: SAU_ID + School_ID (8 characters)

## Data Sources

Data is sourced exclusively from the Maine DOE Data Warehouse:

- Maine DOE Data Warehouse (2016-present):
  <https://www.maine.gov/doe/data-warehouse/reporting/enrollment>

## Data Availability

- Years: 2016-present (Annual October 1 certified counts)

- Aggregation levels: State, SAU (District), School

- Demographics: Race/ethnicity

- Grade levels: PK through 12

## Known Caveats

- Data only available from 2016 forward (no historical data before 2016)

- Maine is predominantly white; small n for some demographic groups

- Some rural schools have very small enrollments (suppression possible)

- Maine has many SAUs with only 1-2 schools

## See also

Useful links:

- <https://github.com/almartin82/meschooldata>

- Report bugs at <https://github.com/almartin82/meschooldata/issues>

## Author

**Maintainer**: Al Martin <almartin@example.com>
