# Exact-Overlap Search Note for `meta_alpha_blend` (2026-05-23)

## Scope of this search

Question tested:
- Is there a directly matching published formulation in GxE prediction equivalent to:
  - `pred_hat(g,e) = alpha(e)*pred_baseline(g,e) + (1-alpha(e))*pred_gmean(g)` ?

Search focus:
- LOEO/CV0 genomic prediction literature
- stacking/meta-learner frameworks for MET
- mixture-of-experts gating in crop genomic prediction

## Outcome summary

- **Exact symbolic/formula match in audited sources:** NOT FOUND.
- **Near-overlap / family-level matches:** FOUND.
- Therefore, the safe claim is:
  - “No exact match found in the audited set as of 2026-05-23; method lies in established stacking/MoE families.”

## Overlap matrix

1. Source: learnMET CV0 stacking docs
- URL: https://cjubin.github.io/learnMET/articles/vignette_cv_stacking_indica.html
- URL: https://rdrr.io/github/cjubin/learnMET/src/R/predict_trait_MET_cv.R
- Overlap type: FAMILY-LEVEL
- Why: shows stacked models in CV0 including leave-one-environment-out, but not this exact two-component convex formula.

2. Source: BMORS (Bayesian multi-output regressor stacking)
- URL: https://pmc.ncbi.nlm.nih.gov/articles/PMC6778812/
- Overlap type: FAMILY-LEVEL
- Why: two-stage stacking in plant breeding; different architecture/targets than this exact blend.

3. Source: MoEGP (mixture of experts for crop genomic prediction)
- URL: https://pmc.ncbi.nlm.nih.gov/articles/PMC12958669/
- Overlap type: NEAR
- Why: explicit gating weights combine expert predictions (conceptually close to environment-conditioned alpha weighting), but deep-network MoE is structurally different from current implementation.

4. Source: Super Learner / Stacking theory
- URL: https://doi.org/10.2202/1544-6115.1309
- Overlap type: FAMILY-LEVEL
- Why: convex/meta combination of base learners is established generally.

5. Source: Adaptive mixtures of experts
- URL: https://doi.org/10.1162/neco.1991.3.1.79
- Overlap type: FAMILY-LEVEL
- Why: gating-weighted expert combination is foundational prior art.

## Local implementation anchor (for comparison)

- `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/24_run_loeo_meta_alpha_blend_yield.R:9`
- `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/24_run_loeo_meta_alpha_blend_yield.R:112`

## Claim discipline

Allowed:
- “Dataset-specific validated improvement under this LOEO protocol.”
- “Belongs to known stacking/MoE family.”
- “No exact audited match found in this search set.”

Not allowed:
- “Completely new in the world.”
- “No prior art exists.”

