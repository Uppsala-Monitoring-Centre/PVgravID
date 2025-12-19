# Constants ---------------------------------------------------------------

#' Age range breaks (in days) and labels
#' @keywords internal
AGE_BREAKS <- c(0, 28, 730, 4380, 6570, 16425, 23725, 73000)
AGE_LABELS <- c(
  "Neonate (<28d)", "Infant (28d-23m)", "Child (2y-11y)",
  "Teenager (12y-17y)", "Adult (18y-44y)", "Adult (45y-64y)", "Elderly (>65y)"
)

#' Sex code mappings
#' @keywords internal

SEX_MAP <- c(F = "Female", M = "Male")

#' Reporter code mappings
#' @keywords internal
REPORTER_MAP <- c(
  CN = "Consumer",
  MD = "Physician",
  HP = "Healthcare practitioner",
  PH = "Pharmacist",
  LW = "Lawyer",
  OT = "Other"
)

#' Submission code mappings
#' @keywords internal
SUBMISSION_MAP <- list(
  Expedited = c("30DAY", "5DAY", "EXP"),
  Periodic = "PER",
  Direct = "DIR"
)

#' Outcome code mappings
#' @keywords internal
OUTCOME_MAP <- c(
  OT = "Other serious",
  CA = "Congenital anomaly",
  HO = "Hospitalization",
  RI = "Required intervention",
  DS = "Disability",
  LT = "Life threatening",
  DE = "Death"
)

# Helper Functions ---------------------------------------------------------

#' Map sex codes to readable labels
#'
#' @param sex_codes Character vector of sex codes (F, M, etc.)
#' @return Character vector of sex labels
#' @keywords internal
map_sex <- function(sex_codes) {
  unname(SEX_MAP[sex_codes])
}

#' Map reporter occupation codes to readable labels
#'
#' @param occp_codes Character vector of occupation codes
#' @return Factor of reporter types
#' @keywords internal
map_reporter <- function(occp_codes) {
  # Replace NULL string with NA
  occp_codes[occp_codes == "NULL"] <- NA_character_

  # Map using constant, keeping unmapped values as-is
  reporter <- ifelse(
    occp_codes %in% names(REPORTER_MAP),
    REPORTER_MAP[occp_codes],
    as.character(occp_codes)
  )

  as.factor(reporter)
}

#' Map submission report codes to submission types
#'
#' @param rept_codes Character vector of report codes
#' @return Character vector of submission types
#' @keywords internal
map_submission <- function(rept_codes) {
  # Create reverse lookup from code to category
  code_to_category <- character(length(rept_codes))
  code_to_category[] <- "Direct" # Default

  for (category in names(SUBMISSION_MAP)) {
    code_to_category[rept_codes %in% SUBMISSION_MAP[[category]]] <- category
  }

  code_to_category
}

#' Categorize age in days into age ranges
#'
#' @param age_days Numeric vector of ages in days
#' @return Factor of age ranges
#' @keywords internal
categorize_age <- function(age_days) {
  cut(
    age_days,
    breaks = AGE_BREAKS,
    include.lowest = TRUE,
    right = FALSE,
    labels = AGE_LABELS
  )
}

#' Map outcome codes to readable labels
#'
#' @param outcome_codes Character vector of outcome codes
#' @return Character vector of outcome labels
#' @keywords internal
map_outcomes <- function(outcome_codes) {
  # Map using constant, keeping unmapped values as-is
  mapped <- ifelse(
    outcome_codes %in% names(OUTCOME_MAP),
    OUTCOME_MAP[outcome_codes],
    outcome_codes
  )
  unname(mapped)
}

#' Categorize substance counts into ranges
#'
#' @param counts Numeric vector of substance counts
#' @return Factor of substance count categories
#' @keywords internal
categorize_substance_count <- function(counts) {
  cut(
    counts,
    breaks = c(0, 1, 2, 5, Inf),
    labels = c("1", "2", "3-5", ">5"),
    right = TRUE
  )
}

