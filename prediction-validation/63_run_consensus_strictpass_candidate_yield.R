## -----------------------------------------------------------------------------
## Stage 63: Consensus candidate from top strict-pass stage-58 settings
##
## Strategy:
## - Take top K settings that passed strict one-sided gates in stage-58.
## - Recompute LOEO predictions per setting.
## - Average predictions across settings to reduce variance.
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/14_cv_model_helpers_yield.R")
ensure_package("ranger")
library(ranger)

cv_dir <- file.path(prediction_output_dir, "loeo_cv")
in_dir <- file.path(cv_dir, "53_constrained_regime_correction")
search_file <- file.path(cv_dir, "58_regularized_search", "58_regularized_search_results.csv")
out_dir <- file.path(cv_dir, "63_consensus_strictpass_candidate")
ensure_dir(out_dir)

fold_df <- read.csv(file.path(in_dir, "53_constrained_fold_features.csv"))
pred53 <- read.csv(file.path(in_dir, "53_constrained_predictions.csv"))
grid_res <- read.csv(search_file)

fold_df$location <- as.factor(fold_df$location)
for (nm in names(fold_df)) {
  if (is.numeric(fold_df[[nm]]) && anyNA(fold_df[[nm]])) {
    fold_df[[nm]][is.na(fold_df[[nm]])] <- mean(fold_df[[nm]], na.rm = TRUE)
  }
}

strict <- grid_res[grid_res$pass_t_strict & grid_res$pass_w_strict, ]
strict <- strict[order(-(strict$gain_all + strict$gain_seen)), ]
K <- min(5, nrow(strict))
settings <- strict[seq_len(K), c("shrink", "u1_cap", "u2_cap", "min_node", "trees")]

build_pred_for_setting <- function(shrink, u1_cap, u2_cap, min_node, trees, seed0 = 6301) {
  u1_hat <- numeric(nrow(fold_df))
  u2_hat <- numeric(nrow(fold_df))

  for (i in seq_len(nrow(fold_df))) {
    tr <- fold_df[-i, ]
    te <- fold_df[i, ]

    fit1 <- ranger(u1_oracle ~ . - fold_id - env_id - u2_oracle - rmse_oracle_all - rmse_oracle_seen,
                   data = tr, num.trees = trees, min.node.size = min_node, seed = seed0 + i)
    fit2 <- ranger(u2_oracle ~ . - fold_id - env_id - u1_oracle - rmse_oracle_all - rmse_oracle_seen,
                   data = tr, num.trees = trees, min.node.size = min_node, seed = seed0 + 1000 + i)

    raw_u1 <- as.numeric(predict(fit1, te)$predictions[1])
    raw_u2 <- as.numeric(predict(fit2, te)$predictions[1])
    u1_hat[i] <- max(-u1_cap, min(u1_cap, shrink * raw_u1))
    u2_hat[i] <- max(-u2_cap, min(u2_cap, shrink * raw_u2))
  }

  pred_out <- do.call(rbind, lapply(seq_len(nrow(fold_df)), function(i) {
    f <- fold_df$fold_id[i]
    x <- pred53[pred53$fold_id == f, c("fold_id", "y_true", "seen_in_train", "pred_meta", "delta", "psi")]
    x$pred_setting <- x$pred_meta + u1_hat[i] * x$delta + u2_hat[i] * x$psi
    x
  }))
  pred_out
}

pred_list <- lapply(seq_len(K), function(i) {
  s <- settings[i, ]
  build_pred_for_setting(s$shrink, s$u1_cap, s$u2_cap, s$min_node, s$trees, seed0 = 6301 + i * 20)
})

base <- pred_list[[1]][, c("fold_id", "y_true", "seen_in_train", "pred_meta")]
for (i in seq_len(K)) {
  base[[paste0("pred_", i)]] <- pred_list[[i]]$pred_setting
}
pred_cols <- paste0("pred_", seq_len(K))
base$pred_consensus <- rowMeans(base[, pred_cols, drop = FALSE])

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
  score_model_by_fold(base, "pred_meta", "meta_alpha_blend"),
  score_model_by_fold(base, "pred_consensus", "consensus_strictpass_candidate")
)

summary_metrics <- aggregate(cbind(correlation, rmse, mspe, mean_bias) ~ model + scope, data = metrics_by_fold, FUN = mean, na.rm = TRUE)

write.csv(settings, file.path(out_dir, "63_selected_settings.csv"), row.names = FALSE)
write.csv(base, file.path(out_dir, "63_consensus_predictions.csv"), row.names = FALSE)
write.csv(metrics_by_fold, file.path(out_dir, "63_consensus_metrics_by_fold.csv"), row.names = FALSE)
write.csv(summary_metrics, file.path(out_dir, "63_consensus_summary_metrics.csv"), row.names = FALSE)

message("Saved stage-63 consensus strict-pass candidate outputs.")
print(settings)
print(summary_metrics)
