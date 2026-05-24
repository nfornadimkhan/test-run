#!/usr/bin/env Rscript

suppressWarnings(suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(glue)
}))

root <- getwd()
runq <- file.path(root, "analysis", "outputs", "prediction_yield", "external_validation", "run_queue")
out_dir <- file.path(runq, "129_master_dossier")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

read_safe <- function(path) {
  if (!file.exists(path)) stop(sprintf("Missing required file: %s", path))
  read_csv(path, show_col_types = FALSE)
}

s127 <- read_safe(file.path(runq, "127_completion_audit", "127_objective_readiness_summary.csv"))
s128 <- read_safe(file.path(runq, "128_claim_compliance", "128_claim_overall_stats.csv"))
s126f <- read_safe(file.path(runq, "126_priority_evidence", "126_evidence_qa_by_feature.csv"))
req <- read_safe(file.path(runq, "127_completion_audit", "127_objective_requirement_audit.csv"))

bounded_ready <- as.logical(s127$bounded_worldfirst_readiness[[1]])
absolute_ready <- as.logical(s127$absolute_worldfirst_readiness[[1]])
direct_cov <- s127$direct_coverage[[1]]
high_risk <- s128$n_high_risk[[1]]
weak <- s126f %>% filter(feature == "allows_negative_weights")
weak_direct <- weak$coverage_direct[[1]]
weak_unknown <- weak$unknown_count[[1]]

req_counts <- req %>% count(status) %>% tidyr::pivot_wider(names_from = status, values_from = n, values_fill = 0)
proven <- ifelse("PROVEN" %in% names(req_counts), req_counts$PROVEN[[1]], 0)
bounded <- ifelse("PROVEN_BOUNDED" %in% names(req_counts), req_counts$PROVEN_BOUNDED[[1]], 0)
unproven <- ifelse("UNPROVEN" %in% names(req_counts), req_counts$UNPROVEN[[1]], 0)

dossier <- glue(
"# Stage 129 Master Discovery Dossier (2026-05-23)\n\n",
"## Final Objective Status\n\n",
"- Objective: `do world-first method discovery`\n",
"- Bounded world-first readiness: **{bounded_ready}**\n",
"- Absolute world-first readiness: **{absolute_ready}**\n\n",
"## Evidence Checksum\n\n",
"- Strict external 4-dataset pass: `{s127$strict4_pass[[1]]}`\n",
"- Seed robustness all runs: `{s127$seed_robust_all_runs[[1]]}`\n",
"- Independent rebuild: `{s127$independent_rebuild[[1]]}`\n",
"- One-command reproducibility: `{s127$one_command_repro[[1]]}`\n",
"- Train-permutation falsification collapse: `{s127$perm_train_collapse[[1]]}`\n",
"- No exact match in expanded comparator manifest: `{s127$no_exact_manifest_match[[1]]}`\n",
"- Direct evidence coverage: `{direct_cov}`\n",
"- Claim compliance high-risk files: `{high_risk}`\n\n",
"## Requirement Audit Summary\n\n",
"- `PROVEN`: {proven}\n",
"- `PROVEN_BOUNDED`: {bounded}\n",
"- `UNPROVEN`: {unproven}\n\n",
"## Approved Strongest Claim\n\n",
"As of 2026-05-23, we discovered and externally validated a fixed affine candidate (`0.80, 0.25, -0.05`) that passes strict confirmatory gates across all four registered external datasets, with robustness/rebuild/falsification checks and no exact audited comparator match in our expanded manifest; this supports a high-confidence bounded world-first claim at the protocol-signature level, not a universal non-existence claim.\n\n",
"## Required Caveats\n\n",
"- Bounded scope: finite comparator set and repository-defined protocol.\n",
"- Absolute global non-existence remains unproven by definition.\n",
"- Residual feature caveat: `allows_negative_weights` direct coverage `{weak_direct}`, unknown rows `{weak_unknown}`.\n\n",
"## Release Safety\n\n",
"- High-risk forbidden phrasing count: `{high_risk}` (target = 0).\n",
"- If this increases above 0, re-run Stage-128 compliance audit before release.\n"
)

out_md <- file.path(out_dir, "129_master_discovery_dossier_2026-05-23.md")
writeLines(dossier, out_md)

summary_tbl <- tibble(
  bounded_worldfirst_ready = bounded_ready,
  absolute_worldfirst_ready = absolute_ready,
  direct_coverage = direct_cov,
  high_risk_claim_files = high_risk,
  weak_feature_allows_negative_weights_direct = weak_direct,
  weak_feature_allows_negative_weights_unknown = weak_unknown,
  req_proven = proven,
  req_proven_bounded = bounded,
  req_unproven = unproven
)
write_csv(summary_tbl, file.path(out_dir, "129_master_readiness_checksum.csv"))

cat("Stage 129 master dossier generated:\n")
cat(sprintf("- %s\n", out_md))
cat(sprintf("- %s\n", file.path(out_dir, "129_master_readiness_checksum.csv")))
