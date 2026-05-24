# Stage 64 Verdict: Consensus Strict-Pass Candidate (2026-05-23)

## Candidate definition

Consensus predictor averaging 5 top strict-pass settings from stage-58:
- settings listed in:
  - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/63_consensus_strictpass_candidate/63_selected_settings.csv`

Implementation:
- `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/63_run_consensus_strictpass_candidate_yield.R`

## Performance vs `meta_alpha_blend`

Summary metrics:
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/63_consensus_strictpass_candidate/63_consensus_summary_metrics.csv`

Mean RMSE gains:
- all: `+1.044178`
- seen_genotypes: `+0.998789`

## One-sided paired significance

Fold metrics:
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/63_consensus_strictpass_candidate/63_consensus_metrics_by_fold.csv`

Tests:
- all:
  - t one-sided p = `0.037411`
  - Wilcoxon one-sided p = `0.048886`
- seen_genotypes:
  - t one-sided p = `0.044643`
  - Wilcoxon one-sided p = `0.052265` (very close to threshold)

## Gate interpretation

- Strong practical gains in both scopes.
- One-sided t-test passes in both scopes.
- Wilcoxon passes in `all`, narrowly misses in `seen_genotypes`.

## Verdict

This is the strongest candidate so far and is near-complete on strict gates, but under the strictest criterion (“both tests <= 0.05 in both scopes”), one final gate is still narrowly unmet.