#' Extract year from date fields with priority
#'
#' @param event_dt Event date vector
#' @param init_fda_dt Initial FDA date vector
#' @param fda_dt FDA date vector
#' @return Factor of years
#' @keywords internal
extract_year <- function(event_dt, init_fda_dt, fda_dt) {
  year <- substr(event_dt, 1, 4)
  is_na <- is.na(year)
  year[is_na] <- substr(init_fda_dt[is_na], 1, 4)
  is_na <- is.na(year)
  year[is_na] <- substr(fda_dt[is_na], 1, 4)
  as.factor(as.numeric(year))
}

#' Load pharmacovigilance data from database or sample
#'
#' @param pids Character vector of primary IDs to load
#' @param database Database name ("sample", "VigiBase", or quarter like "24Q4")
#' @param include_ther Logical, whether to include therapy data
#' @return List of data tables (Demo, Drug, Reac, Indi, Outc, Ther)
#' @keywords internal
load_pv_data <- function(pids, database = "VigiBase", include_ther = FALSE) {
  if (database == "sample") {
    data_list <- list(
      Demo = DiAna::sample_Demo[primaryid %in% pids],
      Drug = DiAna::sample_Drug[primaryid %in% pids],
      Reac = DiAna::sample_Reac[primaryid %in% pids],
      Indi = DiAna::sample_Indi[primaryid %in% pids],
      Outc = DiAna::sample_Outc[primaryid %in% pids],
      Ther = if (include_ther) DiAna::sample_Ther[primaryid %in% pids] else NULL
    )
  } else {
    # DiAna::import returns the data.table directly
    Demo <- DiAna::import("DEMO", quarter = database, pids = pids)
    Drug <- DiAna::import("DRUG", quarter = database, pids = pids)
    Reac <- DiAna::import("REAC", quarter = database, pids = pids)
    Indi <- DiAna::import("INDI", quarter = database, pids = pids)
    Outc <- DiAna::import("OUTC", quarter = database, pids = pids)
    Ther <- if (include_ther) DiAna::import("THER", quarter = database, pids = pids) else NULL

    data_list <- list(
      Demo = Demo,
      Drug = Drug,
      Reac = Reac,
      Indi = Indi,
      Outc = Outc,
      Ther = Ther
    )
  }
  data_list
}

#' Format and separate table output columns
#'
#' @param gt_table Tibble containing gtsummary table
#' @param col_index Column index to separate
#' @return Tibble with separated columns
#' @keywords internal
separate_table_column <- function(gt_table, col_index) {
  suppressWarnings(
    gt_table |>
      tidyr::separate(
        get(colnames(gt_table)[[col_index]]),
        sep = ";",
        into = c(
          paste0("N_", ifelse(col_index == 2, "cases", "controls")),
          paste0("%_", ifelse(col_index == 2, "cases", "controls"))
        )
      )
  )
}

# Main Function ------------------------------------------------------------

