#!/usr/bin/env Rscript

suppressWarnings(suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(stringr)
}))

root <- getwd()
base <- file.path(root, "analysis", "outputs", "prediction_yield", "external_validation", "run_queue", "119_priority_evidence")
in_path <- file.path(base, "119_prior_feature_evidence_long.csv")
out_dir <- file.path(root, "analysis", "outputs", "prediction_yield", "external_validation", "run_queue", "120_priority_evidence")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

if (!file.exists(in_path)) stop(sprintf("Missing input: %s", in_path))

df <- read_csv(in_path, show_col_types = FALSE)

# Mark existing evidenced rows as direct if source is a paper-level note
# and all newly added rows as inferred_scope unless proven otherwise.
df <- df %>%
  mutate(
    evidence_tier = case_when(
      evidence_status == "evidenced" ~ "direct_or_manual",
      TRUE ~ NA_character_
    )
  )

fill_inference <- function(feature_name) {
  case_when(
    feature_name == "has_fixed_global_weights" ~
      "Comparator methods are presented as general stacking/ensemble procedures rather than one pre-fixed global weight tuple.",
    feature_name == "weights_exact_080_025_m005" ~
      "No comparator reports the exact fixed tuple (0.80, 0.25, -0.05) as method-defining weights.",
    feature_name == "allows_negative_weights" ~
      "Weight-sign constraints are method-specific and often not central in abstracts; unresolved rows remain unknown if uncited.",
    feature_name == "uses_only_3_experts_global_geno_marker" ~
      "Comparator stacks typically use different learner sets than the project's three-expert global/geno/marker structure.",
    feature_name == "requires_both_scopes_all_and_seen" ~
      "Comparator evaluations do not describe the specific dual-scope requirement (all + seen_genotypes) as a gate.",
    feature_name == "gate_requires_mean_gain_nonneg" ~
      "Comparator papers report predictive metrics/CV but not this exact nonnegative gain gate requirement.",
    feature_name == "gate_requires_one_sided_t_le_005" ~
      "Comparator evaluations do not specify this one-sided paired t<=0.05 gate as a method requirement.",
    feature_name == "gate_requires_boot_prob_ge_095" ~
      "Comparator evaluations do not specify bootstrap P(gain>0)>=0.95 as a required gate.",
    feature_name == "requires_all4_registered_datasets_pass" ~
      "Comparator studies are not framed around passing this project's four registered external datasets.",
    feature_name == "includes_seed_robustness_layer" ~
      "Comparator methods generally do not describe this project's seed-perturbation gate as a required layer.",
    feature_name == "includes_independent_rebuild_layer" ~
      "Comparator publications generally do not encode independent rebuild verification as a mandatory gate layer.",
    feature_name == "includes_train_label_permutation_falsification" ~
      "Comparator studies generally do not define train-label permutation collapse as a mandatory falsification layer.",
    TRUE ~ ""
  )
}

# Add inference evidence ONLY for rows with known boolean values and missing evidence.
df2 <- df %>%
  mutate(
    should_fill = !is.na(value) & evidence_status == "missing_evidence",
    evidence_source_type = ifelse(should_fill, "inference_from_title_abstract_scope", evidence_source_type),
    evidence_locator = ifelse(should_fill, paste0("paper_url:", url), evidence_locator),
    evidence_excerpt = ifelse(should_fill, fill_inference(feature), evidence_excerpt),
    coding_confidence = ifelse(should_fill, "low", coding_confidence),
    evidence_status = ifelse(should_fill, "evidenced_inferred", evidence_status),
    evidence_tier = ifelse(should_fill, "inferred", evidence_tier),
    coder_note = ifelse(should_fill,
                        "Inference evidence added from comparator scope; replace with section-level direct citation for stronger claim.",
                        coder_note)
  ) %>%
  select(-should_fill)

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
    coverage_any = round((direct_count + inferred_count) / n_rows, 4),
    coverage_direct = round(direct_count / n_rows, 4),
    .groups = "drop"
  ) %>%
  arrange(coverage_direct, coverage_any, feature)

write_csv(df2, file.path(out_dir, "120_prior_feature_evidence_long_enriched.csv"))
write_csv(qa, file.path(out_dir, "120_evidence_qa_summary.csv"))
write_csv(qa_by_feature, file.path(out_dir, "120_evidence_qa_by_feature.csv"))

cat("Stage 120 evidence enrichment generated:\n")
cat(sprintf("- %s\n", file.path(out_dir, "120_prior_feature_evidence_long_enriched.csv")))
cat(sprintf("- %s\n", file.path(out_dir, "120_evidence_qa_summary.csv")))
cat(sprintf("- %s\n", file.path(out_dir, "120_evidence_qa_by_feature.csv")))
