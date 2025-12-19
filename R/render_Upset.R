#' Get Counts for UpSet Plot
#'
#' This function calculates the counts of intersections for an UpSet plot.
#'
#' @param subset A data frame containing the data to be used for the UpSet plot.
#' @param min_elements_in_intersection An integer specifying the minimum number
#'   of elements in an intersection to be included. Default is 100.
#'
#' @return A data frame with the counts of intersections and the concatenated
#'   primary IDs for each intersection.
#'
#' @details
#' The function groups the data by all columns except `primaryid`, calculates
#' the count of primary IDs for each group, and concatenates the primary IDs into
#' a single string. The resulting data frame is sorted in descending order of the
#' counts.
#'
#' @examples
#' \dontrun{
#' # Example usage
#' get_counts_for_upset(subset, min_elements_in_intersection = 100)
#' }
#' @importFrom dplyr group_by across summarise ungroup arrange desc select n
#' @export
get_counts_for_upset <- function(subset, min_elements_in_intersection = 100) {
  subset_counts <- subset |>
    group_by(across(-c("primaryid", "UMC", "EMA", "SakaiHPPV", "SakaiHS", "SakaiM"))) |>
    summarise(all_ids = paste(primaryid, collapse = " | "), count = n()) |>
    ungroup() |>
    arrange(desc(count))
  subset_counts
}

