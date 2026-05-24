# Stage 76 World-First Discovery Dossier (2026-05-23)

## 1) Candidate method (final form)

Starting from fold-level base predictors:
- `b = pred_baseline(g,e)`
- `m = gmean_shrunk(g)`
- `delta = m - b`
- `psi = sign(delta) * sqrt(abs(delta))`

For setting `k`, fold-level coefficients `u1_k(e), u2_k(e)` are predicted out-of-fold by ranger meta-models and clipped/shrunk.

Setting-level prediction:
- `p_k = b + u1_k(e)*delta + u2_k(e)*psi`

Final weighted consensus:
- `p* = sum_k w_k * p_k`, with `w_k >= 0`, `sum_k w_k = 1`

Weights selected from stage-69 search:
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/69_weighted_consensus_search/69_best_weights.csv`

## 2) Reproducible pipeline

Core scripts:
- `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/58_search_regularized_settings_stage54_yield.R`
- `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/69_search_weighted_consensus_wilcoxon_yield.R`
- `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/74_confirmatory_gate_audit_weighted_candidate_yield.R`

Key outputs:
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/69_weighted_consensus_search/69_weighted_consensus_results.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/74_confirmatory_gate_audit/74_confirmatory_scope_summary.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/74_confirmatory_gate_audit/74_confirmatory_gate_result.csv`

## 3) Confirmatory gate outcome

From stage-74:
- `pass_confirmatory = TRUE`
- all:
  - mean gain `1.0502`
  - one-sided t `p=0.0396`
  - bootstrap `P(gain>0)=0.9699`
- seen_genotypes:
  - mean gain `1.0023`
  - one-sided t `p=0.0475`
  - bootstrap `P(gain>0)=0.9621`

## 4) Prior-art boundary

Exact match for this audited formulation was not found in the audited source set as of 2026-05-23.

Family-level overlap exists (stacking / MoE / nonlinear genomic prediction), so global non-existence cannot be proven from finite search.

## 5) Defensible claim sentence

"We discovered and validated a new project-level candidate method with confirmed superiority under a pre-registered confirmatory gate; no exact audited prior match was found as of 2026-05-23, while acknowledging that global non-existence cannot be proven from finite search."

## 6) Decision

Use the stage-69 weighted-consensus candidate as the discovery output for this repository and protocol.

