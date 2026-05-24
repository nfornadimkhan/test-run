# Stage 61 Subset-Significance Robustness Verdict (2026-05-23)

## What was done

- Repeated subset significance audit (4,000 reps per scope, 18/22 folds each rep)
- Candidate: `worldfirst_candidate_fixed` (stage-59)
- Comparator: `meta_alpha_blend`

Script:
- `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/61_replicated_subset_significance_stage59_yield.R`

Outputs:
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/61_subset_significance_stage59/61_subset_significance_summary_by_scope.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/61_subset_significance_stage59/61_subset_significance_joint_summary.csv`

## Key results

Effect size stability:
- all mean gain ≈ `1.097`
- seen_genotypes mean gain ≈ `1.048`
- 5th percentile gains remain positive in both scopes.

Strict significance stability (subset reps):
- all: pass_both_rate ≈ `0.275`
- seen_genotypes: pass_both_rate ≈ `0.203`
- simultaneous pass in both scopes and both tests: `0.053`

## Interpretation

- Practical improvement is consistently positive.
- But strict inferential passing is not stable under subset replication.
- Therefore strict world-first claim gate remains **not satisfied**.

## Current claim boundary

- Strong candidate with large and stable mean gains: yes.
- Defensible strict world-first declaration: no (insufficient inferential stability).

