# Stage 50 Discovery Check: Non-Affine Dual-Gate (2026-05-23)

## Candidate definition

Let:
- `b = pred_baseline(g,e)`
- `m = pred_gmean(g)`
- `delta = m - b`
- `psi(delta) = sign(delta) * sqrt(abs(delta))`

Model:
- `yhat = b + w1(e)*delta + w2(e)*psi(delta)`

with `w1(e), w2(e)` learned out-of-fold from environment/fold features.

## Why this is mathematically distinct from stage-24 blend

Stage-24 convex blend is affine in `(b,m)`:
- `yhat = alpha*b + (1-alpha)*m = b + (1-alpha)*delta`

Stage-49 adds `w2*psi(delta)` where `psi` is nonlinear in `delta`.
Unless `w2=0`, this cannot be reduced to a single affine mixing coefficient on `(b,m)`.

## Empirical outcome (LOEO)

Outputs:
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/49_nonaffine_dualgate/49_nonaffine_dualgate_summary_metrics.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/49_nonaffine_dualgate/49_nonaffine_dualgate_metrics_by_fold.csv`

Summary vs `meta_alpha_blend`:
- all scope:
  - RMSE improved by `0.053313` (34.092708 -> 34.039395)
- seen_genotypes:
  - RMSE worsened by `0.064078` (34.419651 -> 34.483728)

Paired fold tests vs `meta_alpha_blend`:
- all: `t p = 0.944`, `wilcox p = 0.559`
- seen_genotypes: `t p = 0.934`, `wilcox p = 0.673`

## Discovery-status verdict

- Structural novelty candidate: **Yes (provisionally)** at equation level relative to current repo champion.
- Robust superiority for deployment/world-first claim: **No** (fails both-scope robustness).

## Required next step for world-first pursuit

To continue discovery attempt, candidate must pass:
1. Improvement in both scopes (`all`, `seen_genotypes`),
2. statistically defensible paired tests and uncertainty intervals,
3. seed-stability threshold from stage-43 protocol.

