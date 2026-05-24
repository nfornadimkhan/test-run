# Claim Audit Matrix: `meta_alpha_blend` (2026-05-23)

Purpose: prevent hallucination by separating what is directly evidenced from what is not.

## A) Claims that are PROVEN by local repository evidence

1. Claim: The implemented predictor uses an environment-specific convex blend of baseline and genotype-mean components.
- Status: PROVEN
- Evidence:
  - `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/24_run_loeo_meta_alpha_blend_yield.R:9`
  - `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/24_run_loeo_meta_alpha_blend_yield.R:112`

2. Claim: The blend weight is clipped to [0, 1].
- Status: PROVEN
- Evidence:
  - `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/24_run_loeo_meta_alpha_blend_yield.R:100`

3. Claim: On current fold-matched LOEO summary, `meta_alpha_blend` has lower mean RMSE than baseline.
- Status: PROVEN
- Evidence:
  - all: 34.092708 vs 34.390422
  - seen_genotypes: 34.419651 vs 34.850593
  - Source: `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/28_validation_all_approaches/28_summary_metrics.csv:2`
  - Source: `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/28_validation_all_approaches/28_summary_metrics.csv:4`
  - Source: `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/28_validation_all_approaches/28_summary_metrics.csv:9`
  - Source: `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/28_validation_all_approaches/28_summary_metrics.csv:11`

4. Claim: Paired fold tests do not show strong significance for `meta_alpha_blend` gain vs baseline.
- Status: PROVEN
- Evidence:
  - all: t p = 0.7095, wilcox p = 0.7951
  - seen_genotypes: t p = 0.6046, wilcox p = 0.8710
  - Source: `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/28_validation_all_approaches/28_paired_tests_vs_baseline.csv:2`
  - Source: `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/28_validation_all_approaches/28_paired_tests_vs_baseline.csv:8`

## B) Claims that are SUPPORTED by internet prior-art evidence

1. Claim: Stacking/meta-learner methods are established in genomic prediction and MET/CV0 workflows.
- Status: SUPPORTED
- Evidence:
  - learnMET documentation includes stacked models and CV0 leave-one-environment-out modes:
    - https://rdrr.io/github/cjubin/learnMET/src/R/predict_trait_MET_cv.R
    - https://cjubin.github.io/learnMET/articles/vignette_cv_stacking_indica.html
  - BMORS describes two-stage stacking in breeding:
    - https://pmc.ncbi.nlm.nih.gov/articles/PMC6778812/
  - General stacking and mixture-of-experts foundations:
    - https://doi.org/10.2202/1544-6115.1309
    - https://doi.org/10.1162/neco.1991.3.1.79

## C) Claims that are NOT PROVABLE from current evidence

1. Claim: “This method is completely new in the world.”
- Status: NOT PROVABLE / DISALLOWED
- Why: global non-existence cannot be established from finite search; existing method family overlap is documented.

2. Claim: “`meta_alpha_blend` is universally better than baseline for all target environments.”
- Status: NOT PROVABLE / DISALLOWED
- Why: average RMSE improved, but paired tests are not strongly significant.

## D) Safe wording template for publication/reporting

- “In this dataset and LOEO protocol, an environment-conditioned convex blend of baseline and genotype-history predictors achieved the best mean RMSE among evaluated complete models, but fold-level significance versus baseline was weak; therefore we report a dataset-specific improvement rather than a universal superiority claim.”

