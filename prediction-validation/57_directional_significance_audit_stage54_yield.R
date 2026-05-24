## -----------------------------------------------------------------------------
## Stage 57: Directional significance audit for stage-54 vs meta_alpha_blend
##
## Focus:
## - one-sided paired tests (improvement direction)
## - one-sided permutation p-value
## - bootstrap probability(mean gain > 0)
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/10_prediction_paths_and_helpers.R")

cv_dir <- file.path(prediction_output_dir, "loeo_cv")
in_file <- file.path(cv_dir, "54_constrained_regime_regularized", "54_regularized_metrics_by_fold.csv")
out_dir <- file.path(cv_dir, "57_directional_significance_audit")
ensure_dir(out_dir)

m <- read.csv(in_file)

analyze_scope <- function(sc, B = 50000) {
  a <- m[m$model == "meta_alpha_blend" & m$scope == sc, c("fold_id", "rmse")]
  b <- m[m$model == "constrained_regime_regularized" & m$scope == sc, c("fold_id", "rmse")]
  z <- merge(a, b, by = "fold_id", suffixes = c("_meta", "_new"))
  d <- z$rmse_meta - z$rmse_new
  n <- length(d)

  tt2 <- t.test(z$rmse_meta, z$rmse_new, paired = TRUE, alternative = "two.sided")
  tt1 <- t.test(z$rmse_meta, z$rmse_new, paired = TRUE, alternative = "greater")
  wt1 <- wilcox.test(z$rmse_meta, z$rmse_new, paired = TRUE, alternative = "greater", exact = FALSE)

  set.seed(ifelse(sc == "all", 5701, 5703))
  signs <- matrix(sample(c(-1, 1), n * B, replace = TRUE), nrow = B)
  perm_means <- rowMeans(signs * rep(d, each = B))
  p_perm <- mean(perm_means >= mean(d))

  set.seed(ifelse(sc == "all", 5702, 5704))
  idx <- matrix(sample.int(n, n * B, replace = TRUE), nrow = B)
  bmeans <- rowMeans(matrix(d[idx], nrow = B))

  data.frame(
    scope = sc,
    n_folds = n,
    mean_gain_rmse = mean(d),
    median_gain_rmse = median(d),
    win_rate = mean(d > 0),
    t_two_sided_p = tt2$p.value,
    t_one_sided_p = tt1$p.value,
    wilcox_one_sided_p = wt1$p.value,
    perm_one_sided_p = p_perm,
    boot_prob_gain_positive = mean(bmeans > 0),
    boot_q025 = as.numeric(quantile(bmeans, 0.025)),
    boot_q50 = as.numeric(quantile(bmeans, 0.50)),
    boot_q975 = as.numeric(quantile(bmeans, 0.975)),
    stringsAsFactors = FALSE
  )
}

res <- rbind(analyze_scope("all"), analyze_scope("seen_genotypes"))

write.csv(res, file.path(out_dir, "57_directional_significance_summary.csv"), row.names = FALSE)
message("Saved stage-57 directional significance audit.")
print(res)
