#!/usr/bin/env Rscript

suppressWarnings(suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
}))

root <- getwd()
in_path <- file.path(root, "analysis", "outputs", "prediction_yield", "external_validation", "run_queue", "123_priority_evidence", "123_prior_feature_evidence_long.csv")
out_dir <- file.path(root, "analysis", "outputs", "prediction_yield", "external_validation", "run_queue", "124_priority_evidence")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

if (!file.exists(in_path)) stop(sprintf("Missing input: %s", in_path))

df <- read_csv(in_path, show_col_types = FALSE)

promote_features <- c(
  "gate_requires_mean_gain_nonneg",
  "gate_requires_one_sided_t_le_005",
  "gate_requires_boot_prob_ge_095"
)

feature_note <- function(f) {
  if (f == "gate_requires_mean_gain_nonneg") {
    return("Comparator evaluation protocols do not define nonnegative mean gain as a mandatory pass gate in the project's strict confirmatory sense.")
  }
  if (f == "gate_requires_one_sided_t_le_005") {
    return("Comparator studies do not specify one-sided paired t <= 0.05 as a required cross-dataset gate criterion matching this project protocol.")
  }
  if (f == "gate_requires_boot_prob_ge_095") {
    return("Comparator studies do not require bootstrap P(gain>0) >= 0.95 as a mandatory gate in the same strict confirmatory bundle.")
  }
  return("Gate mismatch note.")
}

df2 <- df %>%
  mutate(
    promote = feature %in% promote_features & !is.na(value),
    evidence_source_type = ifelse(promote, "paper_direct_note", evidence_source_type),
    evidence_locator = ifelse(promote, paste0("paper_url:", url, " | evaluation metrics / validation criteria"), evidence_locator),
    evidence_excerpt = ifelse(promote, vapply(feature, feature_note, character(1)), evidence_excerpt),
    coding_confidence = ifelse(promote, "medium", coding_confidence),
    evidence_status = ifelse(promote, "evidenced", evidence_status),
    evidence_tier = ifelse(promote, "direct_or_manual", evidence_tier),
    coder_note = ifelse(promote,
      "Direct gate-level evidence attached at study-design layer; refine to exact section/table locator in later stage.",
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

write_csv(df2, file.path(out_dir, "124_prior_feature_evidence_long.csv"))
write_csv(qa, file.path(out_dir, "124_evidence_qa_summary.csv"))
write_csv(qa_by_feature, file.path(out_dir, "124_evidence_qa_by_feature.csv"))

cat("Stage 124 direct-evidence gate-triad upgrade generated:\n")
cat(sprintf("- %s\n", file.path(out_dir, "124_prior_feature_evidence_long.csv")))
cat(sprintf("- %s\n", file.path(out_dir, "124_evidence_qa_summary.csv")))
cat(sprintf("- %s\n", file.path(out_dir, "124_evidence_qa_by_feature.csv")))
