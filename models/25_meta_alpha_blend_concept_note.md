# Meta-Alpha Blend: Concept, Origin, and What Is New Here

Date: 2026-05-23

## 1) The core formula (plain text)

`predicted_y(g,e) = alpha(e) * baseline_prediction(g,e) + (1 - alpha(e)) * genotype_mean_prediction(g)`

Where:
- `g` = genotype
- `e` = environment
- `alpha(e)` in `[0,1]` controls how much we trust baseline vs genotype historical mean.

## 2) Is this a new scientific discovery?

No. The concept is not new.

It is based on established methods:
- **Model averaging / stacking**: combine two predictors with a weight.
- **Shrinkage / empirical Bayes intuition**: stabilize prediction by pulling toward genotype historical mean when uncertainty is high.
- **GxE reaction-norm pragmatism**: model performance varies by environment, so weighting can be environment-specific.

## 3) What is new in this project

What is new is the **specific implementation and validation in this pipeline**:

1. Baseline predictor comes from the existing LOEO mixed-model outputs.
2. Second predictor is genotype historical mean from training environments only, with shrinkage:
   - `gmean_shrunk = (n_g/(n_g+lambda))*gmean + (lambda/(n_g+lambda))*global_mean`
3. `alpha(e)` is predicted by a leave-one-fold-out meta-model (ranger) using fold-level environment/prediction features.
4. Evaluation is done with the same LOEO fold-wise metric framework as the rest of the project.

## 4) Verified result in this repository

From:
- `analysis/outputs/prediction_yield/loeo_cv/24_meta_alpha_blend/24_meta_alpha_summary_metrics.csv`

Mean over LOEO folds:

- **All rows**
  - baseline RMSE: `34.39042`
  - meta_alpha_blend RMSE: `34.09271`
  - improvement: `-0.29771`

- **Seen genotypes**
  - baseline RMSE: `34.85059`
  - meta_alpha_blend RMSE: `34.41965`
  - improvement: `-0.43094`

## 5) Practical interpretation

- Baseline alone is strong but not uniformly best in every held-out environment.
- Environment-conditioned blending improves unknown-environment prediction by adapting trust between:
  - baseline structural GxE fit, and
  - robust genotype historical signal.

## 6) Reproducibility path

Main script:
- `analysis/prediction-validation/24_run_loeo_meta_alpha_blend_yield.R`

Outputs:
- `analysis/outputs/prediction_yield/loeo_cv/24_meta_alpha_blend/24_meta_alpha_blend_predictions.csv`
- `analysis/outputs/prediction_yield/loeo_cv/24_meta_alpha_blend/24_meta_alpha_fold_features.csv`
- `analysis/outputs/prediction_yield/loeo_cv/24_meta_alpha_blend/24_meta_alpha_metrics_by_fold.csv`
- `analysis/outputs/prediction_yield/loeo_cv/24_meta_alpha_blend/24_meta_alpha_summary_metrics.csv`

