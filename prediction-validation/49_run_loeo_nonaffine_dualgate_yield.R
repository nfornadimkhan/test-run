## -----------------------------------------------------------------------------
## Stage 49: LOEO non-affine dual-gate model
##
## Distinct form from convex blend:
##   delta = gmean_shrunk - baseline
##   psi(delta) = sign(delta) * sqrt(abs(delta))
##   yhat = baseline + w1(e) * delta + w2(e) * psi(delta)
##
## w1(e), w2(e) are predicted out-of-fold from environment/fold features.
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/14_cv_model_helpers_yield.R")
ensure_package("ranger")
library(ranger)

cv_dir <- file.path(prediction_output_dir, "loeo_cv")
out_dir <- file.path(cv_dir, "49_nonaffine_dualgate")
ensure_dir(out_dir)

dat <- read_prediction_input()
pred_base <- read.csv(file.path(cv_dir, "15_baseline_family_predictions.csv"))
pred_base <- pred_base[pred_base$model == "baseline", ]

rmse <- function(y, p) sqrt(mean((y - p)^2, na.rm = TRUE))

fold_ids <- unique(pred_base$fold_id)
fold_rows <- list()
fold_predictions <- list()

w1_grid <- seq(-0.5, 1.5, by = 0.05)
w2_grid <- seq(-2.0, 2.0, by = 0.10)

for (f in fold_ids) {
  te <- pred_base[pred_base$fold_id == f, ]
  env <- unique(te$env_id)
  tr <- dat[!dat$env_id %in% env, ]

  gmean <- aggregate(yld_bu_ac ~ geno_ID, data = tr, FUN = mean)
  ng <- aggregate(yld_bu_ac ~ geno_ID, data = tr, FUN = length)
  names(gmean)[2] <- "gmean"
  names(ng)[2] <- "ng"
  gstats <- merge(gmean, ng, by = "geno_ID", all = TRUE)

  te2 <- merge(te, gstats, by = "geno_ID", all.x = TRUE)
  mu <- mean(tr$yld_bu_ac, na.rm = TRUE)
  te2$gmean[is.na(te2$gmean)] <- mu
  te2$ng[is.na(te2$ng)] <- 0
  te2$gmean_shrunk <- (te2$ng / (te2$ng + 20)) * te2$gmean + (20 / (te2$ng + 20)) * mu

  te2$delta <- te2$gmean_shrunk - te2$predicted_value
  te2$psi <- sign(te2$delta) * sqrt(abs(te2$delta))

  best_rmse <- Inf
  best_w1 <- 0
  best_w2 <- 0

  for (w1 in w1_grid) {
    for (w2 in w2_grid) {
      p <- te2$predicted_value + w1 * te2$delta + w2 * te2$psi
      r <- rmse(te2$y_true, p)
      if (is.finite(r) && r < best_rmse) {
        best_rmse <- r
        best_w1 <- w1
        best_w2 <- w2
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
    w1_oracle = best_w1,
    w2_oracle = best_w2,
    oracle_rmse = best_rmse,
    base_rmse = rmse(te2$y_true, te2$predicted_value),
    mean_pred = mean(te2$predicted_value, na.rm = TRUE),
    sd_pred = sd(te2$predicted_value, na.rm = TRUE),
    n_eval = nrow(te2),
    envf,
    stringsAsFactors = FALSE
  )

  fold_predictions[[f]] <- te2
}

fold_df <- do.call(rbind, fold_rows)
for (nm in names(fold_df)) {
  if (is.numeric(fold_df[[nm]]) && anyNA(fold_df[[nm]])) {
    fold_df[[nm]][is.na(fold_df[[nm]])] <- mean(fold_df[[nm]], na.rm = TRUE)
  }
}
fold_df$location <- as.factor(fold_df$location)

w1_hat <- numeric(nrow(fold_df))
w2_hat <- numeric(nrow(fold_df))

for (i in seq_len(nrow(fold_df))) {
  tr <- fold_df[-i, ]
  te <- fold_df[i, ]

  fit_w1 <- ranger(w1_oracle ~ . - fold_id - env_id - w2_oracle - oracle_rmse, data = tr, num.trees = 600, min.node.size = 2)
  fit_w2 <- ranger(w2_oracle ~ . - fold_id - env_id - w1_oracle - oracle_rmse, data = tr, num.trees = 600, min.node.size = 2)

  w1_hat[i] <- as.numeric(predict(fit_w1, te)$predictions[1])
  w2_hat[i] <- as.numeric(predict(fit_w2, te)$predictions[1])
}

fold_df$w1_meta <- w1_hat
fold_df$w2_meta <- w2_hat

pred_out <- do.call(
  rbind,
  lapply(seq_len(nrow(fold_df)), function(i) {
    f <- fold_df$fold_id[i]
    x <- fold_predictions[[f]]
    w1 <- fold_df$w1_meta[i]
    w2 <- fold_df$w2_meta[i]
    x$w1_meta <- w1
    x$w2_meta <- w2
    x$pred_nonaffine <- x$predicted_value + w1 * x$delta + w2 * x$psi
    x
  })
)

score_model_by_fold <- function(df, pred_col, model_name) {
  do.call(
    rbind,
    lapply(split(df, df$fold_id), function(x) {
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
    })
  )
}

metrics_by_fold <- rbind(
  score_model_by_fold(pred_out, "predicted_value", "baseline"),
  score_model_by_fold(pred_out, "pred_nonaffine", "nonaffine_dualgate")
)

summary_metrics <- aggregate(cbind(correlation, rmse, mspe, mean_bias) ~ model + scope, data = metrics_by_fold, FUN = mean, na.rm = TRUE)

write.csv(pred_out, file.path(out_dir, "49_nonaffine_dualgate_predictions.csv"), row.names = FALSE)
write.csv(fold_df, file.path(out_dir, "49_nonaffine_dualgate_fold_features.csv"), row.names = FALSE)
write.csv(metrics_by_fold, file.path(out_dir, "49_nonaffine_dualgate_metrics_by_fold.csv"), row.names = FALSE)
write.csv(summary_metrics, file.path(out_dir, "49_nonaffine_dualgate_summary_metrics.csv"), row.names = FALSE)

message("Saved stage-49 non-affine dual-gate results.")
print(summary_metrics)
