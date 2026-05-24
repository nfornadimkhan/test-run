#!/usr/bin/env Rscript

suppressWarnings(suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(purrr)
  library(stringr)
  library(tidyr)
}))

root <- getwd()
in_dir <- file.path(root, "analysis", "outputs", "prediction_yield", "external_validation", "run_queue", "118_priority_audit")
out_dir <- in_dir
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

manifest_path <- file.path(in_dir, "118_prior_manifest_expanded.csv")
if (!file.exists(manifest_path)) {
  stop(sprintf("Missing manifest: %s", manifest_path))
}

prior_manifest <- read_csv(manifest_path, show_col_types = FALSE)

feature_cols <- c(
  "has_fixed_global_weights",
  "weights_exact_080_025_m005",
  "allows_negative_weights",
  "uses_only_3_experts_global_geno_marker",
  "requires_both_scopes_all_and_seen",
  "gate_requires_mean_gain_nonneg",
  "gate_requires_one_sided_t_le_005",
  "gate_requires_boot_prob_ge_095",
  "requires_all4_registered_datasets_pass",
  "includes_seed_robustness_layer",
  "includes_independent_rebuild_layer",
  "includes_train_label_permutation_falsification"
)

missing_cols <- setdiff(c("prior_id", "year", "title", "url", feature_cols), names(prior_manifest))
if (length(missing_cols) > 0) {
  stop(sprintf("Manifest missing required columns: %s", paste(missing_cols, collapse = ", ")))
}

# Project signature (ground truth for claimed method/protocol)
project_vec <- c(
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

score_one <- function(row_df) {
  known_matches <- 0
  known_mismatches <- 0
  unknown_count <- 0
  weighted_known_match <- 0
  weighted_known_total <- 0
  weighted_optimistic_match <- 0

  for (f in feature_cols) {
    val <- row_df[[f]][[1]]
    target <- as.logical(project_vec[[f]])
    w <- weights[[f]]

    if (is.na(val)) {
      unknown_count <- unknown_count + 1
      weighted_optimistic_match <- weighted_optimistic_match + w
    } else {
      weighted_known_total <- weighted_known_total + w
      if (isTRUE(as.logical(val) == target)) {
        known_matches <- known_matches + 1
        weighted_known_match <- weighted_known_match + w
        weighted_optimistic_match <- weighted_optimistic_match + w
      } else {
        known_mismatches <- known_mismatches + 1
      }
    }
  }

  weighted_total <- sum(weights)
  known_similarity <- ifelse(weighted_known_total > 0, weighted_known_match / weighted_known_total, NA_real_)
  optimistic_similarity <- weighted_optimistic_match / weighted_total

  exact_match_proven <- (known_mismatches == 0) && (unknown_count == 0) && (known_matches == length(feature_cols))
  exact_match_possible <- (known_mismatches == 0)

  risk_band <- if (exact_match_proven) {
    "HIGH"
  } else if (optimistic_similarity >= 0.80) {
    "MEDIUM"
  } else if (optimistic_similarity >= 0.50) {
    "LOW"
  } else {
    "VERY_LOW"
  }

  row_df %>% mutate(
    n_features = length(feature_cols),
    known_matches = known_matches,
    known_mismatches = known_mismatches,
    unknown_features = unknown_count,
    weighted_known_match = weighted_known_match,
    weighted_known_total = weighted_known_total,
    known_similarity = known_similarity,
    optimistic_similarity = optimistic_similarity,
    exact_match_proven = exact_match_proven,
    exact_match_possible = exact_match_possible,
    exact_match_risk_band = risk_band
  )
}

scored <- bind_rows(lapply(seq_len(nrow(prior_manifest)), function(i) score_one(prior_manifest[i, , drop = FALSE]))) %>%
  arrange(desc(optimistic_similarity), desc(known_similarity), prior_id)

summary_tbl <- tibble(
  n_priors = nrow(scored),
  n_exact_match_proven = sum(scored$exact_match_proven, na.rm = TRUE),
  n_exact_match_possible = sum(scored$exact_match_possible, na.rm = TRUE),
  best_optimistic_similarity = max(scored$optimistic_similarity, na.rm = TRUE),
  best_optimistic_prior_id = scored$prior_id[[which.max(scored$optimistic_similarity)]],
  bounded_novelty_supported_if_strict = (sum(scored$exact_match_proven, na.rm = TRUE) == 0),
  bounded_novelty_supported_if_conservative = (sum(scored$exact_match_possible, na.rm = TRUE) == 0)
)

write_csv(scored, file.path(out_dir, "118_priority_similarity_scores_expanded.csv"))
write_csv(summary_tbl, file.path(out_dir, "118_priority_summary_expanded.csv"))

cat("Stage 118 priority audit generated:\n")
cat(sprintf("- %s\n", file.path(out_dir, "118_priority_similarity_scores_expanded.csv")))
cat(sprintf("- %s\n", file.path(out_dir, "118_priority_summary_expanded.csv")))
