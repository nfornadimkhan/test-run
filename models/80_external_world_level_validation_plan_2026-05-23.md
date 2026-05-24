# Stage 80 External World-Level Validation Plan (2026-05-23)

## Purpose

Advance from:
- project-level validated discovery

toward:
- stronger external world-level evidence.

## Why this is needed

Current repository evidence is strong internally, but absolute global novelty requires broader external confirmation and independent reproduction.

## Plan

1. External datasets (minimum 3 independent MET datasets)
- Criteria:
  - distinct breeding programs or species contexts
  - enough environments for LOEO-style validation
  - availability of comparable environmental covariates

2. Locked model specification
- Freeze:
  - final weighted-consensus formulation
  - selected settings + weights
  - confirmatory gate thresholds
- No tuning on external test folds.

3. Pre-registered external evaluation protocol
- Primary:
  - LOEO RMSE gain vs strong baseline family
  - one-sided paired t-test in both scopes
  - bootstrap P(gain > 0) in both scopes
- Secondary:
  - one-sided Wilcoxon
  - calibration/bias diagnostics

4. Independent replication
- At least one analyst who did not develop the method reruns the pipeline from the release package index.
- Require checksum match of core artifacts before scoring.

5. Cross-dataset synthesis
- Meta-analyze effect sizes across datasets:
  - pooled mean gain
  - heterogeneity statistics
  - fraction of datasets passing confirmatory gate

## External claim upgrade criteria

Upgrade from project-level discovery to stronger world-level evidence only if:
1. at least 2/3 external datasets pass confirmatory gate,
2. pooled gain remains positive with lower confidence bound > 0,
3. independent replication reproduces key outputs.

## Current status

- Internal discovery package: complete.
- External validation campaign: not yet executed.

## Immediate next deliverable

Create stage-81 dataset registry file with candidate public datasets and access metadata.

