# Test file for descriptive function and helper functions
# Tests use DiAna sample dataset only

library(testthat)
library(data.table)
library(DiAna)
library(PVgravID)

# Load sample data
data(sample_Demo)
data(sample_Drug)
data(sample_Reac)
data(sample_Indi)
data(sample_Outc)

# Get test primary IDs
test_pids <- head(sample_Demo$primaryid, 20)
test_cases <- test_pids[1:10]
test_controls <- test_pids[11:20]

# Tests for Helper Functions ----------------------------------------------

test_that("map_sex correctly maps sex codes", {
  expect_equal(PVgravID:::map_sex("F"), "Female")
  expect_equal(PVgravID:::map_sex("M"), "Male")
  expect_true(is.na(PVgravID:::map_sex("U")))
  expect_equal(PVgravID:::map_sex(c("F", "M", NA)), c("Female", "Male", NA))
})

test_that("map_reporter correctly maps reporter codes", {
  expect_equal(as.character(PVgravID:::map_reporter("CN")), "Consumer")
  expect_equal(as.character(PVgravID:::map_reporter("MD")), "Physician")
  expect_s3_class(PVgravID:::map_reporter("CN"), "factor")
  expect_true(is.na(as.character(PVgravID:::map_reporter("NULL"))))
})

test_that("map_submission correctly maps submission codes", {
  expect_equal(PVgravID:::map_submission("30DAY"), "Expedited")
  expect_equal(PVgravID:::map_submission("PER"), "Periodic")
  expect_equal(PVgravID:::map_submission("DIR"), "Direct")
  expect_equal(PVgravID:::map_submission("OTHER"), "Direct")
})

test_that("categorize_age creates correct age ranges", {
  expect_equal(as.character(PVgravID:::categorize_age(20)), "Neonate (<28d)")
  expect_equal(as.character(PVgravID:::categorize_age(500)), "Infant (28d-23m)")
  expect_equal(as.character(PVgravID:::categorize_age(3000)), "Child (2y-11y)")
  expect_equal(as.character(PVgravID:::categorize_age(50000)), "Elderly (>65y)")

  # Handle NA
  result <- PVgravID:::categorize_age(c(100, NA, 5000))
  expect_true(is.na(result[2]))
  expect_false(is.na(result[1]))
})

test_that("categorize_substance_count correctly categorizes counts", {
  expect_equal(as.character(PVgravID:::categorize_substance_count(1)), "1")
  expect_equal(as.character(PVgravID:::categorize_substance_count(2)), "2")
  expect_equal(as.character(PVgravID:::categorize_substance_count(4)), "3-5")
  expect_equal(as.character(PVgravID:::categorize_substance_count(10)), ">5")
})

test_that("extract_year extracts year with correct priority", {
  event_dt <- c("20230101", NA, NA, "20220615")
  init_fda_dt <- c("20210101", "20210501", NA, "20200101")
  fda_dt <- c("20200101", "20190101", "20180101", "20170101")

  result <- PVgravID:::extract_year(event_dt, init_fda_dt, fda_dt)
  expect_s3_class(result, "factor")
  expect_equal(as.character(result), c("2023", "2021", "2018", "2022"))
})

test_that("map_outcomes correctly maps outcome codes", {
  expect_equal(PVgravID:::map_outcomes("CA"), "Congenital anomaly")
  expect_equal(PVgravID:::map_outcomes("DE"), "Death")
  expect_equal(PVgravID:::map_outcomes("HO"), "Hospitalization")
  expect_equal(PVgravID:::map_outcomes("UNKNOWN"), "UNKNOWN")
})

test_that("load_pv_data returns correct structure", {
  result <- PVgravID:::load_pv_data(test_pids, database = "sample", include_ther = FALSE)

  expect_type(result, "list")
  expect_named(result, c("Demo", "Drug", "Reac", "Indi", "Outc", "Ther"))
  expect_s3_class(result$Demo, "data.table")
  expect_null(result$Ther)
  expect_true(all(result$Demo$primaryid %in% test_pids))
})

test_that("load_pv_data includes therapy data when requested", {
  result <- PVgravID:::load_pv_data(test_pids, database = "sample", include_ther = TRUE)
  expect_s3_class(result$Ther, "data.table")
})

