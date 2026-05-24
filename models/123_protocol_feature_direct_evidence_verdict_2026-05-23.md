# Stage 123 Protocol-Feature Direct Evidence Verdict (2026-05-23)

## Objective

Increase direct-evidence density by upgrading two additional protocol-defining features across the full comparator set.

## Artifacts produced

Script:
- `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/123_upgrade_direct_evidence_protocol_features.R`

Outputs:
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/run_queue/123_priority_evidence/123_prior_feature_evidence_long.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/run_queue/123_priority_evidence/123_evidence_qa_summary.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/run_queue/123_priority_evidence/123_evidence_qa_by_feature.csv`

## Measured improvement (vs Stage-122)

Stage-122:
- `n_direct_or_manual = 28`
- `coverage_direct_only = 0.1667`

Stage-123:
- `n_direct_or_manual = 56`
- `coverage_direct_only = 0.3333`

Delta:
- `+28` direct rows
- direct-evidence coverage doubled from `16.67%` to `33.33%`

## Feature-level status after Stage-123

From `123_evidence_qa_by_feature.csv`:
- `has_fixed_global_weights`: direct coverage `1.0`
- `requires_both_scopes_all_and_seen`: direct coverage `1.0`
- `requires_all4_registered_datasets_pass`: direct coverage `1.0`
- `uses_only_3_experts_global_geno_marker`: direct coverage `0.9286`

Still inference-dominant (direct coverage `0`):
- `weights_exact_080_025_m005`
- `gate_requires_mean_gain_nonneg`
- `gate_requires_one_sided_t_le_005`
- `gate_requires_boot_prob_ge_095`
- `includes_seed_robustness_layer`
- `includes_independent_rebuild_layer`
- `includes_train_label_permutation_falsification`

## Interpretation

This is a substantial proof-strength improvement: key protocol mismatch features now have near/full direct evidence across comparators. The bounded world-first claim is stronger than Stage-122 but still not at high-confidence threshold because several gate/falsification-layer features remain direct-evidence sparse.
