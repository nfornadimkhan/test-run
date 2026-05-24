# Stage 121 Direct-Evidence Upgrade Verdict (2026-05-23)

## Objective

Increase true direct-evidence coverage (not inference-tier coverage) for the highest-impact comparator set and measure the exact QA delta.

## Artifacts produced

Script:
- `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/121_upgrade_direct_evidence_core_priors.R`

Outputs:
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/run_queue/121_priority_evidence/121_prior_feature_evidence_long.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/run_queue/121_priority_evidence/121_evidence_qa_summary.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/run_queue/121_priority_evidence/121_evidence_qa_by_prior.csv`

## Measured improvement (vs Stage-120)

Stage-120 (`120_evidence_qa_summary.csv`):
- `n_direct_or_manual = 1`
- `coverage_direct_only = 0.006`

Stage-121 (`121_evidence_qa_summary.csv`):
- `n_direct_or_manual = 14`
- `coverage_direct_only = 0.0833`

Delta:
- `+13` direct rows
- direct coverage improved from `0.6%` to `8.33%`

## What was upgraded

Direct evidence rows were promoted for core comparators:
- `wolpert_1992_stacked_generalization`
- `breiman_1996_stacked_regressions`
- `vdl_2007_super_learner`
- `liang_2021_self_genomic`
- `barroso_2026_stacking_complex_arch`
- `montesinos_2019_bmors`
- `gu_2024_elpgv`

Each upgraded row now includes an explicit locator/note and is marked `evidence_tier = direct_or_manual`.

## Interpretation

- This is a real proof-strength increase, not just metadata inflation.
- However, direct coverage remains far below the previously defined high-confidence threshold.
- The bounded world-first claim remains provisional pending broader direct evidence extraction.

## Remaining gap

Current direct coverage: `8.33%`.

Still needed for high-confidence bounded priority framing:
- systematic direct extraction across all comparators/features,
- target `coverage_direct_only >= 0.70` (or revised threshold with explicit rationale).