#' Generate descriptive statistics for pharmacovigilance data
#'
#' @param pids_cases Character vector of primary IDs for cases
#' @param RG Character vector of primary IDs for reference group (controls). If NULL, only cases are analyzed.
#' @param drug Character vector of drug substances to analyze (for role_cod and time_to_onset)
#' @param save_in_excel Logical, whether to save results to Excel file
#' @param file_name Name of output Excel file
#' @param vars Character vector of variables to include in analysis
#' @param list_pids Named list of additional primary ID groups to compare
#' @param method Statistical method: "independence_test" or "goodness_of_fit"
#' @param database Database to use: "sample", "VigiBase", or quarter like "24Q4"
#'
#' @return Data frame/tibble with descriptive statistics
#' @export
#'
#' @examples
#' \dontrun{
#' # Analyze sample data
#' result <- descriptive(
#'   pids_cases = c("123", "456"),
#'   database = "sample"
#' )
#' }
descriptive <- function(pids_cases, RG = NULL, drug = NULL, save_in_excel = TRUE,
                        file_name = "Descriptives.xlsx", vars = c(
                          "sex", "Submission",
                          "Reporter", "age_range", "Outcome", "country", "continent",
                          "age_in_years", "wt_in_kgs", "Reactions", "Indications",
                          "Substances", "num_Substances", "year", "role_cod", "time_to_onset"
                        ),
                        list_pids = list(), method = "independence_test", database = "VigiBase") {
  # Input validation
  if (length(pids_cases) == 0) {
    stop("pids_cases cannot be empty")
  }
  if (!is.null(RG) && length(RG) == 0) {
    stop("RG must be NULL or contain at least one ID")
  }
  # Load data
  if (is.null(RG)) {
    pids_tot <- pids_cases
  } else {
    # Use unique(c()) instead of base::union() to preserve integer64 class
    pids_tot <- unique(c(pids_cases, RG))
  }
  include_ther <- "time_to_onset" %in% vars
  data_list <- load_pv_data(pids_tot, database, include_ther)

  # Extract data from list
  Demo <- data_list$Demo
  Drug <- data_list$Drug
  Reac <- data_list$Reac
  Indi <- data_list$Indi
  Outc <- data_list$Outc
  Ther <- data_list$Ther

  # Transform demographic data
  temp <- data.table::copy(Demo)
  temp[wt_in_kgs == 0, wt_in_kgs := NA]
  temp[, sex := map_sex(sex)]

  if ("Submission" %in% vars) {
    temp[, Submission := map_submission(rept_cod)]
  }

  temp[, Reporter := map_reporter(occp_cod)]
  temp[, age_in_years := age_in_days / 365]
  temp[, age_range := categorize_age(age_in_days)]

  # Transform outcome data
  temp_outc <- data.table::copy(Outc)
  temp_outc[, outc_cod := map_outcomes(outc_cod)]
  vars <- union(setdiff(vars, "Outcome"), unique(temp_outc$outc_cod))
  temp_outc <- temp_outc[, value := 1] |> tidyr::pivot_wider(
    names_from = outc_cod, values_from = value, values_fill = 0
  )
  temp <- setDT(temp_outc)[temp, on = "primaryid"]

  temp[, country := ifelse(
    is.na(as.character(occr_country)),
    as.character(reporter_country),
    as.character(occr_country)
  )]

  if (database != "VigiBase") {
    country_dictionary <- data.table::as.data.table(DiAna::country_dictionary)

    # country fix - merge continents, keeping all rows from temp even if country is NA
    country_map <- dplyr::distinct(country_dictionary[, .(country, continent)][!is.na(country)])
    setkey(temp, country)
    setkey(country_map, country)
    temp <- country_map[temp]
    temp$country <- as.factor(temp$country)
    temp$continent <- factor(
      temp$continent,
      levels = c("North America", "Europe", "Asia", "South America", "Oceania", "Africa"), ordered = TRUE
    )

    # fix reporter issue (same report, many reporters so many rows)
    temp_reporter <- temp[, .(primaryid, Reporter)]
    temp <- temp[, -c("Reporter", "occp_cod")]
    temp <- dplyr::distinct(temp)
  } else {
    temp_reporter <- temp[, .(primaryid, Reporter)]
    temp <- temp[, -c("Reporter", "occp_cod")]
    temp <- dplyr::distinct(temp)
  }

  temp <- Reac[, .N, by = "primaryid"][, .(primaryid,
    Reactions = N
  )][temp, on = "primaryid"]
  temp <- Drug[, .N, by = "primaryid"][, .(primaryid,
    Substances = N
  )][temp, on = "primaryid"]
  if ("num_Substances" %in% vars) {
    temp[, num_Substances := categorize_substance_count(Substances)]
  }
  temp <- Indi[, .N, by = "primaryid"][, .(primaryid,
    Indications = N
  )][temp, on = "primaryid"]
  if ("time_to_onset" %in% vars) {
    temp_tto <- Drug[Ther, on = c("primaryid", "drug_seq")][substance %in% drug]

    suppressWarnings(temp_tto[, role_cod := max(role_cod), by = "primaryid"])

    temp_tto <- temp_tto[!is.na(time_to_onset) & time_to_onset >= 0]

    suppressWarnings(temp_tto <- temp_tto[, .(time_to_onset = max(time_to_onset)), by = "primaryid"])

    temp <- temp_tto[temp, on = "primaryid"]

    temp$time_to_onset <- as.numeric(temp$time_to_onset)
  }
  if ("year" %in% vars) {
    temp[, year := extract_year(event_dt, init_fda_dt, fda_dt)]
  }
  # Add the max role_cod for the drug
  if (!is.null(drug)) {
    temp_drug <- Drug[primaryid %in% pids_tot][substance %in% drug][
      , role_cod := factor(role_cod, levels = c("C", "I", "SS", "PS"), ordered = TRUE)
    ][, .(role_cod = max(role_cod)), by = "primaryid"]
    suppressMessages(temp <- dplyr::left_join(temp, temp_drug))
  } else {
    vars <- setdiff(vars, c("role_cod", "time_to_onset"))
    warning(
      "Variables role_cod and time_to_onset not considered. ",
      "If you want to include them please provide the drug investigated"
    )
  }


  # descriptive only cases
  if (is.null(RG)) {
    # select the vars

    # table 1: main table without reporter
    # remove reporter from the vars since it´ll be in another table
    vars <- vars[vars != "Reporter"]
    # descriptive
    temp <- temp[, ..vars]
    t <- temp |>
      gtsummary::tbl_summary(statistic = list(
        gtsummary::all_continuous() ~ "{N_nonmiss};{median} ({p25}-{p75}) [{min}-{max}]",
        gtsummary::all_categorical() ~ "{n};{p}%"
      ), digits = colnames(temp) ~ c(0, 1))

    # format the table
    gt_table <- t |> tibble::as_tibble()
    tempN_cases <- as.numeric(gsub(",", "", gsub("\\*\\*", "", gsub(".*N = ", "", colnames(gt_table)[[2]]))))
    suppressWarnings(
      gt_table <- gt_table |> tidyr::separate(
        get(colnames(gt_table)[[2]]),
        sep = ";",
        into = c("N_cases", "%_cases")
      )
    )
    gt_table <- rbind(c("N", as.character(tempN_cases), ""), gt_table)

    # table 2: Reporter table
    t_reporter <- temp_reporter |>
      gtsummary::tbl_summary(statistic = list(
        gtsummary::all_continuous() ~ "{N_nonmiss};{median} ({p25}-{p75}) [{min}-{max}]",
        gtsummary::all_categorical() ~ "{n};{p}%"
      ), digits = colnames(temp_reporter) ~ c(0, 1))

    # format the table
    gt_table_reporter <- t_reporter |> tibble::as_tibble()
    suppressWarnings(gt_table_reporter <- gt_table_reporter |> tidyr::separate(
      get(colnames(gt_table_reporter)[[2]]),
      sep = ";",
      into = c("N_cases", "%_cases")
    ))
    gt_table <- rbind(gt_table, gt_table_reporter)

    # save it to the excel
    if (save_in_excel) {
      writexl::write_xlsx(gt_table, file_name)
    }
  } else {
    # descriptives cases and non-cases
    vars <- c(vars, "Group", names(list_pids))
    # table 1: main table without reporter
    # remove reporter from the vars since it´ll be in another table
    vars <- vars[vars != "Reporter"]

    suppressWarnings(temp[, Group := ifelse(primaryid %in% pids_cases, "Cases", "Non-Cases")])
    if (method == "goodness_of_fit") {
      temp <- rbindlist(list(temp, temp[Group == "Cases"][, Group := "Non-Cases"]))
    }
    if (!is.null(names(list_pids))) {
      for (n in seq_along(list_pids)) {
        temp[[names(list_pids)[[n]]]] <- temp$primaryid %in% list_pids[[n]]
      }
    }
    temp <- temp[, ..vars]

    # add Group to the reporter table
    suppressWarnings(temp_reporter[, Group := ifelse(primaryid %in% pids_cases, "Cases", "Non-Cases")])
    if (method == "goodness_of_fit") {
      temp_reporter <- rbindlist(list(temp_reporter, temp_reporter[Group == "Cases"][, Group := "Non-Cases"]))
    }
    if (!is.null(names(list_pids))) {
      for (n in seq_along(list_pids)) {
        temp_reporter[[names(list_pids)[[n]]]] <- temp_reporter$primaryid %in% list_pids[[n]]
      }
    }

    # perform the descriptive analysis
    # table 1: all except Reporter
    suppressMessages(t <- temp |>
      gtsummary::tbl_summary(
        by = Group, statistic = list(
          gtsummary::all_continuous() ~ "{N_nonmiss};{median} ({p25}-{p75}) [{min}-{max}]",
          gtsummary::all_continuous2() ~ "{N_nonmiss};{median} ({p25}-{p75}) [{min}-{max}]",
          gtsummary::all_categorical() ~ "{n};{p}%"
        ),
        digits = everything() ~ c(0, 1)
      ) |>
      gtsummary::add_p(
        test = list(gtsummary::all_categorical() ~ "fisher.test"),
        test.args = list(
          gtsummary::all_categorical() ~ list(simulate.p.value = TRUE),
          gtsummary::all_continuous() ~ list(exact = FALSE)
        ),
        pvalue_fun = function(x) gtsummary::style_pvalue(x, digits = 3)
      ) |>
      gtsummary::add_q("holm") |>
      gtsummary::bold_labels())

    # format the table
    gt_table <- t |> tibble::as_tibble()
    tempN_cases <- as.numeric(gsub(",", "", gsub(".*N = ", "", colnames(gt_table)[[2]])))
    tempN_controls <- as.numeric(gsub(",", "", gsub(".*N = ", "", colnames(gt_table)[[3]])))
    suppressWarnings(gt_table <- gt_table |> tidyr::separate(
      get(colnames(gt_table)[[2]]),
      sep = ";",
      into = c("N_cases", "%_cases")
    ))
    suppressWarnings(gt_table <- gt_table |> tidyr::separate(
      get(colnames(gt_table)[[4]]),
      sep = ";",
      into = c("N_controls", "%_controls")
    ))

    # table 2: for Reporter only
    suppressMessages(t_reporter <- temp_reporter |>
      gtsummary::tbl_summary(
        by = Group, statistic = list(
          gtsummary::all_continuous() ~ "{N_nonmiss};{median} ({p25}-{p75}) [{min}-{max}]",
          gtsummary::all_continuous2() ~ "{N_nonmiss};{median} ({p25}-{p75}) [{min}-{max}]",
          gtsummary::all_categorical() ~ "{n};{p}%"
        ),
        digits = everything() ~ c(0, 1)
      ) |>
      gtsummary::add_p(
        test = list(gtsummary::all_categorical() ~ "fisher.test"),
        test.args = list(
          gtsummary::all_categorical() ~ list(simulate.p.value = TRUE),
          gtsummary::all_continuous() ~ list(exact = FALSE)
        ),
        pvalue_fun = function(x) gtsummary::style_pvalue(x, digits = 3)
      ) |>
      gtsummary::add_q("holm") |>
      gtsummary::bold_labels())

    # format the table
    gt_table_reporter <- t_reporter |> tibble::as_tibble()
    suppressWarnings(gt_table_reporter <- gt_table_reporter |> tidyr::separate(
      get(colnames(gt_table_reporter)[[2]]),
      sep = ";",
      into = c("N_cases", "%_cases")
    ))
    suppressWarnings(gt_table_reporter <- gt_table_reporter |> tidyr::separate(
      get(colnames(gt_table_reporter)[[4]]),
      sep = ";",
      into = c("N_controls", "%_controls")
    ))

    # merge all in a unique table
    gt_table <- rbind(
      c("N", as.character(tempN_cases), "", as.character(tempN_controls), "", "", ""),
      gt_table,
      gt_table_reporter
    )

    # save it to the excel
    if (save_in_excel) {
      writexl::write_xlsx(gt_table, file_name)
    }
  }
  gt_table
}
