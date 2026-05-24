## -----------------------------------------------------------------------------
## Stage 26: Conservative meta-alpha blend (nested LOFO calibration)
##
## Start from stage-24 meta-alpha predictions and apply:
##   a_cons = 1 - t * (1 - a_meta), with t in [0,1]
##
## Interpretation:
## - t = 1   : original meta-alpha blend
## - t = 0   : baseline only
##
## We tune t per held-out fold using ONLY other folds (nested LOFO),
## minimizing average of all-scope and seen-genotype RMSE.
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/14_cv_model_helpers_yield.R")

cv_dir <- file.path(prediction_output_dir, "loeo_cv")
in_file <- file.path(cv_dir, "24_meta_alpha_blend", "24_meta_alpha_blend_predictions.csv")
out_dir <- file.path(cv_dir, "26_meta_alpha_conservative")
ensure_dir(out_dir)

p <- read.csv(in_file)
fold_ids <- unique(p$fold_id)
t_grid <- seq(0, 1, by = 0.05)

rmse <- function(y, pred) sqrt(mean((y - pred)^2, na.rm = TRUE))

score_fold <- function(df, t_value) {
  a_cons <- 1 - t_value * (1 - df$a_meta)
  pred <- a_cons * df$predicted_value + (1 - a_cons) * df$gmean_shrunk
  r_all <- rmse(df$y_true, pred)
  seen <- df[df$seen_in_train, ]
  pred_seen <- pred[df$seen_in_train]
  r_seen <- rmse(seen$y_true, pred_seen)
  0.5 * r_all + 0.5 * r_seen
}

rows <- list()
pred_rows <- list()

for (f in fold_ids) {
  train_folds <- setdiff(fold_ids, f)
  score_t <- sapply(
    t_grid,
    function(tv) {
      mean(
        sapply(train_folds, function(ff) {
          score_fold(p[p$fold_id == ff, ], tv)
        })
      )
    }
  )
  t_best <- t_grid[which.min(score_t)]

  x <- p[p$fold_id == f, ]
  x$a_cons <- 1 - t_best * (1 - x$a_meta)
  x$pred_cons <- x$a_cons * x$predicted_value + (1 - x$a_cons) * x$gmean_shrunk

  b_all <- rmse(x$y_true, x$predicted_value)
  n_all <- rmse(x$y_true, x$pred_cons)
  s <- x[x$seen_in_train, ]
  b_seen <- rmse(s$y_true, s$predicted_value)
  n_seen <- rmse(s$y_true, s$pred_cons)

  rows[[f]] <- data.frame(
    fold_id = f,
    t_best = t_best,
    baseline_rmse_all = b_all,
    conservative_rmse_all = n_all,
    baseline_rmse_seen = b_seen,
    conservative_rmse_seen = n_seen,
    stringsAsFactors = FALSE
  )
  pred_rows[[f]] <- x
}

fold_metrics <- do.call(rbind, rows)
pred_out <- do.call(rbind, pred_rows)

metrics_by_fold <- rbind(
  do.call(
    rbind,
    lapply(split(pred_out, pred_out$fold_id), function(x) {
      data.frame(
        model = "baseline",
        fold_id = x$fold_id[1],
        scope = "all",
        n_eval = nrow(x),
        correlation = safe_cor(x$y_true, x$predicted_value),
        rmse = safe_rmse(x$y_true, x$predicted_value),
        mspe = safe_mspe(x$y_true, x$predicted_value),
        mean_bias = safe_bias(x$y_true, x$predicted_value),
        stringsAsFactors = FALSE
      )
    })
  ),
  do.call(
    rbind,
    lapply(split(pred_out, pred_out$fold_id), function(x) {
      data.frame(
        model = "meta_alpha_conservative",
        fold_id = x$fold_id[1],
        scope = "all",
        n_eval = nrow(x),
        correlation = safe_cor(x$y_true, x$pred_cons),
        rmse = safe_rmse(x$y_true, x$pred_cons),
        mspe = safe_mspe(x$y_true, x$pred_cons),
        mean_bias = safe_bias(x$y_true, x$pred_cons),
        stringsAsFactors = FALSE
      )
    })
  ),
  do.call(
    rbind,
    lapply(split(pred_out[pred_out$seen_in_train, ], pred_out[pred_out$seen_in_train, ]$fold_id), function(x) {
      data.frame(
        model = "baseline",
        fold_id = x$fold_id[1],
        scope = "seen_genotypes",
        n_eval = nrow(x),
        correlation = safe_cor(x$y_true, x$predicted_value),
        rmse = safe_rmse(x$y_true, x$predicted_value),
        mspe = safe_mspe(x$y_true, x$predicted_value),
        mean_bias = safe_bias(x$y_true, x$predicted_value),
        stringsAsFactors = FALSE
      )
    })
  ),
  do.call(
    rbind,
    lapply(split(pred_out[pred_out$seen_in_train, ], pred_out[pred_out$seen_in_train, ]$fold_id), function(x) {
      data.frame(
        model = "meta_alpha_conservative",
        fold_id = x$fold_id[1],
        scope = "seen_genotypes",
        n_eval = nrow(x),
        correlation = safe_cor(x$y_true, x$pred_cons),
        rmse = safe_rmse(x$y_true, x$pred_cons),
        mspe = safe_mspe(x$y_true, x$pred_cons),
        mean_bias = safe_bias(x$y_true, x$pred_cons),
        stringsAsFactors = FALSE
      )
    })
  )
)

summary_metrics <- aggregate(
  cbind(correlation, rmse, mspe, mean_bias) ~ model + scope,
  data = metrics_by_fold,
  FUN = mean,
  na.rm = TRUE
)

write.csv(pred_out, file.path(out_dir, "26_meta_alpha_conservative_predictions.csv"), row.names = FALSE)
write.csv(fold_metrics, file.path(out_dir, "26_meta_alpha_conservative_fold_rmse.csv"), row.names = FALSE)
write.csv(metrics_by_fold, file.path(out_dir, "26_meta_alpha_conservative_metrics_by_fold.csv"), row.names = FALSE)
write.csv(summary_metrics, file.path(out_dir, "26_meta_alpha_conservative_summary_metrics.csv"), row.names = FALSE)

message("Saved LOEO conservative meta-alpha blend results.")
print(summary_metrics)

