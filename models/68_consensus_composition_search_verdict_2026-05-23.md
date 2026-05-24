# Stage 68 Verdict: Consensus Composition Search (2026-05-23)

## What was searched

- Top-K strict-pass settings from stage-58 (`K=2..8`)
- Aggregation rules: mean, median, trimmed mean (20%)

Script:
- `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/67_search_consensus_composition_yield.R`

Outputs:
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/67_consensus_composition_search/67_consensus_composition_results.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/67_consensus_composition_search/67_consensus_composition_top20.csv`

## Result

- No tested variant passed full strict gate (`pass_all = FALSE` for all rows).
- Many variants passed one-sided t-tests in both scopes (`pass_t_both = TRUE`), with strong gains.
- Final blocker persisted:
  - `seen_genotypes` one-sided Wilcoxon p remained slightly above 0.05 (typically ~0.0523 to ~0.0558).

## Interpretation

The discovery candidate is highly consistent in practical gain, but strict dual-test inferential gate remains narrowly unmet under this composition search.

