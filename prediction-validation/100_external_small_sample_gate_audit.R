## -----------------------------------------------------------------------------
## Stage 100: External strict vs small-sample-adjusted gate audit
## Candidate baseline: stage-96 outputs currently in each dataset folder
## -----------------------------------------------------------------------------

source('/Users/neon/Documents/Nadim\'s Brain/analysis/prediction-validation/10_prediction_paths_and_helpers.R')

base <- '/Users/neon/Documents/Nadim\'s Brain/analysis/outputs/prediction_yield/external_validation'
keys <- c('cimmyt_wheat','dryad_rice','dryad_wheat_sparse','dryad_maize_met')

rows <- lapply(keys, function(k){
  m <- read.csv(file.path(base,k,'confirmatory_candidate_outputs',paste0(k,'_candidate_run_manifest.csv')), stringsAsFactors=FALSE)
  s <- read.csv(file.path(base,k,'confirmatory_candidate_outputs',paste0(k,'_candidate_scope_summary.csv')), stringsAsFactors=FALSE)
  n_folds <- m$n_folds[1]

  strict_pass <- all(s$mean_gain >= 0) && all(s$t_one_sided_p <= 0.05) && all(s$boot_prob_gain_positive >= 0.95)

  # Small-sample adjusted rule:
  # - if n_folds >= 10: same as strict
  # - if n_folds < 10: require gain>=0, bootstrap>=0.99, and t<=0.10
  adj_pass <- if (n_folds >= 10) {
    strict_pass
  } else {
    all(s$mean_gain >= 0) && all(s$boot_prob_gain_positive >= 0.99) && all(s$t_one_sided_p <= 0.10)
  }

  data.frame(
    dataset_key = k,
    n_folds = n_folds,
    mean_gain_all = s$mean_gain[s$scope=='all'][1],
    t_all = s$t_one_sided_p[s$scope=='all'][1],
    boot_all = s$boot_prob_gain_positive[s$scope=='all'][1],
    strict_pass = strict_pass,
    adjusted_pass = adj_pass,
    stringsAsFactors = FALSE
  )
})

out <- do.call(rbind, rows)
out_dir <- file.path(base,'run_queue')
ensure_dir(out_dir)
write.csv(out, file.path(out_dir,'100_small_sample_gate_audit.csv'), row.names=FALSE)
print(out)
