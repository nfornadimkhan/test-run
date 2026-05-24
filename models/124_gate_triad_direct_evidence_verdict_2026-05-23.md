# Stage 124 Gate-Triad Direct Evidence Verdict (2026-05-23)

## Objective

Raise direct-evidence coverage by upgrading the strict confirmatory gate triad across the comparator set.

## Artifacts produced

Script:
- `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/124_upgrade_direct_evidence_gate_triad.R`

Outputs:
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/run_queue/124_priority_evidence/124_prior_feature_evidence_long.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/run_queue/124_priority_evidence/124_evidence_qa_summary.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/run_queue/124_priority_evidence/124_evidence_qa_by_feature.csv`

## Measured improvement (vs Stage-123)

Stage-123:
- `n_direct_or_manual = 56`
- `coverage_direct_only = 0.3333`

Stage-124:
- `n_direct_or_manual = 98`
- `coverage_direct_only = 0.5833`

Delta:
- `+42` direct rows
- direct coverage increased from `33.33%` to `58.33%`

## Feature-level status after Stage-124

Direct coverage now `1.0` for:
- `has_fixed_global_weights`
- `requires_both_scopes_all_and_seen`
- `requires_all4_registered_datasets_pass`
- `gate_requires_mean_gain_nonneg`
- `gate_requires_one_sided_t_le_005`
- `gate_requires_boot_prob_ge_095`

Near-complete:
- `uses_only_3_experts_global_geno_marker` = `0.9286`

Still direct-sparse:
- `weights_exact_080_025_m005` (0)
- `includes_seed_robustness_layer` (0)
- `includes_independent_rebuild_layer` (0)
- `includes_train_label_permutation_falsification` (0)
- `allows_negative_weights` (0.0714, with unknown rows)

## Interpretation

This stage substantially strengthens bounded novelty evidence and brings direct coverage close to the previously defined high-confidence threshold. Remaining gap is concentrated in a small subset of features, primarily those tied to repository-specific robustness/falsification layers and exact-weight tuple matching.
