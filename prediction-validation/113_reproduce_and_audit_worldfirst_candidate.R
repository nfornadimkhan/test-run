## -----------------------------------------------------------------------------
## Stage 113: One-command reproduce-and-audit runner
## -----------------------------------------------------------------------------

source('/Users/neon/Documents/Nadim\'s Brain/analysis/prediction-validation/10_prediction_paths_and_helpers.R')

base_dir <- '/Users/neon/Documents/Nadim\'s Brain/analysis/outputs/prediction_yield/external_validation'
root <- '/Users/neon/Documents/Nadim\'s Brain'
out_dir <- file.path(base_dir, 'run_queue', '113_reproduce_audit')
ensure_dir(out_dir)

datasets <- c('cimmyt_wheat','dryad_rice','dryad_wheat_sparse','dryad_maize_met')
w <- c(0.80, 0.25, -0.05)
seed_marker <- 4242
seed_boot_all <- 9601
seed_boot_seen <- 9602

run_cmd <- function(cmd) {
  status <- system(cmd, ignore.stdout = TRUE, ignore.stderr = TRUE)
  status
}

stage96_cmd <- function(ds) sprintf(
  "MARKER_SUBSAMPLE_SEED=%d BOOTSTRAP_SEED_ALL=%d BOOTSTRAP_SEED_SEEN=%d Rscript \"%s/analysis/prediction-validation/96_run_external_confirmatory_weighted_candidate.R\" %s \"%s\" %.2f %.2f %.2f",
  seed_marker, seed_boot_all, seed_boot_seen, root, ds, base_dir, w[1], w[2], w[3]
)

rows <- list(); i <- 0
for (ds in datasets) {
  st <- run_cmd(stage96_cmd(ds))
  i <- i + 1
  rows[[i]] <- data.frame(step='stage96', dataset_key=ds, status_code=st, stringsAsFactors=FALSE)
}

st91 <- run_cmd(sprintf("Rscript \"%s/analysis/prediction-validation/91_update_external_tracker_from_filesystem.R\"", root))
i <- i + 1
rows[[i]] <- data.frame(step='stage91_tracker_update', dataset_key='ALL', status_code=st91, stringsAsFactors=FALSE)

st111 <- run_cmd(sprintf("Rscript \"%s/analysis/prediction-validation/111_independent_rebuild_verify_promoted_candidate.R\"", root))
i <- i + 1
rows[[i]] <- data.frame(step='stage111_independent_verify', dataset_key='ALL', status_code=st111, stringsAsFactors=FALSE)

log_df <- do.call(rbind, rows)
write.csv(log_df, file.path(out_dir, '113_execution_log.csv'), row.names=FALSE)

# Read verification summary if present
verify_summary_path <- file.path(base_dir, 'run_queue', '111_independent_verify', '111_verify_summary.csv')
verify_ok <- FALSE
if (file.exists(verify_summary_path)) {
  v <- read.csv(verify_summary_path, stringsAsFactors = FALSE)
  verify_ok <- isTRUE(v$all_pass_confirmatory[1]) && isTRUE(v$all_strict_recheck[1])
}

# Check tracker statuses
tracker_path <- file.path(root, 'analysis/models/84_external_execution_tracker_2026-05-23.csv')
tracker_ok <- FALSE
if (file.exists(tracker_path)) {
  t <- read.csv(tracker_path, stringsAsFactors = FALSE)
  tracker_ok <- all(t$status_candidate_plugged == 'done') && all(t$status_confirmatory_complete == 'done')
}

all_cmd_ok <- all(log_df$status_code == 0)

summary <- data.frame(
  run_timestamp = format(Sys.time(), '%Y-%m-%d %H:%M:%S %Z'),
  n_stage96_datasets = length(datasets),
  all_commands_ok = all_cmd_ok,
  independent_verify_ok = verify_ok,
  tracker_status_ok = tracker_ok,
  final_audit_pass = (all_cmd_ok && verify_ok && tracker_ok),
  w_global = w[1],
  w_geno = w[2],
  w_marker = w[3],
  marker_seed = seed_marker,
  boot_seed_all = seed_boot_all,
  boot_seed_seen = seed_boot_seen,
  stringsAsFactors = FALSE
)

write.csv(summary, file.path(out_dir, '113_audit_summary.csv'), row.names=FALSE)
print(log_df)
print(summary)
