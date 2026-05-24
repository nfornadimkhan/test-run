## -----------------------------------------------------------------------------
## Stage 111: Independent rebuild-and-verify for promoted candidate
##
## Re-runs stage-96 for all external datasets with promoted weights and verifies:
## - pass_confirmatory == TRUE
## - scope rows exist for all + seen_genotypes
## - strict threshold checks remain satisfied
## -----------------------------------------------------------------------------

source('/Users/neon/Documents/Nadim\'s Brain/analysis/prediction-validation/10_prediction_paths_and_helpers.R')

base_dir <- '/Users/neon/Documents/Nadim\'s Brain/analysis/outputs/prediction_yield/external_validation'
datasets <- c('cimmyt_wheat','dryad_rice','dryad_wheat_sparse','dryad_maize_met')
out_dir <- file.path(base_dir,'run_queue','111_independent_verify')
ensure_dir(out_dir)

w <- c(0.80,0.25,-0.05)
marker_seed <- 4242
boot_seed_all <- 9601
boot_seed_seen <- 9602

run_cmd <- function(ds) {
  sprintf(
    "MARKER_SUBSAMPLE_SEED=%d BOOTSTRAP_SEED_ALL=%d BOOTSTRAP_SEED_SEEN=%d Rscript \"/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/96_run_external_confirmatory_weighted_candidate.R\" %s \"%s\" %.2f %.2f %.2f",
    marker_seed, boot_seed_all, boot_seed_seen, ds, base_dir, w[1], w[2], w[3]
  )
}

verify_ds <- function(ds) {
  status <- system(run_cmd(ds), ignore.stdout = TRUE, ignore.stderr = TRUE)
  gate_path <- file.path(base_dir,ds,'confirmatory_candidate_outputs',paste0(ds,'_candidate_gate_result.csv'))
  sum_path <- file.path(base_dir,ds,'confirmatory_candidate_outputs',paste0(ds,'_candidate_scope_summary.csv'))

  if (status != 0 || !file.exists(gate_path) || !file.exists(sum_path)) {
    return(data.frame(dataset_key=ds, cmd_status=status, pass_confirmatory=FALSE, has_all=FALSE, has_seen=FALSE,
                      all_gain=NA_real_, seen_gain=NA_real_, all_t=NA_real_, seen_t=NA_real_,
                      all_boot=NA_real_, seen_boot=NA_real_, strict_recheck=FALSE, stringsAsFactors=FALSE))
  }

  g <- read.csv(gate_path, stringsAsFactors = FALSE)
  s <- read.csv(sum_path, stringsAsFactors = FALSE)

  has_all <- any(s$scope == 'all')
  has_seen <- any(s$scope == 'seen_genotypes')

  a <- s[s$scope == 'all', , drop = FALSE]
  v <- s[s$scope == 'seen_genotypes', , drop = FALSE]

  strict_recheck <- FALSE
  if (nrow(a) > 0 && nrow(v) > 0) {
    strict_recheck <- isTRUE(a$mean_gain[1] >= 0) &&
      isTRUE(v$mean_gain[1] >= 0) &&
      isTRUE(a$t_one_sided_p[1] <= 0.05) &&
      isTRUE(v$t_one_sided_p[1] <= 0.05) &&
      isTRUE(a$boot_prob_gain_positive[1] >= 0.95) &&
      isTRUE(v$boot_prob_gain_positive[1] >= 0.95)
  }

  data.frame(
    dataset_key = ds,
    cmd_status = status,
    pass_confirmatory = isTRUE(g$pass_confirmatory[1]),
    has_all = has_all,
    has_seen = has_seen,
    all_gain = if (nrow(a) > 0) a$mean_gain[1] else NA_real_,
    seen_gain = if (nrow(v) > 0) v$mean_gain[1] else NA_real_,
    all_t = if (nrow(a) > 0) a$t_one_sided_p[1] else NA_real_,
    seen_t = if (nrow(v) > 0) v$t_one_sided_p[1] else NA_real_,
    all_boot = if (nrow(a) > 0) a$boot_prob_gain_positive[1] else NA_real_,
    seen_boot = if (nrow(v) > 0) v$boot_prob_gain_positive[1] else NA_real_,
    strict_recheck = strict_recheck,
    stringsAsFactors = FALSE
  )
}

rows <- do.call(rbind, lapply(datasets, verify_ds))
write.csv(rows, file.path(out_dir,'111_verify_detail.csv'), row.names = FALSE)

summary_row <- data.frame(
  n_datasets = nrow(rows),
  n_pass_confirmatory = sum(rows$pass_confirmatory, na.rm = TRUE),
  n_strict_recheck = sum(rows$strict_recheck, na.rm = TRUE),
  all_pass_confirmatory = all(rows$pass_confirmatory),
  all_strict_recheck = all(rows$strict_recheck),
  marker_seed = marker_seed,
  boot_seed_all = boot_seed_all,
  boot_seed_seen = boot_seed_seen,
  w_global = w[1],
  w_geno = w[2],
  w_marker = w[3],
  stringsAsFactors = FALSE
)

write.csv(summary_row, file.path(out_dir,'111_verify_summary.csv'), row.names = FALSE)
print(rows)
print(summary_row)
