utils::globalVariables(c(
  "FAERS_version", "age_in_days", "import", "indi_pt",
  "pt", "route", "sample_Demo", "sample_Drug",
  "sample_Drug_Supp", "sample_Indi", "sample_Outc",
  "sample_Reac", "sample_Ther", "scale_fill_manual",
  "sex", "theme", "type", "primaryid", "E_age_over_50y",
  "E_agegroup_elderly", "age_group", "E_parent_M",
  "Parent", "parent_sex", "E_reac_paternal", "llt",
  "E_reac_contraception", "E_reac_normal", "E_reac_lactation",
  "E_reac_menstrual", "E_indi_contraception", "E_indi_menstrual",
  "I_gestation", "gestation_period", "I_route_transplacental",
  "I_route_intramniotic", "I_route_extraamniotic",
  "I_indi_exposure_mater_A", "I_indi_exposure_mater_B",
  "I_indi_exposure_mater_C", "I_indi_exposure_unk_A",
  "I_indi_exposure_unk_B", "I_indi_exposure_nolact",
  "I_indi_fet_abo_pregn_norm", "I_reac_exposure_matACunkA",
  "I_reac_exposure_matB", "I_reac_fet_abo_pregn",
  "I_reac_fet_abo_pregn", "I_reac_normal", "I_reac_cong_below_2",
  "I_reac_cong_CA", "outc_cod", "I_reac_cong_parent",
  "I_reac_neon_below_8days", "I_reac_neon_CA", "I_reac_neon_parent",
  "I_parent_F_nolac", "I_parent_F_nolac", "I_serious_CA",
  "I_concurrent_pregn", "Comorb", "comorbidity_llt", "persistence",
  "count", "gestation_period", "outc_cod", "Comorb", "comorbidity_llt",
  "persistence", "N", "category", "criteria", ".", "..set_names",
  "wt_in_kgs", "Submission", "rept_cod", "Reporter", "occp_cod",
  "age_in_years", "age_range", "value", "country", "occr_country",
  "reporter_country", "country_dictionary", "continent", "num_substances",
  "Substances", "substance", "role_cod", "time_to_onset", "event_dt",
  "init_fda_dt", "fda_dt", "..vars", "Group", "E_reac_normalCombined",
  "E_reac_noADR", "E_indi_normalCombined", "I_indi_exposure_matACunkA",
  "I_reac_neon_cong", "I_indi_fet_pregn_norm", "E_nofertile_F", "E_indi_paternal",
  "E_indi_congenital", "UMC", "EMA", "SakaiHPPV", "SakaiHS", "SakaiM", "num_Substances",
  "..excl_criteria", "Demo", "Drug", "Reac", "Indi", "Outc", "Ther",
  # check_pregnancy_criteria.R variables
  "pt_neonatal", "outc_ca", "txt_pregn", "pt_lactation", "rt_transmammary",
  "pt_congenital", "pt_foetal", "pt_delivery", "pt_normal",
  "pt_ex_pater_A", "pt_ex_pater_B", "pt_ex_pater_C", ".SD",
  # ComplexUpset functions
  "intersection_matrix", "intersection_size", "upset_set_size", "upset_query",
  # ggplot2 functions
  "geom_point", "geom_bar", "scale_y_continuous", "expansion",
  "element_blank", "element_line",
  # data.table functions
  "data.table", "setkey", "rbindlist", "setDT", ":=", ".N",
  # dplyr/tidyr functions
  "group_by", "across", "summarise", "n", "ungroup", "arrange", "desc", "select",
  # ggplot2 additional functions
  "coord_flip", "scale_x_reverse", "scale_y_reverse"
))
