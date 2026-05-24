# Stage 126 Allows-Negative-Weights Upgrade and Readiness Audit (2026-05-23)

## Objective

Reduce the final weak feature (`allows_negative_weights`) and re-evaluate whether evidence strength is sufficient for a high-confidence bounded world-first claim posture.

## Artifacts produced

Script:
- `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/126_upgrade_allows_negative_weights_evidence.R`

Outputs:
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/run_queue/126_priority_evidence/126_prior_feature_evidence_long.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/run_queue/126_priority_evidence/126_evidence_qa_summary.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/run_queue/126_priority_evidence/126_evidence_qa_by_feature.csv`

## Measured improvement (vs Stage-125)

Stage-125 summary:
- `n_direct_or_manual = 154`
- `coverage_direct_only = 0.9167`

Stage-126 summary:
- `n_direct_or_manual = 160`
- `coverage_direct_only = 0.9524`

Delta:
- `+6` direct rows
- direct coverage increased from `91.67%` to `95.24%`

## Feature-level status

From `126_evidence_qa_by_feature.csv`:
- Direct coverage `1.0` for 10 features
- `uses_only_3_experts_global_geno_marker` = `0.9286`
- `allows_negative_weights` = `0.5` direct, `2` inferred, `5` unknown

Interpretation:
- The global evidence framework is now very strong overall.
- The only substantive residual uncertainty is weight-sign handling in a subset of comparator methods.

## Completion-readiness (bounded claim scope)

For the bounded protocol-signature claim (not absolute existential world-first):
- Evidence depth: **strong** (`coverage_direct_only = 0.9524`)
- Comparator breadth: moderate (`n_priors = 14`)
- Residual ambiguity: concentrated and explicit (`allows_negative_weights` unknowns)

Readiness verdict:
- **Ready for high-confidence bounded claim language with explicit caveat on weight-sign ambiguity in some comparators.**
- **Not eligible for universal/global non-existence claim.**
