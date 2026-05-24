# Stage 94 Post-Data-Drop Execution Card (2026-05-23)

## Use this right after raw files are placed

Run from project root (`/Users/neon/Documents/Nadim's Brain`).

## 1) Preflight check

```bash
Rscript analysis/prediction-validation/92_external_preflight_validator.R
```

Expected:
- `phenotype_present = TRUE`
- `markers_present = TRUE`
for target datasets.

## 2) Fill mapping templates

Edit:
- `analysis/models/90_column_mapping_template_cimmyt_wheat_2026-05-23.csv`
- `analysis/models/90_column_mapping_template_dryad_rice_2026-05-23.csv`

Required rows must have non-empty `raw_column`.

## 3) Ingest canonical datasets (stage-83)

```bash
Rscript analysis/prediction-validation/83_ingest_cimmyt_wheat_template.R
Rscript analysis/prediction-validation/83_ingest_dryad_rice_template.R
```

## 4) Run external confirmatory templates (stage-84)

```bash
Rscript analysis/prediction-validation/84_run_external_confirmatory_template.R cimmyt_wheat /Users/neon/Documents/Nadim\'s\ Brain/analysis/outputs/prediction_yield/external_validation
Rscript analysis/prediction-validation/84_run_external_confirmatory_template.R dryad_rice /Users/neon/Documents/Nadim\'s\ Brain/analysis/outputs/prediction_yield/external_validation
```

## 5) Refresh tracker and queue

```bash
Rscript analysis/prediction-validation/91_update_external_tracker_from_filesystem.R
Rscript analysis/prediction-validation/87_external_run_queue_bootstrap.R
```

## 6) Verify outputs exist

Check for each dataset:
- `*_canonical.csv`
- `*_fold_map.csv`
- `*_ingestion_qc.csv`
- `confirmatory_template_outputs/*_template_summary.csv`

## Done condition

When both datasets show stage-84 outputs and tracker marks template run as done, external confirmatory campaign is operationally started.

