#!/usr/bin/env Rscript

suppressWarnings(suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(purrr)
  library(stringr)
  library(tidyr)
}))

root <- getwd()
base_dir <- file.path(root, "analysis", "outputs", "prediction_yield", "external_validation")
out_dir <- file.path(base_dir, "run_queue", "116_claim_matrix")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

datasets <- c("cimmyt_wheat", "dryad_rice", "dryad_wheat_sparse", "dryad_maize_met")

safe_read <- function(path) {
  if (!file.exists(path)) stop(sprintf("Missing required file: %s", path))
  read_csv(path, show_col_types = FALSE)
}

# Stage 106 strict confirmatory evidence from per-dataset gate and scope summaries
stage106 <- map_dfr(datasets, function(ds) {
  gate_path <- file.path(base_dir, ds, "confirmatory_candidate_outputs", sprintf("%s_candidate_gate_result.csv", ds))
  scope_path <- file.path(base_dir, ds, "confirmatory_candidate_outputs", sprintf("%s_candidate_scope_summary.csv", ds))
  gate <- safe_read(gate_path)
  scope <- safe_read(scope_path)
  t_col <- if ("t_pvalue" %in% names(scope)) "t_pvalue" else "t_one_sided_p"
  boot_col <- if ("boot_prob_gain_gt0" %in% names(scope)) "boot_prob_gain_gt0" else "boot_prob_gain_positive"

  tibble(
    dataset_key = ds,
    pass_confirmatory = as.logical(gate$pass_confirmatory[[1]]),
    gain_floor_pass = as.logical(gate$gain_floor_pass[[1]]),
    t_pass = as.logical(gate$t_pass[[1]]),
    boot_pass = as.logical(gate$boot_pass[[1]]),
    min_gain = min(scope$mean_gain, na.rm = TRUE),
    max_t = max(scope[[t_col]], na.rm = TRUE),
    min_boot = min(scope[[boot_col]], na.rm = TRUE)
  )
})

# Stage 109 robustness
s109 <- safe_read(file.path(base_dir, "run_queue", "109_seed_robustness", "109_seed_robustness_run_summary.csv"))
robust_all4_runs <- sum(s109$all4_pass, na.rm = TRUE)
robust_total_runs <- nrow(s109)

# Stage 111 independent verification
s111 <- safe_read(file.path(base_dir, "run_queue", "111_independent_verify", "111_verify_summary.csv"))
independent_pass <- if ("all_pass_confirmatory" %in% names(s111)) {
  all(s111$all_pass_confirmatory, na.rm = TRUE)
} else if ("pass_confirmatory" %in% names(s111)) {
  all(s111$pass_confirmatory, na.rm = TRUE)
} else {
  FALSE
}

# Stage 113 one-command reproduce audit
s113 <- safe_read(file.path(base_dir, "run_queue", "113_reproduce_audit", "113_audit_summary.csv"))
repro_pass <- if ("final_audit_pass" %in% names(s113)) {
  all(s113$final_audit_pass, na.rm = TRUE)
} else if ("pass" %in% names(s113)) {
  all(s113$pass, na.rm = TRUE)
} else {
  FALSE
}

# Stage 114 falsification
s114 <- safe_read(file.path(base_dir, "run_queue", "114_falsification", "114_falsification_pass_rates.csv"))
train_perm_collapse <- s114 %>% filter(mode == "perm_train") %>% summarise(ok = all(pass_rate == 0)) %>% pull(ok)
true_mode_full <- s114 %>% filter(mode == "none") %>% summarise(ok = all(pass_rate == 1)) %>% pull(ok)

# Stage 115 strong baselines
s115 <- safe_read(file.path(base_dir, "run_queue", "115_baseline_strength", "115_candidate_vs_strong_baselines.csv"))
uniform_vs_global <- s115 %>% filter(comparator == "pred_global") %>% summarise(ok = all(mean_gain_vs_comparator > 0)) %>% pull(ok)
uniform_vs_geno <- s115 %>% filter(comparator == "pred_geno") %>% summarise(ok = all(mean_gain_vs_comparator > 0)) %>% pull(ok)
uniform_vs_oracle <- s115 %>% filter(comparator == "best_single_expert_oracle") %>% summarise(ok = all(mean_gain_vs_comparator > 0)) %>% pull(ok)

claim_matrix <- tribble(
  ~claim_id, ~claim_text, ~status, ~evidence,
  "C1", "Single fixed candidate (0.80,0.25,-0.05) passes strict confirmatory external gate on all 4 datasets", ifelse(all(stage106$pass_confirmatory), "PROVEN", "NOT_PROVEN"), "stage106 per-dataset gate files",
  "C2", "Candidate robustness holds under seed perturbations", ifelse(robust_all4_runs == robust_total_runs, "PROVEN", "PARTIAL"), sprintf("stage109 all4_pass runs %d/%d", robust_all4_runs, robust_total_runs),
  "C3", "Independent rebuild reproduces strict pass", ifelse(independent_pass, "PROVEN", "NOT_PROVEN"), "stage111 verify summary",
  "C4", "One-command reproduce-and-audit passes", ifelse(repro_pass, "PROVEN", "NOT_PROVEN"), "stage113 audit summary",
  "C5", "Train-label permutation collapses confirmatory pass (anti-leakage falsification)", ifelse(train_perm_collapse && true_mode_full, "PROVEN", "PARTIAL"), "stage114 pass rates",
  "C6", "Candidate uniformly beats global baseline", ifelse(uniform_vs_global, "PROVEN", "NOT_PROVEN"), "stage115 comparator analysis",
  "C7", "Candidate uniformly beats genotype baseline", ifelse(uniform_vs_geno, "PROVEN", "NOT_PROVEN"), "stage115 comparator analysis",
  "C8", "Candidate uniformly beats oracle best single expert", ifelse(uniform_vs_oracle, "PROVEN", "NOT_PROVEN"), "stage115 comparator analysis",
  "C9", "Absolute world-first existence claim (no one has done equivalent ever)", "NOT_PROVEN", "finite search cannot prove global non-existence",
  "C10", "Bounded novelty claim: no exact audited prior match to this full protocol-and-gate bundle as-of 2026-05-23", "SUPPORTED_BOUNDED", "stages 107/114/115 + prior-art anchors"
)

write_csv(stage106, file.path(out_dir, "116_stage106_dataset_gate_snapshot.csv"))
write_csv(claim_matrix, file.path(out_dir, "116_claim_proof_matrix.csv"))

cat("Stage 116 claim matrix generated:\n")
cat(sprintf("- %s\n", file.path(out_dir, "116_stage106_dataset_gate_snapshot.csv")))
cat(sprintf("- %s\n", file.path(out_dir, "116_claim_proof_matrix.csv")))
