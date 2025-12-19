#' generate_pregnancy_flags
#'
#' This function generates a table indicating whether each report meets the
#' pregnancy-related criteria defined by the UMC, EMA, and Sakai algorithms
#' for a given database.
#'
#' @param database A character string specifying the database to use. Default
#'   is `FAERS_version`. If "sample", sample data from the DiAna package is
#'   used.
#' @param pids_vct A vector of primary IDs to filter the data. Default to NA,
#'   that takes all the primary IDs in the Demo table.
#'
#' @return A data.table containing the primary IDs, individual criteria flags,
#'   and aggregated flags for each algorithm. The UMC column indicates reports
#'   identified by the UMC/Vigibase algorithm; the EMA column by the
#'   EMA/EudraVigilance algorithm; and the SakaiHPPV, SakaiHS, and SakaiM
#'   columns by the Sakai algorithm's high PPV, high sensitivity, and medium
#'   versions, respectively.
#'
#' @details
#' The function imports data from the specified database and checks various
#' exclusion and inclusion criteria related to pregnancy. The criteria include
#' age, sex, exposure, reactions, and outcomes.
#'
#' @examples
#' \dontrun{
#' # Example usage with sample data
#' pregnancy_retrieval(database = "sample", pids_vct = c(1, 2, 3))
#' }
#' @import data.table DiAna
#' @importFrom dplyr distinct
#' @export

