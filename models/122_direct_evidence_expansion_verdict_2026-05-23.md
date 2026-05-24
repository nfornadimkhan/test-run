# Stage 122 Direct-Evidence Expansion Verdict (2026-05-23)

## Objective

Increase direct-evidence coverage across additional comparator papers that were still at zero direct rows after Stage-121.

## Artifacts produced

Script:
- `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/122_upgrade_direct_evidence_additional_priors.R`

Outputs:
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/run_queue/122_priority_evidence/122_prior_feature_evidence_long.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/run_queue/122_priority_evidence/122_evidence_qa_summary.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/run_queue/122_priority_evidence/122_evidence_qa_by_prior.csv`

## Measured improvement (vs Stage-121)

Stage-121:
- `n_direct_or_manual = 14`
- `coverage_direct_only = 0.0833`

Stage-122:
- `n_direct_or_manual = 28`
- `coverage_direct_only = 0.1667`

Delta:
- `+14` direct rows
- direct-evidence coverage doubled from `8.33%` to `16.67%`

## Comparator-level effect

After Stage-122, each of the 14 comparators has at least 2 direct rows (`coverage_direct = 0.1667` per comparator), reducing concentration risk where only a few papers carried direct evidence.

## Interpretation

- This is another real proof-strength gain toward a defensible bounded world-first claim.
- Still below high-confidence threshold; direct evidence remains the critical bottleneck.

## Current boundary

Allowed:
- "No exact audited match found under current bounded comparator protocol, with growing direct evidence support."

Not yet allowed:
- "High-confidence bounded priority claim robust to section-level scrutiny across most comparator features."

Reason:
- direct coverage is `16.67%`, still well below target (`>=70%` previously set as a hard gate).
