# Validation and Novelty Verdict (No-Hallucination)

Date: 2026-05-23

## Scope of validation

Validated against all **complete, fold-matched LOEO** approaches available in this repository:

- baseline
- baseline_ec
- rrr1
- rrr2
- rfr_us
- meta_alpha_blend
- meta_alpha_conservative

Validation script:
- `analysis/prediction-validation/28_validate_all_approaches_yield.R`

Outputs:
- `analysis/outputs/prediction_yield/loeo_cv/28_validation_all_approaches/28_summary_metrics.csv`
- `analysis/outputs/prediction_yield/loeo_cv/28_validation_all_approaches/28_paired_tests_vs_baseline.csv`
- `analysis/outputs/prediction_yield/loeo_cv/28_validation_all_approaches/28_model_coverage.csv`

## Empirical result

From fold-wise mean RMSE:

- **all**
  - meta_alpha_blend: `34.09271` (best)
  - meta_alpha_conservative: `34.30117`
  - baseline: `34.39042`
  - rrr/rfr/baseline_ec: around `39+` (worse)

- **seen_genotypes**
  - meta_alpha_blend: `34.41965` (best)
  - meta_alpha_conservative: `34.68580`
  - baseline: `34.85059`
  - rrr/rfr/baseline_ec: around `39+` (worse)

## Statistical caution

Paired fold tests vs baseline (22 LOEO folds) indicate:

- improvement direction is positive on mean RMSE for meta blends,
- but p-values are not small enough for strong significance claims.

Therefore:
- we can claim **best observed mean fold RMSE in this repository**,
- we cannot claim definitive universal superiority yet.

## Novelty verdict (global)

This is **not a globally new method**.

Reason:
- Environment-dependent blending/stacking of predictors is a known family in ML/statistics.
- Mixture-of-experts style gating is also established.

What is new here is **project-level contribution**:
- specific two-expert blend for this GxE pipeline,
- strict LOEO fold-wise implementation and comparison,
- robust tuning variants (conservative shrinkage).

## External references supporting non-novelty claim

- Wolpert, 1992 (stacked generalization):  
  https://yanpuli.github.io/files/stacking/Wolpert1992.pdf

- van der Laan et al., 2007 (Super Learner / stacking framework):  
  https://www.ovid.com/journals/sgmbio/abstract/10.2202/1544-6115.1309~super-learner

- Jacobs et al., 1991 (adaptive mixtures of experts):  
  https://direct.mit.edu/neco/article/3/1/79/5560/Adaptive-Mixtures-of-Local-Experts

## Final no-hallucination conclusion

1. **Yes**, we found a better-performing approach in this repository under fold-matched LOEO mean RMSE (`meta_alpha_blend`).
2. **No**, it is not a brand-new method in the world; it is a strong, context-adapted application of known ensemble/gating ideas.

