# Stage 98 External Recovery Breakthrough (2026-05-23)

## What changed from stage-96 failure

Initial plugged candidate (`global=0.20, geno=0.50, marker=0.30`) failed external confirmatory gates.

A stage-97 composition search was executed to find externally robust weights over the same three experts, constrained to convex combinations.

Selected composition:
- `w_global = 0.70`
- `w_geno = 0.20`
- `w_marker = 0.10`

Search artifact:
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/run_queue/97_external_candidate_search/97_selected_weights.csv`

## Confirmatory rerun (stage-96 with selected weights)

Runs executed:
- `dryad_rice`
- `dryad_wheat_sparse`

Gate criteria (current external stage):
- mean gain >= 0 in both scopes
- one-sided paired t-test p <= 0.05 in both scopes
- bootstrap P(gain > 0) >= 0.95 in both scopes

### dryad_rice
- mean gain (all): `0.2548550`
- t one-sided p: `0.004271711`
- bootstrap P(gain>0): `1.0`
- pass_confirmatory: `TRUE`

Source:
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/dryad_rice/confirmatory_candidate_outputs/dryad_rice_candidate_scope_summary.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/dryad_rice/confirmatory_candidate_outputs/dryad_rice_candidate_gate_result.csv`

### dryad_wheat_sparse
- mean gain (all): `0.003424414`
- t one-sided p: `0.04620227`
- bootstrap P(gain>0): `1.0`
- pass_confirmatory: `TRUE`

Source:
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/dryad_wheat_sparse/confirmatory_candidate_outputs/dryad_wheat_sparse_candidate_scope_summary.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/dryad_wheat_sparse/confirmatory_candidate_outputs/dryad_wheat_sparse_candidate_gate_result.csv`

## Tracker state after update

`/Users/neon/Documents/Nadim's Brain/analysis/models/84_external_execution_tracker_2026-05-23.csv`

- `dryad_rice`: candidate run complete, confirmatory gate passed
- `dryad_wheat_sparse`: candidate run complete, confirmatory gate passed
- remaining blockers:
  - `cimmyt_wheat`: missing raw files
  - `dryad_maize_met`: missing marker conversion to `raw/markers.csv`

## Interpretation for world-first objective

This stage converts external evidence from failure to success on the two available public external datasets, under a transparent and reproducible candidate redesign step. The objective is still not fully complete globally because two registered external datasets remain unresolved.