test_that("separate_table_column handles column separation correctly", {
  test_tbl <- tibble::tibble(
    var = c("A", "B"),
    col1 = c("10;50%", "20;40%"),
    col2 = c("5;25%", "15;35%")
  )

  result <- PVgravID:::separate_table_column(test_tbl, 2)
  expect_true("N_cases" %in% colnames(result))
  expect_true("%_cases" %in% colnames(result))
})

# Tests for Main Function -------------------------------------------------

test_that("descriptive returns expected structure with cases only", {
  result <- descriptive(
    pids_cases = test_cases,
    RG = NULL,
    database = "sample",
    save_in_excel = FALSE,
    vars = c("sex", "age_range", "Reactions")
  )

  expect_s3_class(result, c("tbl_df", "tbl", "data.frame"))
  expect_true(nrow(result) > 0)
  expect_equal(result[[1]][[1]], "N")
})

test_that("descriptive returns expected structure with cases and controls", {
  result <- descriptive(
    pids_cases = test_cases,
    RG = test_controls,
    database = "sample",
    save_in_excel = FALSE,
    vars = c("sex", "age_range")
  )

  expect_s3_class(result, c("tbl_df", "tbl", "data.frame"))
  expect_true(any(grepl("cases", colnames(result))))
  expect_true(any(grepl("controls", colnames(result))))
})

test_that("descriptive handles input validation", {
  expect_error(
    descriptive(pids_cases = character(0), database = "sample"),
    "pids_cases cannot be empty"
  )

  expect_error(
    descriptive(pids_cases = test_cases, RG = character(0), database = "sample"),
    "RG must be NULL or contain at least one ID"
  )
})

test_that("descriptive handles different variable combinations", {
  result <- descriptive(
    pids_cases = test_cases,
    database = "sample",
    save_in_excel = FALSE,
    vars = c("sex", "age_range", "Reactions", "Indications", "Substances")
  )
  expect_s3_class(result, "data.frame")
  expect_true(nrow(result) > 5)
})

test_that("descriptive handles special variables", {
  # Submission variable
  result1 <- descriptive(
    pids_cases = test_cases,
    database = "sample",
    save_in_excel = FALSE,
    vars = c("Submission")
  )
  expect_s3_class(result1, "data.frame")

  # Reporter variable (handled separately)
  result2 <- descriptive(
    pids_cases = test_cases,
    database = "sample",
    save_in_excel = FALSE,
    vars = c("Reporter")
  )
  expect_s3_class(result2, "data.frame")

  # Year variable
  result3 <- descriptive(
    pids_cases = test_cases,
    database = "sample",
    save_in_excel = FALSE,
    vars = c("year")
  )
  expect_s3_class(result3, "data.frame")
})

test_that("descriptive warns when drug-dependent vars requested without drug", {
  expect_warning(
    descriptive(
      pids_cases = test_cases,
      drug = NULL,
      database = "sample",
      save_in_excel = FALSE,
      vars = c("role_cod", "time_to_onset")
    ),
    "Variables role_cod and time_to_onset not considered"
  )
})

test_that("descriptive works with list_pids parameter", {
  list_pids_test <- list(
    group1 = test_cases[1:5],
    group2 = test_cases[6:10]
  )

  result <- descriptive(
    pids_cases = test_cases,
    RG = test_controls,
    database = "sample",
    save_in_excel = FALSE,
    vars = c("sex"),
    list_pids = list_pids_test
  )

  expect_s3_class(result, "data.frame")
})

test_that("descriptive works with goodness_of_fit method", {
  result <- descriptive(
    pids_cases = test_cases,
    RG = test_controls,
    database = "sample",
    save_in_excel = FALSE,
    vars = c("sex"),
    method = "goodness_of_fit"
  )

  expect_s3_class(result, "data.frame")
})

test_that("descriptive produces consistent results", {
  result1 <- descriptive(
    pids_cases = test_cases,
    database = "sample",
    save_in_excel = FALSE,
    vars = c("sex", "age_range")
  )

  result2 <- descriptive(
    pids_cases = test_cases,
    database = "sample",
    save_in_excel = FALSE,
    vars = c("sex", "age_range")
  )

  expect_equal(result1, result2)
})

# Excel Export Tests ------------------------------------------------------

