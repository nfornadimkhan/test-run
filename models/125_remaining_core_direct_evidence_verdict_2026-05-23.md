# Stage 125 Remaining-Core Direct Evidence Verdict (2026-05-23)

## Objective

Upgrade direct evidence on the remaining zero-direct core features (exact-weight tuple and robustness/falsification-layer features) across all comparators.

## Artifacts produced

Script:
- `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/125_upgrade_direct_evidence_remaining_core_features.R`

Outputs:
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/run_queue/125_priority_evidence/125_prior_feature_evidence_long.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/run_queue/125_priority_evidence/125_evidence_qa_summary.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/run_queue/125_priority_evidence/125_evidence_qa_by_feature.csv`

## Measured improvement (vs Stage-124)

Stage-124:
- `n_direct_or_manual = 98`
- `coverage_direct_only = 0.5833`

Stage-125:
- `n_direct_or_manual = 154`
- `coverage_direct_only = 0.9167`

Delta:
- `+56` direct rows
- direct coverage increased from `58.33%` to `91.67%`

## Feature-level status

Direct coverage `1.0` for 10/12 features:
- `has_fixed_global_weights`
- `weights_exact_080_025_m005`
- `requires_both_scopes_all_and_seen`
- `requires_all4_registered_datasets_pass`
- `gate_requires_mean_gain_nonneg`
- `gate_requires_one_sided_t_le_005`
- `gate_requires_boot_prob_ge_095`
- `includes_seed_robustness_layer`
- `includes_independent_rebuild_layer`
- `includes_train_label_permutation_falsification`

Near-complete:
- `uses_only_3_experts_global_geno_marker` = `0.9286`

Remaining weak feature:
- `allows_negative_weights` = `0.0714` direct, with `5` unknown rows.

## Claim-strength interpretation

The bounded world-first claim is now strongly supported at protocol-signature level under the repository audit framework, with direct evidence coverage above the previously defined high-confidence threshold.

Still required caveat:
- This remains a bounded claim (finite comparator set and coding process), not a universal proof of global non-existence.
