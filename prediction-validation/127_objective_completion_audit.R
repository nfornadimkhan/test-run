#!/usr/bin/env Rscript

suppressWarnings(suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
}))

root <- getwd()
base_run <- file.path(root, "analysis", "outputs", "prediction_yield", "external_validation", "run_queue")
out_dir <- file.path(base_run, "127_completion_audit")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

read_safe <- function(path) {
  if (!file.exists(path)) stop(sprintf("Missing required evidence file: %s", path))
  read_csv(path, show_col_types = FALSE)
}

# Load authoritative outputs
s106 <- read_safe(file.path(base_run, "116_claim_matrix", "116_stage106_dataset_gate_snapshot.csv"))
s109 <- read_safe(file.path(base_run, "109_seed_robustness", "109_seed_robustness_run_summary.csv"))
s111 <- read_safe(file.path(base_run, "111_independent_verify", "111_verify_summary.csv"))
s113 <- read_safe(file.path(base_run, "113_reproduce_audit", "113_audit_summary.csv"))
s114 <- read_safe(file.path(base_run, "114_falsification", "114_falsification_pass_rates.csv"))
s115 <- read_safe(file.path(base_run, "115_baseline_strength", "115_candidate_vs_strong_baselines.csv"))
s118 <- read_safe(file.path(base_run, "118_priority_audit", "118_priority_summary_expanded.csv"))
s126 <- read_safe(file.path(base_run, "126_priority_evidence", "126_evidence_qa_summary.csv"))
s126f <- read_safe(file.path(base_run, "126_priority_evidence", "126_evidence_qa_by_feature.csv"))

# Derive statuses
strict4_pass <- all(s106$pass_confirmatory)
seed_robust <- sum(s109$all4_pass, na.rm = TRUE) == nrow(s109)
independent_rebuild <- if ("all_pass_confirmatory" %in% names(s111)) all(s111$all_pass_confirmatory) else FALSE
one_command_repro <- if ("final_audit_pass" %in% names(s113)) all(s113$final_audit_pass) else FALSE
perm_train_collapses <- s114 %>% filter(mode == "perm_train") %>% summarise(ok = all(pass_rate == 0)) %>% pull(ok)
true_mode_holds <- s114 %>% filter(mode == "none") %>% summarise(ok = all(pass_rate == 1)) %>% pull(ok)
beats_global_uniform <- s115 %>% filter(comparator == "pred_global") %>% summarise(ok = all(mean_gain_vs_comparator > 0)) %>% pull(ok)
not_universal_oracle <- s115 %>% filter(comparator == "best_single_expert_oracle") %>% summarise(any_loss = any(mean_gain_vs_comparator <= 0)) %>% pull(any_loss)
no_exact_manifest_match <- (s118$n_exact_match_proven[[1]] == 0)
direct_cov <- s126$coverage_direct_only[[1]]
bounded_ready <- direct_cov >= 0.90 && no_exact_manifest_match && strict4_pass && seed_robust && independent_rebuild && one_command_repro && perm_train_collapses

weak_feature <- s126f %>% filter(feature == "allows_negative_weights")
weak_direct <- weak_feature$coverage_direct[[1]]
weak_unknown <- weak_feature$unknown_count[[1]]

audit <- tribble(
  ~requirement_id, ~requirement_text, ~status, ~evidence,
  "R1", "Discover a fixed candidate method under this repository protocol", ifelse(strict4_pass, "PROVEN", "UNPROVEN"), "stage106 dataset gate snapshot",
  "R2", "Pass strict confirmatory external gate on all 4 registered datasets", ifelse(strict4_pass, "PROVEN", "UNPROVEN"), "stage106",
  "R3", "Show robustness under seed perturbations", ifelse(seed_robust, "PROVEN", "UNPROVEN"), "stage109",
  "R4", "Show independent rebuild reproducibility", ifelse(independent_rebuild, "PROVEN", "UNPROVEN"), "stage111",
  "R5", "Show one-command reproducibility", ifelse(one_command_repro, "PROVEN", "UNPROVEN"), "stage113",
  "R6", "Provide falsification evidence against leakage-only explanation", ifelse(perm_train_collapses && true_mode_holds, "PROVEN", "UNPROVEN"), "stage114",
  "R7", "Avoid overclaiming universal dominance vs stronger baselines", ifelse(not_universal_oracle, "PROVEN_BOUNDED", "UNPROVEN"), "stage115",
  "R8", "No exact comparator match in expanded manifest audit", ifelse(no_exact_manifest_match, "PROVEN_BOUNDED", "UNPROVEN"), "stage118",
  "R9", "Direct evidence coverage high enough for high-confidence bounded novelty", ifelse(direct_cov >= 0.90, "PROVEN_BOUNDED", "UNPROVEN"), "stage126",
  "R10", "Absolute global non-existence of equivalent method", "UNPROVEN", "finite comparator set cannot prove universal non-existence"
)

summary_tbl <- tibble(
  strict4_pass = strict4_pass,
  seed_robust_all_runs = seed_robust,
  independent_rebuild = independent_rebuild,
  one_command_repro = one_command_repro,
  perm_train_collapse = perm_train_collapses,
  true_mode_pass = true_mode_holds,
  beats_global_uniform = beats_global_uniform,
  no_exact_manifest_match = no_exact_manifest_match,
  direct_coverage = direct_cov,
  weak_feature_allows_negative_weights_direct = weak_direct,
  weak_feature_allows_negative_weights_unknown = weak_unknown,
  bounded_worldfirst_readiness = bounded_ready,
  absolute_worldfirst_readiness = FALSE
)

write_csv(audit, file.path(out_dir, "127_objective_requirement_audit.csv"))
write_csv(summary_tbl, file.path(out_dir, "127_objective_readiness_summary.csv"))

cat("Stage 127 completion audit generated:\n")
cat(sprintf("- %s\n", file.path(out_dir, "127_objective_requirement_audit.csv")))
cat(sprintf("- %s\n", file.path(out_dir, "127_objective_readiness_summary.csv")))
