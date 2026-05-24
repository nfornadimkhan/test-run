# Paper Continuation: Prediction and Validation Workflow

This folder contains the **next steps after model fitting**.

The earlier `pre-processing/` and `models/` folders answered:

- how do we build environmental covariates?
- how do we fit the main GxE regression model families?

This folder answers the next paper-level questions:

- how do we test prediction into new environments?
- how do we create `LOEO` and `LYLO` validation splits?
- how do we compare models by prediction quality instead of only fit quality?

## Why this folder exists

The paper does not stop at fitting models and reading AIC.

Its deeper goal is:

- predict genotype performance in environments not yet observed
- quantify whether a richer model truly helps in that prediction problem

So this folder is intentionally separate from the fitting scripts.

It represents the shift from:

- **in-sample model comparison**

to:

- **out-of-sample prediction and validation**

## Folder logic

The stages here are meant to be run in order.

### Stage 10. Prepare the prediction dataset

Run:

- `10_prepare_prediction_dataset_yield.R`

What it does:

- reads the current trait-specific ASReml input table
- detects which observed EC aliases are actually present
- writes a clean prediction dataset for the validation scripts
- records metadata so later stages know whether this run is using the older
  5-EC table or the newer 8-EC AgERA5 table

Output:

- `outputs/prediction_yield/10_yield_prediction_dataset.csv`
- `outputs/prediction_yield/10_yield_prediction_metadata.csv`

### Stage 11. Create `LOEO` validation splits

Run:

- `11_create_loeo_splits_yield.R`

What it does:

- creates **leave-one-environment-out** folds
- each fold holds out one environment and trains on the rest

Interpretation:

- this is the cleanest first prediction test
- it asks whether the model can generalize to an unseen environment

Output:

- `outputs/prediction_yield/11_loeo_folds.csv`

### Stage 12. Create `LYLO` validation splits

Run:

- `12_create_lylo_splits_yield.R`

What it does:

- creates **leave-year-location-out** style folds
- each fold leaves out a full year-location environment in a way that stays
  explicit about the year and location identity

Interpretation:

- this is closer to a future recommendation problem than random row-based CV
- it helps prevent unrealistically easy validation

Output:

- `outputs/prediction_yield/12_lylo_folds.csv`

### Stage 13. Build the evaluation plan

Run:

- `13_build_prediction_evaluation_plan_yield.R`

What it does:

- summarizes how many folds exist
- records genotype counts and environment counts per fold
- writes a plain table you can inspect before expensive refitting begins

Output:

- `outputs/prediction_yield/13_prediction_evaluation_plan.csv`

## What is not yet in this folder

These scripts prepare the paper’s next phase cleanly, but they do **not yet**
run full repeated ASReml CV refits across all model families.

That comes after the split design is checked and understood.

This is deliberate.

Why:

- CV refits are much slower than one-pass model fitting
- it is better to understand the folds first
- the paper’s prediction question depends on choosing the right validation
  problem before launching expensive fits

## Recommended study order

1. inspect `10_yield_prediction_dataset.csv`
2. inspect `11_loeo_folds.csv`
3. inspect `12_lylo_folds.csv`
4. inspect `13_prediction_evaluation_plan.csv`
5. only then begin fold-wise refits and prediction scoring

## Fold-wise refit stages now added

### Stage 14. Shared fold-wise CV helpers

Run:

- `14_cv_model_helpers_yield.R`

This file is not usually run by itself. It defines the reusable machinery for:

- masking one held-out environment as missing
- refitting on the combined table
- predicting only the held-out `Y:L:G` combinations
- scoring both `all` held-out rows and `seen_genotypes` rows

### Stage 15. LOEO baseline-family refits

Run:

- `15_run_loeo_baseline_family_yield.R`

Models:

- `baseline`
- `baseline_ec`

Outputs:

- `outputs/prediction_yield/loeo_cv/15_baseline_family_predictions.csv`
- `outputs/prediction_yield/loeo_cv/15_baseline_family_metrics.csv`

### Stage 16. LOEO RRR/RFR refits

Run:

- `16_run_loeo_rrr_rfr_yield.R`

Models:

- `rrr1`
- `rrr2`
- `rfr_us`

### Stage 17. LOEO FW refits

Run:

- `17_run_loeo_fw_yield.R`

Models:

- `fw1_us`
- `fw2_us`

### Stage 18. LOEO metrics summary

Run:

- `18_summarize_loeo_results_yield.R`

This combines the metrics from Stages `15` to `17` into one model-comparison
table.

## FA-native prediction benchmark

These stages exist because factor-analytic models are naturally used for
predicting missing genotype-environment cells within an observed set of
environments, not for extrapolating into a completely unseen environment.

### Stage 20. Create sparse-MET FA folds

Run:

- `20_create_fa_sparse_met_folds_yield.R`

What it does:

- creates 5 row-wise folds
- stratifies within each environment so every fold still contains rows from all
  environments
- masks genotype-environment cells rather than holding out entire environments

Outputs:

- `outputs/prediction_yield/20_fa_sparse_met_folds.csv`
- `outputs/prediction_yield/20_fa_sparse_met_plan.csv`

### Stage 21. Run sparse-MET FA benchmark

Run:

- `21_run_sparse_met_fa_yield.R`

What it does:

- fits `fa2` by default on the sparse-MET folds
- can also run other model names using the same fold design
- compares prediction of masked cells while all environments remain observed in
  training

Outputs:

- `outputs/prediction_yield/sparse_met_cv/21_fa_predictions.csv`
- `outputs/prediction_yield/sparse_met_cv/21_fa_metrics.csv`

## Technical validation already done

The fold-wise prediction engine was smoke-tested successfully on one `LOEO`
fold for:

- `baseline`
- `baseline_ec`

So the cross-validation prediction path is now technically working before you
launch longer multi-fold runs.

## Key concept

The main transition is:

- **fit comparison** asks: which model explains the observed data better?
- **prediction validation** asks: which model predicts unseen environments
  better?

That is the real continuation of the paper.
