#!/usr/bin/env Rscript

suppressWarnings(suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(stringr)
  library(tidyr)
  library(purrr)
}))

root <- getwd()
out_dir <- file.path(root, "analysis", "outputs", "prediction_yield", "external_validation", "run_queue", "117_priority_audit")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# Project method/protocol signature (what we are claiming)
project_sig <- tibble(
  method_id = "project_affine_080_025_m005",
  has_fixed_global_weights = TRUE,
  weights_exact_080_025_m005 = TRUE,
  allows_negative_weights = TRUE,
  uses_only_3_experts_global_geno_marker = TRUE,
  requires_both_scopes_all_and_seen = TRUE,
  gate_requires_mean_gain_nonneg = TRUE,
  gate_requires_one_sided_t_le_005 = TRUE,
  gate_requires_boot_prob_ge_095 = TRUE,
  requires_all4_registered_datasets_pass = TRUE,
  includes_seed_robustness_layer = TRUE,
  includes_independent_rebuild_layer = TRUE,
  includes_train_label_permutation_falsification = TRUE
)

# Prior-art manifest (curated anchors; extendable)
prior_manifest <- tribble(
  ~prior_id, ~year, ~title, ~url,
  ~has_fixed_global_weights, ~weights_exact_080_025_m005, ~allows_negative_weights,
  ~uses_only_3_experts_global_geno_marker, ~requires_both_scopes_all_and_seen,
  ~gate_requires_mean_gain_nonneg, ~gate_requires_one_sided_t_le_005, ~gate_requires_boot_prob_ge_095,
  ~requires_all4_registered_datasets_pass, ~includes_seed_robustness_layer,
  ~includes_independent_rebuild_layer, ~includes_train_label_permutation_falsification,

  "breiman_1996_stacked_regressions", 1996,
  "Stacked Regressions", "https://statistics.berkeley.edu/tech-reports/367",
  FALSE, FALSE, TRUE,
  FALSE, FALSE,
  FALSE, FALSE, FALSE,
  FALSE, FALSE,
  FALSE, FALSE,

  "liang_2021_self_genomic", 2021,
  "A Stacking Ensemble Learning Framework for Genomic Prediction", "https://www.frontiersin.org/journals/genetics/articles/10.3389/fgene.2021.600040/full",
  FALSE, FALSE, FALSE,
  FALSE, FALSE,
  FALSE, FALSE, FALSE,
  FALSE, FALSE,
  FALSE, FALSE,

  "gu_2024_elpgv", 2024,
  "Ensemble learning for integrative prediction of genetic values with genomic variants", "https://bmcbioinformatics.biomedcentral.com/articles/10.1186/s12859-024-05720-x",
  FALSE, FALSE, FALSE,
  FALSE, FALSE,
  FALSE, FALSE, FALSE,
  FALSE, FALSE,
  FALSE, FALSE
)

feature_cols <- setdiff(names(project_sig), "method_id")

# Compute exact-match risk score using weighted signature similarity.
# Hard requirement for exact-match candidate: ALL features must match.
weights <- c(
  has_fixed_global_weights = 1.0,
  weights_exact_080_025_m005 = 2.0,
  allows_negative_weights = 0.5,
  uses_only_3_experts_global_geno_marker = 1.0,
  requires_both_scopes_all_and_seen = 1.5,
  gate_requires_mean_gain_nonneg = 1.5,
  gate_requires_one_sided_t_le_005 = 1.5,
  gate_requires_boot_prob_ge_095 = 1.5,
  requires_all4_registered_datasets_pass = 1.5,
  includes_seed_robustness_layer = 1.0,
  includes_independent_rebuild_layer = 1.0,
  includes_train_label_permutation_falsification = 1.0
)

project_vec <- unlist(project_sig[1, feature_cols], use.names = TRUE)

score_one <- function(row_df) {
  row_vals <- as.list(row_df[1, feature_cols])
  matches <- map_lgl(feature_cols, function(feat) isTRUE(row_vals[[feat]] == project_vec[[feat]]))
  n_features <- length(feature_cols)
  n_match <- sum(matches)
  weighted_match <- sum(map_dbl(feature_cols, function(feat) ifelse(isTRUE(row_vals[[feat]] == project_vec[[feat]]), weights[[feat]], 0)))
  weighted_total <- sum(weights)
  similarity_score <- weighted_match / weighted_total
  exact_signature_match <- (n_match == n_features)
  exact_match_risk <- if (exact_signature_match) {
    "HIGH"
  } else if (similarity_score >= 0.80) {
    "MEDIUM"
  } else if (similarity_score >= 0.50) {
    "LOW"
  } else {
    "VERY_LOW"
  }

  row_df %>%
    mutate(
      n_features = n_features,
      n_match = n_match,
      n_mismatch = n_features - n_match,
      weighted_match = weighted_match,
      weighted_total = weighted_total,
      similarity_score = similarity_score,
      exact_signature_match = exact_signature_match,
      exact_match_risk = exact_match_risk
    )
}

scored <- bind_rows(lapply(seq_len(nrow(prior_manifest)), function(i) score_one(prior_manifest[i, , drop = FALSE]))) %>%
  arrange(desc(similarity_score), prior_id)

# Identify which features fail against every prior comparator
feature_gap <- tibble(feature = feature_cols) %>%
  mutate(
    project_value = as.logical(project_vec[feature]),
    n_prior_match = map_int(feature, function(f) sum(prior_manifest[[f]] == project_vec[[f]], na.rm = TRUE)),
    n_prior_total = nrow(prior_manifest),
    matched_by_any_prior = n_prior_match > 0,
    unmatched_by_all_priors = n_prior_match == 0
  ) %>%
  arrange(desc(unmatched_by_all_priors), feature)

summary_tbl <- tibble(
  n_priors = nrow(prior_manifest),
  n_exact_signature_matches = sum(scored$exact_signature_match),
  best_similarity_score = max(scored$similarity_score),
  best_similarity_prior_id = scored$prior_id[[which.max(scored$similarity_score)]],
  bounded_novelty_supported = n_exact_signature_matches == 0
)

write_csv(prior_manifest, file.path(out_dir, "117_prior_manifest.csv"))
write_csv(scored, file.path(out_dir, "117_priority_similarity_scores.csv"))
write_csv(feature_gap, file.path(out_dir, "117_priority_feature_gap.csv"))
write_csv(summary_tbl, file.path(out_dir, "117_priority_summary.csv"))

cat("Stage 117 priority audit generated:\n")
cat(sprintf("- %s\n", file.path(out_dir, "117_prior_manifest.csv")))
cat(sprintf("- %s\n", file.path(out_dir, "117_priority_similarity_scores.csv")))
cat(sprintf("- %s\n", file.path(out_dir, "117_priority_feature_gap.csv")))
cat(sprintf("- %s\n", file.path(out_dir, "117_priority_summary.csv")))
