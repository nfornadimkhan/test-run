# Stage 120 Inference-Tier Evidence Verdict (2026-05-23)

## Objective

Increase comparator traceability coverage while explicitly separating `inferred` evidence from `direct` evidence, so coverage gains do not masquerade as proof-strength gains.

## Artifacts produced

Script:
- `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/120_enrich_priority_evidence_with_inference.R`

Outputs:
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/run_queue/120_priority_evidence/120_prior_feature_evidence_long_enriched.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/run_queue/120_priority_evidence/120_evidence_qa_summary.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/run_queue/120_priority_evidence/120_evidence_qa_by_feature.csv`

## Quantitative result

From `120_evidence_qa_summary.csv`:
- `n_priors = 14`
- `n_feature_rows = 168`
- `n_direct_or_manual = 1`
- `n_inferred = 162`
- `n_unknown = 5`
- `coverage_any_evidence = 0.9702`
- `coverage_direct_only = 0.006`

## Interpretation

- Coverage for **any** evidence is now high because inference-based evidence was attached to almost all known-value rows.
- **Direct evidence remains critically low** (0.6%).
- Therefore, this stage improves audit structure and transparency, not priority-proof strength.

## Claim impact

Allowed:
- "Comparator coding now has near-complete traceability metadata with explicit inference labeling."

Not allowed:
- "Priority evidence is now strong" (false under direct-evidence criterion).

## Hard next gate

Upgrade from inference-tier to direct-tier by adding section/table/appendix-level locators for each comparator-feature row.

Suggested threshold for high-confidence bounded priority claim:
- `coverage_direct_only >= 0.70`
- `n_unknown <= 5% of rows`
- `no comparator with exact_match_possible driven only by inference`
