# G2F Environmental Covariate Workflow

This folder is a step-by-step practice pipeline for building environmental covariates for the `G2F` maize dataset.

The goal is not only to get a final merged table. The goal is to understand the logic of each stage.

## Folder structure

- `data/`
  Raw input files you already have.
- `scripts/`
  Legacy location no longer used.
- `pre-processing/`
  Data-building scripts that prepare environments, weather, covariates, merges, and the trait-specific ASReml input.
- `models/`
  Model-fitting scripts, grouped separately from preprocessing.
- `prediction-validation/`
  The paper-continuation scripts for LOEO, LYLO, and prediction-focused evaluation design.
- `outputs/`
  Files created by the scripts.

## Run order

### Stage 1. Define environments

Run:

- `pre-processing/01_define_environments_G2F.R`

What it does:

- reads `info_environments_G2F.csv`
- creates a clean `env_id = year_location`
- standardizes dates
- checks that each environment has coordinates and crop dates
- writes a clean environment table

Output:

- `outputs/01_environments_G2F.csv`

### Stage 2A. Download AgERA5 daily grids

Run:

- `pre-processing/02_download_agera5_daily.py`

What it does:

- reads the clean environment table
- computes one bounding box covering your environments
- downloads AgERA5 version `2.0` NetCDF files year by year
- stores one regional climate grid file per variable-year combination

AgERA5 variables requested:

- `2m_temperature` as:
  - `24_hour_mean`
  - `24_hour_maximum`
  - `24_hour_minimum`
- `precipitation_flux`
- `solar_radiation_flux`
- `reference_evapotranspiration`
- `vapour_pressure_deficit_at_maximum_temperature`
- `2m_relative_humidity_derived` as:
  - `24_hour_minimum`

Raw output:

- `outputs/agera5_raw/*.nc`
- `outputs/agera5_raw/agera5_manifest.csv`

### Stage 2B. Extract AgERA5 grid values for each environment

Run:

- `pre-processing/02b_extract_agera5_for_envs.R`

What it does:

- opens the AgERA5 NetCDF files
- matches each environment to the nearest AgERA5 grid cell
- keeps only the planting-to-harvest date window for each environment
- standardizes the extracted series into the same daily weather columns used by later stages

Daily variables fetched:

- `temperature_2m_mean`
- `temperature_2m_max`
- `temperature_2m_min`
- `precipitation_sum`
- `shortwave_radiation_sum`
- `et0_fao_evapotranspiration`
- `vapour_pressure_deficit_at_maximum_temperature`
- `relative_humidity_derived_minimum`

Output:

- `outputs/02_daily_weather_G2F.csv`

### Stage 3. Build basic season-level covariates

Run:

- `pre-processing/03_build_basic_environment_covariates.R`

What it does:

- reads the daily weather table
- aggregates daily weather over the full crop season
- builds beginner-level environment covariates

Covariates created:

- `MeanTemp_season`
- `MaxTemp_mean_season`
- `MinTemp_mean_season`
- `RainSum_season`
- `RadMean_season`
- `VPDMax_mean_season`
- `RHDerivedMin_mean_season`
- `ET0Sum_season`
- `HotDays35_season`
- `DryDays1mm_season`
- `GDD10_season`
- `SeasonLength_days`

Output:

- `outputs/03_environment_covariates_basic_G2F.csv`

### Stage 4. Build stage-window covariates

Run:

- `pre-processing/04_build_stage_window_covariates.R`

What it does:

- computes daily maize GDD with the maize-specific capped method:
  - lower threshold = `10 C`
  - upper threshold = `30 C`
- accumulates GDD from planting onward
- assigns each day to a biological maize development window using cumulative GDD breakpoints
- computes the same type of covariates inside each biological window

This is closer to real GxE work because environmental timing matters.

Windows used:

- `early vegetative`: emergence through about `V6`
- `late vegetative`: after `V6` up to silking (`R1`)
- `flowering`: `R1` through early reproductive development up to about `R3`
- `grain fill`: after `R3` through maturity

Why this is better than equal calendar splits:

- maize development is driven more by accumulated heat than by calendar day count
- two environments with the same number of days can still be at different biological stages
- stress during silking or early reproductive growth is often more important than the same stress earlier

Output:

- `outputs/04_environment_covariates_stagewise_G2F.csv`

### Stage 5. Merge environment covariates with phenotype and soil

Run:

- `pre-processing/05_merge_pheno_env_soil_G2F.R`

What it does:

- reads phenotype data
- adds `env_id`
- merges basic covariates
- merges stagewise covariates
- merges soil covariates

Output:

- `outputs/05_G2F_analysis_ready_basic.csv`
- `outputs/05_G2F_analysis_ready_stagewise.csv`

## Recommended way to learn

Do not jump to Stage 5 first.

Study it like this:

