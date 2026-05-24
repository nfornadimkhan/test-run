# Stage 105 Adaptive and Affine Frontier Audit (2026-05-23)

## Purpose

Probe beyond fixed convex weights to determine whether the remaining strict blocker (`dryad_maize_met` all-scope t-test) can be removed without breaking other external datasets.

## Experiments executed

### 1) Stage 102 (maize affine sweep, initial)
- Script: `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/102_maize_affine_weight_search.R`
- Finding: apparent strict-pass candidates existed for maize, but this version evaluated only one scope pathway and could be optimistic.

### 2) Stage 103 (maize affine sweep, corrected both scopes)
- Script: `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/103_maize_affine_bothscope_search.R`
- Finding: 4 maize strict-pass candidates in corrected both-scope evaluation (e.g., around `w_marker=-0.05`).
- Key result file:
  - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/run_queue/103_maize_affine_bothscope_search/103_maize_affine_bothscope_results.csv`

### 3) Cross-dataset validation of maize-optimized affine candidates
- Candidate example tested globally: `0.65 / 0.40 / -0.05`
- Result: fails strict pass on other datasets (`dryad_rice`, `dryad_wheat_sparse`).

### 4) Stage 104 (global affine search over 4 datasets)
- Script: `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/104_global_affine_search_4datasets.R`
- Finding: no single affine composition in scanned region passes strict criteria on all 4 datasets.
- Result summary: `n_pass_all4 = 0`
- Key result file:
  - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/run_queue/104_global_affine_search/104_global_affine_results.csv`

### 5) Stage 105 (adaptive per-fold training-only weight selection)
- Script: `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/105_run_external_adaptive_weight_candidate.R`
- Policy: inner-LOEO selection within each outer fold (no outer-test leakage).
- Outcome: unstable; severe degradation on `dryad_rice` and `dryad_maize_met`, despite pass on `dryad_wheat_sparse`.
- Conclusion: adaptive policy increases variance/overfitting under low-fold regimes and is not promoted.

## Restored reference candidate state

After frontier tests, canonical external state was restored using fixed robust candidate:
- `w_global = 0.75`, `w_geno = 0.25`, `w_marker = 0.00`

Current strict status:
- PASS: `cimmyt_wheat`, `dryad_rice`, `dryad_wheat_sparse`
- FAIL: `dryad_maize_met` (all-scope t-test)

Tracker:
- `/Users/neon/Documents/Nadim's Brain/analysis/models/84_external_execution_tracker_2026-05-23.csv`

## Interpretation

The remaining gap is now characterized as a validated frontier constraint in this model family:
- local maize strict recovery is possible,
- but no tested single global composition (convex or affine) passes strict gates on all 4 datasets simultaneously.
