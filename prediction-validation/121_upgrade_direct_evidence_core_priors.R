#!/usr/bin/env Rscript

suppressWarnings(suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(stringr)
}))

root <- getwd()
in_path <- file.path(root, "analysis", "outputs", "prediction_yield", "external_validation", "run_queue", "120_priority_evidence", "120_prior_feature_evidence_long_enriched.csv")
out_dir <- file.path(root, "analysis", "outputs", "prediction_yield", "external_validation", "run_queue", "121_priority_evidence")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

if (!file.exists(in_path)) stop(sprintf("Missing input: %s", in_path))

df <- read_csv(in_path, show_col_types = FALSE)

updates <- tribble(
  ~prior_id, ~feature, ~evidence_locator, ~evidence_excerpt,
  "wolpert_1992_stacked_generalization", "has_fixed_global_weights", "Neural Networks 5(2):241-259, abstract/method description", "Stacked generalization is described as a general two-level scheme using base generalizers plus a second-space learner, not a single pre-fixed global weight tuple.",
  "wolpert_1992_stacked_generalization", "uses_only_3_experts_global_geno_marker", "Neural Networks 5(2):241-259, abstract/method description", "Method is generic over one or more generalizers and not tied to the project's three experts (global/geno/marker).",

  "breiman_1996_stacked_regressions", "has_fixed_global_weights", "Machine Learning 24(1):49-64, method summary", "Stacked regressions forms data-driven linear combinations learned from cross-validation predictions rather than one pre-fixed global tuple.",
  "breiman_1996_stacked_regressions", "allows_negative_weights", "Machine Learning 24(1):49-64, stacking coefficient discussion", "Paper discusses stacking coefficients under constrained combinations in regression stacking context.",

  "vdl_2007_super_learner", "has_fixed_global_weights", "Stat Appl Genet Mol Biol 6:Article25, abstract", "Super learner builds a weighted combination from a learner library using cross-validation, not a single pre-fixed tuple.",
  "vdl_2007_super_learner", "uses_only_3_experts_global_geno_marker", "Stat Appl Genet Mol Biol 6:Article25, abstract", "Candidate learner library is broad and not restricted to the project's three experts.",

  "liang_2021_self_genomic", "uses_only_3_experts_global_geno_marker", "Frontiers Genetics 12:600040, methods/introduction", "SELF uses SVR, KRR, and ENET as base learners with OLS meta-learner, which differs from the project's global/geno/marker trio.",
  "liang_2021_self_genomic", "has_fixed_global_weights", "Frontiers Genetics 12:600040, methods/introduction", "Stacking framework trains a meta-learner over base predictions rather than applying a single pre-fixed global tuple.",

  "barroso_2026_stacking_complex_arch", "uses_only_3_experts_global_geno_marker", "Agronomy 2026, 16(2):241, methods summary", "SEL framework evaluates multiple base learners and robust meta-learners, not the project's three fixed experts.",
  "barroso_2026_stacking_complex_arch", "has_fixed_global_weights", "Agronomy 2026, 16(2):241, methods summary", "Stacking design depends on selected base/meta learners under CV rather than one pre-fixed global tuple.",

  "montesinos_2019_bmors", "uses_only_3_experts_global_geno_marker", "G3/PMC BMORS article, objectives/method", "BMORS is a Bayesian multi-output regressor stacking framework over multi-trait/multi-environment models, not the project’s three experts.",
  "montesinos_2019_bmors", "has_fixed_global_weights", "G3/PMC BMORS article, objectives/method", "BMORS extends stacking in a Bayesian multi-output setting and is not defined by a fixed project-specific tuple.",

  "gu_2024_elpgv", "has_fixed_global_weights", "BMC Bioinformatics 25:120, abstract/method", "ELPGV combines several base genomic methods and updates/estimates ensemble weights; not a project-specific fixed tuple.",
  "gu_2024_elpgv", "uses_only_3_experts_global_geno_marker", "BMC Bioinformatics 25:120, abstract/method", "ELPGV base methods include GBLUP/BayesA/BayesB/BayesCpi, not the project's global/geno/marker trio."
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
      "Direct evidence note attached from paper-level method description; replace with exact section/table quote where possible.",
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

write_csv(df2, file.path(out_dir, "121_prior_feature_evidence_long.csv"))
write_csv(qa, file.path(out_dir, "121_evidence_qa_summary.csv"))
write_csv(qa_by_prior, file.path(out_dir, "121_evidence_qa_by_prior.csv"))

cat("Stage 121 direct-evidence upgrade generated:\n")
cat(sprintf("- %s\n", file.path(out_dir, "121_prior_feature_evidence_long.csv")))
cat(sprintf("- %s\n", file.path(out_dir, "121_evidence_qa_summary.csv")))
cat(sprintf("- %s\n", file.path(out_dir, "121_evidence_qa_by_prior.csv")))
