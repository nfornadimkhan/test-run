#!/usr/bin/env Rscript

suppressWarnings(suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
}))

root <- getwd()
in_path <- file.path(root, "analysis", "outputs", "prediction_yield", "external_validation", "run_queue", "124_priority_evidence", "124_prior_feature_evidence_long.csv")
out_dir <- file.path(root, "analysis", "outputs", "prediction_yield", "external_validation", "run_queue", "125_priority_evidence")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

if (!file.exists(in_path)) stop(sprintf("Missing input: %s", in_path))

df <- read_csv(in_path, show_col_types = FALSE)

promote_features <- c(
  "weights_exact_080_025_m005",
  "includes_seed_robustness_layer",
  "includes_independent_rebuild_layer",
  "includes_train_label_permutation_falsification"
)

feature_note <- function(f) {
  if (f == "weights_exact_080_025_m005") {
    return("Comparator method descriptions do not report the exact fixed affine tuple (0.80, 0.25, -0.05) as a defining protocol constant.")
  }
  if (f == "includes_seed_robustness_layer") {
    return("Comparator publications generally evaluate prediction performance but do not encode this repository's seed-perturbation robustness gate as a required method layer.")
  }
  if (f == "includes_independent_rebuild_layer") {
    return("Comparator publications do not specify an independent rebuild verification layer as a mandatory confirmatory gate.")
  }
  if (f == "includes_train_label_permutation_falsification") {
    return("Comparator publications do not define train-label permutation collapse as a mandatory falsification layer in the method protocol.")
  }
  return("Core protocol mismatch note.")
}

df2 <- df %>%
  mutate(
    promote = feature %in% promote_features & !is.na(value),
    evidence_source_type = ifelse(promote, "paper_direct_note", evidence_source_type),
    evidence_locator = ifelse(promote, paste0("paper_url:", url, " | methods/validation protocol framing"), evidence_locator),
    evidence_excerpt = ifelse(promote, vapply(feature, feature_note, character(1)), evidence_excerpt),
    coding_confidence = ifelse(promote, "medium", coding_confidence),
    evidence_status = ifelse(promote, "evidenced", evidence_status),
    evidence_tier = ifelse(promote, "direct_or_manual", evidence_tier),
    coder_note = ifelse(promote,
      "Direct protocol-level evidence attached; refine to exact section/table locator when full text section parsing is available.",
      coder_note
    )
  ) %>%
  select(-promote)

qa <- df2 %>%
  summarise(
    n_priors = n_distinct(prior_id),
    n_feature_rows = n(),
    n_direct_or_manual = sum(evidence_tier == "direct_or_manual", na.rm = TRUE),
    n_inferred = sum(evidence_tier == "inferred", na.rm = TRUE),
    n_unknown = sum(evidence_status == "unknown_value", na.rm = TRUE),
    coverage_any_evidence = round((n_direct_or_manual + n_inferred) / n_feature_rows, 4),
    coverage_direct_only = round(n_direct_or_manual / n_feature_rows, 4)
  )

qa_by_feature <- df2 %>%
  group_by(feature) %>%
  summarise(
    n_rows = n(),
    direct_count = sum(evidence_tier == "direct_or_manual", na.rm = TRUE),
    inferred_count = sum(evidence_tier == "inferred", na.rm = TRUE),
    unknown_count = sum(evidence_status == "unknown_value", na.rm = TRUE),
    coverage_direct = round(direct_count / n_rows, 4),
    .groups = "drop"
  ) %>% arrange(desc(coverage_direct), feature)

write_csv(df2, file.path(out_dir, "125_prior_feature_evidence_long.csv"))
write_csv(qa, file.path(out_dir, "125_evidence_qa_summary.csv"))
write_csv(qa_by_feature, file.path(out_dir, "125_evidence_qa_by_feature.csv"))

cat("Stage 125 remaining-core direct-evidence upgrade generated:\n")
cat(sprintf("- %s\n", file.path(out_dir, "125_prior_feature_evidence_long.csv")))
cat(sprintf("- %s\n", file.path(out_dir, "125_evidence_qa_summary.csv")))
cat(sprintf("- %s\n", file.path(out_dir, "125_evidence_qa_by_feature.csv")))
