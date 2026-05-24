# Stage 57 Directional Significance Verdict (2026-05-23)

## Artifacts

- Script:
  - `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/57_directional_significance_audit_stage54_yield.R`
- Output:
  - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/57_directional_significance_audit/57_directional_significance_summary.csv`

## Directional audit results (stage-54 vs meta_alpha_blend)

### Scope: all

- mean RMSE gain: `1.153965`
- one-sided t-test p: `0.04649` (passes 0.05)
- one-sided permutation p: `0.04658` (passes 0.05)
- one-sided Wilcoxon p: `0.05583` (borderline)
- bootstrap P(gain > 0): `0.96386`

### Scope: seen_genotypes

- mean RMSE gain: `1.098221`
- one-sided t-test p: `0.05556` (just above 0.05)
- one-sided permutation p: `0.05522` (just above 0.05)
- one-sided Wilcoxon p: `0.07201`
- bootstrap P(gain > 0): `0.95624`

## Gate interpretation

- Strong directional evidence of improvement exists in both scopes.
- Strict alpha=0.05 gate is fully passed in `all` and narrowly missed in `seen_genotypes`.
- Therefore, a strict “world-first discovery proven” claim is still not yet defensible.

## Practical status

- This is currently the strongest candidate in the project.
- Next step should target variance reduction or additional replicated validation so that `seen_genotypes` crosses strict significance thresholds.

