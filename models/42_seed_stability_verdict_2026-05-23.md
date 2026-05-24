# Stage 42 Seed-Stability Verdict (2026-05-23)

## Purpose

Assess whether the small numerical edge seen for the ranger+shift alpha model is stable across random seeds.

## Artifacts

- Script:
  - `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/42_seed_stability_ranger_alpha_yield.R`
- Outputs:
  - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/42_seed_stability_ranger_alpha/42_seed_stability_summary.csv`
  - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/42_seed_stability_ranger_alpha/42_seed_level_summary.csv`

Reference:
- stage-28 `meta_alpha_blend` RMSE (fixed benchmark)

## Key results (50 seeds each)

### ranger_shift vs meta_alpha_blend

- Scope `all`:
  - mean gain vs meta = `-0.029857` RMSE
  - 5th–95th percentile gain = `[-0.090649, 0.038492]`
  - probability of beating meta = `0.18`

- Scope `seen_genotypes`:
  - mean gain vs meta = `-0.035541` RMSE
  - 5th–95th percentile gain = `[-0.096807, 0.031616]`
  - probability of beating meta = `0.14`

### ranger_base vs meta_alpha_blend

- Always worse in both scopes (probability beat = `0.00`).

## Verdict

- The earlier tiny edge for ranger+shift is not seed-robust.
- Under repeated seeds, `meta_alpha_blend` remains the stronger default benchmark.
- Evidence supports using `meta_alpha_blend` as primary model and reporting ranger+shift only as a sensitivity variant.

