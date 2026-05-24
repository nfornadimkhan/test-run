# Stage 66 Verdict: Consensus Refinement (2026-05-23)

## Compared candidates

- Stage-63 mean consensus
- Stage-65 median consensus
- Baseline comparator: `meta_alpha_blend`

## Summary

Both consensus variants produce large RMSE gains in both scopes.

### Mean consensus (stage-63)
- all gain: `+1.044178`
- seen gain: `+0.998789`
- one-sided p-values:
  - all: t `0.0374`, Wilcoxon `0.0489`
  - seen: t `0.0446`, Wilcoxon `0.0523`

### Median consensus (stage-65)
- all gain: `+1.013158`
- seen gain: `+0.969185`
- one-sided p-values:
  - all: t `0.0366`, Wilcoxon `0.0489`
  - seen: t `0.0436`, Wilcoxon `0.0523`

## Decision from this refinement

- Mean consensus remains slightly stronger on effect size.
- Median consensus does not fix the final blocker.
- Final blocker remains unchanged:
  - seen-genotypes Wilcoxon one-sided p is narrowly above 0.05.

## Current status

World-first claim still not strictly proven under the hard gate requiring both one-sided tests <= 0.05 in both scopes.

