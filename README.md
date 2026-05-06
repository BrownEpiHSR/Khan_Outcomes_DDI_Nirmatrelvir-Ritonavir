# Khan_Potential_Nirmatrelvir_Ritonavir_Harms_Nursing_Homes
Khan et al-Potential Nirmatrelvir/Ritonavir Interaction Harms in Nursing Homes

## Data Documentation
The `data_documentation/` directory contains the following files:

- `Ritonavir_DDI_Outcomes_Data_Documentation.xlsx` - Replication-oriented codebook describing key analytic variables, outcome definitions, grace period measures, IPTW variables, and program-level documentation for the statistical analyses.

## Code
The `code/` directory contains the following programs:

- `1_Crude_rate_ratio_and_differences_GH.sas` - Creates crude (unweighted) rate ratios and rate differences comparing days with versus without concurrent medications with potential drug-drug interactions.

- `2_Create_covariates_sex_and_age_GH.sas` - Creates demographic covariates including age and sex from Medicare enrollment and demographic source files.

- `3_Create_covariate_prior_nursing_home_time_GH.sas` - Derives prior nursing home stay duration variables used for covariate adjustment and inverse probability weighting models.

- `4_Estimates_for_death_3_days_grace_period_GH.R` - Estimates unweighted and IPTW-weighted mortality rates, rate ratios, and rate differences for the 3-day grace period analysis using bootstrap confidence intervals.

- `5_Estimates_for_death_7_days_grace_period_GH.R` - Estimates unweighted and IPTW-weighted mortality rates, rate ratios, and rate differences for the 7-day grace period analysis using bootstrap confidence intervals.

- `6_Estimates_for_death_14_days_grace_period_GH.R` - Estimates unweighted and IPTW-weighted mortality rates, rate ratios, and rate differences for the 14-day grace period analysis using bootstrap confidence intervals.

- `7_Estimates_for_hospitalization_14_days_grace_period_GH.R` - Estimates unweighted and IPTW-weighted hospitalization rates, rate ratios, and rate differences for the 14-day grace period analysis using bootstrap confidence intervals.

Programs were run in sequence to produce the study findings.

Additional notes:
- Statistical analyses were conducted using SAS and R.
- IPTW models used stabilized inverse probability of treatment weights estimated using age, sex, and prior nursing home time covariates.
- Confidence intervals were estimated using percentile bootstrap methods with 1,000 replicates to account for within-resident correlation arising from repeated antiviral treatment courses.
- Users replicating the analyses will need authorized access to LTCDC electronic medication administration record (eMAR) data and linked Medicare claims/enrollment files.
