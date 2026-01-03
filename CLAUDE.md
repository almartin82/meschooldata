## CRITICAL DATA SOURCE RULES

**NEVER use Urban Institute API, NCES CCD, or ANY federal data source** — the entire point of these packages is to provide STATE-LEVEL data directly from state DOEs. Federal sources aggregate/transform data differently and lose state-specific details. If a state DOE source is broken, FIX IT or find an alternative STATE source — do not fall back to federal data.

---

# meschooldata Package - Maine School Enrollment Data

## Current Status: DATA SOURCE BROKEN (as of 2026-01-03)

The primary enrollment data files are NO LONGER AVAILABLE via direct download. Maine DOE has migrated to interactive QuickSight dashboards.

### What Was Investigated:

1. **Main enrollment page**: https://www.maine.gov/doe/data-warehouse/reporting/enrollment
   - Only 3 files available (none are primary enrollment data):
     - `DATA - 60 Percent Enrollment by Fiscal Responsibility - 5.07.2025.xlsx` (fiscal responsibility breakdown, not main enrollment)
     - `DATA - Home Instruction Counts by District and Year 2025 - 8.7.2025.xlsx` (homeschool only)
     - `DATA - Home Instruction Counts by Age and Year 2025 - 8.7.2025.xlsx` (homeschool only)

2. **Data Warehouse page**: https://www.maine.gov/doe/data-reporting/warehouse
   - Contains behavioral, absenteeism, special ed files — NO enrollment files

3. **QuickFacts**: https://www.maine.gov/doe/data-reporting/reporting/warehouse/quickfacts
   - Embedded QuickSight dashboard at: `https://p20w.slds.maine.gov/QuickFacts`
   - No direct file download capability

4. **Historical URLs return 404**:
   - `Public Funded Enrollments by Responsible District 2021.xlsx` - 404
   - `DATA - Enrollment Counts by Responsible SAU` - 404
   - `DATA - Public Funded Responsible Counts by District` - 404

### Available QuickSight Dashboards (NO API ACCESS):

- QuickFacts: `https://p20w.slds.maine.gov/QuickFacts`
- Enrollment by Student Demographic: `https://p20w.slds.maine.gov/PublicFundedAttendingByStudentDemographicGroup`

These dashboards use Amazon QuickSight embedded views. They do NOT provide:
- Direct download links
- API endpoints
- Programmatic access

### Verified Working File Downloads:

```
URL: https://www.maine.gov/doe/sites/maine.gov.doe/files/inline-files/DATA%20-%2060%20Percent%20Enrollment%20by%20Fiscal%20Responsibility%20-%205.07.2025.xlsx
Status: HTTP 200 ✓
Content: Excel file with fiscal responsibility breakdown (NOT main enrollment)
```

---

## Required Actions to Fix

1. **Contact Maine DOE** to request:
   - Direct Excel/CSV downloads of enrollment data
   - API access to QuickSight dashboards
   - Historical data files

2. **Alternative approaches** (in order of preference):
   - Find archived Excel files from Maine DOE
   - Use browser automation (Selenium/RSelenium) to export from dashboard
   - Request custom data extract from Maine DOE (they offer this service)
   - As LAST RESORT: manual download instructions for users

3. **Do NOT use**:
   - Urban Institute Education Data Portal
   - NCES CCD data
   - Any federal data aggregation

---

## Available Years (when working)

2016-2024 (October 1 certified enrollment data)

---

## Data Pipeline Testing Framework

### LIVE Test Categories (in order of execution):

1. **URL Availability Test**
   - HTTP HEAD request to each data URL
   - Expected: HTTP 200
   - Test file: `tests/testthat/test-pipeline-live.R`

2. **File Download Test**
   - Full GET request with write_disk
   - Verify file size > minimum threshold
   - Verify file type (Excel, not HTML error page)

3. **File Parsing Test**
   - readxl::excel_sheets() succeeds
   - readxl::read_excel() returns data frame
   - Data frame has rows and columns

4. **Column Structure Test**
   - Expected sheets exist (Metadata, Data Report, etc.)
   - Expected columns exist (year, district, school, enrollment, etc.)

5. **Year Filtering Test**
   - Can extract single year from multi-year file
   - Extracted data has correct year

6. **Aggregation Test**
   - Sum of districts = state total
   - Sum of schools = district totals
   - Tolerance: within 1%

7. **Data Quality Test**
   - No Inf values
   - No NaN values
   - No negative enrollment counts
   - Percentages in range [0, 1]

8. **Output Fidelity Test**
   - tidy=TRUE output matches raw data totals
   - Grade sums equal row totals
   - Demographic sums equal row totals

### Running Live Tests

```r
devtools::test(filter = "pipeline-live")
```

---

## Git Commits and PRs
- NEVER reference Claude, Claude Code, or AI assistance in commit messages
- NEVER reference Claude, Claude Code, or AI assistance in PR descriptions
- NEVER add Co-Authored-By lines mentioning Claude or Anthropic
- Keep commit messages focused on what changed, not how it was written

---

## Local Testing Before PRs (REQUIRED)

**PRs will not be merged until CI passes.** Run these checks locally BEFORE opening a PR:

### CI Checks That Must Pass

| Check | Local Command | What It Tests |
|-------|---------------|---------------|
| R-CMD-check | `devtools::check()` | Package builds, tests pass, no errors/warnings |
| Python tests | `pytest tests/test_pymeschooldata.py -v` | Python wrapper works correctly |
| pkgdown | `pkgdown::build_site()` | Documentation and vignettes render |

### Quick Commands

```r
# R package check (required)
devtools::check()

# Python tests (required)
system("pip install -e ./pymeschooldata && pytest tests/test_pymeschooldata.py -v")

# pkgdown build (required)
pkgdown::build_site()
```

### Pre-PR Checklist

Before opening a PR, verify:
- [ ] `devtools::check()` — 0 errors, 0 warnings
- [ ] `pytest tests/test_pymeschooldata.py` — all tests pass
- [ ] `pkgdown::build_site()` — builds without errors
- [ ] Vignettes render (no `eval=FALSE` hacks)

---

## LIVE Pipeline Testing

This package includes `tests/testthat/test-pipeline-live.R` with LIVE network tests.

### Test Categories:
1. URL Availability - HTTP 200 checks
2. File Download - Verify actual file (not HTML error)
3. File Parsing - readxl/readr succeeds
4. Column Structure - Expected columns exist
5. get_raw_enr() - Raw data function works
6. Data Quality - No Inf/NaN, non-negative counts
7. Aggregation - State total > 0
8. Output Fidelity - tidy=TRUE matches raw

### Running Tests:
```r
devtools::test(filter = "pipeline-live")
```

See `state-schooldata/CLAUDE.md` for complete testing framework documentation.

