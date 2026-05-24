## -----------------------------------------------------------------------------
## Stage 24: LOEO meta-alpha blend (best current unknown-environment method)
##
## Base predictors:
## - baseline mixed-model prediction (from stage 15 output)
## - genotype historical mean (training environments only), shrunk to global mean
##
## Blend:
## yhat = alpha_hat(e) * yhat_baseline + (1 - alpha_hat(e)) * gmean_shrunk
##
## alpha_hat(e) is predicted by a leave-one-fold-out meta-model (ranger)
## from fold-level environment/prediction features.
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/14_cv_model_helpers_yield.R")

ensure_package("ranger")
library(ranger)

cv_dir <- file.path(prediction_output_dir, "loeo_cv")
out_dir <- file.path(cv_dir, "24_meta_alpha_blend")
ensure_dir(out_dir)

dat <- read_prediction_input()
pred_base <- read.csv(file.path(cv_dir, "15_baseline_family_predictions.csv"))
pred_base <- pred_base[pred_base$model == "baseline", ]

rmse <- function(y, p) sqrt(mean((y - p)^2, na.rm = TRUE))

fold_ids <- unique(pred_base$fold_id)
fold_rows <- list()
fold_predictions <- list()

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

  # Oracle alpha (target for fold-level meta-model only).
  a_grid <- seq(0, 1, by = 0.01)
  rms <- sapply(a_grid, function(a) rmse(te2$y_true, a * te2$predicted_value + (1 - a) * te2$gmean_shrunk))
  a_opt <- a_grid[which.min(rms)]

  envf <- unique(dat[dat$env_id == env, c(
    "year", "location",
    "EC1", "EC2", "EC3", "EC4", "EC5",
    "MeanTemp_season_sc", "RainSum_season_sc", "RadMean_season_sc",
    "ET0Sum_season_sc", "HotDays35_season_sc"
  )])

  fold_rows[[f]] <- data.frame(
    fold_id = f,
    env_id = env,
    a_oracle = a_opt,
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

# Leave-one-fold-out alpha prediction
alpha_hat <- numeric(nrow(fold_df))
for (i in seq_len(nrow(fold_df))) {
  tr <- fold_df[-i, ]
  te <- fold_df[i, ]
  fit <- ranger(
    a_oracle ~ . - fold_id - env_id,
    data = tr,
    num.trees = 500,
    min.node.size = 2
  )
  a <- as.numeric(predict(fit, te)$predictions[1])
  alpha_hat[i] <- max(0, min(1, a))
}
fold_df$a_meta <- alpha_hat

pred_out <- do.call(
  rbind,
  lapply(seq_len(nrow(fold_df)), function(i) {
    f <- fold_df$fold_id[i]
    a <- fold_df$a_meta[i]
    x <- fold_predictions[[f]]
    x$a_meta <- a
    x$a_oracle <- fold_df$a_oracle[i]
    x$pred_meta <- a * x$predicted_value + (1 - a) * x$gmean_shrunk
    x
  })
)

score_model_by_fold <- function(df, pred_col, model_name) {
  do.call(
    rbind,
    lapply(split(df, df$fold_id), function(x) {
      all_df <- data.frame(
        model = model_name,
        fold_id = x$fold_id[1],
        scope = "all",
        n_eval = nrow(x),
        correlation = safe_cor(x$y_true, x[[pred_col]]),
        rmse = safe_rmse(x$y_true, x[[pred_col]]),
        mspe = safe_mspe(x$y_true, x[[pred_col]]),
        mean_bias = safe_bias(x$y_true, x[[pred_col]]),
        stringsAsFactors = FALSE
      )
      seen <- x[x$seen_in_train, ]
      seen_df <- data.frame(
        model = model_name,
        fold_id = x$fold_id[1],
        scope = "seen_genotypes",
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
  score_model_by_fold(pred_out, "pred_meta", "meta_alpha_blend")
)

summary_metrics <- aggregate(
  cbind(correlation, rmse, mspe, mean_bias) ~ model + scope,
  data = metrics_by_fold,
  FUN = mean,
  na.rm = TRUE
)

write.csv(pred_out, file.path(out_dir, "24_meta_alpha_blend_predictions.csv"), row.names = FALSE)
write.csv(fold_df, file.path(out_dir, "24_meta_alpha_fold_features.csv"), row.names = FALSE)
write.csv(metrics_by_fold, file.path(out_dir, "24_meta_alpha_metrics_by_fold.csv"), row.names = FALSE)
write.csv(summary_metrics, file.path(out_dir, "24_meta_alpha_summary_metrics.csv"), row.names = FALSE)

message("Saved LOEO meta-alpha blend results.")
print(summary_metrics)
