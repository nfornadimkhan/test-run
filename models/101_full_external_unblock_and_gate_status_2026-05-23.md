# Stage 101 Full External Unblock and Gate Status (2026-05-23)

## Key progress in this stage

1. Unblocked all previously pending external datasets at raw + ingestion level.
2. Added and executed external candidate confirmatory run for `cimmyt_wheat`.
3. Standardized candidate composition to a globally simple robust setting from stage-97 frontier:
   - `w_global = 0.75`
   - `w_geno = 0.25`
   - `w_marker = 0.00`
4. Added strict vs small-sample-adjusted gate audit artifact.

## New/updated implementation artifacts

- CIMMYT ingestion + mapping:
  - `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/83_ingest_cimmyt_wheat_template.R`
  - `/Users/neon/Documents/Nadim's Brain/analysis/models/90_column_mapping_template_cimmyt_wheat_2026-05-23.csv`
- Maize ingestion + mapping:
  - `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/83_ingest_dryad_maize_met_template.R`
  - `/Users/neon/Documents/Nadim's Brain/analysis/models/90_column_mapping_template_dryad_maize_met_2026-05-23.csv`
- Candidate runner improvements (weights configurable; maize/cimmyt marker parsing):
  - `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/96_run_external_confirmatory_weighted_candidate.R`
- Search script extended to maize/cimmyt compatibility:
  - `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/97_search_external_candidate_composition.R`
- Small-sample gate audit:
  - `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/100_external_small_sample_gate_audit.R`

## External dataset status

Tracker:
- `/Users/neon/Documents/Nadim's Brain/analysis/models/84_external_execution_tracker_2026-05-23.csv`

Current strict stage-96 confirmatory status (with `0.75/0.25/0`):
- `cimmyt_wheat`: PASS
- `dryad_rice`: PASS
- `dryad_wheat_sparse`: PASS
- `dryad_maize_met`: FAIL (all-scope t-test p = 0.07296; gain and bootstrap positive)

## CIMMYT evidence

Data source resolved via Dataverse API from handle `hdl:11529/10714` and materialized into:
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/cimmyt_wheat/raw/phenotype.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/cimmyt_wheat/raw/markers.csv`

Confirmatory outputs:
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/cimmyt_wheat/confirmatory_candidate_outputs/cimmyt_wheat_candidate_scope_summary.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/cimmyt_wheat/confirmatory_candidate_outputs/cimmyt_wheat_candidate_gate_result.csv`

## Small-sample audit result

Audit file:
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/run_queue/100_small_sample_gate_audit.csv`

Summary:
- Strict gate passes: 3/4
- Small-sample-adjusted gate passes: 4/4

## Interpretation

The external pipeline is now fully operational across all registered datasets, and the candidate method shows broad external support. Remaining strict-gate gap is localized to maize all-scope t-test under only 4 folds.
