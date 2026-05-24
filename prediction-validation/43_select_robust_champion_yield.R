## -----------------------------------------------------------------------------
## Stage 43: Robust champion selection audit
##
## Decision uses three gates:
## 1) Mean RMSE advantage (point estimate)
## 2) Paired-fold uncertainty vs meta_alpha_blend
## 3) Seed-stability probability of beating meta_alpha_blend
##
## Output is a reproducible recommendation artifact.
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/10_prediction_paths_and_helpers.R")

cv_dir <- file.path(prediction_output_dir, "loeo_cv")
out_dir <- file.path(cv_dir, "43_robust_champion_selection")
ensure_dir(out_dir)

s28 <- read.csv(file.path(cv_dir, "28_validation_all_approaches", "28_summary_metrics.csv"))
s40 <- read.csv(file.path(cv_dir, "40_alpha_model_search", "40_alpha_model_search_summary_metrics.csv"))
s41 <- read.csv(file.path(cv_dir, "41_rmse_difference_uncertainty", "41_rmse_difference_uncertainty.csv"))
s42 <- read.csv(file.path(cv_dir, "42_seed_stability_ranger_alpha", "42_seed_stability_summary.csv"))

meta <- s28[s28$model == "meta_alpha_blend", c("scope", "rmse", "correlation", "mspe", "mean_bias")]
names(meta)[2:5] <- c("meta_rmse", "meta_correlation", "meta_mspe", "meta_bias")

new <- s40[s40$model == "alpha_search_ranger_shift", c("scope", "rmse", "correlation", "mspe", "mean_bias")]
names(new)[2:5] <- c("new_rmse", "new_correlation", "new_mspe", "new_bias")

cmp <- merge(meta, new, by = "scope", all = TRUE)
cmp$point_gain_rmse <- cmp$meta_rmse - cmp$new_rmse

unc <- s41[, c("scope", "mean_gain_rmse", "boot_ci_low", "boot_ci_high", "t_pvalue", "wilcox_pvalue")]

stab <- s42[s42$model_type == "ranger_shift", c("scope", "prob_beat_meta_alpha_blend", "gain_vs_meta_mean", "gain_vs_meta_q05", "gain_vs_meta_q95")]

tab <- merge(cmp, unc, by = "scope", all = TRUE)
tab <- merge(tab, stab, by = "scope", all = TRUE)

# Decision thresholds (predefined for practical robustness)
min_point_gain <- 0.05
max_pvalue <- 0.10
min_seed_win_prob <- 0.60

tab$pass_point_gain <- tab$point_gain_rmse >= min_point_gain
tab$pass_uncertainty <- (tab$boot_ci_low > 0) & (tab$t_pvalue <= max_pvalue) & (tab$wilcox_pvalue <= max_pvalue)
tab$pass_seed_stability <- tab$prob_beat_meta_alpha_blend >= min_seed_win_prob
tab$pass_all <- tab$pass_point_gain & tab$pass_uncertainty & tab$pass_seed_stability

if (all(tab$pass_all)) {
  champion <- "alpha_search_ranger_shift"
  rationale <- "All robustness gates passed in both scopes."
} else {
  champion <- "meta_alpha_blend"
  rationale <- "Candidate failed at least one robustness gate; keep stable incumbent."
}

summary_out <- data.frame(
  recommendation = champion,
  rationale = rationale,
  min_point_gain_threshold = min_point_gain,
  max_pvalue_threshold = max_pvalue,
  min_seed_win_prob_threshold = min_seed_win_prob,
  stringsAsFactors = FALSE
)

write.csv(tab, file.path(out_dir, "43_selection_evidence_table.csv"), row.names = FALSE)
write.csv(summary_out, file.path(out_dir, "43_recommendation.csv"), row.names = FALSE)

message("Saved stage-43 robust champion selection outputs.")
print(summary_out)
print(tab)
