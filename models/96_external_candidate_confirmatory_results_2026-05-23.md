# Stage 96 External Candidate Confirmatory Results (2026-05-23)

## What was executed

A true external candidate run was executed (not template baseline) using:

- Script: `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/96_run_external_confirmatory_weighted_candidate.R`
- Candidate definition:
  - `pred_candidate = 0.20 * pred_global + 0.50 * pred_geno + 0.30 * pred_marker_pc`
- Baseline:
  - `pred_baseline = pred_global`

Per-fold evaluation used the external LOEO fold map, with one-sided t-test, one-sided Wilcoxon, and bootstrap probability of positive gain.

## Dataset-level outcomes

| Dataset | Mean gain (all) | t one-sided p | Wilcoxon one-sided p | Boot P(gain>0) | Confirmatory gate |
|---|---:|---:|---:|---:|---|
| dryad_rice | -0.2904 | 0.9199 | 0.9632 | 0.0000 | FAIL |
| dryad_wheat_sparse | 0.00493 | 0.0605 | 0.0502 | 1.0000 | FAIL |

Gate rule used in this stage:
- `mean_gain >= 0` in both scopes (`all`, `seen_genotypes`)
- one-sided t-test `p <= 0.05` in both scopes
- bootstrap `P(gain>0) >= 0.95` in both scopes

## Output artifacts

- Dryad rice:
  - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/dryad_rice/confirmatory_candidate_outputs/dryad_rice_candidate_scope_summary.csv`
  - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/dryad_rice/confirmatory_candidate_outputs/dryad_rice_candidate_gate_result.csv`
- Dryad wheat sparse:
  - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/dryad_wheat_sparse/confirmatory_candidate_outputs/dryad_wheat_sparse_candidate_scope_summary.csv`
  - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/dryad_wheat_sparse/confirmatory_candidate_outputs/dryad_wheat_sparse_candidate_gate_result.csv`
- Tracker update:
  - `/Users/neon/Documents/Nadim's Brain/analysis/models/84_external_execution_tracker_2026-05-23.csv`

## Interpretation for world-first objective

This stage materially strengthened evidence quality by moving from readiness to actual external candidate execution on two datasets. Current result is negative for confirmatory success:

- Candidate is now externally tested and reproducible.
- External confirmatory criteria are **not** met yet.
- The strongest near-term path is iterative external method redesign + re-test, and completion of remaining datasets (`cimmyt_wheat`, `dryad_maize_met`) to avoid overfitting conclusions to two datasets.
