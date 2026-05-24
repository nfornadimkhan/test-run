## -----------------------------------------------------------------------------
## Stage 61: Replicated subset-significance audit for stage-59 candidate
##
## Purpose:
## Evaluate stability of one-sided paired significance when using random subsets
## of LOEO folds, to test robustness of near-threshold p-values.
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/10_prediction_paths_and_helpers.R")

cv_dir <- file.path(prediction_output_dir, "loeo_cv")
in_file <- file.path(cv_dir, "59_worldfirst_candidate_fixed", "59_fixed_metrics_by_fold.csv")
out_dir <- file.path(cv_dir, "61_subset_significance_stage59")
ensure_dir(out_dir)

m <- read.csv(in_file)

run_rep <- function(scope_name, fold_k = 18, n_rep = 4000, seed = 6101) {
  z <- m[m$scope == scope_name, c("fold_id", "model", "rmse")]
  meta <- z[z$model == "meta_alpha_blend", c("fold_id", "rmse")]
  newm <- z[z$model == "worldfirst_candidate_fixed", c("fold_id", "rmse")]
  d0 <- merge(meta, newm, by = "fold_id", suffixes = c("_meta", "_new"))

  folds <- unique(d0$fold_id)
  if (fold_k > length(folds)) fold_k <- length(folds)

  set.seed(seed)
  reps <- vector("list", n_rep)

  for (i in seq_len(n_rep)) {
    fsub <- sample(folds, size = fold_k, replace = FALSE)
    x <- d0[d0$fold_id %in% fsub, ]
    d <- x$rmse_meta - x$rmse_new

    tt <- t.test(x$rmse_meta, x$rmse_new, paired = TRUE, alternative = "greater")
    wt <- wilcox.test(x$rmse_meta, x$rmse_new, paired = TRUE, alternative = "greater", exact = FALSE)

    reps[[i]] <- data.frame(
      scope = scope_name,
      rep_id = i,
      n_folds = fold_k,
      mean_gain = mean(d),
      win_rate = mean(d > 0),
      p_t_one_sided = tt$p.value,
      p_w_one_sided = wt$p.value,
      pass_t = tt$p.value <= 0.05,
      pass_w = wt$p.value <= 0.05,
      pass_both = (tt$p.value <= 0.05) & (wt$p.value <= 0.05),
      stringsAsFactors = FALSE
    )
  }

  do.call(rbind, reps)
}

res_all <- run_rep("all", fold_k = 18, n_rep = 4000, seed = 6101)
res_seen <- run_rep("seen_genotypes", fold_k = 18, n_rep = 4000, seed = 6102)
res <- rbind(res_all, res_seen)

summ <- do.call(rbind, lapply(split(res, res$scope), function(x) {
  data.frame(
    scope = x$scope[1],
    n_rep = nrow(x),
    fold_k = x$n_folds[1],
    mean_gain_mean = mean(x$mean_gain),
    mean_gain_q05 = as.numeric(quantile(x$mean_gain, 0.05)),
    mean_gain_q95 = as.numeric(quantile(x$mean_gain, 0.95)),
    pass_t_rate = mean(x$pass_t),
    pass_w_rate = mean(x$pass_w),
    pass_both_rate = mean(x$pass_both),
    stringsAsFactors = FALSE
  )
}))

joint <- merge(
  res_all[, c("rep_id", "pass_t", "pass_w", "pass_both")],
  res_seen[, c("rep_id", "pass_t", "pass_w", "pass_both")],
  by = "rep_id",
  suffixes = c("_all", "_seen")
)

joint_summary <- data.frame(
  n_rep = nrow(joint),
  pass_t_both_scopes_rate = mean(joint$pass_t_all & joint$pass_t_seen),
  pass_w_both_scopes_rate = mean(joint$pass_w_all & joint$pass_w_seen),
  pass_both_tests_both_scopes_rate = mean(joint$pass_both_all & joint$pass_both_seen),
  stringsAsFactors = FALSE
)

write.csv(res, file.path(out_dir, "61_subset_significance_replicates.csv"), row.names = FALSE)
write.csv(summ, file.path(out_dir, "61_subset_significance_summary_by_scope.csv"), row.names = FALSE)
write.csv(joint_summary, file.path(out_dir, "61_subset_significance_joint_summary.csv"), row.names = FALSE)

message("Saved stage-61 subset-significance audit outputs.")
print(summ)
print(joint_summary)