test_that("descriptive creates Excel file when save_in_excel = TRUE", {
  temp_file <- tempfile(fileext = ".xlsx")

  result <- descriptive(
    pids_cases = test_cases,
    database = "sample",
    save_in_excel = TRUE,
    file_name = temp_file,
    vars = c("sex", "age_range")
  )

  expect_true(file.exists(temp_file))

  # Clean up
  if (file.exists(temp_file)) unlink(temp_file)
})

test_that("descriptive does not create file when save_in_excel = FALSE", {
  temp_file <- tempfile(fileext = ".xlsx")
  if (file.exists(temp_file)) unlink(temp_file)

  result <- descriptive(
    pids_cases = test_cases,
    database = "sample",
    save_in_excel = FALSE,
    file_name = temp_file,
    vars = c("sex")
  )

  expect_false(file.exists(temp_file))
})

test_that("descriptive Excel file contains correct data", {
  temp_file <- tempfile(fileext = ".xlsx")

  result <- descriptive(
    pids_cases = test_cases,
    database = "sample",
    save_in_excel = TRUE,
    file_name = temp_file,
    vars = c("sex")
  )

  if (requireNamespace("readxl", quietly = TRUE)) {
    excel_data <- readxl::read_excel(temp_file)
    expect_equal(nrow(excel_data), nrow(result))
    expect_equal(ncol(excel_data), ncol(result))
  }

  if (file.exists(temp_file)) unlink(temp_file)
})

# Data Integrity Tests ----------------------------------------------------

test_that("descriptive creates N row correctly", {
  result <- descriptive(
    pids_cases = test_cases,
    RG = test_controls,
    database = "sample",
    save_in_excel = FALSE,
    vars = c("sex")
  )

  expect_equal(result[[1]][[1]], "N")
  expect_equal(as.numeric(result[[2]][[1]]), length(test_cases))
  expect_equal(as.numeric(result[[4]][[1]]), length(test_controls))
})

test_that("descriptive handles missing data gracefully", {
  result <- descriptive(
    pids_cases = test_cases,
    database = "sample",
    save_in_excel = FALSE,
    vars = c("sex", "age_range", "wt_in_kgs")
  )

  expect_s3_class(result, "data.frame")
  expect_true(nrow(result) > 0)
})

test_that("descriptive produces statistical test columns with cases and controls", {
  result <- descriptive(
    pids_cases = test_cases,
    RG = test_controls,
    database = "sample",
    save_in_excel = FALSE,
    vars = c("sex", "age_range")
  )

  # Should have p-value and q-value columns
  has_p_col <- any(grepl("p.value|p-value", colnames(result), ignore.case = TRUE))
  has_q_col <- any(grepl("q.value|q-value", colnames(result), ignore.case = TRUE))
  expect_true(has_p_col)
  expect_true(has_q_col)
})

test_that("descriptive returns tibble format", {
  result <- descriptive(
    pids_cases = test_cases,
    database = "sample",
    save_in_excel = FALSE,
    vars = c("sex")
  )

  expect_s3_class(result, "tbl_df")
  expect_s3_class(result, "data.frame")
})

# Constants Tests ---------------------------------------------------------

test_that("Constants are properly defined", {
  expect_type(PVgravID:::AGE_BREAKS, "double")
  expect_equal(length(PVgravID:::AGE_BREAKS), 8)
  expect_equal(PVgravID:::AGE_BREAKS[1], 0)

  expect_type(PVgravID:::AGE_LABELS, "character")
  expect_equal(length(PVgravID:::AGE_LABELS), 7)

  expect_type(PVgravID:::SEX_MAP, "character")
  expect_named(PVgravID:::SEX_MAP, c("F", "M"))

  expect_type(PVgravID:::REPORTER_MAP, "character")
  expect_true("CN" %in% names(PVgravID:::REPORTER_MAP))

  expect_type(PVgravID:::SUBMISSION_MAP, "list")
  expect_named(PVgravID:::SUBMISSION_MAP, c("Expedited", "Periodic", "Direct"))

  expect_type(PVgravID:::OUTCOME_MAP, "character")
  expect_true(all(c("CA", "DE", "HO") %in% names(PVgravID:::OUTCOME_MAP)))
})
