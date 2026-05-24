## -----------------------------------------------------------------------------
## Stage 41: Uncertainty analysis for RMSE differences between top blend variants
##
## Compares:
## - meta_alpha_blend (stage 24)
## - alpha_search_ranger_shift (stage 40)
##
## Outputs bootstrap CIs and fold-level sign probabilities.
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/10_prediction_paths_and_helpers.R")

cv_dir <- file.path(prediction_output_dir, "loeo_cv")
out_dir <- file.path(cv_dir, "41_rmse_difference_uncertainty")
ensure_dir(out_dir)

old <- read.csv(file.path(cv_dir, "24_meta_alpha_blend", "24_meta_alpha_metrics_by_fold.csv"))
new <- read.csv(file.path(cv_dir, "40_alpha_model_search", "40_alpha_model_search_metrics_by_fold.csv"))
new <- new[new$model == "alpha_search_ranger_shift", ]

boot_mean <- function(x, B = 20000, seed = 41) {
  set.seed(seed)
  n <- length(x)
  idx <- matrix(sample.int(n, size = n * B, replace = TRUE), nrow = B, ncol = n)
  means <- rowMeans(matrix(x[idx], nrow = B))
  c(
    mean = mean(x),
    q025 = as.numeric(quantile(means, 0.025)),
    q50 = as.numeric(quantile(means, 0.50)),
    q975 = as.numeric(quantile(means, 0.975))
  )
}

analyze_scope <- function(scope_name) {
  a <- old[old$model == "meta_alpha_blend" & old$scope == scope_name, c("fold_id", "rmse")]
  b <- new[new$scope == scope_name, c("fold_id", "rmse")]
  m <- merge(a, b, by = "fold_id", suffixes = c("_meta", "_new"))

  d <- m$rmse_meta - m$rmse_new

  tt <- t.test(m$rmse_meta, m$rmse_new, paired = TRUE)
  wt <- wilcox.test(m$rmse_meta, m$rmse_new, paired = TRUE, exact = FALSE)
  bt <- boot_mean(d, B = 20000, seed = ifelse(scope_name == "all", 4101, 4102))

  data.frame(
    scope = scope_name,
    n_folds = nrow(m),
    mean_gain_rmse = mean(d),
    median_gain_rmse = median(d),
    win_rate = mean(d > 0),
    loss_rate = mean(d < 0),
    tie_rate = mean(d == 0),
    t_pvalue = tt$p.value,
    t_ci_low = tt$conf.int[1],
    t_ci_high = tt$conf.int[2],
    wilcox_pvalue = wt$p.value,
    boot_mean = bt["mean"],
    boot_ci_low = bt["q025"],
    boot_ci_med = bt["q50"],
    boot_ci_high = bt["q975"],
    stringsAsFactors = FALSE
  )
}

res <- rbind(
  analyze_scope("all"),
  analyze_scope("seen_genotypes")
)

write.csv(res, file.path(out_dir, "41_rmse_difference_uncertainty.csv"), row.names = FALSE)
message("Saved stage-41 uncertainty analysis.")
print(res)
