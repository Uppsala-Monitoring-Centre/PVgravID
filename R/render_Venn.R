#' Render a Venn Diagram
#'
#' This function creates and renders a Venn diagram using the `eulerr` package.
#' It takes a list of primary IDs and generates a Venn diagram to visualize
#' the intersections.
#'
#' @param pids_sets A named list where each element is a vector of primary IDs.
#'   The names of the list elements will be used as labels in the Venn diagram.
#'
#' @return A Venn diagram plot.
#' @export
#'
#' @examples
#' \dontrun{
#' t_EV <- data.table(primaryids = c(1, 2, 3))
#' t_UMC <- data.table(primaryids = c(2, 3, 4))
#' t_Sakai <- data.table(high_specificity = c(3, 4, 5))
#' render_venn(list(
#'   "EudraVigilance" = t_EV$primaryids,
#'   "VigiBase" = t_UMC$primaryids, "Sakai" = t_Sakai$high_specificity
#' ))
#' }
#'
render_venn <- function(pids_sets) {
  i <- 0
  for (name in names(pids_sets)) {
    df_temp <- data.table::data.table(primaryid = unlist(pids_sets[[name]]))
    df_temp[[name]] <- TRUE
    if (i == 0) {
      df_comparison <- df_temp
    } else {
      df_comparison <- merge(df_comparison, df_temp, all = TRUE)
    }
    i <- i + 1
  }
  custom_colors <- c(
    A = "#f24726", B = "#fef445", C = "#12cdd4",
    "A&B" = "#fac710", "A&C" = "#ca87d5", "B&C" = "#cee741", "A&B&C" = "#e6e6e6"
  )
  df_comparison[is.na(df_comparison)] <- FALSE
  set_names <- names(pids_sets)
  venn <- eulerr::euler(df_comparison[, ..set_names])
  plot(venn, quantities = TRUE, fill = custom_colors)
}
