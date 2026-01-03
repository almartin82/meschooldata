# meschooldata

<!-- badges: start -->
[![R-CMD-check](https://github.com/almartin82/meschooldata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/almartin82/meschooldata/actions/workflows/R-CMD-check.yaml)
[![Python Tests](https://github.com/almartin82/meschooldata/actions/workflows/python-test.yaml/badge.svg)](https://github.com/almartin82/meschooldata/actions/workflows/python-test.yaml)
[![pkgdown](https://github.com/almartin82/meschooldata/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/almartin82/meschooldata/actions/workflows/pkgdown.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

**[Documentation](https://almartin82.github.io/meschooldata/)** | **[Getting Started](https://almartin82.github.io/meschooldata/articles/quickstart.html)** | **[Enrollment Trends](https://almartin82.github.io/meschooldata/articles/enrollment-trends.html)**

Fetch and analyze Maine school enrollment data from the Maine Department of Education (DOE) Data Warehouse in R or Python.

## What can you find with meschooldata?

**10 years of enrollment data (2016-2025).** 175,000 students. 260+ School Administrative Units. Here are ten stories hiding in the numbers (see [Enrollment Trends](https://almartin82.github.io/meschooldata/articles/enrollment-trends.html) for visualizations):

1. **Maine is one of the whitest states in America** - Over 90% of students are white, the highest east of the Mississippi
2. **Portland is diversifying rapidly** - Over 40% students of color, unlike the rest of Maine
3. **Rural Maine is losing students fast** - Aroostook County SAUs down 20-30% since 2016
4. **Lewiston: Somali refugees transform a mill town** - One of the most diverse cities in New England
5. **COVID's kindergarten dip** - Maine lost nearly 10% of kindergartners in 2021
6. **Southern Maine is growing** - Cumberland and York counties gaining while the rest declines
7. **Many SAUs have fewer than 500 students** - Maine's fragmented district structure
8. **Bangor is stable in a declining region** - Maintains enrollment while Penobscot County shrinks
9. **English learners concentrated in a few districts** - Portland and Lewiston serve the vast majority
10. **The graying of Maine shows in the schools** - Population aging faster than any other state

## Installation

```r
# install.packages("remotes")
remotes::install_github("almartin82/meschooldata")
```

## Quick start

### R

```r
library(meschooldata)
library(dplyr)

# Fetch one year
enr_2025 <- fetch_enr(2025)

# Fetch multiple years
enr_multi <- fetch_enr_multi(2020:2025)

# State totals
enr_2025 %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL")

# SAU breakdown
enr_2025 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  head(15)

# Portland demographics
enr_2025 %>%
  filter(is_district, grepl("Portland", district_name),
         grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian")) %>%
  select(district_name, subgroup, n_students, pct)
```

### Python

```python
import pymeschooldata as me

# Fetch one year
enr_2025 = me.fetch_enr(2025)

# Fetch multiple years
enr_multi = me.fetch_enr_multi(range(2020, 2026))

# State totals
state_totals = enr_2025[
    (enr_2025['is_state'] == True) &
    (enr_2025['subgroup'] == 'total_enrollment') &
    (enr_2025['grade_level'] == 'TOTAL')
]

# SAU breakdown
sau_totals = enr_2025[
    (enr_2025['is_district'] == True) &
    (enr_2025['subgroup'] == 'total_enrollment') &
    (enr_2025['grade_level'] == 'TOTAL')
].sort_values('n_students', ascending=False).head(15)

# Portland demographics
portland = enr_2025[
    (enr_2025['is_district'] == True) &
    (enr_2025['district_name'].str.contains('Portland')) &
    (enr_2025['grade_level'] == 'TOTAL') &
    (enr_2025['subgroup'].isin(['white', 'black', 'hispanic', 'asian']))
][['district_name', 'subgroup', 'n_students', 'pct']]
```

## Data availability

| Years | Source | Notes |
|-------|--------|-------|
| **2016-2025** | Maine DOE Data Warehouse | Annual October 1 certified counts |

Data is sourced from the Maine Department of Education Data Warehouse:
https://www.maine.gov/doe/data-warehouse/reporting/enrollment

### What's included

- **Levels:** State, SAU (School Administrative Unit), School
- **Demographics:** White, Black, Hispanic, Asian, Native American, Pacific Islander, Multiracial
- **Grade levels:** PK through 12

### Maine-specific notes

- Maine uses **School Administrative Units (SAUs)** instead of districts
- SAU IDs are 4 digits (e.g., 1000 = Lewiston)
- Many SAUs have only 1-2 schools
- Data only available from 2016 forward (no historical data before 2016)
- Maine is predominantly white; small n for some demographic groups in most districts
- Enrollment based on October 1 counts

### Known limitations

- Pre-2016 historical data is not available through this package
- Some rural schools have very small enrollments that may be suppressed
- File URLs may change when Maine DOE updates their data files

## Part of the State Schooldata Project

A simple, consistent interface for accessing state-published school data in Python and R.

**All 50 state packages:** [github.com/almartin82](https://github.com/almartin82?tab=repositories&q=schooldata)

## Author

[Andy Martin](https://github.com/almartin82) (almartin@gmail.com)

## License

MIT
