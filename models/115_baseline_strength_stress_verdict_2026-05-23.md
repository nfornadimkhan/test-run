# Stage 115 Baseline-Strength Stress Verdict (2026-05-23)

## Objective

Test whether the promoted candidate (`0.80/0.25/-0.05`) remains competitive when compared against stronger single-expert comparators, not only the global baseline.

## Comparators evaluated

Per dataset and scope (`all`, `seen_genotypes`):
- `pred_global` (global mean expert)
- `pred_geno` (genotype-mean expert)
- `pred_marker` (marker-PC expert)
- `best_single_expert_oracle` (ex post best among the three experts by mean RMSE in that dataset/scope)

## Evidence files

- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/run_queue/115_baseline_strength/115_candidate_vs_strong_baselines.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/run_queue/115_baseline_strength/115_best_single_expert_by_scope.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/run_queue/115_baseline_strength/115_fold_rmse_by_model.csv`

## Key findings

1. Candidate robustly outperforms `pred_global` across all datasets/scopes (positive gains; significant in most).
2. Candidate strongly outperforms `pred_marker` in most settings.
3. Candidate does **not** uniformly beat `pred_geno`:
   - notably weaker vs `pred_geno` in `cimmyt_wheat`.
4. Candidate does **not** uniformly beat `best_single_expert_oracle`:
   - loses in `cimmyt_wheat` (both scopes),
   - loses in `dryad_maize_met` seen-genotypes,
   - wins or ties elsewhere.

## Interpretation

The promoted candidate is best viewed as a **globally fixed, strict-gate-safe compromise** across datasets rather than an absolute per-dataset/per-scope champion against all single-expert comparators.

This supports a stronger reproducibility/robustness claim, while avoiding over-claiming universal dominance.

## Claim impact

- Keep: strict external pass, robustness, independent rebuild verification.
- Avoid: "uniformly best against every stronger baseline on every dataset/scope".
