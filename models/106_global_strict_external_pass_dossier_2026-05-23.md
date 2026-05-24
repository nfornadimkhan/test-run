# Stage 106 Global Strict External Pass Dossier (2026-05-23)

## Candidate promoted

Single global affine composition:
- `w_global = 0.80`
- `w_geno = 0.25`
- `w_marker = -0.05`

Run command pattern:
- `Rscript analysis/prediction-validation/96_run_external_confirmatory_weighted_candidate.R <dataset_key> <base_dir> 0.80 0.25 -0.05`

## Strict confirmatory gate definition

Per dataset, both scopes (`all`, `seen_genotypes`) must satisfy:
1. `mean_gain >= 0`
2. one-sided paired t-test `p <= 0.05`
3. bootstrap `P(gain > 0) >= 0.95`

## Results (all 4 datasets)

### cimmyt_wheat
- all: mean_gain `0.1350818`, t `2.44e-10`
- seen: mean_gain `0.3033397`, t `1.33e-12`
- pass_confirmatory: `TRUE`

### dryad_rice
- all: mean_gain `0.2711676`, t `0.0056973`
- seen: mean_gain `0.2734347`, t `0.0073611`
- pass_confirmatory: `TRUE`

### dryad_wheat_sparse
- all: mean_gain `0.0036311`, t `0.0486904`
- seen: mean_gain `0.0036311`, t `0.0486904`
- pass_confirmatory: `TRUE`

### dryad_maize_met
- all: mean_gain `0.0108315`, t `0.0346133`
- seen: mean_gain `0.1401382`, t `0.0472882`
- pass_confirmatory: `TRUE`

## Core evidence files

- Tracker:
  - `/Users/neon/Documents/Nadim's Brain/analysis/models/84_external_execution_tracker_2026-05-23.csv`
- Per-dataset outputs:
  - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/<dataset_key>/confirmatory_candidate_outputs/<dataset_key>_candidate_scope_summary.csv`
  - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/<dataset_key>/confirmatory_candidate_outputs/<dataset_key>_candidate_gate_result.csv`

## Interpretation

This stage clears the previously established cross-dataset strict-feasibility frontier under the standardized pipeline and produces a single externally validated candidate that passes strict confirmatory gates on all registered external datasets.
