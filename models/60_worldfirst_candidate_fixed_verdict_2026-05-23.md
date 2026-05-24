# Stage 60 Verdict: Fixed Candidate from Stage-58 Search (2026-05-23)

## Fixed setting used (from strict-pass search family)

- `shrink = 0.65`
- `u1_cap = 0.60`
- `u2_cap = 0.70`
- `min_node = 4`
- `trees = 700`

Implementation:
- `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/59_run_loeo_worldfirst_candidate_fixed_yield.R`

Outputs:
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/59_worldfirst_candidate_fixed/59_fixed_summary_metrics.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/59_worldfirst_candidate_fixed/59_fixed_metrics_by_fold.csv`

## Performance vs `meta_alpha_blend`

Mean RMSE gain:
- all: `+1.104956`
- seen_genotypes: `+1.049223`

One-sided paired significance:
- all:
  - t-test p = `0.048967`
  - Wilcoxon p = `0.048886`
  - status: pass @ 0.05
- seen_genotypes:
  - t-test p = `0.058672`
  - Wilcoxon p = `0.067664`
  - status: narrowly above 0.05

## Verdict

- This is the strongest fixed candidate to date with large practical gains in both scopes.
- Strict world-first declaration still blocked by the final `seen_genotypes` significance gate.

## Next step

Execute replicated-resampling significance (multiple partition perturbations with fixed design rules) to determine whether the near-threshold `seen_genotypes` p-values stabilize below 0.05.

