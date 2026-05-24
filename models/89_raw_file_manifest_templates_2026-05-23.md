# Stage 89 Raw File Manifest Templates (2026-05-23)

## Purpose

Define the minimal raw-file manifest required to unlock stage-83 ingestion for each external dataset.

## 1) CIMMYT wheat (`cimmyt_wheat`)

Raw folder:
- `analysis/outputs/prediction_yield/external_validation/cimmyt_wheat/raw/`

Required files (template names):
1. `phenotype.csv`
2. `markers.csv`
3. `env_covariates.csv` (optional but preferred)

Required column mapping table (fill before ingestion):
- `raw_genotype_col -> geno_id`
- `raw_environment_col -> env_id`
- `raw_trait_col -> trait_value`
- `raw_year_col -> year` (optional)
- `raw_location_col -> location` (optional)

## 2) Dryad rice (`dryad_rice`)

Raw folder:
- `analysis/outputs/prediction_yield/external_validation/dryad_rice/raw/`

Required files (template names):
1. `phenotype.csv`
2. `markers.csv`
3. `env_covariates.csv` (optional but preferred)

Required column mapping table (fill before ingestion):
- `raw_genotype_col -> geno_id`
- `raw_environment_col -> env_id`
- `raw_trait_col -> trait_value`
- `raw_year_col -> year` (optional)
- `raw_location_col -> location` (optional)

## 3) Dryad wheat sparse (`dryad_wheat_sparse`)

Raw folder:
- `analysis/outputs/prediction_yield/external_validation/dryad_wheat_sparse/raw/`

Required files (template names):
1. `phenotype.csv`
2. `markers.csv`
3. `env_covariates.csv` (optional but preferred)

## 4) Dryad maize MET (`dryad_maize_met`)

Raw folder:
- `analysis/outputs/prediction_yield/external_validation/dryad_maize_met/raw/`

Required files (template names):
1. `phenotype.csv`
2. `markers.csv`
3. `env_covariates.csv` (optional but preferred)

## Readiness criterion

A dataset is ingestion-ready when:
1. raw folder exists,
2. `phenotype.csv` and `markers.csv` exist,
3. column mapping table is filled and saved in notes or QC metadata.

## Next immediate command (after files are in place)

1. Run stage-83 ingestion script for dataset.
2. Re-run stage-87 queue script:
```bash
Rscript /Users/neon/Documents/Nadim\'s\ Brain/analysis/prediction-validation/87_external_run_queue_bootstrap.R
```

