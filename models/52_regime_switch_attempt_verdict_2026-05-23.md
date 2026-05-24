# Stage 52 Verdict: Regime-Switch Unseen Correction Attempt (2026-05-23)

## Method tested

Stage-51 model:
- seen rows: keep `meta_alpha_blend` prediction unchanged
- unseen rows: apply nonlinear correction
  - `pred_switch = pred_meta + u1*delta + u2*sign(delta)*sqrt(abs(delta))`

Files:
- `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/51_run_loeo_regime_switch_unseen_correction_yield.R`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/51_regime_switch_unseen_correction/51_switch_unseen_summary_metrics.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/51_regime_switch_unseen_correction/51_switch_unseen_metrics_by_fold.csv`

## Outcome

Compared to `meta_alpha_blend`:
- all scope RMSE: worsened by `0.089756` (34.092708 -> 34.182464)
- seen_genotypes RMSE: unchanged exactly (34.419651 -> 34.419651)

Fold-level notes:
- all scope mean gain (meta - switch): `-0.089756`
- paired tests: not supportive of improvement.

## Interpretation

- The regime-switch idea successfully protected seen-genotype performance.
- But unseen-only correction degraded overall RMSE.
- Therefore this variant is not a world-first candidate and not a deployment replacement.

## New constraint for next discovery attempt

Any next candidate must satisfy simultaneously:
1. preserve or improve seen-genotypes RMSE,
2. improve all-scope RMSE,
3. pass uncertainty + stability checks.

