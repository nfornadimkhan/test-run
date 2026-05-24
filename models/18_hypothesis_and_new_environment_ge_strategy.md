# GxE for New Environment Prediction: Hypotheses and Better Mathematical Strategy

Date: 2026-05-23  
Scope: `analysis/outputs`, `analysis/models`, `analysis/prediction-validation`

## 1) Critical diagnosis of current pipeline

Current workflow is strong in structure (baseline, EC, RRR, RFR, FW + LOEO CV), but two issues block reliable scientific conclusions for **new-environment** prediction:

1. **Model comparison is currently incomplete**  
   `15_baseline_family_metrics.csv` contains only one LOEO fold (4 data rows + header), while `16_rrr_rfr_metrics.csv` contains many folds.  
   Therefore, current “RRR/RFR vs baseline” claims are not statistically valid yet.

2. **Pure LOEO still mixes two tasks**  
   Prediction rows include both:
   - seen genotypes in unseen environment (what you want for deployment),
   - effectively new genotype cases (without marker kernel support, much harder task).  
   This inflates variance and blurs interpretation unless scored separately and weighted.

## 2) Scientific hypotheses

### H1 (main)
Most transferable GxE signal for new environments is captured by a **low-rank reaction norm** driven by biologically timed ECs (stage-wise climate), not by full unstructured genotype-specific EC covariance.

### H2
Adding a **genomic relationship matrix** for genotype main effects and EC slopes improves prediction for sparse genotypes and stabilizes fold-to-fold behavior.

### H3
Using environment descriptors in a **kernel on environments** yields better extrapolation to new sites/years than fixed EC effects alone.

## 3) Proposed mathematically stronger model

Let observation \(y_{g,e,r}\) be yield of genotype \(g\) in environment \(e\) (plot/rep \(r\)).

```math
y_{g,e,r} = \mu + \mathbf{x}_{e}^{\top}\boldsymbol{\beta}
          + u_g + v_e
          + \sum_{k=1}^{K} \lambda_{gk} f_k(\mathbf{x}_e)
          + \epsilon_{g,e,r}
```

Where:
- \(\mathbf{x}_e\): standardized stage-wise EC vector for environment \(e\)
- \(u_g \sim \mathcal{N}(0,\sigma_u^2 K_G)\): genotype random effect with genomic kernel \(K_G\) (or identity if markers absent)
- \(v_e \sim \mathcal{N}(0,\sigma_v^2 K_E)\): environment random effect with environmental kernel \(K_E\)
- \(f_k(\mathbf{x}_e)\): latent environment factors (linear or nonlinear basis)
- \(\lambda_{gk} \sim \mathcal{N}(0,\tau_k^2 K_G)\): genotype sensitivities to latent factors
- \(\epsilon_{g,e,r} \sim \mathcal{N}(0,\sigma_e^2)\), optionally heteroscedastic by environment class

Equivalent matrix form:

```math
\mathbf{Y} = \mathbf{1}\mu + \mathbf{X}\boldsymbol{\beta}
           + \mathbf{U} + \mathbf{V}
           + \sum_{k=1}^{K}\mathbf{\Lambda}_k \mathbf{f}_k^{\top}
           + \mathbf{E}
```

Interpretation: this is a **kernelized factor-analytic reaction norm**, combining FA/RRR strengths with environment similarity and genomic borrowing.

## 4) Why this is better than current RRR/RFR-only setup

1. **Better extrapolation** to unseen environments through \(K_E\), not only fixed EC coefficients.
2. **Shrinkage on genotype sensitivities** through \(K_G\), reducing unstable slope estimates.
3. **Rank control \(K\)** keeps complexity aligned with data size; avoids RFR over-parameterization.
4. **Biological timing preserved** via stage-wise EC features, already built in your pipeline.

## 5) Validation protocol required before claiming improvement

1. Re-run Stage 15 fully (all LOEO folds) so baseline is comparable.
2. Keep separate metrics:
   - Seen genotype in unseen environment (primary deployment metric),
   - Truly unseen genotype (secondary challenge metric).
3. Add uncertainty metrics:
   - interval coverage,
   - CRPS or log-score (not RMSE/correlation only).
4. Use blocked repeated CV:
   - LOEO,
   - leave-one-year-out,
   - leave-one-location-out.
5. Compare models by fold-wise paired differences and confidence intervals.

## 6) Minimal implementation roadmap

1. Build \(K_E\) from stage-wise ECs (RBF or linear kernel after PCA/PLS denoising).  
2. If markers available, build \(K_G\); else start with identity and pedigree later.  
3. Fit FA reaction-norm ranks \(K=1..4\) with shrinkage priors/penalties.  
4. Select \(K\) by external CV (not AIC alone).  
5. Report fold-wise gains vs completed baseline.

## 7) Immediate decision

After completing LOEO baseline folds, current evidence is:

- baseline (no explicit EC fixed effects) has similar correlation but **much lower RMSE/MSPE** than baseline_ec, RRR1/2, and RFR.
- mean over LOEO folds (all rows):
  - baseline: corr 0.449, RMSE 34.39, MSPE 1329
  - baseline_ec: corr 0.449, RMSE 39.03, MSPE 1783
  - rrr1: corr 0.449, RMSE 39.13, MSPE 1793
  - rrr2: corr 0.449, RMSE 39.07, MSPE 1788
  - rfr_us: corr 0.450, RMSE 39.01, MSPE 1780

Interpretation:
- Added EC structures (as currently parameterized) are likely overfitting or mis-specified for out-of-environment prediction.
- Better approach remains: kernelized low-rank reaction norm with stronger shrinkage and environment similarity regularization.

Next strict step:
1. Run the Stage-18 kernel reaction-norm LOEO script and compare fold-wise against the completed baseline.
2. If no consistent fold-wise RMSE gain, keep baseline as deployment model and treat EC models as explanatory, not predictive.
