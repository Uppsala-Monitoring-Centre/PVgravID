# Check Inclusion and Exclusion Criteria

Evaluates a set of exclusion and inclusion conditions on a dataset, thus
allowing to implement tailored criteria. Exclusion criteria are combined
with logical AND (`&`), while inclusion criteria are combined with
logical OR (`|`). If no exclusion criteria are supplied, the function
returns the inclusion result alone.

## Usage

``` r
check_criteria(data, exclusions, inclusions)
```

## Arguments

- data:

  A data frame containing the variables to evaluate.

- exclusions:

  A character vector of column names whose corresponding exclusion
  checks will be applied. Each column is passed to `check_exclusion()`.
  Examples are:

  E_age_over_50y

  :   age specified and older than 50 years old

  E_agegroup_elderly

  :   age group specified as "elderly"

  E_parent_M

  :   linked to a parental report specifying "male" as sex

  E_reac_paternal

  :   paternal exposure specified among reaction in the lack of maternal
      exposure

  E_reac_normalCombined

  :   among reactions, specified normal pregnancy outcome, lactation,
      menstrual disorders, contraceptive methods

  E_reac_noADR

  :   only exposure term, with not adverse outcome specified

  E_indi_normalCombined

  :   among indications, specified menstrual disorders or contraception

  E_nofertile_F

  :   report of a male individual, or under 15 or over 55 years old, or
      unspecified sex or age

  E_reac_normalCombined

  :   among reactions, specified normal pregnancy outcome, lactation,
      menstrual disorders, contraceptive methods

  E_indi_paternal

  :   among indications, specified paternal exposure

  E_indi_congenital

  :   among indications, specified congenital disorder

- inclusions:

  A character vector of column names whose corresponding inclusion
  checks will be applied. Each column is passed to `check_inclusion()`.
  Examples are:

  I_gestation

  :   information about the gestation period

  I_route_transplacental

  :   route specified as transplacental

  I_route_intramniotic

  :   route specified as intramniotic

  I_route_extraamniotic

  :   route specified as extraamniotic

  I_indi_exposure_matACunkA

  :   maternal exposure reported as indication

  I_indi_exposure_mater_B

  :   maternal exposure reported as indication_terms 2 (see paper)

  I_indi_exposure_nolact

  :   maternal or paternal exposure reported as indication, excluding
      reports of exposure through lactation

  I_indi_fet_abo_pregn_norm

  :   among indications, terms concerning fetal disorders, abortion,
      delivery, or normal pregnancy outcome

  I_reac_exposure_matACunkA

  :   maternal exposure reported as reaction

  I_reac_exposure_matB

  :   maternal exposure reported as indication_terms 2 (see paper)

  I_reac_fet_abo_pregn

  :   among reactions, terms concerning fetal disorders, abortion,
      delivery

  I_reac_normal

  :   among reactions, terms concerning normal pregnancy outcome

  I_reac_cong_below_2

  :   among reactions, specified congenital disorders, in an age of less
      then 2 years old

  I_reac_cong_CA

  :   congenital anomaly specified as reaction, with congenital anomaly
      specified as seriousness

  I_reac_cong_parent

  :   linked parental report and congenital anomaly as reaction

  I_reac_neon_below_8days

  :   neonatal reaction in a neonate less than 8 days old

  I_reac_neon_CA

  :   neonatal reaction with outcome of congenital anomaly

  I_reac_neon_parent

  :   linked parental report in neonatal reaction

  I_parent_F_nolac

  :   parental report with sex specified as female, excluding reports of
      exposure through lactation

  I_serious_CA

  :   reports specifying as outcome a congenital anomaly

  I_concurrent_pregn

  :   reports specificying in the comorbidity a pregnancy related term

  I_reac_neon_cong

  :   neonatal or congenital reactions

  I_indi_fet_pregn_norm

  :   fetal or delivery related term, or normal pregnancy outcome
      reported as indication

## Value

A logical vector indicating which rows satisfy the combined inclusion
and exclusion criteria. If `exclusions` is empty, only the inclusion
criteria are applied.

## Examples

``` r
# The following example shows how the default algorithms are run
# within the generate_pregnancy_flags function, so to support tailoring.
# exclusions_UMC <- c("E_age_over_50y", "E_agegroup_elderly", "E_parent_M",
# "E_reac_paternal")
# inclusions_UMC <- c("I_gestation", "I_serious_CA", "I_reac_cong_below_2",
# "I_reac_normal", "I_reac_fet_abo_pregn", "I_reac_exposure_matACunkA",
# "I_indi_fet_abo_pregn_norm", "I_indi_exposure_matACunkA",
# "I_route_transplacental", "I_reac_neon_below_8days", "I_concurrent_pregn",
# "I_parent_F_nolac")
# criteria_df[, UMC := check_criteria(.SD, exclusions_UMC, inclusions_UMC),
# .SDcols = c(exclusions_UMC, inclusions_UMC)]
# exclusions_EMA <- c("E_age_over_50y", "E_reac_normalCombined",
# "E_reac_noADR", "E_indi_normalCombined")
# inclusions_EMA <- c("I_gestation", "I_reac_cong_CA", "I_reac_cong_parent",
# "I_reac_fet_abo_pregn", "I_reac_exposure_matACunkA",
# "I_indi_exposure_nolact", "I_route_transplacental", "I_route_intramniotic",
# "I_reac_neon_CA", "I_reac_neon_parent")
# criteria_df[, EMA := check_criteria(.SD, exclusions_EMA, inclusions_EMA),
# .SDcols = c(exclusions_EMA, inclusions_EMA)]
# exclusions_SakaiHPPV <- NA
# inclusions_SakaiHPPV <- c("I_reac_exposure_matACunkA",
# "I_reac_exposure_matB", "I_indi_exposure_matACunkA",
# "I_indi_exposure_mater_B", "I_route_transplacental",
# "I_route_intramniotic", "I_route_extraamniotic")
# criteria_df[, SakaiHPPV := check_criteria(.SD, exclusions_SakaiHPPV,
# inclusions_SakaiHPPV), .SDcols = c(inclusions_SakaiHPPV)]
# exclusions_SakaiHS <- NA
# inclusions_SakaiHS <- c(
# "I_reac_exposure_matACunkA", "I_reac_exposure_matB",
# "I_indi_exposure_matACunkA", "I_indi_exposure_mater_B",
# "I_route_transplacental", "I_route_intramniotic", "I_route_extraamniotic",
# "I_reac_fet_abo_pregn",
# "I_reac_normal",
# "I_reac_neon_cong",
# "I_indi_fet_pregn_norm"
# )
#
# criteria_df[, SakaiHS := check_criteria(.SD, exclusions_SakaiHS,
# inclusions_SakaiHS), .SDcols = c(inclusions_SakaiHS)]
#
# exclusions_SakaiM <- c(
#  "E_reac_paternal_Sakai",
#  "E_indi_paternal",
#  "E_indi_congenital",
#  "E_nofertile_F"
# )
#
# inclusions_SakaiM <- c(
#  # + inclusion SakaiHPPV, added separately because
# not affected by exclusion criteria
#  "I_reac_fet_abo_pregn",
#  "I_reac_normal",
#  "I_reac_neon_cong",
#  "I_indi_fet_pregn_norm"
# )
#
# criteria_df[, SakaiM := check_criteria(.SD, exclusions_SakaiM,
# inclusions_SakaiM), .SDcols = c(exclusions_SakaiM, inclusions_SakaiM)][
# , SakaiM := SakaiM | SakaiHPPV]
```
