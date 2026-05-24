# Master Evidence Index and Repro Steps (2026-05-23)

## Final evidence-backed status

- Current operational champion: `meta_alpha_blend`
- Reason: alternatives did not show robust, reproducible superiority under fold uncertainty + seed stability checks.

## Core model formula (plain text)

`pred_hat(g,e) = alpha(e) * pred_baseline(g,e) + (1 - alpha(e)) * pred_gmean(g)`

## Primary implementation artifacts

- Stage 24 (meta alpha blend):
  - `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/24_run_loeo_meta_alpha_blend_yield.R`
- Stage 39 (shift-aware extension):
  - `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/39_run_loeo_shift_aware_meta_blend_yield.R`
- Stage 40 (alpha-model search):
  - `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/40_run_loeo_alpha_model_search_yield.R`
- Stage 41 (paired + bootstrap uncertainty):
  - `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/41_analyze_rmse_difference_uncertainty_yield.R`
- Stage 42 (seed stability):
  - `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/42_seed_stability_ranger_alpha_yield.R`
- Stage 43 (robust champion selector):
  - `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/43_select_robust_champion_yield.R`

## Key result files

- Fold-matched baseline + meta benchmark:
  - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/28_validation_all_approaches/28_summary_metrics.csv`
  - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/28_validation_all_approaches/28_paired_tests_vs_baseline.csv`
- Stage 39:
  - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/39_shift_aware_meta_blend/39_shift_aware_meta_summary_metrics.csv`
- Stage 40:
  - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/40_alpha_model_search/40_alpha_model_search_summary_metrics.csv`
  - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/40_alpha_model_search/40_alpha_model_search_metrics_by_fold.csv`
- Stage 41:
  - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/41_rmse_difference_uncertainty/41_rmse_difference_uncertainty.csv`
- Stage 42:
  - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/42_seed_stability_ranger_alpha/42_seed_stability_summary.csv`
  - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/42_seed_stability_ranger_alpha/42_seed_level_summary.csv`
- Stage 43:
  - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/43_robust_champion_selection/43_selection_evidence_table.csv`
  - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/43_robust_champion_selection/43_recommendation.csv`

## Decision memos

- Novelty/provenance:
  - `/Users/neon/Documents/Nadim's Brain/analysis/models/34_meta_alpha_blend_provenance_and_evidence_2026-05-23.md`
  - `/Users/neon/Documents/Nadim's Brain/analysis/models/35_claim_audit_matrix_meta_alpha_blend_2026-05-23.md`
  - `/Users/neon/Documents/Nadim's Brain/analysis/models/36_exact_overlap_search_meta_alpha_2026-05-23.md`
  - `/Users/neon/Documents/Nadim's Brain/analysis/models/37_reproducible_novelty_search_protocol_2026-05-23.md`
- Model progression:
  - `/Users/neon/Documents/Nadim's Brain/analysis/models/39_shift_aware_meta_blend_first_run_results_2026-05-23.md`
  - `/Users/neon/Documents/Nadim's Brain/analysis/models/40_alpha_model_search_results_2026-05-23.md`
  - `/Users/neon/Documents/Nadim's Brain/analysis/models/41_uncertainty_verdict_on_top2_blends_2026-05-23.md`
  - `/Users/neon/Documents/Nadim's Brain/analysis/models/42_seed_stability_verdict_2026-05-23.md`
  - `/Users/neon/Documents/Nadim's Brain/analysis/models/43_robust_champion_selection_verdict_2026-05-23.md`

## Repro commands (in order)

```bash
Rscript /Users/neon/Documents/Nadim's\ Brain/analysis/prediction-validation/24_run_loeo_meta_alpha_blend_yield.R
Rscript /Users/neon/Documents/Nadim's\ Brain/analysis/prediction-validation/39_run_loeo_shift_aware_meta_blend_yield.R
Rscript /Users/neon/Documents/Nadim's\ Brain/analysis/prediction-validation/40_run_loeo_alpha_model_search_yield.R
Rscript /Users/neon/Documents/Nadim's\ Brain/analysis/prediction-validation/41_analyze_rmse_difference_uncertainty_yield.R
Rscript /Users/neon/Documents/Nadim's\ Brain/analysis/prediction-validation/42_seed_stability_ranger_alpha_yield.R
Rscript /Users/neon/Documents/Nadim's\ Brain/analysis/prediction-validation/43_select_robust_champion_yield.R
```

## Strict claim boundary

- Supported:
  - `meta_alpha_blend` is the strongest robust choice in this repository as of 2026-05-23.
  - Some variants can show tiny point-estimate improvements, but these were not robust under uncertainty and seed stability checks.
- Not supported:
  - global “completely new in the world” claim.
  - universal superiority claim across datasets/environments.

