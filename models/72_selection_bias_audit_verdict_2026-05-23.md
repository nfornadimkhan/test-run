# Stage 72 Verdict: Selection-Bias Audit for Weighted Consensus (2026-05-23)

## Purpose

Stage-69 found strict-pass weighted solutions on full folds, but that can be optimistic after searching many candidates.  
Stage-71 audited this by selecting weights on train folds and evaluating on held-out folds repeatedly.

## Artifacts

- Script:
  - `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/71_selection_bias_audit_weighted_candidate_yield.R`
- Outputs:
  - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/71_selection_bias_audit_weighted/71_selection_bias_summary.csv`
  - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/71_selection_bias_audit_weighted/71_selection_bias_replicates.csv`

## Results

- Repetitions: `500`
- Candidate pool per repetition: `1000`
- Mean gains on held-out folds:
  - all: `+1.079`
  - seen_genotypes: `+1.033`
- 5th percentile gain:
  - all: `+0.0015`
  - seen_genotypes: `-0.0782`

Strict pass rates under nested selection:
- pass_t_both_rate: `0.244`
- pass_w_both_rate: `0.214`
- pass_all_rate: `0.202`

## Verdict

- Practical gains remain strong after bias control.
- Strict inferential pass is not stable under nested selection.
- Therefore strict world-first declaration remains **not yet proven** under the current protocol.

