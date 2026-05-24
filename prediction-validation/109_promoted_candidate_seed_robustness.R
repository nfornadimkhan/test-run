## -----------------------------------------------------------------------------
## Stage 109: Robustness grid for promoted candidate under seed perturbations
## -----------------------------------------------------------------------------

source('/Users/neon/Documents/Nadim\'s Brain/analysis/prediction-validation/10_prediction_paths_and_helpers.R')

base_dir <- '/Users/neon/Documents/Nadim\'s Brain/analysis/outputs/prediction_yield/external_validation'
datasets <- c('cimmyt_wheat','dryad_rice','dryad_wheat_sparse','dryad_maize_met')
out_dir <- file.path(base_dir,'run_queue','109_seed_robustness')
ensure_dir(out_dir)

w <- c(0.80,0.25,-0.05)
marker_seeds <- c(4201, 4242, 4301, 4444, 4601)
boot_pairs <- list(c(9601,9602), c(9701,9702), c(9801,9802))

run_one <- function(dataset_key, marker_seed, boot_all, boot_seen) {
  cmd <- sprintf(
    "MARKER_SUBSAMPLE_SEED=%d BOOTSTRAP_SEED_ALL=%d BOOTSTRAP_SEED_SEEN=%d Rscript \"/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/96_run_external_confirmatory_weighted_candidate.R\" %s \"%s\" %.2f %.2f %.2f",
    marker_seed, boot_all, boot_seen, dataset_key, base_dir, w[1], w[2], w[3]
  )
  status <- system(cmd, ignore.stdout = TRUE, ignore.stderr = TRUE)
  gate_path <- file.path(base_dir,dataset_key,'confirmatory_candidate_outputs',paste0(dataset_key,'_candidate_gate_result.csv'))
  sum_path <- file.path(base_dir,dataset_key,'confirmatory_candidate_outputs',paste0(dataset_key,'_candidate_scope_summary.csv'))
  if (status != 0 || !file.exists(gate_path) || !file.exists(sum_path)) {
    return(data.frame(dataset_key=dataset_key, pass=FALSE, all_t=NA_real_, seen_t=NA_real_, all_gain=NA_real_, seen_gain=NA_real_, stringsAsFactors=FALSE))
  }
  g <- read.csv(gate_path, stringsAsFactors=FALSE)
  s <- read.csv(sum_path, stringsAsFactors=FALSE)
  a <- s[s$scope=='all',,drop=FALSE]
  v <- s[s$scope=='seen_genotypes',,drop=FALSE]
  data.frame(
    dataset_key = dataset_key,
    pass = isTRUE(g$pass_confirmatory[1]),
    all_t = a$t_one_sided_p[1],
    seen_t = v$t_one_sided_p[1],
    all_gain = a$mean_gain[1],
    seen_gain = v$mean_gain[1],
    stringsAsFactors = FALSE
  )
}

rows <- list(); k <- 0
for (ms in marker_seeds) {
  for (bp in boot_pairs) {
    ba <- bp[1]; bs <- bp[2]
    per_ds <- do.call(rbind, lapply(datasets, function(ds) run_one(ds, ms, ba, bs)))
    k <- k + 1
    rows[[k]] <- cbind(
      run_id = k,
      marker_seed = ms,
      boot_seed_all = ba,
      boot_seed_seen = bs,
      per_ds,
      stringsAsFactors = FALSE
    )
  }
}

detail <- do.call(rbind, rows)
write.csv(detail, file.path(out_dir,'109_seed_robustness_detail.csv'), row.names=FALSE)

agg <- aggregate(as.numeric(pass) ~ run_id + marker_seed + boot_seed_all + boot_seed_seen, data=detail, FUN=sum)
names(agg)[5] <- 'n_dataset_pass'
agg$all4_pass <- agg$n_dataset_pass == length(datasets)
write.csv(agg, file.path(out_dir,'109_seed_robustness_run_summary.csv'), row.names=FALSE)

by_ds <- aggregate(as.numeric(pass) ~ dataset_key, data=detail, FUN=mean)
names(by_ds)[2] <- 'pass_rate'
write.csv(by_ds, file.path(out_dir,'109_seed_robustness_dataset_passrate.csv'), row.names=FALSE)

cat('runs',nrow(agg),'all4_pass_rate',mean(agg$all4_pass),"\n")
print(by_ds)