### algorithms for retrieval -----------------------
generate_pregnancy_flags <- function(database = FAERS_version, pids_vct = NA) {
  if (database == "sample") {
    Demo <- DiAna::sample_Demo
    Drug <- DiAna::sample_Drug # nolint: object_usage_linter.
    Reac <- DiAna::sample_Reac
    Indi <- DiAna::sample_Indi
    Outc <- DiAna::sample_Outc
    Drug_supp <- DiAna::sample_Drug_Supp
  } else {
    DiAna::import("DEMO", quarter = database, pids = pids_vct)
    DiAna::import("DRUG", quarter = database, pids = pids_vct)
    DiAna::import("REAC", quarter = database, pids = pids_vct)
    DiAna::import("INDI", quarter = database, pids = pids_vct)
    DiAna::import("OUTC", quarter = database, pids = pids_vct)
    DiAna::import("DRUG_SUPP", quarter = database, pids = pids_vct)
    if (database == "VigiBase") {
      DiAna::import("COMORB", quarter = database, pids = pids_vct)
      DiAna::import("PARENT", quarter = database, pids = pids_vct)
    }
  }
  # Create df-------------
  criteria_df <- Demo[, .("primaryid" = primaryid)]

  # exclusion criteria ---------------------------------------------------------
  ## inspect age patient -------------------------------------------------------
  DAYS_PER_YEAR <- 365.242199

  criteria_df[, "E_age_over_50y" := primaryid %in% Demo[
    age_in_days >= 50 * DAYS_PER_YEAR
  ]$primaryid]
  if (is.null(Demo$age_group)) {
    criteria_df$E_agegroup_elderly <- NA
  } else {
    criteria_df[, "E_agegroup_elderly" := primaryid %in% Demo[as.character(age_group) == "Elderly"]$primaryid]
  }

  ## inspect sex ---------------------------------------------------------------
  if (exists("Parent")) {
    criteria_df[, "E_parent_M" := primaryid %in% Parent[parent_sex == "M"]$primaryid]
  } else {
    criteria_df[, "E_parent_M" := NA]
  }
  ## exposure paternal ---------------------------------------------------------
  if (is.null(Reac$llt)) {
    criteria_df[, "E_reac_paternal" := primaryid %in% Reac[
      pt %in% c(pt_ex_pater_A, pt_ex_pater_B, pt_ex_pater_D)
    ]$primaryid & !primaryid %in% Reac[pt %in% c(pt_ex_mater_A, pt_ex_mater_B, pt_ex_mater_C)]$primaryid]
  } else {
    criteria_df[, "E_reac_paternal" := primaryid %in% Reac[
      pt %in% c(pt_ex_pater_A, pt_ex_pater_B, pt_ex_pater_D) | llt %in% llt_ex_pater
    ]$primaryid & !primaryid %in% Reac[pt %in% c(pt_ex_mater_A, pt_ex_mater_B, pt_ex_mater_C)]$primaryid]
  }
  ## reac normal combined ---------------------------------------------------------------
  criteria_df[, "E_reac_normalCombined" := primaryid %in% Reac[
    pt %in% c(pt_ectopic, pt_contraception, pt_normal, pt_lactation, pt_menstrual)
  ]$primaryid]
  ## no adr  ---------------------------------------------------------------
  criteria_df[, "E_reac_noADR" := primaryid %in% Reac[
    pt %in% c("no adverse reaction")
  ]$primaryid]
  ## indi normal combined --------------------------------------------------------
  criteria_df[, "E_indi_normalCombined" := primaryid %in% Indi[
    indi_pt %in% c(pt_contraception, pt_menstrual)
  ]$primaryid]

  # inclusion criteria ---------------------------------------------------------
  ## gestational period --------------------------------------------------------
  if (!is.null(Demo$gestation_period)) {
    criteria_df[, "I_gestation" := primaryid %in% Demo[
      !is.na(gestation_period)
    ]$primaryid]
  } else {
    criteria_df[, "I_gestation" := NA]
  }

  ## adm route -----------------------------------------------------------------
  criteria_df[, "I_route_transplacental" := primaryid %in% Drug_supp[
    route %in% rt_transplacental
  ]$primaryid]
  criteria_df[, "I_route_intramniotic" := primaryid %in% Drug_supp[
    route %in% rt_intraamniotic
  ]$primaryid]
  criteria_df[, "I_route_extraamniotic" := primaryid %in% Drug_supp[
    route %in% rt_extraamniotic
  ]$primaryid]
  ## Indi exposure --------------------------------------------------------------
  # UMC and Sakai
  criteria_df[, "I_indi_exposure_matACunkA" := primaryid %in% Indi[
    indi_pt %in% c(
      pt_ex_mater_A, pt_ex_mater_C, pt_ex_unk_A
    )
  ]$primaryid]

  # Sakai
  criteria_df[, "I_indi_exposure_mater_B" := primaryid %in% Indi[
    indi_pt %in% pt_ex_mater_B
  ]$primaryid]

  # Zaccaria
  criteria_df[, "I_indi_exposure_nolact" := primaryid %in% Indi[
    indi_pt %in% c(
      pt_ex_mater_A, pt_ex_mater_B, pt_ex_unk_A, pt_ex_unk_B,
      pt_ex_pater_A, pt_ex_pater_C
    )
  ]$primaryid & !primaryid %in% Indi[
    indi_pt %in% pt_lactation
  ]$primaryid]
  criteria_df[, "I_indi_fet_abo_pregn_norm" := primaryid %in% Indi[
    indi_pt %in% c(pt_foetal, pt_normal, pt_delivery, pt_abortion)
  ]$primaryid]
  ## Reactions -----------------------------------------------------------------
  criteria_df[, "I_reac_exposure_matACunkA" := primaryid %in% Reac[
    pt %in% c(pt_ex_mater_A, pt_ex_mater_C, pt_ex_unk_A)
  ]$primaryid]
  criteria_df[, "I_reac_exposure_matB" := primaryid %in% Reac[
    pt %in% c(pt_ex_mater_B)
  ]$primaryid]
  criteria_df[, "I_reac_fet_abo_pregn" := primaryid %in% Reac[
    pt %in% c(pt_foetal, pt_abortion, pt_delivery)
  ]$primaryid]
  criteria_df[, "I_reac_normal" := primaryid %in% Reac[
    pt %in% c(pt_normal)
  ]$primaryid]
  ## Congenital reactions ------------------------------------------------------
  criteria_df[, "I_reac_cong_below_2" := primaryid %in% Demo[
    age_in_days < 24 * DAYS_PER_MONTH
  ]$primaryid & primaryid %in% Reac[
    pt %in% pt_congenital
  ]$primaryid]
  criteria_df[, "I_reac_cong_CA" := primaryid %in% Outc[
    outc_cod %in% outc_ca
  ]$primaryid & primaryid %in% Reac[
    pt %in% pt_congenital
  ]$primaryid]
  if (exists("Parent")) {
    criteria_df[, "I_reac_cong_parent" := primaryid %in% Parent$primaryid & primaryid %in% Reac[
      pt %in% pt_congenital
    ]$primaryid]
  } else {
    criteria_df[, "I_reac_cong_parent" := NA]
  }
  ## Neonatal reactions --------------------------------------------------------
  criteria_df[, "I_reac_neon_below_8days" := primaryid %in% Demo[
    age_in_days < 8
  ]$primaryid & primaryid %in% Reac[
    pt %in% pt_neonatal
  ]$primaryid]
  criteria_df[, "I_reac_neon_CA" := primaryid %in% Outc[
    outc_cod %in% outc_ca
  ]$primaryid & primaryid %in% Reac[
    pt %in% pt_neonatal
  ]$primaryid]
  if (exists("Parent")) {
    criteria_df[, "I_reac_neon_parent" := primaryid %in% Parent$primaryid & primaryid %in% Reac[
      pt %in% pt_neonatal
    ]$primaryid]
  } else {
    criteria_df[, "I_reac_neon_parent" := NA]
  }
  ## Parent --------------------------------------------------------------------
  if (exists("Parent")) {
    criteria_df[, "I_parent_F_nolac" := primaryid %in% Parent[
      parent_sex == "F"
    ]$primaryid & !primaryid %in% c(Indi[
      indi_pt %in% pt_lactation
    ]$primaryid, Reac[pt %in% pt_lactation]$primaryid, Drug_supp[
      route %in% rt_transmammary
    ]$primaryid)]
  } else {
    criteria_df[, "I_parent_F_nolac" := NA]
  }
  ## Outcome -------------------------------------------------------------------
  criteria_df[, "I_serious_CA" := primaryid %in% Outc[
    outc_cod %in% outc_ca
  ]$primaryid]

  ## History -------------------------------------------------------------------
  if (exists("Comorb")) {
    criteria_df[, "I_concurrent_pregn" := primaryid %in% Comorb[
      comorbidity_llt %in% txt_pregn & persistence == TRUE
    ]$primaryid]
  } else {
    criteria_df[, "I_concurrent_pregn" := NA]
  }
  criteria_df <- unique(criteria_df)
  criteria_df[, "I_reac_neon_cong" := primaryid %in% Reac[
    pt %in% c(pt_neonatal, pt_congenital)
  ]$primaryid]
  criteria_df[, "I_indi_fet_pregn_norm" := primaryid %in% Indi[
    indi_pt %in% c(pt_foetal, pt_delivery, pt_normal)
  ]$primaryid]
  criteria_df[, "E_nofertile_F" := primaryid %in% Demo[
    sex == "M" | is.na(sex) |
      age_in_days < 15 * DAYS_PER_YEAR | age_in_days >= 55 * DAYS_PER_YEAR | is.na(age_in_days)
  ]$primaryid]
  criteria_df[, "E_indi_paternal" := primaryid %in% Indi[
    indi_pt %in% c(pt_ex_pater_A, pt_ex_pater_B, pt_ex_pater_C)
  ]$primaryid]
  criteria_df[, "E_reac_paternal_Sakai" := primaryid %in% Reac[
    pt %in% c(pt_ex_pater_A, pt_ex_pater_B, pt_ex_pater_C)
  ]$primaryid]
  criteria_df[, "E_indi_congenital" := primaryid %in% Indi[
    indi_pt %in% pt_congenital
  ]$primaryid]

  # UMC algorithm -----------------------------------------------------------
  exclusions_UMC <- c("E_age_over_50y", "E_agegroup_elderly", "E_parent_M", "E_reac_paternal")

  inclusions_UMC <- c(
    "I_gestation", "I_serious_CA", "I_reac_cong_below_2", "I_reac_normal", "I_reac_fet_abo_pregn",
    "I_reac_exposure_matACunkA", "I_indi_fet_abo_pregn_norm", "I_indi_exposure_matACunkA", "I_route_transplacental",
    "I_reac_neon_below_8days", "I_concurrent_pregn", "I_parent_F_nolac"
  )


  criteria_df[,
    "UMC" := check_criteria(.SD, exclusions_UMC, inclusions_UMC),
    .SDcols = c(exclusions_UMC, inclusions_UMC)
  ]

  # EMA algorithm -----------------------------------------------------------
  exclusions_EMA <- c("E_age_over_50y", "E_reac_normalCombined", "E_reac_noADR", "E_indi_normalCombined")

  inclusions_EMA <- c(
    "I_gestation", "I_reac_cong_CA", "I_reac_cong_parent", "I_reac_fet_abo_pregn",
    "I_reac_exposure_matACunkA", "I_indi_exposure_nolact", "I_route_transplacental", "I_route_intramniotic",
    "I_reac_neon_CA", "I_reac_neon_parent"
  )

  criteria_df[,
    "EMA" := check_criteria(.SD, exclusions_EMA, inclusions_EMA),
    .SDcols = c(exclusions_EMA, inclusions_EMA)
  ]

  # Sakai algorithm - HPPV -----------------------------------------------------------
  exclusions_SakaiHPPV <- NA

  inclusions_SakaiHPPV <- c(
    "I_reac_exposure_matACunkA", "I_reac_exposure_matB", "I_indi_exposure_matACunkA",
    "I_indi_exposure_mater_B", "I_route_transplacental", "I_route_intramniotic", "I_route_extraamniotic"
  )

  criteria_df[,
    "SakaiHPPV" := check_criteria(.SD, exclusions_SakaiHPPV, inclusions_SakaiHPPV),
    .SDcols = c(inclusions_SakaiHPPV)
  ]

  # Sakai algorithm - HS -----------------------------------------------------------
  exclusions_SakaiHS <- NA

  inclusions_SakaiHS <- c(
    "I_reac_exposure_matACunkA", "I_reac_exposure_matB", "I_indi_exposure_matACunkA", "I_indi_exposure_mater_B",
    "I_route_transplacental", "I_route_intramniotic", "I_route_extraamniotic",
    "I_reac_fet_abo_pregn", "I_reac_normal", "I_reac_neon_cong", "I_indi_fet_pregn_norm"
  )

  criteria_df[,
    "SakaiHS" := check_criteria(.SD, exclusions_SakaiHS, inclusions_SakaiHS),
    .SDcols = c(inclusions_SakaiHS)
  ]

  # Sakai algorithm - M -----------------------------------------------------------
  exclusions_SakaiM <- c(
    "E_reac_paternal_Sakai", "E_indi_paternal", "E_indi_congenital", "E_nofertile_F"
  )

  inclusions_SakaiM <- c(
    # + inclusion SakaiHPPV, added separately because not affected by exclusion criteria
    "I_reac_fet_abo_pregn", "I_reac_normal", "I_reac_neon_cong", "I_indi_fet_pregn_norm"
  )

  criteria_df[,
    "SakaiM" := check_criteria(.SD, exclusions_SakaiM, inclusions_SakaiM),
    .SDcols = c(exclusions_SakaiM, inclusions_SakaiM)
  ]
  criteria_df[, "SakaiM" := criteria_df[["SakaiM"]] | criteria_df[["SakaiHPPV"]]]

  criteria_df
}

