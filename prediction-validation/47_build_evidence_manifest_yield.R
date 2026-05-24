## -----------------------------------------------------------------------------
## Stage 47: Evidence manifest builder
##
## Creates a machine-readable manifest of key scripts/outputs/memos with:
## - existence flag
## - file size
## - SHA256 checksum
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/10_prediction_paths_and_helpers.R")

ensure_package("digest")
library(digest)

out_dir <- file.path(prediction_output_dir, "loeo_cv", "47_evidence_manifest")
ensure_dir(out_dir)

root <- "/Users/neon/Documents/Nadim's Brain"

targets <- c(
  "analysis/prediction-validation/24_run_loeo_meta_alpha_blend_yield.R",
  "analysis/prediction-validation/39_run_loeo_shift_aware_meta_blend_yield.R",
  "analysis/prediction-validation/40_run_loeo_alpha_model_search_yield.R",
  "analysis/prediction-validation/41_analyze_rmse_difference_uncertainty_yield.R",
  "analysis/prediction-validation/42_seed_stability_ranger_alpha_yield.R",
  "analysis/prediction-validation/43_select_robust_champion_yield.R",
  "analysis/outputs/prediction_yield/loeo_cv/28_validation_all_approaches/28_summary_metrics.csv",
  "analysis/outputs/prediction_yield/loeo_cv/40_alpha_model_search/40_alpha_model_search_summary_metrics.csv",
  "analysis/outputs/prediction_yield/loeo_cv/41_rmse_difference_uncertainty/41_rmse_difference_uncertainty.csv",
  "analysis/outputs/prediction_yield/loeo_cv/42_seed_stability_ranger_alpha/42_seed_stability_summary.csv",
  "analysis/outputs/prediction_yield/loeo_cv/43_robust_champion_selection/43_recommendation.csv",
  "analysis/models/44_master_evidence_index_and_repro_2026-05-23.md",
  "analysis/models/45_final_truth_statement_2026-05-23.md",
  "analysis/models/46_executive_summary_for_decision_2026-05-23.md"
)

rows <- lapply(targets, function(rel) {
  abs <- file.path(root, rel)
  exists <- file.exists(abs)
  size <- if (exists) file.info(abs)$size else NA
  sha <- if (exists) digest(abs, algo = "sha256", file = TRUE) else NA
  data.frame(
    path = abs,
    exists = exists,
    size_bytes = size,
    sha256 = sha,
    stringsAsFactors = FALSE
  )
})

manifest <- do.call(rbind, rows)
manifest$category <- ifelse(grepl("/analysis/prediction-validation/", manifest$path), "script",
                     ifelse(grepl("/analysis/outputs/", manifest$path), "output", "memo"))

write.csv(manifest, file.path(out_dir, "47_evidence_manifest.csv"), row.names = FALSE)

summary_df <- data.frame(
  total_targets = nrow(manifest),
  found_targets = sum(manifest$exists),
  missing_targets = sum(!manifest$exists),
  created_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  stringsAsFactors = FALSE
)
write.csv(summary_df, file.path(out_dir, "47_evidence_manifest_summary.csv"), row.names = FALSE)

message("Saved stage-47 evidence manifest.")
print(summary_df)
