# Meta Alpha Blend: Provenance and Evidence (2026-05-23)

## 1) Plain-text formula (no LaTeX)

pred_hat(g,e) = alpha(e) * pred_baseline(g,e) + (1 - alpha(e)) * pred_gmean(g)

Where:
- g = genotype
- e = environment
- pred_baseline(g,e) = baseline mixed-model prediction for genotype g in environment e
- pred_gmean(g) = historical genotype mean predictor (with shrinkage in code)
- alpha(e) in [0,1] = environment-specific blending weight

## 2) Where this concept comes from

This is **not** a brand-new mathematical family. It belongs to known families:
- stacked generalization / stacking (meta-combination of base predictors)
- mixture-of-experts style convex gating (weighted expert combination)
- plant-breeding ensemble/meta-model approaches (including stacking-style second-stage models)

Representative prior-art references:
- Wolpert (1992), Stacked Generalization: [https://www.researchgate.net/publication/222467943_Stacked_Generalization](https://www.researchgate.net/publication/222467943_Stacked_Generalization)
- Super Learner (van der Laan et al., 2007): [https://doi.org/10.2202/1544-6115.1309](https://doi.org/10.2202/1544-6115.1309)
- Adaptive Mixtures of Local Experts (Jacobs et al., 1991): [https://doi.org/10.1162/neco.1991.3.1.79](https://doi.org/10.1162/neco.1991.3.1.79)
- BMORS (Bayesian multi-output regressor stacking in breeding): [https://pmc.ncbi.nlm.nih.gov/articles/PMC6778812/](https://pmc.ncbi.nlm.nih.gov/articles/PMC6778812/)
- Stacking ensemble framework for genomic prediction: [https://pmc.ncbi.nlm.nih.gov/articles/PMC7969712/](https://pmc.ncbi.nlm.nih.gov/articles/PMC7969712/)
- Recent crop MoE genomic prediction example (MoEGP): [https://pmc.ncbi.nlm.nih.gov/articles/PMC12958669/](https://pmc.ncbi.nlm.nih.gov/articles/PMC12958669/)

## 3) What is specific in this repo (verified locally)

Implementation files:
- `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/24_run_loeo_meta_alpha_blend_yield.R`
- `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/26_run_loeo_meta_alpha_conservative_blend_yield.R`
- `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/28_validate_all_approaches_yield.R`

Explicit local equation in stage 24 script:
- `yhat = alpha_hat(e) * yhat_baseline + (1 - alpha_hat(e)) * gmean_shrunk`

Fold-matched validation outputs:
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/28_validation_all_approaches/28_summary_metrics.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/28_validation_all_approaches/28_paired_tests_vs_baseline.csv`

Observed means from local summary CSV:
- all-scope RMSE:
  - meta_alpha_blend: 34.092708
  - baseline: 34.390422
- seen_genotypes RMSE:
  - meta_alpha_blend: 34.419651
  - baseline: 34.850593

Interpretation:
- In this project, this blend gives the best average RMSE among tested complete LOEO models.
- Paired fold tests vs baseline were not strongly significant; claim should remain: **better average in this dataset/protocol**, not universal superiority.

## 4) Strict novelty verdict

- Claim allowed: this repository contributes a practical, validated configuration and audit of a stacking/blending idea for this specific GxE LOEO setting.
- Claim not allowed: “completely new in the world” or “new discovery of an unseen method class.”

## 5) Reproducibility checklist

1. Re-run stage 24:
   - `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/24_run_loeo_meta_alpha_blend_yield.R`
2. Re-run stage 26 (conservative variant):
   - `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/26_run_loeo_meta_alpha_conservative_blend_yield.R`
3. Re-run stage 28 for fold-matched aggregate validation:
   - `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/28_validate_all_approaches_yield.R`
4. Confirm metrics in:
   - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/28_validation_all_approaches/28_summary_metrics.csv`
