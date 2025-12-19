#' Generate a flowchart for a specified pregnancy algorithm
#' Creates a graphical flowchart summarizing inclusion and exclusion criteria
#' for pregnancy algorithms.
#' @param database A FAERS@DiAna quarter (e.g., '25Q2') or the name of the
#'   folder containing your input data. Defaults to `FAERS_version`.
#' @param pregnancy_flags_table A data frame returned by
#'   `generate_pregnancy_flags()`.
#' @param algorithm Character string specifying the algorithm to display.
#'   Allowed values: "UMC", "EMA", "SakaiHPPV", "SakaHS", "SakaiM".
#' @return A ggplot object representing the flowchart.
#' @examples
#' \dontrun{
#' flowchart_generator(
#'   database = FAERS_version,
#'   pregnancy_flags_table = flags,
#'   algorithm = "UMC"
#' )
#' }
#'
#' @importFrom ggplot2 theme coord_flip scale_x_reverse scale_y_reverse
#' @export
flowchart_generator <- function(database = FAERS_version, pregnancy_flags_table, algorithm) {
  # create elements for the flowchart
  N <- paste0("Dataset ", database, "\n", "N = ", nrow(pregnancy_flags_table))
  O1 <- paste0(
    "Excluding patient age >= 50y", "\n",
    "N = ", nrow(pregnancy_flags_table[E_age_over_50y == TRUE])
  )
  O2 <- paste0(
    "Excluding patient age group Elderly", "\n",
    "N = ", nrow(pregnancy_flags_table[E_agegroup_elderly == TRUE])
  )
  O3 <- paste0(
    "Excluding parent sex Male", "\n",
    "N = ", nrow(pregnancy_flags_table[E_parent_M == TRUE])
  )
  O4 <- paste0(
    "Excluding paternal exposure", "\n",
    "N = ", nrow(pregnancy_flags_table[E_reac_paternal == TRUE])
  )
  O5 <- paste0(
    "Excluding normal pregnancy event", "\n",
    "N = ", nrow(pregnancy_flags_table[E_reac_normalCombined == TRUE])
  )
  O6 <- paste0(
    "Excluding no event", "\n",
    "N = ", nrow(pregnancy_flags_table[E_reac_noADR == TRUE])
  )
  O7 <- paste0(
    "Excluding normal pregnancy indication", "\n",
    "N = ", nrow(pregnancy_flags_table[E_indi_normalCombined == TRUE])
  )
  SakaiM_demo <- paste0(
    "Fertile female", "\n",
    "N = ", nrow(pregnancy_flags_table[E_nofertile_F == TRUE])
  )
  SakaiM_indi <- paste0(
    "Indi pater, cong", "\n",
    "N = ", nrow(pregnancy_flags_table[E_indi_paternal == TRUE | E_indi_congenital == TRUE])
  )
  SakaiM_reac <- paste0(
    "Reac pater", "\n",
    "N = ", nrow(pregnancy_flags_table[E_reac_paternal == TRUE])
  )
  I1 <- paste0(
    "Gestation period populated", "\n",
    "N = ", nrow(pregnancy_flags_table[I_gestation == TRUE])
  )
  I2 <- paste0(
    "Adm route transplacental", "\n",
    "N = ", nrow(pregnancy_flags_table[I_route_transplacental == TRUE])
  )
  I3 <- paste0(
    "Adm route intraamniotic", "\n",
    "N = ", nrow(pregnancy_flags_table[I_route_intramniotic == TRUE])
  )
  I4 <- paste0(
    "Adm route extraamniotic", "\n",
    "N = ", nrow(pregnancy_flags_table[I_route_extraamniotic == TRUE])
  )
  I5 <- paste0(
    "Event in maternal exp A,C, general exp A", "\n",
    "N = ", nrow(pregnancy_flags_table[I_reac_exposure_matACunkA == TRUE])
  )
  I6 <- paste0(
    "Event in maternal exp B", "\n",
    "N = ", nrow(pregnancy_flags_table[I_reac_exposure_matB == TRUE])
  )
  I7 <- paste0(
    "Event in foetal dis, pregnancy, labour, delivery, term of pregnancy", "\n",
    "N = ", nrow(pregnancy_flags_table[I_reac_fet_abo_pregn == TRUE])
  )
  I8 <- paste0(
    "Event in normal pregnancy", "\n",
    "N = ", nrow(pregnancy_flags_table[I_reac_normal == TRUE])
  )
  I9 <- paste0(
    "Indi in maternal exp A,C, general exp A", "\n",
    "N = ", nrow(pregnancy_flags_table[I_indi_exposure_matACunkA == TRUE])
  )
  I10 <- paste0(
    "Indi in maternal exp B", "\n",
    "N = ", nrow(pregnancy_flags_table[I_indi_exposure_mater_B == TRUE])
  )
  I11 <- paste0(
    "Indi in maternal exp A,B, general exp A,B, paternal exp A,C AND indi not lactation", "\n",
    "N = ", nrow(pregnancy_flags_table[I_indi_exposure_nolact == TRUE])
  )
  I12 <- paste0(
    "Indi in foetal dis, pregnancy, labour, delivery, term of pregnancy, normal pregnancy", "\n",
    "N = ", nrow(pregnancy_flags_table[I_indi_fet_abo_pregn_norm == TRUE])
  )
  I13 <- paste0(
    "Event congenital AND seriousness CA", "\n",
    "N = ", nrow(pregnancy_flags_table[I_reac_cong_CA == TRUE])
  )
  I14 <- paste0(
    "Event congenital AND parent/child report", "\n",
    "N = ", nrow(pregnancy_flags_table[I_reac_cong_parent == TRUE])
  )
  I15 <- paste0(
    "Seriousness CA", "\n",
    "N = ", nrow(pregnancy_flags_table[I_serious_CA == TRUE])
  )
  I16 <- paste0(
    "Event congenital AND patient age < 2y", "\n",
    "N = ", nrow(pregnancy_flags_table[I_reac_cong_below_2 == TRUE])
  )
  I17 <- paste0(
    "Event neonatal AND seriousness CA", "\n",
    "N = ", nrow(pregnancy_flags_table[I_reac_neon_CA == TRUE])
  )
  I18 <- paste0(
    "Event neonatal AND parent/child report", "\n",
    "N = ", nrow(pregnancy_flags_table[I_reac_neon_parent == TRUE])
  )
  I19 <- paste0(
    "Event neonatal AND patient age < 8d", "\n",
    "N = ", nrow(pregnancy_flags_table[I_reac_neon_below_8days == TRUE])
  )
  I20 <- paste0(
    "Concurrent pregnancy", "\n",
    "N = ", nrow(pregnancy_flags_table[I_concurrent_pregn == TRUE])
  )
  I21 <- paste0(
    "No lactation mother", "\n",
    "N = ", nrow(pregnancy_flags_table[I_parent_F_nolac == TRUE])
  )
  SakaiHS_indi <- paste0(
    "Indi foetal, normal, delivery (Sakai)", "\n",
    "N = ", nrow(pregnancy_flags_table[I_indi_fet_pregn_norm == TRUE]) # nolint: object_usage_linter
  )
  SakaiHS_reac <- paste0(
    "Reac foetal, normal, delivery, neonatal, cong, abo (Sakai)", "\n",
    "N = ", pregnancy_flags_table[
      (I_reac_fet_abo_pregn | I_reac_normal | I_reac_neon_cong | I_indi_fet_pregn_norm) # nolint: object_usage_linter
      , .N
    ]
  )
  NF <- paste0(
    "Pregnancy reports:", "\n",
    "N = ", nrow(pregnancy_flags_table[get(algorithm) == TRUE])
  )

  # define elements to be considered by each algorithm
  if (algorithm == "UMC") {
    # nolint next: object_usage_linter.
    excl_criteria <- c(
      "E_age_over_50y", "E_agegroup_elderly", "E_parent_M", "E_reac_paternal"
    )
    excl_criteria_codes <- c(O1, O2, O3, O4)
    incl_criteria_codes <- c(I1, I2, I5, I7, I8, I9, I12, I15, I16, I19, I20, I21)
  } else if (algorithm == "EV") {
    excl_criteria <- c("E_age_over_50y", "E_reac_normalCombined", "E_reac_noADR", "E_indi_normalCombined")
    excl_criteria_codes <- c(O1, O5, O6, O7)
    incl_criteria_codes <- c(I1, I2, I3, I5, I7, I11, I13, I14, I17, I18)
  } else if (algorithm == "SakaiH") {
    excl_criteria <- c()
    excl_criteria_codes <- c()
    incl_criteria_codes <- c(I2, I3, I4, I5, I6, I9, I10)
  } else if (algorithm == "SakaiL") {
    excl_criteria <- c()
    excl_criteria_codes <- c()
    incl_criteria_codes <- c(I2, I3, I4, I5, I6, I9, I10, SakaiHS_indi, SakaiHS_reac)
  } else if (algorithm == "SakaiM") {
    excl_criteria <- c("Fertile female", "Indi pater, cong", "Reac pater")
    excl_criteria_codes <- c(SakaiM_demo, SakaiM_indi, SakaiM_reac)
    incl_criteria_codes <- c(I2, I3, I4, I5, I6, I9, I10, SakaiHS_indi, SakaiHS_reac)
  }

  N_adm <- paste0(
    "Admissible reports:", "\n",
    "N = ",
    nrow(pregnancy_flags_table) - nrow(pregnancy_flags_table[rowSums(pregnancy_flags_table[, ..excl_criteria]) > 0])
  )

  # define and plot flowchart
  flowchart_data <- tibble::tibble(
    from = c(
      rep(N, length(excl_criteria_codes)), excl_criteria_codes,
      rep(N_adm, length(incl_criteria_codes)), incl_criteria_codes
    ),
    to = c(
      excl_criteria_codes, rep(N_adm, length(excl_criteria_codes)),
      incl_criteria_codes, rep(NF, length(incl_criteria_codes))
    )
  )
  flowchart_node <- tibble::tibble(name = c(N, excl_criteria_codes, N_adm, incl_criteria_codes, NF))
  flowchart <- ggflowchart::ggflowchart(flowchart_data, flowchart_node, text_size = 1.5) +
    theme(legend.position = "none") + coord_flip() + scale_x_reverse() + scale_y_reverse()
  flowchart
}
