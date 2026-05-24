# Stage 43 Robust Champion Selection Verdict (2026-05-23)

## Artifacts

- Script:
  - `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/43_select_robust_champion_yield.R`
- Evidence table:
  - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/43_robust_champion_selection/43_selection_evidence_table.csv`
- Recommendation file:
  - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/43_robust_champion_selection/43_recommendation.csv`

## Decision rule

Candidate `alpha_search_ranger_shift` must pass all gates in both scopes:

1. Point-gain gate:
   - `meta_rmse - candidate_rmse >= 0.05`
2. Uncertainty gate:
   - bootstrap lower CI of gain `> 0`
   - paired `t` and Wilcoxon `p <= 0.10`
3. Seed-stability gate:
   - probability(candidate beats meta) `>= 0.60`

## Result

- Recommended champion: `meta_alpha_blend`
- Why:
  - Candidate point gains are tiny (`0.00418` and `0.000085`) and below threshold.
  - Uncertainty intervals include zero and paired tests are not significant.
  - Seed win probability is low (`0.18` and `0.14`), far below stability threshold.

## Practical interpretation

The alternative ranger+shift variant occasionally wins but does not show robust, reproducible superiority. Current evidence supports retaining `meta_alpha_blend` as the operational model.

