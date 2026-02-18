# Generate a flowchart for a specified pregnancy algorithm Creates a graphical flowchart summarizing inclusion and exclusion criteria for pregnancy algorithms.

Generate a flowchart for a specified pregnancy algorithm Creates a
graphical flowchart summarizing inclusion and exclusion criteria for
pregnancy algorithms.

## Usage

``` r
flowchart_generator(database = FAERS_version, pregnancy_flags_table, algorithm)
```

## Arguments

- database:

  A FAERS@DiAna quarter (e.g., '25Q2') or the name of the folder
  containing your input data. Defaults to `FAERS_version`.

- pregnancy_flags_table:

  A data frame returned by
  [`generate_pregnancy_flags()`](https://uppsala-monitoring-centre.github.io/PVgravID/reference/generate_pregnancy_flags.md).

- algorithm:

  Character string specifying the algorithm to display. Allowed values:
  "UMC", "EMA", "SakaiHPPV", "SakaHS", "SakaiM".

## Value

A ggplot object representing the flowchart.

## Examples

``` r
if (FALSE) { # \dontrun{
flowchart_generator(
  database = FAERS_version,
  pregnancy_flags_table = flags,
  algorithm = "UMC"
)
} # }
```
