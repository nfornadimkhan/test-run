#!/usr/bin/env Rscript

suppressWarnings(suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(stringr)
}))

root <- getwd()
base_dir <- file.path(root, "analysis", "outputs", "prediction_yield", "external_validation", "run_queue")
in_dir <- file.path(base_dir, "118_priority_audit")
out_dir <- file.path(base_dir, "119_priority_evidence")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

manifest_path <- file.path(in_dir, "118_prior_manifest_expanded.csv")
if (!file.exists(manifest_path)) stop(sprintf("Missing input manifest: %s", manifest_path))

features <- c(
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

priors <- read_csv(manifest_path, show_col_types = FALSE)

long_tbl <- priors %>%
  pivot_longer(cols = all_of(features), names_to = "feature", values_to = "value") %>%
  mutate(
    value = case_when(
      is.na(value) ~ NA,
      value %in% c(TRUE, FALSE) ~ as.logical(value),
      TRUE ~ as.logical(value)
    ),
    evidence_source_type = NA_character_,
    evidence_locator = NA_character_,
    evidence_excerpt = NA_character_,
    coding_confidence = case_when(
      is.na(value) ~ "unknown",
      TRUE ~ "low"
    ),
    evidence_status = case_when(
      is.na(value) ~ "unknown_value",
      TRUE ~ "missing_evidence"
    ),
    coder_note = "Seeded from Stage-118 manifest; evidence citation still required"
  )

# Add minimal evidence where directly asserted by Stage-118 and title-level cues (still low confidence)
long_tbl <- long_tbl %>%
  mutate(
    evidence_source_type = ifelse(prior_id == "breiman_1996_stacked_regressions" & feature == "allows_negative_weights" & value == TRUE, "paper", evidence_source_type),
    evidence_locator = ifelse(prior_id == "breiman_1996_stacked_regressions" & feature == "allows_negative_weights" & value == TRUE, "stacked regression combination constraints discussion (manual note)", evidence_locator),
    evidence_excerpt = ifelse(prior_id == "breiman_1996_stacked_regressions" & feature == "allows_negative_weights" & value == TRUE, "Method family allows linear combinations beyond nonnegative simplex in common formulations.", evidence_excerpt),
    coding_confidence = ifelse(prior_id == "breiman_1996_stacked_regressions" & feature == "allows_negative_weights" & value == TRUE, "medium", coding_confidence),
    evidence_status = ifelse(prior_id == "breiman_1996_stacked_regressions" & feature == "allows_negative_weights" & value == TRUE, "evidenced", evidence_status),
    coder_note = ifelse(prior_id == "breiman_1996_stacked_regressions" & feature == "allows_negative_weights" & value == TRUE, "Seed evidence added; still should be replaced by exact section-level quote.", coder_note)
  )

qa_summary <- long_tbl %>%
  summarise(
    n_priors = n_distinct(prior_id),
    n_feature_rows = n(),
    n_evidenced = sum(evidence_status == "evidenced"),
    n_missing_evidence = sum(evidence_status == "missing_evidence"),
    n_unknown_value = sum(evidence_status == "unknown_value"),
    evidence_coverage_rate = round(n_evidenced / n_feature_rows, 4),
    known_value_rate = round(sum(!is.na(value)) / n_feature_rows, 4)
  )

prior_qa <- long_tbl %>%
  group_by(prior_id, year, title) %>%
  summarise(
    n_features = n(),
    n_evidenced = sum(evidence_status == "evidenced"),
    n_missing_evidence = sum(evidence_status == "missing_evidence"),
    n_unknown_value = sum(evidence_status == "unknown_value"),
    evidence_coverage_rate = round(n_evidenced / n_features, 4),
    .groups = "drop"
  ) %>%
  arrange(evidence_coverage_rate, desc(n_missing_evidence), prior_id)

feature_qa <- long_tbl %>%
  group_by(feature) %>%
  summarise(
    n_priors = n(),
    n_evidenced = sum(evidence_status == "evidenced"),
    n_missing_evidence = sum(evidence_status == "missing_evidence"),
    n_unknown_value = sum(evidence_status == "unknown_value"),
    evidence_coverage_rate = round(n_evidenced / n_priors, 4),
    .groups = "drop"
  ) %>%
  arrange(evidence_coverage_rate, desc(n_missing_evidence), feature)

write_csv(long_tbl, file.path(out_dir, "119_prior_feature_evidence_long.csv"))
write_csv(qa_summary, file.path(out_dir, "119_evidence_qa_summary.csv"))
write_csv(prior_qa, file.path(out_dir, "119_evidence_qa_by_prior.csv"))
write_csv(feature_qa, file.path(out_dir, "119_evidence_qa_by_feature.csv"))

cat("Stage 119 evidence-linked manifest + QA generated:\n")
cat(sprintf("- %s\n", file.path(out_dir, "119_prior_feature_evidence_long.csv")))
cat(sprintf("- %s\n", file.path(out_dir, "119_evidence_qa_summary.csv")))
cat(sprintf("- %s\n", file.path(out_dir, "119_evidence_qa_by_prior.csv")))
cat(sprintf("- %s\n", file.path(out_dir, "119_evidence_qa_by_feature.csv")))
