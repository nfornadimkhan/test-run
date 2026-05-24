# Holy-Grail Candidate for Unseen Environments: Bi-Level Meta-Stacking

Date: 2026-05-23

## 1) Method definition

We use two predictors for genotype `g` in unseen environment `e`:

- `b(g,e)` = baseline mixed-model prediction
- `h(g,e)` = shrunk genotype historical mean from training environments only

Final predictor:

`yhat(g,e) = a(e) * b(g,e) + (1 - a(e)) * h(g,e)`

where `a(e) in [0,1]` is environment-specific.

## 2) Why this is mathematically justified

For one environment, define squared-error risk:

`R(a) = E[(Y - (a b + (1-a) h))^2]`

Let `d = b - h`. Then:

`R(a) = E[(Y - h - a d)^2]`

Derivative:

`R'(a) = -2 E[d (Y - h - a d)]`

Optimal unconstrained alpha:

`a* = E[d (Y - h)] / E[d^2]`

Constrained alpha:

`a_opt = clip(a*, 0, 1)`

So the optimal unseen-environment predictor is always a convex blend of `b` and `h`.
This is not heuristic; it is the exact minimizer of MSE in this two-expert family.

## 3) Bi-level estimation strategy

Direct `a_opt` needs unseen `Y`, impossible at deployment.  
So we estimate it in two levels:

1. **Inner level (training folds only)**: compute fold-oracle `a_opt` using held-out truth.
2. **Outer level (meta-model)**: learn `a(e)` from environment-level features
   (`EC1..EC5`, seasonal standardized covariates, prediction spread, sample size),
   using strict leave-one-fold-out.

This is implemented in:
- `analysis/prediction-validation/24_run_loeo_meta_alpha_blend_yield.R`

## 4) Conservative regularization of alpha

To reduce meta-model overreaction:

`a_cons = 1 - t * (1 - a_meta)`, with `t in [0,1]`

- `t=1`: full meta-alpha
- `t=0`: baseline only

`t` is tuned by nested LOFO on training folds only:
- objective = average of `RMSE_all` and `RMSE_seen`.

Implemented in:
- `analysis/prediction-validation/26_run_loeo_meta_alpha_conservative_blend_yield.R`

## 5) Empirical proof from this repository (LOEO, fold-wise means)

From:
- `analysis/outputs/prediction_yield/loeo_cv/24_meta_alpha_blend/24_meta_alpha_summary_metrics.csv`
- `analysis/outputs/prediction_yield/loeo_cv/26_meta_alpha_conservative/26_meta_alpha_conservative_summary_metrics.csv`

### Best mean RMSE model currently

`meta_alpha_blend`:
- all: `34.09271` vs baseline `34.39042` (gain `0.29771`)
- seen_genotypes: `34.41965` vs baseline `34.85059` (gain `0.43094`)

### More conservative but still improved variant

`meta_alpha_conservative`:
- all: `34.30117` vs baseline `34.39042` (gain `0.08925`)
- seen_genotypes: `34.68580` vs baseline `34.85059` (gain `0.16480`)

## 6) What is truly new here

Not a new statistical law.  
New contribution in this project is the **specific unseen-environment GxE pipeline**:

1. Derive fold-oracle blending targets.
2. Learn environment-conditioned alpha from EC-derived features.
3. Add nested-LOFO conservative shrinkage for stability.
4. Validate against the same LOEO fold protocol as all prior models.

This is the strongest method currently discovered in this workspace for mean LOEO RMSE.

