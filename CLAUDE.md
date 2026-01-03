## CRITICAL DATA SOURCE RULES

**NEVER use Urban Institute API, NCES CCD, or ANY federal data source** — the entire point of these packages is to provide STATE-LEVEL data directly from state DOEs. Federal sources aggregate/transform data differently and lose state-specific details. If a state DOE source is broken, FIX IT or find an alternative STATE source — do not fall back to federal data.

---

# meschooldata Package - Maine School Enrollment Data

## Current Status: DATA SOURCE UNAVAILABLE (as of January 2026)

The primary enrollment data files are **NOT AVAILABLE** via direct download. Maine DOE has migrated to interactive QuickSight dashboards with no programmatic access.

### Data Source Investigation Summary

**Date of Investigation:** 2026-01-03

#### Pages Checked

| URL | Status | Content |
|-----|--------|---------|
| https://www.maine.gov/doe/data-warehouse/reporting/enrollment | HTTP 200 | Enrollment page - only 3 files available |
| https://www.maine.gov/doe/data-reporting/warehouse | HTTP 200 | Data Warehouse - behavioral/absenteeism data only |
| https://p20w.slds.maine.gov/QuickFacts | HTTP 200 | QuickSight dashboard - NO API, NO export |
| https://neo.maine.gov/DOE/NEO/Dashboard | HTTP 200 | NEO Dashboard - requires login |
| https://www.maine.gov/doe/dashboard | HTTP 200 | ESSA Dashboard - Tableau, export PDFs only |

#### Available Files (HTTP 200)

| File | URL | Purpose |
|------|-----|---------|
| 60% Enrollment by Fiscal Responsibility | `/doe/sites/.../DATA%20-%2060%20Percent%20Enrollment%20by%20Fiscal%20Responsibility%20-%205.07.2025.xlsx` | Fiscal breakdown for private schools (40 rows) - **NOT main enrollment** |
| Home Instruction by District | `/doe/sites/.../DATA%20-%20Home%20Instruction%20Counts%20by%20District%20and%20Year%202025%20-%208.7.2025.xlsx` | Homeschool counts only |
| Home Instruction by Age | `/doe/sites/.../DATA%20-%20Home%20Instruction%20Counts%20by%20Age%20and%20Year%202025%20-%208.7.2025.xlsx` | Homeschool by age |
| Chronic Absenteeism Report | `/doe/sites/.../DATA%20-%20Chronic%20Absenteeism%20Report%202024%20-%206.20.2025.xlsx` | Absenteeism RATES only (no counts) |

#### Missing Files (HTTP 404)

| Expected File | Status |
|---------------|--------|
| `DATA - Enrollment Counts by Responsible SAU - 10.29.2025.xlsx` | 404 - REMOVED |
| `DATA - Public Funded Responsible Counts by District - 6.4.2025.xlsx` | 404 - REMOVED |
| `Public Funded Enrollments by Responsible District 2024.xlsx` | 404 - REMOVED |
| All other enrollment-by-district patterns | 404 - REMOVED |

#### Dashboards (No Programmatic Access)

| Dashboard | URL | Access |
|-----------|-----|--------|
| QuickFacts | https://p20w.slds.maine.gov/QuickFacts | QuickSight - NO API, print disabled, no export |
| ESSA Dashboard | https://www.maine.gov/doe/dashboard | Tableau - PDF export only |
| NEO Dashboard | https://neo.maine.gov/DOE/NEO/Dashboard | Requires login |

---

## Package Functions

### For Users

| Function | Purpose |
|----------|---------|
| `get_download_instructions()` | Displays instructions for manually obtaining data |
| `import_local_enrollment(file_path, end_year)` | Import from locally downloaded Excel/CSV file |
| `get_available_years()` | Returns available year range (2016-2024) |
| `cache_status()` | Show cached data files |
| `clear_cache()` | Clear cached data |

### Usage When Data Source is Fixed

```r
# When direct download works:
enr <- fetch_enr(2024)
enr_multi <- fetch_enr_multi(2022:2024)
```

### Usage With Local Files

```r
# 1. Get instructions
get_download_instructions()

# 2. Download file manually from dashboard

# 3. Import local file
enr <- import_local_enrollment("~/Downloads/maine_enrollment.xlsx", end_year = 2024)
```

---

## Required Actions to Fix Data Source

### Option 1: Contact Maine DOE (Recommended)
1. Email: medms.helpdesk@maine.gov
2. Request: Direct Excel/CSV downloads of enrollment data
3. Alternative: Request API access to QuickSight dashboards

### Option 2: Browser Automation (Complex)
1. Use RSelenium to automate dashboard interaction
2. Export data from QuickSight dashboard
3. Parse exported data

### Option 3: Wait for Restoration
- Maine DOE may restore Excel downloads
- Monitor: https://www.maine.gov/doe/data-warehouse/reporting/enrollment

### DO NOT USE
- Urban Institute Education Data Portal
- NCES CCD data
- Any federal data aggregation

---

## LIVE Pipeline Testing

The package includes comprehensive LIVE tests in `tests/testthat/test-pipeline-live.R`:

### Test Categories

1. **URL Availability Tests** - Verify pages return HTTP 200
2. **File Download Tests** - Download files, verify size and type
3. **File Parsing Tests** - Read with readxl, verify structure
4. **Column Structure Tests** - Check for expected sheets/columns
5. **Package Function Tests** - Verify functions work correctly
6. **Cache Function Tests** - Test cache operations
7. **import_local_enrollment Tests** - Test local file import
8. **Data Quality Tests** (skipped until data available) - No Inf/NaN
9. **Aggregation Tests** (skipped until data available) - Totals sum correctly
10. **Output Fidelity Tests** (skipped until data available) - tidy matches raw

### Running Tests

```r
# All tests
devtools::test()

# Pipeline tests only
devtools::test(filter = "pipeline-live")
```

---

## Available Years

**When working:** 2016-2024 (October 1 certified enrollment data)

---

## Local Testing Before PRs (REQUIRED)

**PRs will not be merged until CI passes.** Run these checks locally BEFORE opening a PR:

```r
# R package check (required)
devtools::check()

# Python tests (required)
system("pytest tests/test_pymeschooldata.py -v")

# pkgdown build (required)
pkgdown::build_site()
```

### Pre-PR Checklist

- [ ] `devtools::check()` — 0 errors, 0 warnings
- [ ] `devtools::test()` — all tests pass (skips allowed)
- [ ] `pkgdown::build_site()` — builds without errors

---

## Test Results Summary

**As of 2026-01-03:**
- 69 tests passing
- 0 tests failing
- 6 tests skipped (waiting for data source)