1. run Stage 1 and inspect the environment table
2. run Stage 2 and inspect the daily weather table
3. run Stage 3 and manually verify one environment
4. run Stage 4 and compare season-level vs stage-level summaries
5. run Stage 5 and only then start modelling

## First models to try after Stage 5

Once you have the merged file, begin with:

1. baseline model with genotype + year + location
2. add season-level environmental covariates
3. compare with stage-window covariates
4. then move toward genotype-by-covariate interaction ideas

## ASReml reproduction track for yield

After Stage 5, the recommended paper-reproduction path is now:

### Stage 6. Prepare the trait-specific ASReml input

Run:

- `pre-processing/06_prepare_yield_asreml_input.R`

What it does:

- starts with `yld_bu_ac`
- uses the basic season-level covariates as the first observed EC set
- scales those ECs at the environment level
- creates paper-style aliases `EC1` to `EC8`
- adds the factor columns and dummy variables needed by the ASReml model families

Current observed EC mapping:

- `EC1 = MeanTemp_season`
- `EC2 = MaxTemp_mean_season`
- `EC3 = MinTemp_mean_season`
- `EC4 = RainSum_season`
- `EC5 = RadMean_season`
- `EC6 = ET0Sum_season`
- `EC7 = VPDMax_mean_season`
- `EC8 = RHDerivedMin_mean_season`

Outputs:

- `outputs/asreml_yield/06_yield_asreml_input.csv`
- `outputs/asreml_yield/06_yield_env_covariates_scaled.csv`

### Stage 7. Fit baseline and baseline+EC ASReml models

Run:

- `models/07_fit_yield_baseline_and_ec_asreml.R`

What it does:

- fits the paper-style baseline random backbone
- fits the same backbone plus fixed observed EC effects
- writes model objects and a comparison table

Outputs:

- `outputs/asreml_yield/baseline_yield_asreml.rds`
- `outputs/asreml_yield/baseline_ec_yield_asreml.rds`
- `outputs/asreml_yield/07_yield_baseline_metrics.csv`

### Stage 8. Fit richer observed-EC response models

Run:

- `models/08_fit_yield_rrr_and_rfr_asreml.R`

What it does:

- fits `RRR1`
- attempts `RRR2`
- attempts `RFR` / unstructured regression

Teaching note:

- `RRR` is usually the first rich model to learn because it is more stable
- `RFR` is intentionally harder and is part of the lesson, not an error in the workflow

Outputs:

- `outputs/asreml_yield/rr1_yield_asreml.rds`
- `outputs/asreml_yield/rr2_yield_asreml.rds` if successful
- `outputs/asreml_yield/rfr_yield_asreml.rds` if successful
- `outputs/asreml_yield/08_yield_rrr_rfr_metrics.csv`

### Stage 9. Fit synthetic-covariate FW models

Run:

- `models/09_fit_yield_fw_asreml.R`

What it does:

- derives synthetic environmental covariates from observed ECs
- fits `FW1-US`
- attempts `FW2-US`

Teaching note:

- this stage is the most advanced one in the current pipeline
- it is expected to be slower and sometimes less stable than the earlier stages

Outputs:

- `outputs/asreml_yield/fw1_rr_step_yield_asreml.rds`
- `outputs/asreml_yield/fw1_us_step_yield_asreml.rds`
- `outputs/asreml_yield/fw2_rr_step_yield_asreml.rds`
- `outputs/asreml_yield/fw2_us_step_yield_asreml.rds` if successful
- `outputs/asreml_yield/09_yield_fw_metrics.csv`

## Paper continuation: prediction and validation

After fitting the model families, the paper continues into a different phase:

- prediction into new environments
- validation-split design
- prediction-focused comparison instead of fit-only comparison

That work is now separated into:

- `prediction-validation/`

Run order there:

1. `10_prepare_prediction_dataset_yield.R`
2. `11_create_loeo_splits_yield.R`
3. `12_create_lylo_splits_yield.R`
4. `13_build_prediction_evaluation_plan_yield.R`

Outputs written there:

- `outputs/prediction_yield/10_yield_prediction_dataset.csv`
- `outputs/prediction_yield/10_yield_prediction_metadata.csv`
- `outputs/prediction_yield/11_loeo_folds.csv`
- `outputs/prediction_yield/12_lylo_folds.csv`
- `outputs/prediction_yield/13_prediction_evaluation_plan.csv`

## Important note

This workflow uses simple windows and simple covariates on purpose.

It is a training pipeline.

Later you can improve it by:

- replacing generic breakpoint rules with hybrid-specific or trial-specific phenology records
- using crop-specific thresholds for heat stress
- changing the `GDD` base temperature
- adding soil-environment combinations
- refining the AgERA5 variable set or adding additional stress descriptors
- repeating the ASReml reproduction track with stagewise environmental covariates instead of only season-level ECs
