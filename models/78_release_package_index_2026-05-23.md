# Stage 78 Release Package Index (2026-05-23)

## Purpose

Provide a single index for reviewers to reproduce and audit the discovery claim end-to-end.

## A) Core candidate definition

- Dossier:
  - `/Users/neon/Documents/Nadim's Brain/analysis/models/76_worldfirst_discovery_dossier_2026-05-23.md`

## B) Candidate generation pipeline

1. Search regularized settings:
   - `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/58_search_regularized_settings_stage54_yield.R`
2. Weighted consensus search:
   - `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/69_search_weighted_consensus_wilcoxon_yield.R`
3. Confirmatory gate audit:
   - `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/74_confirmatory_gate_audit_weighted_candidate_yield.R`

## C) Required outputs for verification

1. Stage-58 search table:
   - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/58_regularized_search/58_regularized_search_results.csv`
2. Stage-69 selected weighted candidate:
   - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/69_weighted_consensus_search/69_weighted_consensus_results.csv`
   - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/69_weighted_consensus_search/69_best_weights.csv`
3. Stage-74 confirmatory verdict files:
   - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/74_confirmatory_gate_audit/74_confirmatory_scope_summary.csv`
   - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/74_confirmatory_gate_audit/74_confirmatory_gate_result.csv`

## D) Critical caveat and bias audit

- Nested selection-bias audit:
  - `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/71_selection_bias_audit_weighted_candidate_yield.R`
  - `/Users/neon/Documents/Nadim's Brain/analysis/models/72_selection_bias_audit_verdict_2026-05-23.md`

## E) Claim governance

- Claim compliance checklist:
  - `/Users/neon/Documents/Nadim's Brain/analysis/models/77_discovery_claim_compliance_checklist_2026-05-23.md`

## F) Approved claim text

"A new project-level candidate method was discovered and validated under pre-registered confirmatory criteria, with no exact audited prior match found as of 2026-05-23; global non-existence is not claimed."

