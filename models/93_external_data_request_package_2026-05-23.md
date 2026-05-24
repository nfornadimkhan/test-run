# Stage 93 External Data Request Package (2026-05-23)

## Objective

Collect all missing external raw files in one coordinated request so stage-83/84 runs can start immediately.

## Request packet (send as-is)

Please provide the following folders and files:

### 1) CIMMYT wheat

Target folder:
- `analysis/outputs/prediction_yield/external_validation/cimmyt_wheat/raw/`

Required files:
1. `phenotype.csv`
2. `markers.csv`
3. `env_covariates.csv` (if available)

### 2) Dryad rice

Target folder:
- `analysis/outputs/prediction_yield/external_validation/dryad_rice/raw/`

Required files:
1. `phenotype.csv`
2. `markers.csv`
3. `env_covariates.csv` (if available)

### 3) Dryad wheat sparse

Target folder:
- `analysis/outputs/prediction_yield/external_validation/dryad_wheat_sparse/raw/`

Required files:
1. `phenotype.csv`
2. `markers.csv`
3. `env_covariates.csv` (if available)

### 4) Dryad maize MET

Target folder:
- `analysis/outputs/prediction_yield/external_validation/dryad_maize_met/raw/`

Required files:
1. `phenotype.csv`
2. `markers.csv`
3. `env_covariates.csv` (if available)

## Required metadata (minimum)

For each dataset, provide a short mapping note:
1. phenotype genotype column name
2. phenotype environment column name
3. phenotype target trait column name
4. year and location columns (if present)

## Acceptance check

After files are copied:
1. Run:
   - `Rscript /Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/92_external_preflight_validator.R`
2. Confirm all target datasets show:
   - `phenotype_present = TRUE`
   - `markers_present = TRUE`

## Next execution after acceptance

1. Fill stage-90 mapping templates.
2. Run stage-83 ingestion templates.
3. Run stage-84 external confirmatory template.
4. Update tracker with stage-91.

