# Stage 41 Uncertainty Verdict on Top-2 Blends (2026-05-23)

## Compared models

- Model A: `meta_alpha_blend` (stage 24)
- Model B: `alpha_search_ranger_shift` (stage 40)

Input fold metrics:
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/24_meta_alpha_blend/24_meta_alpha_metrics_by_fold.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/40_alpha_model_search/40_alpha_model_search_metrics_by_fold.csv`

Stage-41 output:
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/41_rmse_difference_uncertainty/41_rmse_difference_uncertainty.csv`

## Definition

Gain is defined as:
- `gain = RMSE(meta_alpha_blend) - RMSE(alpha_search_ranger_shift)`
- positive gain means stage-40 model is better.

## Results

### Scope: all (22 folds)

- Mean gain: `0.004179`
- Median gain: `0.009278`
- Win rate: `0.545`
- Paired t-test: `p = 0.909`, CI `[-0.0713, 0.0796]`
- Paired Wilcoxon: `p = 0.871`
- Bootstrap 95% CI of mean gain: `[-0.0606, 0.0794]`

### Scope: seen_genotypes (22 folds)

- Mean gain: `0.000085`
- Median gain: `0.009217`
- Win rate: `0.545`
- Paired t-test: `p = 0.998`, CI `[-0.0763, 0.0764]`
- Paired Wilcoxon: `p = 0.770`
- Bootstrap 95% CI of mean gain: `[-0.0659, 0.0744]`

## Verdict

- The stage-40 model has a tiny numerical mean-RMSE advantage.
- Uncertainty is large relative to the effect size; all inferential intervals include zero.
- Evidence supports a **practical tie** rather than a robust superiority claim.

## Reporting-safe statement

"The alpha-search ranger+shift variant achieved slightly lower mean RMSE than meta_alpha_blend in this run, but paired and bootstrap uncertainty analyses indicate the effect is not statistically robust; we therefore treat the two models as effectively tied under current LOEO evidence."

