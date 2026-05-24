## -----------------------------------------------------------------------------
## Stage 53: Constrained regime correction (two-objective)
##
## Goal:
## - improve all-scope RMSE
## - avoid seen_genotypes degradation
##
## For each fold, choose (u1,u2) by minimizing:
##   obj = rmse_all + lambda * max(0, rmse_seen - rmse_seen_meta)
##
## Prediction:
##   pred = pred_meta + u1*delta + u2*psi
##   delta = gmean_shrunk - predicted_value
##   psi = sign(delta) * sqrt(abs(delta))
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/14_cv_model_helpers_yield.R")
ensure_package("ranger")
library(ranger)

cv_dir <- file.path(prediction_output_dir, "loeo_cv")
out_dir <- file.path(cv_dir, "53_constrained_regime_correction")
ensure_dir(out_dir)

pred24 <- read.csv(file.path(cv_dir, "24_meta_alpha_blend", "24_meta_alpha_blend_predictions.csv"))
pred24 <- pred24[pred24$model == "baseline", ]
dat <- read_prediction_input()

rmse <- function(y, p) sqrt(mean((y - p)^2, na.rm = TRUE))
fold_ids <- unique(pred24$fold_id)

u1_grid <- seq(-1.0, 1.0, by = 0.05)
u2_grid <- seq(-1.5, 1.5, by = 0.10)
lambda_pen <- 4.0

fold_rows <- list()
fold_pred <- list()

for (f in fold_ids) {
  x <- pred24[pred24$fold_id == f, ]
  env <- unique(x$env_id)
  x$delta <- x$gmean_shrunk - x$predicted_value
  x$psi <- sign(x$delta) * sqrt(abs(x$delta))

  seen <- x[x$seen_in_train, ]
  rmse_seen_meta <- rmse(seen$y_true, seen$pred_meta)

  best_obj <- Inf
  best_u1 <- 0
  best_u2 <- 0
  best_all <- rmse(x$y_true, x$pred_meta)
  best_seen <- rmse_seen_meta

  for (u1 in u1_grid) {
    for (u2 in u2_grid) {
      p <- x$pred_meta + u1 * x$delta + u2 * x$psi
      r_all <- rmse(x$y_true, p)
      r_seen <- rmse(seen$y_true, p[x$seen_in_train])
      obj <- r_all + lambda_pen * max(0, r_seen - rmse_seen_meta)
      if (is.finite(obj) && obj < best_obj) {
        best_obj <- obj
        best_u1 <- u1
        best_u2 <- u2
        best_all <- r_all
        best_seen <- r_seen
      }
    }
  }

  envf <- unique(dat[dat$env_id == env, c(
    "year", "location",
    "EC1", "EC2", "EC3", "EC4", "EC5",
    "MeanTemp_season_sc", "RainSum_season_sc", "RadMean_season_sc",
    "ET0Sum_season_sc", "HotDays35_season_sc"
  )])

  fold_rows[[f]] <- data.frame(
    fold_id = f,
    env_id = env,
    u1_oracle = best_u1,
    u2_oracle = best_u2,
    rmse_meta_all = rmse(x$y_true, x$pred_meta),
    rmse_meta_seen = rmse_seen_meta,
    rmse_oracle_all = best_all,
    rmse_oracle_seen = best_seen,
    n_eval = nrow(x),
    envf,
    stringsAsFactors = FALSE
  )
  fold_pred[[f]] <- x
}

fold_df <- do.call(rbind, fold_rows)
for (nm in names(fold_df)) {
  if (is.numeric(fold_df[[nm]]) && anyNA(fold_df[[nm]])) {
    fold_df[[nm]][is.na(fold_df[[nm]])] <- mean(fold_df[[nm]], na.rm = TRUE)
  }
}
fold_df$location <- as.factor(fold_df$location)

u1_hat <- numeric(nrow(fold_df))
u2_hat <- numeric(nrow(fold_df))
for (i in seq_len(nrow(fold_df))) {
  tr <- fold_df[-i, ]
  te <- fold_df[i, ]
  fit1 <- ranger(u1_oracle ~ . - fold_id - env_id - u2_oracle - rmse_oracle_all - rmse_oracle_seen, data = tr, num.trees = 600, min.node.size = 2)
  fit2 <- ranger(u2_oracle ~ . - fold_id - env_id - u1_oracle - rmse_oracle_all - rmse_oracle_seen, data = tr, num.trees = 600, min.node.size = 2)
  u1_hat[i] <- as.numeric(predict(fit1, te)$predictions[1])
  u2_hat[i] <- as.numeric(predict(fit2, te)$predictions[1])
}
fold_df$u1_meta <- u1_hat
fold_df$u2_meta <- u2_hat

pred_out <- do.call(rbind, lapply(seq_len(nrow(fold_df)), function(i) {
  f <- fold_df$fold_id[i]
  x <- fold_pred[[f]]
  u1 <- fold_df$u1_meta[i]
  u2 <- fold_df$u2_meta[i]
  x$u1_meta <- u1
  x$u2_meta <- u2
  x$pred_constrained <- x$pred_meta + u1 * x$delta + u2 * x$psi
  x
}))

score_model_by_fold <- function(df, pred_col, model_name) {
  do.call(rbind, lapply(split(df, df$fold_id), function(x) {
    all_df <- data.frame(
      model = model_name, fold_id = x$fold_id[1], scope = "all",
      n_eval = nrow(x),
      correlation = safe_cor(x$y_true, x[[pred_col]]),
      rmse = safe_rmse(x$y_true, x[[pred_col]]),
      mspe = safe_mspe(x$y_true, x[[pred_col]]),
      mean_bias = safe_bias(x$y_true, x[[pred_col]]),
      stringsAsFactors = FALSE
    )
    seen <- x[x$seen_in_train, ]
    seen_df <- data.frame(
      model = model_name, fold_id = x$fold_id[1], scope = "seen_genotypes",
      n_eval = nrow(seen),
      correlation = safe_cor(seen$y_true, seen[[pred_col]]),
      rmse = safe_rmse(seen$y_true, seen[[pred_col]]),
      mspe = safe_mspe(seen$y_true, seen[[pred_col]]),
      mean_bias = safe_bias(seen$y_true, seen[[pred_col]]),
      stringsAsFactors = FALSE
    )
    rbind(all_df, seen_df)
  }))
}

metrics_by_fold <- rbind(
  score_model_by_fold(pred_out, "pred_meta", "meta_alpha_blend"),
  score_model_by_fold(pred_out, "pred_constrained", "constrained_regime_correction")
)
summary_metrics <- aggregate(cbind(correlation, rmse, mspe, mean_bias) ~ model + scope, data = metrics_by_fold, FUN = mean, na.rm = TRUE)

write.csv(pred_out, file.path(out_dir, "53_constrained_predictions.csv"), row.names = FALSE)
write.csv(fold_df, file.path(out_dir, "53_constrained_fold_features.csv"), row.names = FALSE)
write.csv(metrics_by_fold, file.path(out_dir, "53_constrained_metrics_by_fold.csv"), row.names = FALSE)
write.csv(summary_metrics, file.path(out_dir, "53_constrained_summary_metrics.csv"), row.names = FALSE)

message("Saved stage-53 constrained regime correction results.")
print(summary_metrics)
