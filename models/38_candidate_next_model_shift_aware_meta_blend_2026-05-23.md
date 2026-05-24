# Candidate Next Model (Hypothesis Only): Shift-Aware Meta-Blend

## Why this document exists

Current evidence shows:
- `meta_alpha_blend` improves mean RMSE over baseline in this repo.
- method family overlap exists (stacking / MoE); global novelty claim is not supportable.

Goal now: define a stronger **testable** model idea for new environments without claiming novelty prematurely.

## Candidate model definition

Base prediction:
- `b(g,e)` = baseline mixed-model prediction
- `m(g)` = shrunk genotype historical mean

Shift score (environment-level):
- `s(e)` = standardized domain-shift index between train environments and target environment using EC features.
- Example: Mahalanobis distance in EC space + optional calibration terms.

Environment gating:
- `alpha(e) = sigmoid( w0 + w1*z_base(e) + w2*z_var(e) + w3*s(e) )`
- where `z_base(e)` can include fold-level baseline diagnostics (mean/sd prediction, error proxy).

Prediction:
- `yhat(g,e) = alpha(e)*b(g,e) + (1-alpha(e))*m(g)`

Uncertainty layer (conformal on residuals):
- fit residual model on outer-train folds
- produce interval: `[yhat - q_{1-delta}(e), yhat + q_{1-delta}(e)]`
- with `q_{1-delta}(e)` calibrated by similar-shift environments (or weighted conformal).

## What is likely new vs known (status)

Known from prior art (supported):
- stacking/meta-learning in genomic prediction
- MoE-style gating in crop genomic prediction
- uncertainty-aware ML and conformal under shift in broader domains

Potentially distinctive in this repo (UNVERIFIED):
- combining:
  1) baseline-vs-genotype-history convex blend,
  2) explicit EC shift score in gating,
  3) LOEO-calibrated conformal uncertainty for MET prediction
  
This is a **candidate differentiation hypothesis**, not a novelty claim.

## Evidence anchors for known components

- BMORS stacking in plant breeding:
  - https://pmc.ncbi.nlm.nih.gov/articles/PMC6778812/
- learnMET stacking in CV0/LOEO contexts:
  - https://cjubin.github.io/learnMET/articles/vignette_cv_stacking_indica.html
  - https://rdrr.io/github/cjubin/learnMET/src/R/predict_trait_MET_cv.R
- MoE in crop genomic prediction:
  - https://pmc.ncbi.nlm.nih.gov/articles/PMC12958669/
- Recent stacking ensemble genomic prediction:
  - https://www.mdpi.com/2073-4395/16/2/241
- Conformal under shift (general ML / biomolecular):
  - https://pubmed.ncbi.nlm.nih.gov/36256807/

## Minimal validation protocol in this repo

1. Keep current outer LOEO folds exactly unchanged.
2. For each held-out environment:
   - compute EC shift score `s(e)` from training environments only.
   - fit gating model on other folds only (strict no leakage).
   - generate `yhat(g,e)`.
3. Evaluate:
   - RMSE/correlation/bias (as in stage 28)
   - paired fold tests vs baseline and vs `meta_alpha_blend`
4. For uncertainty:
   - report empirical coverage at 80% and 90%
   - report interval width and conditional coverage vs shift bins.

## Success criteria (pre-registered style)

- Point prediction:
  - lower mean RMSE than `meta_alpha_blend` on both `all` and `seen_genotypes`
  - non-trivial win rate (>0.5) across LOEO folds
- Uncertainty:
  - coverage close to nominal in high-shift folds without exploding interval width

If these fail, retain current `meta_alpha_blend` as operational best.

