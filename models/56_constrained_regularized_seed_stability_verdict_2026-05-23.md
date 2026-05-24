# Stage 56 Verdict: Constrained-Regularized Candidate (2026-05-23)

## What was tested

- Stage-54 model: constrained regime correction with coefficient shrinkage/caps.
- Stage-55 seed-stability sweep (50 seeds) for stage-54 fold-level meta-model fitting.

Files:
- `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/54_run_loeo_constrained_regime_regularized_yield.R`
- `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/55_seed_stability_constrained_regularized_yield.R`

Outputs:
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/54_constrained_regime_regularized/54_regularized_summary_metrics.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/54_constrained_regime_regularized/54_regularized_metrics_by_fold.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/55_seed_stability_constrained_regularized/55_seed_stability_summary.csv`

## Core evidence

Mean RMSE improvement vs `meta_alpha_blend` (stage-54):
- all: `+1.153965`
- seen_genotypes: `+1.098221`

Seed stability (stage-55, 50 seeds):
- all:
  - gain_mean = `1.133069`
  - gain_q05..q95 = `[1.070041, 1.194717]`
  - probability gain > 0 = `1.00`
- seen_genotypes:
  - gain_mean = `1.076147`
  - gain_q05..q95 = `[1.013113, 1.139719]`
  - probability gain > 0 = `1.00`

## Gate status for world-first pursuit

1. Structural distinctness: PASS (non-affine corrective regime form).
2. Strong practical gain magnitude: PASS.
3. Seed robustness: PASS.
4. Paired-fold significance at strict threshold (p <= 0.05 both scopes): NOT YET PASS (currently around 0.09–0.14).

## Verdict

- This is the strongest discovery candidate so far.
- It is not yet safe to declare “world-first discovery” because the strict paired significance gate remains unmet.

## Immediate next step

Run repeated LOEO perturbation/blocked-resampling significance (stage-57) to test whether the observed gains remain significant under replicated fold partitions.

