# Stage 39 First-Run Results (2026-05-23)

## What was run

- Script:
  - `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/39_run_loeo_shift_aware_meta_blend_yield.R`
- Output summary:
  - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/39_shift_aware_meta_blend/39_shift_aware_meta_summary_metrics.csv`

Reference comparator (existing best mean RMSE method):
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/28_validation_all_approaches/28_summary_metrics.csv`

## Numeric result snapshot

From stage 39 summary:
- all:
  - baseline RMSE = 34.390422
  - shift_aware_meta_blend RMSE = 34.174963
- seen_genotypes:
  - baseline RMSE = 34.850593
  - shift_aware_meta_blend RMSE = 34.508861

Against stage-24 `meta_alpha_blend` (from stage 28 summary):
- all:
  - meta_alpha_blend RMSE = 34.092708
  - shift_aware_meta_blend RMSE = 34.174963
  - delta (shift - meta_alpha) = +0.082255 (worse)
- seen_genotypes:
  - meta_alpha_blend RMSE = 34.419651
  - shift_aware_meta_blend RMSE = 34.508861
  - delta (shift - meta_alpha) = +0.089210 (worse)

## Interpretation

- The shift-aware variant improved RMSE relative to baseline in this run.
- It did **not** beat current `meta_alpha_blend` on mean RMSE.
- Correlation and MSPE were not improved versus baseline in aggregate.

## Decision for now

- Keep `meta_alpha_blend` as current best mean-RMSE point predictor.
- Treat stage 39 as a promising directional variant that needs further tuning:
  - shift score definition,
  - alpha model regularization,
  - calibration of bias/variance trade-off.

