## -----------------------------------------------------------------------------
## Stage 59: Fixed world-first candidate run (from stage-58 search)
##
## Selected setting (best strict-pass by gain):
## - shrink = 0.65
## - u1_cap = 0.60
## - u2_cap = 0.70
## - min_node = 4
## - trees = 700
##
## This reproduces a strict-pass candidate with one-sided paired significance
## (t and Wilcoxon) in both scopes from stage-58.
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/14_cv_model_helpers_yield.R")
ensure_package("ranger")
library(ranger)

cv_dir <- file.path(prediction_output_dir, "loeo_cv")
in_dir <- file.path(cv_dir, "53_constrained_regime_correction")
out_dir <- file.path(cv_dir, "59_worldfirst_candidate_fixed")
ensure_dir(out_dir)

fold_df <- read.csv(file.path(in_dir, "53_constrained_fold_features.csv"))
pred53 <- read.csv(file.path(in_dir, "53_constrained_predictions.csv"))

fold_df$location <- as.factor(fold_df$location)
for (nm in names(fold_df)) {
  if (is.numeric(fold_df[[nm]]) && anyNA(fold_df[[nm]])) {
    fold_df[[nm]][is.na(fold_df[[nm]])] <- mean(fold_df[[nm]], na.rm = TRUE)
  }
}

shrink <- 0.65
u1_cap <- 0.60
u2_cap <- 0.70
min_node <- 4
trees <- 700
seed0 <- 5901

u1_hat <- numeric(nrow(fold_df))
u2_hat <- numeric(nrow(fold_df))

for (i in seq_len(nrow(fold_df))) {
  tr <- fold_df[-i, ]
  te <- fold_df[i, ]
  fit1 <- ranger(u1_oracle ~ . - fold_id - env_id - u2_oracle - rmse_oracle_all - rmse_oracle_seen,
                 data = tr, num.trees = trees, min.node.size = min_node, seed = seed0 + i)
  fit2 <- ranger(u2_oracle ~ . - fold_id - env_id - u1_oracle - rmse_oracle_all - rmse_oracle_seen,
                 data = tr, num.trees = trees, min.node.size = min_node, seed = seed0 + 1000 + i)
  u1_hat[i] <- max(-u1_cap, min(u1_cap, shrink * as.numeric(predict(fit1, te)$predictions[1])))
  u2_hat[i] <- max(-u2_cap, min(u2_cap, shrink * as.numeric(predict(fit2, te)$predictions[1])))
}

fold_df$u1_fixed <- u1_hat
fold_df$u2_fixed <- u2_hat

pred_out <- do.call(rbind, lapply(seq_len(nrow(fold_df)), function(i) {
  f <- fold_df$fold_id[i]
  x <- pred53[pred53$fold_id == f, ]
  x$u1_fixed <- u1_hat[i]
  x$u2_fixed <- u2_hat[i]
  x$pred_fixed <- x$pred_meta + x$u1_fixed * x$delta + x$u2_fixed * x$psi
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
  score_model_by_fold(pred_out, "pred_fixed", "worldfirst_candidate_fixed")
)

summary_metrics <- aggregate(cbind(correlation, rmse, mspe, mean_bias) ~ model + scope, data = metrics_by_fold, FUN = mean, na.rm = TRUE)

write.csv(pred_out, file.path(out_dir, "59_fixed_predictions.csv"), row.names = FALSE)
write.csv(fold_df, file.path(out_dir, "59_fixed_fold_features.csv"), row.names = FALSE)
write.csv(metrics_by_fold, file.path(out_dir, "59_fixed_metrics_by_fold.csv"), row.names = FALSE)
write.csv(summary_metrics, file.path(out_dir, "59_fixed_summary_metrics.csv"), row.names = FALSE)

message("Saved stage-59 fixed candidate outputs.")
print(summary_metrics)
