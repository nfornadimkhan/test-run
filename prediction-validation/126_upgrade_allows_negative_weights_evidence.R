#!/usr/bin/env Rscript

suppressWarnings(suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
}))

root <- getwd()
in_path <- file.path(root, "analysis", "outputs", "prediction_yield", "external_validation", "run_queue", "125_priority_evidence", "125_prior_feature_evidence_long.csv")
out_dir <- file.path(root, "analysis", "outputs", "prediction_yield", "external_validation", "run_queue", "126_priority_evidence")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

if (!file.exists(in_path)) stop(sprintf("Missing input: %s", in_path))

df <- read_csv(in_path, show_col_types = FALSE)

# Comparator-specific updates for allows_negative_weights.
# We avoid forcing certainty where evidence remains ambiguous.
updates <- tribble(
  ~prior_id, ~value_new, ~evidence_locator, ~evidence_excerpt, ~confidence,
  "vdl_2007_super_learner", FALSE, "Stat Appl Genet Mol Biol (2007) Super Learner method overview", "Super Learner is commonly presented with convex-combination style meta-learning over candidate learners in this framework context.", "medium",
  "polley_vdl_2010_superlearner_chapter", FALSE, "Super Learner in Prediction chapter", "Super Learner exposition emphasizes weighted combinations over learner library under cross-validation-based risk minimization.", "medium",
  "de_los_campos_2024_diverse_ensembles", FALSE, "Improved genomic prediction with ensembles of diverse models, methods framing", "Ensemble averaging/combination is presented without project-specific negative-weight protocol requirement.", "low",
  "enbayes_2025_constraint_weights", FALSE, "EnBayes abstract/method summary", "Constraint weight optimization is described for ensemble weights; does not indicate project-style signed fixed tuple usage.", "low",
  "uubens_2025_obscured_ensembles", FALSE, "Obscured-ensemble methods summary", "Obscured ensemble formulation does not present negative affine fixed-tuple protocol as defining requirement.", "low",
  "weighted_kernels_2022", FALSE, "Weighted kernels multi-environment GP method description", "Kernel weighting framework is distinct and does not describe project-style signed affine expert weights.", "low"
)

key <- updates %>% mutate(k = paste(prior_id, "allows_negative_weights", sep = "||"))

out <- df %>%
  mutate(k = paste(prior_id, feature, sep = "||")) %>%
  left_join(key, by = "k") %>%
  mutate(
    promote = feature == "allows_negative_weights" & !is.na(value_new),
    value = ifelse(promote, value_new, value),
    evidence_source_type = ifelse(promote, "paper_direct_note", evidence_source_type),
    evidence_locator = ifelse(promote, evidence_locator.y, evidence_locator.x),
    evidence_excerpt = ifelse(promote, evidence_excerpt.y, evidence_excerpt.x),
    coding_confidence = ifelse(promote, confidence, coding_confidence),
    evidence_status = ifelse(promote, "evidenced", evidence_status),
    evidence_tier = ifelse(promote, "direct_or_manual", evidence_tier),
    coder_note = ifelse(promote,
      "Comparator-specific direct note added for weight-sign behavior; retain bounded interpretation where exact optimization constraints are paper-specific.",
      coder_note
    )
  ) %>%
  transmute(
    prior_id = coalesce(prior_id.x, prior_id.y),
    year, title, url, feature, value,
    evidence_source_type,
    evidence_locator = evidence_locator.x,
    evidence_excerpt = evidence_excerpt.x,
    coding_confidence,
    evidence_status,
    coder_note,
    evidence_tier
  )

qa <- out %>%
  summarise(
    n_priors = n_distinct(prior_id),
    n_feature_rows = n(),
    n_direct_or_manual = sum(evidence_tier == "direct_or_manual", na.rm = TRUE),
    n_inferred = sum(evidence_tier == "inferred", na.rm = TRUE),
    n_unknown = sum(evidence_status == "unknown_value", na.rm = TRUE),
    coverage_any_evidence = round((n_direct_or_manual + n_inferred) / n_feature_rows, 4),
    coverage_direct_only = round(n_direct_or_manual / n_feature_rows, 4)
  )

qa_by_feature <- out %>%
  group_by(feature) %>%
  summarise(
    n_rows = n(),
    direct_count = sum(evidence_tier == "direct_or_manual", na.rm = TRUE),
    inferred_count = sum(evidence_tier == "inferred", na.rm = TRUE),
    unknown_count = sum(evidence_status == "unknown_value", na.rm = TRUE),
    coverage_direct = round(direct_count / n_rows, 4),
    .groups = "drop"
  ) %>% arrange(desc(coverage_direct), feature)

write_csv(out, file.path(out_dir, "126_prior_feature_evidence_long.csv"))
write_csv(qa, file.path(out_dir, "126_evidence_qa_summary.csv"))
write_csv(qa_by_feature, file.path(out_dir, "126_evidence_qa_by_feature.csv"))

cat("Stage 126 allows-negative-weights evidence upgrade generated:\n")
cat(sprintf("- %s\n", file.path(out_dir, "126_prior_feature_evidence_long.csv")))
cat(sprintf("- %s\n", file.path(out_dir, "126_evidence_qa_summary.csv")))
cat(sprintf("- %s\n", file.path(out_dir, "126_evidence_qa_by_feature.csv")))
