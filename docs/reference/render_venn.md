# Render a Venn Diagram

This function creates and renders a Venn diagram using the `eulerr`
package. It takes a list of primary IDs and generates a Venn diagram to
visualize the intersections.

## Usage

``` r
render_venn(pids_sets)
```

## Arguments

- pids_sets:

  A named list where each element is a vector of primary IDs. The names
  of the list elements will be used as labels in the Venn diagram.

## Value

A Venn diagram plot.

## Examples

``` r
if (FALSE) { # \dontrun{
t_EV <- data.table(primaryids = c(1, 2, 3))
t_UMC <- data.table(primaryids = c(2, 3, 4))
t_Sakai <- data.table(high_specificity = c(3, 4, 5))
render_venn(list(
  "EudraVigilance" = t_EV$primaryids,
  "VigiBase" = t_UMC$primaryids, "Sakai" = t_Sakai$high_specificity
))
} # }
```
