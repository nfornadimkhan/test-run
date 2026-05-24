## -----------------------------------------------------------------------------
## Stage 28: Validate all existing complete LOEO approaches (fold-matched)
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/14_cv_model_helpers_yield.R")

cv_dir <- file.path(prediction_output_dir, "loeo_cv")
out_dir <- file.path(cv_dir, "28_validation_all_approaches")
ensure_dir(out_dir)

read_metrics <- function(path, required_models = NULL) {
  if (!file.exists(path)) return(NULL)
  x <- read.csv(path, stringsAsFactors = FALSE)
  if (!is.null(required_models)) x <- x[x$model %in% required_models, ]
  x
}

## Authoritative per-model sources to avoid duplicate fold rows:
## - baseline + baseline_ec: stage 15
## - rrr1/rrr2/rfr_us: stage 16
## - meta_alpha_blend: stage 24
## - meta_alpha_conservative: stage 26
m15 <- read_metrics(file.path(cv_dir, "15_baseline_family_metrics.csv"), c("baseline", "baseline_ec"))
m16 <- read_metrics(file.path(cv_dir, "16_rrr_rfr_metrics.csv"), c("rrr1", "rrr2", "rfr_us"))
m24 <- read_metrics(file.path(cv_dir, "24_meta_alpha_blend", "24_meta_alpha_metrics_by_fold.csv"), c("meta_alpha_blend"))
m26 <- read_metrics(file.path(cv_dir, "26_meta_alpha_conservative", "26_meta_alpha_conservative_metrics_by_fold.csv"), c("meta_alpha_conservative"))

allm <- do.call(rbind, list(m15, m16, m24, m26))
allm <- allm[, c("model", "fold_id", "scope", "n_eval", "correlation", "rmse", "mspe", "mean_bias")]
allm <- unique(allm)

# Keep only models with complete fold coverage (same fold count as baseline per scope).
complete_models <- c()
scopes <- unique(allm$scope)
for (sc in scopes) {
  bfolds <- unique(allm$fold_id[allm$model == "baseline" & allm$scope == sc])
  mods <- unique(allm$model[allm$scope == sc])
  for (m in mods) {
    mfolds <- unique(allm$fold_id[allm$model == m & allm$scope == sc])
    if (length(intersect(bfolds, mfolds)) == length(bfolds)) {
      complete_models <- c(complete_models, m)
    }
  }
}
complete_models <- unique(complete_models)
allm_complete <- allm[allm$model %in% complete_models, ]

summary_metrics <- aggregate(
  cbind(correlation, rmse, mspe, mean_bias) ~ model + scope,
  data = allm_complete,
  FUN = mean,
  na.rm = TRUE
)

summary_metrics <- summary_metrics[order(summary_metrics$scope, summary_metrics$rmse), ]

# Paired fold tests vs baseline
paired_rows <- list()
for (sc in unique(allm_complete$scope)) {
  base <- allm_complete[allm_complete$model == "baseline" & allm_complete$scope == sc, c("fold_id", "rmse")]
  others <- setdiff(unique(allm_complete$model[allm_complete$scope == sc]), "baseline")
  for (m in others) {
    cmp <- allm_complete[allm_complete$model == m & allm_complete$scope == sc, c("fold_id", "rmse")]
    z <- merge(base, cmp, by = "fold_id", suffixes = c("_base", "_alt"))
    d <- z$rmse_base - z$rmse_alt
    tt <- t.test(d)
    wt <- suppressWarnings(wilcox.test(d, exact = FALSE))
    paired_rows[[paste(sc, m, sep = "_")]] <- data.frame(
      scope = sc,
      model = m,
      n_folds = nrow(z),
      mean_gain_rmse = mean(d, na.rm = TRUE),
      median_gain_rmse = median(d, na.rm = TRUE),
      win_rate = mean(d > 0, na.rm = TRUE),
      t_pvalue = tt$p.value,
      t_ci_low = tt$conf.int[1],
      t_ci_high = tt$conf.int[2],
      wilcox_pvalue = wt$p.value,
      stringsAsFactors = FALSE
    )
  }
}
paired_tests <- do.call(rbind, paired_rows)
paired_tests <- paired_tests[order(paired_tests$scope, -paired_tests$mean_gain_rmse), ]

# Track incomplete models (not fully comparable)
model_coverage <- do.call(
  rbind,
  lapply(split(allm, list(allm$model, allm$scope), drop = TRUE), function(x) {
    data.frame(
      model = x$model[1],
      scope = x$scope[1],
      n_folds = length(unique(x$fold_id)),
      stringsAsFactors = FALSE
    )
  })
)
model_coverage <- model_coverage[order(model_coverage$scope, -model_coverage$n_folds), ]

write.csv(allm_complete, file.path(out_dir, "28_fold_matched_metrics.csv"), row.names = FALSE)
write.csv(summary_metrics, file.path(out_dir, "28_summary_metrics.csv"), row.names = FALSE)
write.csv(paired_tests, file.path(out_dir, "28_paired_tests_vs_baseline.csv"), row.names = FALSE)
write.csv(model_coverage, file.path(out_dir, "28_model_coverage.csv"), row.names = FALSE)

message("Validation completed.")
print(summary_metrics)
print(paired_tests)
