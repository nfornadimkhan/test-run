# Stage 40 Alpha-Model Search Results (2026-05-23)

## Run artifacts

- Script:
  - `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/40_run_loeo_alpha_model_search_yield.R`
- Outputs:
  - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/40_alpha_model_search/40_alpha_model_search_summary_metrics.csv`
  - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/40_alpha_model_search/40_alpha_model_search_metrics_by_fold.csv`

Comparator:
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/28_validation_all_approaches/28_summary_metrics.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/24_meta_alpha_blend/24_meta_alpha_metrics_by_fold.csv`

## Best variant from stage 40

- `alpha_search_ranger_shift` had the best mean RMSE in both scopes:
  - all: RMSE `34.088529`
  - seen_genotypes: RMSE `34.419565`

Against baseline:
- all gain: `34.390422 - 34.088529 = 0.301893`
- seen_genotypes gain: `34.850593 - 34.419565 = 0.431027`

Against stage-24 `meta_alpha_blend`:
- all gain: `34.092708 - 34.088529 = 0.004179`
- seen_genotypes gain: `34.419651 - 34.419565 = 0.000085`

## Paired fold comparison vs stage-24 `meta_alpha_blend`

Using 22 LOEO folds:

- all:
  - mean RMSE gain = `0.004179`
  - win rate = `0.545`
  - paired t-test p = `0.909`
  - paired Wilcoxon p = `0.871`

- seen_genotypes:
  - mean RMSE gain = `0.000085`
  - win rate = `0.545`
  - paired t-test p = `0.998`
  - paired Wilcoxon p = `0.770`

## Interpretation

- Stage-40 found a configuration with **numerically lower** mean RMSE than `meta_alpha_blend`.
- The margin is extremely small and not statistically strong under paired fold tests.
- Practical conclusion: `alpha_search_ranger_shift` and `meta_alpha_blend` are effectively tied under current evidence.

