## -----------------------------------------------------------------------------
## Stage 54: Regularized constrained regime correction
##
## Builds on stage 53, but regularizes fold-level gate coefficients to reduce
## variance and improve statistical robustness:
## - coefficient clipping
## - global shrinkage toward zero
##
## pred = pred_meta + u1*delta + u2*psi
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/14_cv_model_helpers_yield.R")
ensure_package("ranger")
library(ranger)

cv_dir <- file.path(prediction_output_dir, "loeo_cv")
out_dir <- file.path(cv_dir, "54_constrained_regime_regularized")
ensure_dir(out_dir)

in_dir <- file.path(cv_dir, "53_constrained_regime_correction")
fold_df <- read.csv(file.path(in_dir, "53_constrained_fold_features.csv"))
pred53 <- read.csv(file.path(in_dir, "53_constrained_predictions.csv"))

fold_df$location <- as.factor(fold_df$location)
for (nm in names(fold_df)) {
  if (is.numeric(fold_df[[nm]]) && anyNA(fold_df[[nm]])) {
    fold_df[[nm]][is.na(fold_df[[nm]])] <- mean(fold_df[[nm]], na.rm = TRUE)
  }
}

shrink <- 0.70
u1_cap <- 0.60
u2_cap <- 0.90

u1_hat <- numeric(nrow(fold_df))
u2_hat <- numeric(nrow(fold_df))

for (i in seq_len(nrow(fold_df))) {
  tr <- fold_df[-i, ]
  te <- fold_df[i, ]

  fit1 <- ranger(
    u1_oracle ~ . - fold_id - env_id - u2_oracle - rmse_oracle_all - rmse_oracle_seen,
    data = tr, num.trees = 700, min.node.size = 3
  )
  fit2 <- ranger(
    u2_oracle ~ . - fold_id - env_id - u1_oracle - rmse_oracle_all - rmse_oracle_seen,
    data = tr, num.trees = 700, min.node.size = 3
  )

  raw_u1 <- as.numeric(predict(fit1, te)$predictions[1])
  raw_u2 <- as.numeric(predict(fit2, te)$predictions[1])

  s_u1 <- shrink * raw_u1
  s_u2 <- shrink * raw_u2

  u1_hat[i] <- max(-u1_cap, min(u1_cap, s_u1))
  u2_hat[i] <- max(-u2_cap, min(u2_cap, s_u2))
}

fold_df$u1_reg <- u1_hat
fold_df$u2_reg <- u2_hat

pred_out <- do.call(
  rbind,
  lapply(seq_len(nrow(fold_df)), function(i) {
    f <- fold_df$fold_id[i]
    x <- pred53[pred53$fold_id == f, ]
    u1 <- fold_df$u1_reg[i]
    u2 <- fold_df$u2_reg[i]
    x$u1_reg <- u1
    x$u2_reg <- u2
    x$pred_reg <- x$pred_meta + u1 * x$delta + u2 * x$psi
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
  score_model_by_fold(pred_out, "pred_meta", "meta_alpha_blend"),
  score_model_by_fold(pred_out, "pred_reg", "constrained_regime_regularized")
)

summary_metrics <- aggregate(
  cbind(correlation, rmse, mspe, mean_bias) ~ model + scope,
  data = metrics_by_fold,
  FUN = mean, na.rm = TRUE
)

write.csv(pred_out, file.path(out_dir, "54_regularized_predictions.csv"), row.names = FALSE)
write.csv(fold_df, file.path(out_dir, "54_regularized_fold_features.csv"), row.names = FALSE)
write.csv(metrics_by_fold, file.path(out_dir, "54_regularized_metrics_by_fold.csv"), row.names = FALSE)
write.csv(summary_metrics, file.path(out_dir, "54_regularized_summary_metrics.csv"), row.names = FALSE)

message("Saved stage-54 regularized regime-correction results.")
print(summary_metrics)
