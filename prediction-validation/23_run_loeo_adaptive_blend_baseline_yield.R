## -----------------------------------------------------------------------------
## Stage 23: LOEO adaptive blend on top of baseline predictions
##
## Goal:
## Improve unknown-environment prediction by combining:
## - baseline mixed-model prediction
## - genotype historical mean from training environments
##
## Blend:
## yhat_blend = alpha_e * yhat_baseline + (1 - alpha_e) * gmean_shrunk
##
## alpha_e is predicted by a leave-one-fold-out meta-model using only fold-level
## features available at prediction time (no test response leakage).
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/14_cv_model_helpers_yield.R")

cv_dir <- file.path(prediction_output_dir, "loeo_cv")
out_dir <- file.path(cv_dir, "23_adaptive_blend")
ensure_dir(out_dir)

dat <- read_prediction_input()
pred_base <- read.csv(file.path(cv_dir, "15_baseline_family_predictions.csv"))
pred_base <- pred_base[pred_base$model == "baseline", ]

if (!"prediction_se" %in% names(pred_base)) {
  pred_base$prediction_se <- NA_real_
}

rmse <- function(y, p) sqrt(mean((y - p)^2, na.rm = TRUE))

make_fold_augmented <- function(fold_id, lambda = 20) {
  te <- pred_base[pred_base$fold_id == fold_id, ]
  env <- unique(te$env_id)
  tr <- dat[!dat$env_id %in% env, ]

  gmean2 <- aggregate(yld_bu_ac ~ geno_ID, data = tr, FUN = mean)
  ng2 <- aggregate(yld_bu_ac ~ geno_ID, data = tr, FUN = length)
  names(gmean2)[2] <- "gmean"
  names(ng2)[2] <- "ng"
  gmean2 <- merge(gmean2, ng2, by = "geno_ID", all = TRUE)

  te2 <- merge(te, gmean2, by = "geno_ID", all.x = TRUE)
  mu <- mean(tr$yld_bu_ac, na.rm = TRUE)
  te2$gmean[is.na(te2$gmean)] <- mu
  te2$ng[is.na(te2$ng)] <- 0
  te2$gmean_shrunk <- (te2$ng / (te2$ng + lambda)) * te2$gmean + (lambda / (te2$ng + lambda)) * mu

  # Oracle alpha per fold (for meta-model target only).
  a_grid <- seq(0, 1, by = 0.02)
  rms <- sapply(a_grid, function(a) rmse(te2$y_true, a * te2$predicted_value + (1 - a) * te2$gmean_shrunk))
  te2$alpha_oracle <- a_grid[which.min(rms)]
  te2
}

fold_ids <- unique(pred_base$fold_id)
fold_aug <- lapply(fold_ids, make_fold_augmented)

fold_features <- do.call(
  rbind,
  lapply(fold_aug, function(x) {
    data.frame(
      fold_id = x$fold_id[1],
      env_id = x$env_id[1],
      alpha_oracle = x$alpha_oracle[1],
      n_eval = nrow(x),
      mean_pred = mean(x$predicted_value, na.rm = TRUE),
      sd_pred = sd(x$predicted_value, na.rm = TRUE),
      mean_se = mean(x$prediction_se, na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  })
)

if (all(!is.finite(fold_features$mean_se))) {
  fold_features$mean_se <- mean(fold_features$sd_pred, na.rm = TRUE)
}

fold_features$mean_se[!is.finite(fold_features$mean_se)] <- mean(fold_features$mean_se[is.finite(fold_features$mean_se)], na.rm = TRUE)

predict_alpha_lofo <- function(i) {
  tr <- fold_features[-i, ]
  te <- fold_features[i, ]
  fit <- lm(alpha_oracle ~ mean_se + sd_pred + mean_pred + n_eval, data = tr)
  a <- as.numeric(predict(fit, newdata = te))
  a <- max(0, min(1, a))
  a
}

fold_features$alpha_pred <- sapply(seq_len(nrow(fold_features)), predict_alpha_lofo)

pred_out <- do.call(
  rbind,
  lapply(seq_along(fold_aug), function(i) {
    x <- fold_aug[[i]]
    a <- fold_features$alpha_pred[fold_features$fold_id == x$fold_id[1]]
    x$alpha_pred <- a
    x$pred_blend <- a * x$predicted_value + (1 - a) * x$gmean_shrunk
    x
  })
)

score_scope <- function(df, pred_col, scope_name = "all") {
  x <- df
  if (scope_name == "seen_genotypes") x <- x[x$seen_in_train, ]
  x <- x[complete.cases(x$y_true, x[[pred_col]]), ]
  data.frame(
    scope = scope_name,
    n_eval = nrow(x),
    correlation = safe_cor(x$y_true, x[[pred_col]]),
    rmse = safe_rmse(x$y_true, x[[pred_col]]),
    mspe = safe_mspe(x$y_true, x[[pred_col]]),
    mean_bias = safe_bias(x$y_true, x[[pred_col]]),
    stringsAsFactors = FALSE
  )
}

fold_metrics <- do.call(
  rbind,
  lapply(split(pred_out, pred_out$fold_id), function(x) {
    data.frame(
      fold_id = x$fold_id[1],
      model = "adaptive_blend",
      rbind(score_scope(x, "pred_blend", "all"), score_scope(x, "pred_blend", "seen_genotypes")),
      alpha_pred = x$alpha_pred[1],
      alpha_oracle = x$alpha_oracle[1],
      stringsAsFactors = FALSE
    )
  })
)

baseline_fold_metrics <- do.call(
  rbind,
  lapply(split(pred_out, pred_out$fold_id), function(x) {
    data.frame(
      fold_id = x$fold_id[1],
      model = "baseline",
      rbind(score_scope(x, "predicted_value", "all"), score_scope(x, "predicted_value", "seen_genotypes")),
      stringsAsFactors = FALSE
    )
  })
)

metrics_all <- rbind(
  fold_metrics[, c("model", "fold_id", "scope", "n_eval", "correlation", "rmse", "mspe", "mean_bias")],
  baseline_fold_metrics[, c("model", "fold_id", "scope", "n_eval", "correlation", "rmse", "mspe", "mean_bias")]
)

summary_metrics <- aggregate(cbind(correlation, rmse, mspe, mean_bias) ~ model + scope, data = metrics_all, FUN = mean, na.rm = TRUE)

write.csv(pred_out, file.path(out_dir, "23_adaptive_blend_predictions.csv"), row.names = FALSE)
write.csv(fold_features, file.path(out_dir, "23_adaptive_blend_fold_features.csv"), row.names = FALSE)
write.csv(metrics_all, file.path(out_dir, "23_adaptive_blend_metrics_by_fold.csv"), row.names = FALSE)
write.csv(summary_metrics, file.path(out_dir, "23_adaptive_blend_summary_metrics.csv"), row.names = FALSE)

message("Saved LOEO adaptive-blend results.")
print(summary_metrics)