#' Render UpSet Plot
#'
#' This function renders an UpSet plot based on the provided subset of data.
#'
#' @param subset A data frame containing the data to be used for the UpSet plot.
#' @param min_elements_in_intersection An integer specifying the minimum number
#'   of elements in an intersection to be included. Default is 100.
#'
#' @importFrom data.table setDT data.table
#' @importFrom ComplexUpset intersection_matrix intersection_size upset_set_size upset_query
#' @importFrom ggplot2 geom_point geom_bar scale_y_continuous expansion theme element_blank element_line
#' @export
#' @return A ggplot object representing the UpSet plot.
#'
#' @details
#' The function processes the input data to handle missing values, converts
#' columns to numeric, and filters intersections based on the specified minimum
#' number of elements. It then orders the sets and creates the UpSet plot using
#' the ComplexUpset package.
#'
#' @examples
#' \dontrun{
#' # Example usage
#' render_upset(subset, min_elements_in_intersection = 100)
#' }
#'
#' @import ComplexUpset
#' @export
render_upset <- function(subset, min_elements_in_intersection = 100) {
  subset[is.na(subset)] <- FALSE
  subset <- apply(subset, 2, as.numeric) |> as.data.frame()


  subset <- subset |> select(-c("primaryid", "UMC", "EMA", "SakaiHPPV", "SakaiHS", "SakaiM"))
  df_intersections <- setDT(subset)[, .N, by = eval(colnames(subset))][order(-N)][N >= min_elements_in_intersection]

  subset <- subset |> select(-colnames(subset)[apply(subset, 2, sum) == 0])
  order_sets <- data.table(criteria = colnames(subset), N = apply(subset, 2, sum))
  order_sets <- order_sets[, category := substr(criteria, 0, 1)]
  order_sets <- order_sets[order(category, -N)]
  ordered_subsets <- factor(order_sets$criteria, ordered = TRUE)
  order_sets <- order_sets[, .(criteria, category)]
  u_plot <- ComplexUpset::upset(subset, ordered_subsets,
    matrix = intersection_matrix(
      geom = geom_point(
        shape = "circle filled",
        size = 2,
        stroke = 0.45
      )
    ),
    n_intersections = nrow(df_intersections),
    base_annotations = list(
      "Intersection size" = (
        intersection_size(
          width = 0.5, # reduce width of the bars
          text = list(angle = 90, vjust = -0.1, hjust = -0.1) # rotate labels
        )
        # add some space on the top of the bars
        + scale_y_continuous(expand = expansion(mult = c(0, 0.05)))
          + theme(
            # hide grid lines
            panel.grid.major = element_blank(),
            panel.grid.minor = element_blank(),
            # show axis lines
            axis.line = element_line(colour = "black")
          )
      )
    ),
    set_sizes = (
      upset_set_size(geom = geom_bar(width = 0.4))
      + theme(
          axis.line.x = element_line(colour = "black"),
          axis.ticks.x = element_line()
        )
    ),
    sort_sets = FALSE,
    width_ratio = 0.1,
    height_ratio = 1.8
  )

  plot <- ComplexUpset::upset(subset, ordered_subsets,
    matrix = intersection_matrix(
      geom = geom_point(
        shape = "circle filled",
        size = 2,
        stroke = 0.45
      )
    ),
    n_intersections = nrow(df_intersections),
    queries = setdiff(list(
      if ("E_reac_paternal" %in% u_plot[[4]][["layers"]][[1]][["data"]][["group_name"]]) {
        upset_query(set = "E_reac_paternal", fill = "turquoise3")
      },
      if ("E_age_over_50y" %in% u_plot[[4]][["layers"]][[1]][["data"]][["group_name"]]) {
        upset_query(set = "E_age_over_50y", fill = "olivedrab2")
      },
      if ("E_agegroup_elderly" %in% u_plot[[4]][["layers"]][[1]][["data"]][["group_name"]]) {
        upset_query(set = "E_agegroup_elderly", fill = "turquoise3")
      },
      if ("E_parent_M" %in% u_plot[[4]][["layers"]][[1]][["data"]][["group_name"]]) {
        upset_query(set = "E_parent_M", fill = "turquoise3")
      },
      if ("E_reac_ectopic" %in% u_plot[[4]][["layers"]][[1]][["data"]][["group_name"]]) {
        upset_query(set = "E_reac_ectopic", fill = "yellow")
      },
      if ("E_reac_contraception" %in% u_plot[[4]][["layers"]][[1]][["data"]][["group_name"]]) {
        upset_query(set = "E_reac_contraception", fill = "yellow")
      },
      if ("E_reac_normal" %in% u_plot[[4]][["layers"]][[1]][["data"]][["group_name"]]) {
        upset_query(set = "E_reac_normal", fill = "yellow")
      },
      if ("E_reac_lactation" %in% u_plot[[4]][["layers"]][[1]][["data"]][["group_name"]]) {
        upset_query(set = "E_reac_lactation", fill = "yellow")
      },
      if ("E_reac_menstrual" %in% u_plot[[4]][["layers"]][[1]][["data"]][["group_name"]]) {
        upset_query(set = "E_reac_menstrual", fill = "yellow")
      },
      if ("E_indi_contraception" %in% u_plot[[4]][["layers"]][[1]][["data"]][["group_name"]]) {
        upset_query(set = "E_indi_contraception", fill = "yellow")
      },
      if ("E_indi_menstrual" %in% u_plot[[4]][["layers"]][[1]][["data"]][["group_name"]]) {
        upset_query(set = "E_indi_menstrual", fill = "yellow")
      },
      if ("I_gestation" %in% u_plot[[4]][["layers"]][[1]][["data"]][["group_name"]]) {
        upset_query(set = "I_gestation", fill = "olivedrab2")
      },
      if ("I_route_transplacental" %in% u_plot[[4]][["layers"]][[1]][["data"]][["group_name"]]) {
        upset_query(set = "I_route_transplacental", fill = "snow2")
      },
      if ("I_route_intramniotic" %in% u_plot[[4]][["layers"]][[1]][["data"]][["group_name"]]) {
        upset_query(set = "I_route_intramniotic", fill = "goldenrod1")
      },
      if ("I_route_extraamniotic" %in% u_plot[[4]][["layers"]][[1]][["data"]][["group_name"]]) {
        upset_query(set = "I_route_extraamniotic", fill = "orangered1")
      },
      if ("I_indi_exposure_mater_A" %in% u_plot[[4]][["layers"]][[1]][["data"]][["group_name"]]) {
        upset_query(set = "I_indi_exposure_mater_A", fill = "mediumorchid")
      },
      if ("I_indi_exposure_mater_B" %in% u_plot[[4]][["layers"]][[1]][["data"]][["group_name"]]) {
        upset_query(set = "I_indi_exposure_mater_B", fill = "orangered1")
      },
      if ("I_indi_exposure_mater_C" %in% u_plot[[4]][["layers"]][[1]][["data"]][["group_name"]]) {
        upset_query(set = "I_indi_exposure_mater_C", fill = "mediumorchid")
      },
      if ("I_indi_exposure_unk_A" %in% u_plot[[4]][["layers"]][[1]][["data"]][["group_name"]]) {
        upset_query(set = "I_indi_exposure_unk_A", fill = "mediumorchid")
      },
      if ("I_indi_exposure_unk_B" %in% u_plot[[4]][["layers"]][[1]][["data"]][["group_name"]]) {
        upset_query(set = "I_indi_exposure_unk_B", fill = "turquoise3")
      },
      if ("I_indi_exposure_nolact" %in% u_plot[[4]][["layers"]][[1]][["data"]][["group_name"]]) {
        upset_query(set = "I_indi_exposure_nolact", fill = "yellow")
      },
      if ("I_indi_fet_abo_pregn_norm" %in% u_plot[[4]][["layers"]][[1]][["data"]][["group_name"]]) {
        upset_query(set = "I_indi_fet_abo_pregn_norm", fill = "turquoise3")
      },
      if ("I_reac_exposure_matACunkA" %in% u_plot[[4]][["layers"]][[1]][["data"]][["group_name"]]) {
        upset_query(set = "I_reac_exposure_matACunkA", fill = "mediumorchid")
      },
      if ("I_reac_exposure_matB" %in% u_plot[[4]][["layers"]][[1]][["data"]][["group_name"]]) {
        upset_query(set = "I_reac_exposure_matB", fill = "orangered1")
      },
      if ("I_reac_fet_abo_pregn" %in% u_plot[[4]][["layers"]][[1]][["data"]][["group_name"]]) {
        upset_query(set = "I_reac_fet_abo_pregn", fill = "olivedrab2")
      },
      if ("I_reac_normal" %in% u_plot[[4]][["layers"]][[1]][["data"]][["group_name"]]) {
        upset_query(set = "I_reac_normal", fill = "turquoise3")
      },
      if ("I_reac_cong_below_2" %in% u_plot[[4]][["layers"]][[1]][["data"]][["group_name"]]) {
        upset_query(set = "I_reac_cong_below_2", fill = "turquoise3")
      },
      if ("I_reac_cong_CA" %in% u_plot[[4]][["layers"]][[1]][["data"]][["group_name"]]) {
        upset_query(set = "I_reac_cong_CA", fill = "yellow")
      },
      if ("I_reac_cong_parent" %in% u_plot[[4]][["layers"]][[1]][["data"]][["group_name"]]) {
        upset_query(set = "I_reac_cong_parent", fill = "yellow")
      },
      if ("I_reac_neon_below_8days" %in% u_plot[[4]][["layers"]][[1]][["data"]][["group_name"]]) {
        upset_query(set = "I_reac_neon_below_8days", fill = "turquoise3")
      },
      if ("I_reac_neon_CA" %in% u_plot[[4]][["layers"]][[1]][["data"]][["group_name"]]) {
        upset_query(set = "I_reac_neon_CA", fill = "yellow")
      },
      if ("I_reac_neon_parent" %in% u_plot[[4]][["layers"]][[1]][["data"]][["group_name"]]) {
        upset_query(set = "I_reac_neon_parent", fill = "yellow")
      },
      if ("I_parent_F_nolac" %in% u_plot[[4]][["layers"]][[1]][["data"]][["group_name"]]) {
        upset_query(set = "I_parent_F_nolac", fill = "turquoise3")
      },
      if ("I_serious_CA" %in% u_plot[[4]][["layers"]][[1]][["data"]][["group_name"]]) {
        upset_query(set = "I_serious_CA", fill = "turquoise3")
      },
      if ("I_concurrent_pregn" %in% u_plot[[4]][["layers"]][[1]][["data"]][["group_name"]]) {
        upset_query(set = "I_concurrent_pregn", fill = "turquoise3")
      }
    ), NULL) |> (\(x) Filter(Negate(is.null), x))(),
    base_annotations = list(
      "Intersection size" = (
        intersection_size(
          text_colors = c(on_bar = "goldenrod", on_background = "goldenrod"),
          width = 0.5,
          text = list(angle = 0)
        )
        # add some space on the top of the bars
        + scale_y_continuous(expand = expansion(mult = c(0, 0.05)))
          + theme(
            # hide grid lines
            panel.grid.major = element_blank(),
            panel.grid.minor = element_blank(),
            # show axis lines
            axis.line = element_line(colour = "black")
          )
      )
    ),
    set_sizes = (
      upset_set_size(geom = geom_bar(width = 0.4))
      + theme(
          axis.line.x = element_line(colour = "black"),
          axis.ticks.x = element_line()
        )
    ),
    sort_sets = FALSE,
    width_ratio = 0.1,
    height_ratio = 1.8
  )
  plot
}
