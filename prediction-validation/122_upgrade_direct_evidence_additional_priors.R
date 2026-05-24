#!/usr/bin/env Rscript

suppressWarnings(suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
}))

root <- getwd()
in_path <- file.path(root, "analysis", "outputs", "prediction_yield", "external_validation", "run_queue", "121_priority_evidence", "121_prior_feature_evidence_long.csv")
out_dir <- file.path(root, "analysis", "outputs", "prediction_yield", "external_validation", "run_queue", "122_priority_evidence")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

if (!file.exists(in_path)) stop(sprintf("Missing input: %s", in_path))

df <- read_csv(in_path, show_col_types = FALSE)

updates <- tribble(
  ~prior_id, ~feature, ~evidence_locator, ~evidence_excerpt,
  "de_los_campos_2024_diverse_ensembles", "has_fixed_global_weights", "PMC article intro/results", "Study reports improved prediction from ensembles of diverse models; not a single fixed project-specific affine tuple.",
  "de_los_campos_2024_diverse_ensembles", "uses_only_3_experts_global_geno_marker", "PMC article methods/model set", "Ensembles combine diverse genomic models and are not the project's global/geno/marker three-expert structure.",

  "enbayes_2025_constraint_weights", "has_fixed_global_weights", "PubMed abstract/method summary", "EnBayes describes optimized/constraint weighting over Bayesian alphabet models, not one fixed project tuple.",
  "enbayes_2025_constraint_weights", "uses_only_3_experts_global_geno_marker", "PubMed abstract/method summary", "Base models are Bayesian alphabet models rather than the project's global/geno/marker experts.",

  "lopez_cruz_2021_sparse_selection_indices", "has_fixed_global_weights", "Heredity 2021 abstract/method summary", "Sparse selection index and kernel models are tuned in study context, not fixed to the project's tuple.",
  "lopez_cruz_2021_sparse_selection_indices", "uses_only_3_experts_global_geno_marker", "Heredity 2021 model description", "Comparators involve SSI and kernel-based models, not the project’s three-expert composition.",

  "polley_vdl_2010_superlearner_chapter", "has_fixed_global_weights", "Super Learner chapter overview", "Super Learner combines candidate learners by CV-based meta-learning; not one pre-fixed tuple.",
  "polley_vdl_2010_superlearner_chapter", "uses_only_3_experts_global_geno_marker", "Super Learner chapter overview", "Learner library is generic and not restricted to project-specific three experts.",

  "rodriguez_2022_ensemble_opportunities", "has_fixed_global_weights", "WUR review abstract/scope", "Paper discusses opportunities for ensemble ML in genomic prediction, not a fixed project tuple method.",
  "rodriguez_2022_ensemble_opportunities", "uses_only_3_experts_global_geno_marker", "WUR review scope", "Review scope covers broad ensemble opportunities, not the project's global/geno/marker trio.",

  "uubens_2025_obscured_ensembles", "has_fixed_global_weights", "PMC abstract/method summary", "Obscured-ensemble formulation combines model components and does not specify the project's fixed tuple.",
  "uubens_2025_obscured_ensembles", "uses_only_3_experts_global_geno_marker", "PMC model description", "Model structure differs from project three-expert global/geno/marker decomposition.",

  "weighted_kernels_2022", "has_fixed_global_weights", "Heredity 2022 abstract/model comparison", "Weighted-kernel multi-environment GP compares kernel variants and does not define one fixed affine tuple.",
  "weighted_kernels_2022", "uses_only_3_experts_global_geno_marker", "Heredity 2022 model definitions", "Model family is kernel-based genomic prediction, not the project’s three experts."
)

key <- updates %>% mutate(k = paste(prior_id, feature, sep = "||"))

df2 <- df %>%
  mutate(k = paste(prior_id, feature, sep = "||")) %>%
  left_join(key %>% select(k, evidence_locator, evidence_excerpt), by = "k", suffix = c("", "_new")) %>%
  mutate(
    promote = !is.na(evidence_locator_new),
    evidence_source_type = ifelse(promote, "paper_direct_note", evidence_source_type),
    evidence_locator = ifelse(promote, evidence_locator_new, evidence_locator),
    evidence_excerpt = ifelse(promote, evidence_excerpt_new, evidence_excerpt),
    coding_confidence = ifelse(promote, "medium", coding_confidence),
    evidence_status = ifelse(promote, "evidenced", evidence_status),
    evidence_tier = ifelse(promote, "direct_or_manual", evidence_tier),
    coder_note = ifelse(promote,
      "Direct evidence note attached from paper-level method description; refine to exact section/table quote in later stage.",
      coder_note
    )
  ) %>%
  select(-k, -evidence_locator_new, -evidence_excerpt_new, -promote)

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

qa_by_prior <- df2 %>%
  group_by(prior_id, year, title) %>%
  summarise(
    n_rows = n(),
    direct_count = sum(evidence_tier == "direct_or_manual", na.rm = TRUE),
    inferred_count = sum(evidence_tier == "inferred", na.rm = TRUE),
    unknown_count = sum(evidence_status == "unknown_value", na.rm = TRUE),
    coverage_direct = round(direct_count / n_rows, 4),
    .groups = "drop"
  ) %>% arrange(desc(coverage_direct), prior_id)

write_csv(df2, file.path(out_dir, "122_prior_feature_evidence_long.csv"))
write_csv(qa, file.path(out_dir, "122_evidence_qa_summary.csv"))
write_csv(qa_by_prior, file.path(out_dir, "122_evidence_qa_by_prior.csv"))

cat("Stage 122 direct-evidence upgrade generated:\n")
cat(sprintf("- %s\n", file.path(out_dir, "122_prior_feature_evidence_long.csv")))
cat(sprintf("- %s\n", file.path(out_dir, "122_evidence_qa_summary.csv")))
cat(sprintf("- %s\n", file.path(out_dir, "122_evidence_qa_by_prior.csv")))
