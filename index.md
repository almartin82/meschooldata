# meschooldata

**[Documentation](https://almartin82.github.io/meschooldata/)** \|
**[Getting
Started](https://almartin82.github.io/meschooldata/articles/quickstart.html)**

Fetch and analyze Maine school enrollment data from the Maine Department
of Education (DOE) Data Warehouse in R or Python.

## What can you find with meschooldata?

**10 years of enrollment data (2016-2025).** 175,000 students. 260+
School Administrative Units. Here are ten stories hiding in the numbers:

------------------------------------------------------------------------

### 1. Maine is one of the whitest states in America

Over 90% of Maine students are white - the highest percentage of any
state east of the Mississippi.

``` r
library(meschooldata)
library(dplyr)

enr_2025 <- fetch_enr(2025)

enr_2025 %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian", "multiracial")) %>%
  mutate(pct = round(pct * 100, 1)) %>%
  select(subgroup, n_students, pct) %>%
  arrange(desc(pct))
```

------------------------------------------------------------------------

### 2. Portland is diversifying rapidly

Portland Public Schools looks nothing like the rest of Maine - over 40%
students of color and growing.

``` r
enr <- fetch_enr_multi(2016:2025)

enr %>%
  filter(is_district, grepl("Portland", district_name),
         grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian")) %>%
  filter(end_year %in% c(2016, 2020, 2025)) %>%
  mutate(pct = round(pct * 100, 1)) %>%
  select(end_year, subgroup, pct)
```

------------------------------------------------------------------------

### 3. Rural Maine is losing students fast

Small SAUs in Aroostook County (the County) have lost 20-30% of
enrollment since 2016.

``` r
enr %>%
  filter(is_district, end_year %in% c(2016, 2025),
         subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  group_by(district_name) %>%
  filter(n() == 2) %>%
  summarize(
    n_2016 = n_students[end_year == 2016],
    n_2025 = n_students[end_year == 2025],
    pct_change = round((n_2025 / n_2016 - 1) * 100, 1)
  ) %>%
  arrange(pct_change) %>%
  head(10)
```

------------------------------------------------------------------------

### 4. Lewiston: Somali refugees transform a mill town

Lewiston has become one of the most diverse cities in New England thanks
to refugee resettlement.

``` r
enr %>%
  filter(is_district, grepl("Lewiston", district_name),
         grade_level == "TOTAL", subgroup == "black") %>%
  mutate(pct = round(pct * 100, 1)) %>%
  select(end_year, n_students, pct)
```

------------------------------------------------------------------------

### 5. COVID’s kindergarten dip

Maine lost nearly 10% of kindergartners in 2021 - families kept kids
home an extra year.

``` r
enr %>%
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("K", "01", "06", "12")) %>%
  select(end_year, grade_level, n_students)
```

------------------------------------------------------------------------

### 6. Southern Maine is growing

Cumberland and York counties are gaining students while the rest of the
state declines.

``` r
# Compare southern vs northern Maine
enr %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Portland|South Portland|Scarborough|Falmouth|Cape Elizabeth", district_name)) %>%
  group_by(end_year) %>%
  summarize(southern = sum(n_students, na.rm = TRUE))
```

------------------------------------------------------------------------

### 7. Many SAUs have fewer than 500 students

Maine has more tiny school districts than almost any other state - some
with under 100 students.

``` r
enr_2025 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  mutate(size = case_when(
    n_students < 100 ~ "Under 100",
    n_students < 500 ~ "100-499",
    n_students < 1000 ~ "500-999",
    n_students < 5000 ~ "1,000-4,999",
    TRUE ~ "5,000+"
  )) %>%
  group_by(size) %>%
  summarize(n_districts = n())
```

------------------------------------------------------------------------

### 8. Bangor is stable in a declining region

Bangor maintains steady enrollment while surrounding Penobscot County
shrinks.

``` r
enr %>%
  filter(is_district, grepl("Bangor", district_name),
         subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  select(end_year, district_name, n_students)
```

------------------------------------------------------------------------

### 9. English learners concentrated in a few districts

Portland, Lewiston, and a handful of other districts serve the vast
majority of Maine’s EL students.

``` r
enr_2025 %>%
  filter(is_district, subgroup == "lep", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  select(district_name, n_students, pct) %>%
  head(10)
```

------------------------------------------------------------------------

### 10. The graying of Maine shows in the schools

Maine’s population is aging faster than any other state - and schools
are feeling it first.

``` r
enr %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  select(end_year, n_students) %>%
  mutate(change = n_students - lag(n_students))
```

------------------------------------------------------------------------

## Installation

``` r
# install.packages("remotes")
remotes::install_github("almartin82/meschooldata")
```

## Quick start

### R

``` r
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

``` python
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

| Years         | Source                   | Notes                             |
|---------------|--------------------------|-----------------------------------|
| **2016-2025** | Maine DOE Data Warehouse | Annual October 1 certified counts |

Data is sourced from the Maine Department of Education Data Warehouse:
<https://www.maine.gov/doe/data-warehouse/reporting/enrollment>

### What’s included

- **Levels:** State, SAU (School Administrative Unit), School
- **Demographics:** White, Black, Hispanic, Asian, Native American,
  Pacific Islander, Multiracial
- **Grade levels:** PK through 12

### Maine-specific notes

- Maine uses **School Administrative Units (SAUs)** instead of districts
- SAU IDs are 4 digits (e.g., 1000 = Lewiston)
- Many SAUs have only 1-2 schools
- Data only available from 2016 forward (no historical data before 2016)
- Maine is predominantly white; small n for some demographic groups in
  most districts
- Enrollment based on October 1 counts

### Known limitations

- Pre-2016 historical data is not available through this package
- Some rural schools have very small enrollments that may be suppressed
- File URLs may change when Maine DOE updates their data files

## Part of the State Schooldata Project

A simple, consistent interface for accessing state-published school data
in Python and R.

**All 50 state packages:**
[github.com/almartin82](https://github.com/almartin82?tab=repositories&q=schooldata)

## Author

[Andy Martin](https://github.com/almartin82) (<almartin@gmail.com>)

## License

MIT