check_inclusion <- function(criterion) {
  ifelse(!is.na(criterion), criterion, FALSE)
}
check_exclusion <- function(criterion) {
  ifelse(!is.na(criterion), !criterion, TRUE)
}

#' Check Inclusion and Exclusion Criteria
#'
#' Evaluates a set of exclusion and inclusion conditions on a dataset,
#' thus allowing to implement tailored criteria.
#' Exclusion criteria are combined with logical AND (`&`),
#' while inclusion criteria are combined with logical OR (`|`).
#' If no exclusion criteria are supplied, the function returns the inclusion result alone.
#'
#' @param data A data frame containing the variables to evaluate.
#' @param exclusions A character vector of column names whose corresponding
#'   exclusion checks will be applied. Each column is passed to `check_exclusion()`.
#'   Examples are:
#'   \describe{
#'      \item{E_age_over_50y}{age specified and older than 50 years old}
#'      \item{E_agegroup_elderly}{age group specified as "elderly"}
#'      \item{E_parent_M}{linked to a parental report specifying "male" as sex}
#'      \item{E_reac_paternal}{
#'        paternal exposure specified among reaction in the lack of maternal exposure}
#'      \item{E_reac_normalCombined}{
#'        among reactions, specified normal pregnancy outcome, lactation, menstrual disorders, contraceptive methods}
#'      \item{E_reac_noADR}{
#'        only exposure term, with not adverse outcome specified}
#'      \item{E_indi_normalCombined}{among indications, specified menstrual disorders or contraception}
#'      \item{E_nofertile_F}{
#'        report of a male individual, or under 15 or over 55 years old, or unspecified sex or age}
#'      \item{E_reac_normalCombined}{
#'        among reactions, specified normal pregnancy outcome, lactation, menstrual disorders, contraceptive methods}
#'      \item{E_indi_paternal}{among indications, specified paternal exposure}
#'      \item{E_indi_congenital}{among indications, specified congenital disorder}
#'   }
#'
#' @param inclusions A character vector of column names whose corresponding
#'   inclusion checks will be applied. Each column is passed to `check_inclusion()`.
#'   Examples are:
#'   \describe{
#'      \item{I_gestation}{information about the gestation period}
#'      \item{I_route_transplacental}{route specified as transplacental}
#'      \item{I_route_intramniotic}{route specified as intramniotic}
#'      \item{I_route_extraamniotic}{route specified as extraamniotic}
#'      \item{I_indi_exposure_matACunkA}{maternal exposure reported as indication}
#'      \item{I_indi_exposure_mater_B}{
#'        maternal exposure reported as indication_terms 2 (see paper)}
#'      \item{I_indi_exposure_nolact}{
#'        maternal or paternal exposure reported as indication, excluding reports of exposure through lactation}
#'      \item{I_indi_fet_abo_pregn_norm}{
#'        among indications, terms concerning fetal disorders, abortion, delivery, or normal pregnancy outcome}
#'      \item{I_reac_exposure_matACunkA}{maternal exposure reported as reaction}
#'      \item{I_reac_exposure_matB}{maternal exposure reported as indication_terms 2 (see paper)}
#'      \item{I_reac_fet_abo_pregn}{
#'        among reactions, terms concerning fetal disorders, abortion, delivery}
#'     \item{I_reac_normal}{
#'        among reactions, terms concerning normal pregnancy outcome}
#'      \item{I_reac_cong_below_2}{
#'        among reactions, specified congenital disorders, in an age of less then 2 years old}
#'      \item{I_reac_cong_CA}{
#'        congenital anomaly specified as reaction, with congenital anomaly specified as seriousness}
#'      \item{I_reac_cong_parent}{linked parental report and congenital anomaly as reaction}
#'      \item{I_reac_neon_below_8days}{neonatal reaction in a neonate less than 8 days old}
#'      \item{I_reac_neon_CA}{neonatal reaction with outcome of congenital anomaly}
#'      \item{I_reac_neon_parent}{linked parental report in neonatal reaction}
#'      \item{I_parent_F_nolac}{
#'        parental report with sex specified as female, excluding reports of exposure through lactation}
#'      \item{I_serious_CA}{reports specifying as outcome a congenital anomaly}
#'      \item{I_concurrent_pregn}{reports specificying in the comorbidity a pregnancy related term}
#'      \item{I_reac_neon_cong}{neonatal or congenital reactions}
#'      \item{I_indi_fet_pregn_norm}{
#'        fetal or delivery related term, or normal pregnancy outcome reported as indication}
#'   }
#' @return
#' A logical vector indicating which rows satisfy the combined
#' inclusion and exclusion criteria.
#' If `exclusions` is empty, only the inclusion criteria are applied.
#'
#'
#' @examples
#' # The following example shows how the default algorithms are run
#' # within the generate_pregnancy_flags function, so to support tailoring.
#' # exclusions_UMC <- c("E_age_over_50y", "E_agegroup_elderly", "E_parent_M",
#' # "E_reac_paternal")
#' # inclusions_UMC <- c("I_gestation", "I_serious_CA", "I_reac_cong_below_2",
#' # "I_reac_normal", "I_reac_fet_abo_pregn", "I_reac_exposure_matACunkA",
#' # "I_indi_fet_abo_pregn_norm", "I_indi_exposure_matACunkA",
#' # "I_route_transplacental", "I_reac_neon_below_8days", "I_concurrent_pregn",
#' # "I_parent_F_nolac")
#' # criteria_df[, UMC := check_criteria(.SD, exclusions_UMC, inclusions_UMC),
#' # .SDcols = c(exclusions_UMC, inclusions_UMC)]
#' # exclusions_EMA <- c("E_age_over_50y", "E_reac_normalCombined",
#' # "E_reac_noADR", "E_indi_normalCombined")
#' # inclusions_EMA <- c("I_gestation", "I_reac_cong_CA", "I_reac_cong_parent",
#' # "I_reac_fet_abo_pregn", "I_reac_exposure_matACunkA",
#' # "I_indi_exposure_nolact", "I_route_transplacental", "I_route_intramniotic",
#' # "I_reac_neon_CA", "I_reac_neon_parent")
#' # criteria_df[, EMA := check_criteria(.SD, exclusions_EMA, inclusions_EMA),
#' # .SDcols = c(exclusions_EMA, inclusions_EMA)]
#' # exclusions_SakaiHPPV <- NA
#' # inclusions_SakaiHPPV <- c("I_reac_exposure_matACunkA",
#' # "I_reac_exposure_matB", "I_indi_exposure_matACunkA",
#' # "I_indi_exposure_mater_B", "I_route_transplacental",
#' # "I_route_intramniotic", "I_route_extraamniotic")
#' # criteria_df[, SakaiHPPV := check_criteria(.SD, exclusions_SakaiHPPV,
#' # inclusions_SakaiHPPV), .SDcols = c(inclusions_SakaiHPPV)]
#' # exclusions_SakaiHS <- NA
#' # inclusions_SakaiHS <- c(
#' # "I_reac_exposure_matACunkA", "I_reac_exposure_matB",
#' # "I_indi_exposure_matACunkA", "I_indi_exposure_mater_B",
#' # "I_route_transplacental", "I_route_intramniotic", "I_route_extraamniotic",
#' # "I_reac_fet_abo_pregn",
#' # "I_reac_normal",
#' # "I_reac_neon_cong",
#' # "I_indi_fet_pregn_norm"
#' # )
#' #
#' # criteria_df[, SakaiHS := check_criteria(.SD, exclusions_SakaiHS,
#' # inclusions_SakaiHS), .SDcols = c(inclusions_SakaiHS)]
#' #
#' # exclusions_SakaiM <- c(
#' #  "E_reac_paternal_Sakai",
#' #  "E_indi_paternal",
#' #  "E_indi_congenital",
#' #  "E_nofertile_F"
#' # )
#' #
#' # inclusions_SakaiM <- c(
#' #  # + inclusion SakaiHPPV, added separately because
#' # not affected by exclusion criteria
#' #  "I_reac_fet_abo_pregn",
#' #  "I_reac_normal",
#' #  "I_reac_neon_cong",
#' #  "I_indi_fet_pregn_norm"
#' # )
#' #
#' # criteria_df[, SakaiM := check_criteria(.SD, exclusions_SakaiM,
#' # inclusions_SakaiM), .SDcols = c(exclusions_SakaiM, inclusions_SakaiM)][
#' # , SakaiM := SakaiM | SakaiHPPV]

#' @export
check_criteria <- function(data, exclusions, inclusions) {
  excl_result <- Reduce(`&`, lapply(exclusions, function(col) check_exclusion(data[[col]])))
  incl_result <- Reduce(`|`, lapply(inclusions, function(col) check_inclusion(data[[col]])))
  results <- ifelse(length(excl_result) == 0, list(incl_result), list(excl_result & incl_result))
  unlist(results)
}
