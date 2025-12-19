# Generate descriptive statistics for pharmacovigilance data

Generate descriptive statistics for pharmacovigilance data

## Usage

``` r
descriptive(
  pids_cases,
  RG = NULL,
  drug = NULL,
  save_in_excel = TRUE,
  file_name = "Descriptives.xlsx",
  vars = c("sex", "Submission", "Reporter", "age_range", "Outcome", "country",
    "continent", "age_in_years", "wt_in_kgs", "Reactions", "Indications", "Substances",
    "num_Substances", "year", "role_cod", "time_to_onset"),
  list_pids = list(),
  method = "independence_test",
  database = "VigiBase"
)
```

## Arguments

- pids_cases:

  Character vector of primary IDs for cases

- RG:

  Character vector of primary IDs for reference group (controls). If
  NULL, only cases are analyzed.

- drug:

  Character vector of drug substances to analyze (for role_cod and
  time_to_onset)

- save_in_excel:

  Logical, whether to save results to Excel file

- file_name:

  Name of output Excel file

- vars:

  Character vector of variables to include in analysis

- list_pids:

  Named list of additional primary ID groups to compare

- method:

  Statistical method: "independence_test" or "goodness_of_fit"

- database:

  Database to use: "sample", "VigiBase", or quarter like "24Q4"

## Value

Data frame/tibble with descriptive statistics

## Examples

``` r
if (FALSE) { # \dontrun{
# Analyze sample data
result <- descriptive(
  pids_cases = c("123", "456"),
  database = "sample"
)
} # }
```
