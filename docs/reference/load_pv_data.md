# Load pharmacovigilance data from database or sample

Load pharmacovigilance data from database or sample

## Usage

``` r
load_pv_data(pids, database = "VigiBase", include_ther = FALSE)
```

## Arguments

- pids:

  Character vector of primary IDs to load

- database:

  Database name ("sample", "VigiBase", or quarter like "24Q4")

- include_ther:

  Logical, whether to include therapy data

## Value

List of data tables (Demo, Drug, Reac, Indi, Outc, Ther)
