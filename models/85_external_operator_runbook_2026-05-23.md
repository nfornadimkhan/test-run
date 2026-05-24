# Stage 85 External Operator Runbook (2026-05-23)

## Purpose

Provide exact execution steps to move from templates to real external validation runs.

## Prerequisites

1. Download raw dataset files locally.
2. Place files under:
   - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/<dataset_key>/raw/`
3. Update raw column mappings in stage-83 scripts if names differ.

## Step 1: Run stage-83 ingestion templates

### CIMMYT wheat
```bash
Rscript /Users/neon/Documents/Nadim\'s\ Brain/analysis/prediction-validation/83_ingest_cimmyt_wheat_template.R
```

### Dryad rice
```bash
Rscript /Users/neon/Documents/Nadim\'s\ Brain/analysis/prediction-validation/83_ingest_dryad_rice_template.R
```

Expected artifacts per dataset:
- `<dataset_key>_canonical.csv`
- `<dataset_key>_marker_manifest.csv`
- `<dataset_key>_fold_map.csv`
- `<dataset_key>_ingestion_qc.csv`

## Step 2: Run stage-84 confirmatory template

```bash
Rscript /Users/neon/Documents/Nadim\'s\ Brain/analysis/prediction-validation/84_run_external_confirmatory_template.R \
  cimmyt_wheat \
  /Users/neon/Documents/Nadim\'s\ Brain/analysis/outputs/prediction_yield/external_validation
```

```bash
Rscript /Users/neon/Documents/Nadim\'s\ Brain/analysis/prediction-validation/84_run_external_confirmatory_template.R \
  dryad_rice \
  /Users/neon/Documents/Nadim\'s\ Brain/analysis/outputs/prediction_yield/external_validation
```

## Step 3: Update execution tracker

File:
- `/Users/neon/Documents/Nadim's Brain/analysis/models/84_external_execution_tracker_2026-05-23.csv`

Set status columns to:
- `done` after each successful stage
- `blocked` with reason in `notes` if errors occur

## Step 4: Plug final candidate

In stage-84 script, replace placeholder prediction block with the final weighted-consensus candidate implementation using:
- stage-69 selected settings + weights

## Step 5: Produce external confirmatory summary table

Create one merged CSV with:
1. dataset key
2. mean gain (all, seen)
3. one-sided t p-values (all, seen)
4. bootstrap P(gain > 0) (all, seen)
5. pass/fail against external upgrade criteria from stage-80

## Success condition

External world-level evidence upgrade can be considered only after these runs are complete on at least 3 independent datasets.

