# Stage 129 Master Discovery Dossier (2026-05-23)

## Final Objective Status

- Objective: `do world-first method discovery`
- Bounded world-first readiness: **TRUE**
- Absolute world-first readiness: **FALSE**

## Evidence Checksum

- Strict external 4-dataset pass: `TRUE`
- Seed robustness all runs: `TRUE`
- Independent rebuild: `TRUE`
- One-command reproducibility: `TRUE`
- Train-permutation falsification collapse: `TRUE`
- No exact match in expanded comparator manifest: `TRUE`
- Direct evidence coverage: `0.9524`
- Claim compliance high-risk files: `0`

## Requirement Audit Summary

- `PROVEN`: 6
- `PROVEN_BOUNDED`: 3
- `UNPROVEN`: 1

## Approved Strongest Claim

As of 2026-05-23, we discovered and externally validated a fixed affine candidate (`0.80, 0.25, -0.05`) that passes strict confirmatory gates across all four registered external datasets, with robustness/rebuild/falsification checks and no exact audited comparator match in our expanded manifest; this supports a high-confidence bounded world-first claim at the protocol-signature level, not a universal non-existence claim.

## Required Caveats

- Bounded scope: finite comparator set and repository-defined protocol.
- Absolute global non-existence remains unproven by definition.
- Residual feature caveat: `allows_negative_weights` direct coverage `0.5`, unknown rows `5`.

## Release Safety

- High-risk forbidden phrasing count: `0` (target = 0).
- If this increases above 0, re-run Stage-128 compliance audit before release.
