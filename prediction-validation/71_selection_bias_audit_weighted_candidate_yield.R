## -----------------------------------------------------------------------------
## Stage 71: Selection-bias audit for weighted-consensus discovery candidate
##
## Why:
## Stage-69 searched many weight vectors on the same folds. This audit estimates
## optimism by selecting weights on train folds and evaluating on held-out folds.
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/14_cv_model_helpers_yield.R")
ensure_package("ranger")
library(ranger)

cv_dir <- file.path(prediction_output_dir, "loeo_cv")
in_dir <- file.path(cv_dir, "53_constrained_regime_correction")
search_file <- file.path(cv_dir, "58_regularized_search", "58_regularized_search_results.csv")
out_dir <- file.path(cv_dir, "71_selection_bias_audit_weighted")
ensure_dir(out_dir)

fold_df <- read.csv(file.path(in_dir, "53_constrained_fold_features.csv"))
pred53 <- read.csv(file.path(in_dir, "53_constrained_predictions.csv"))
res58 <- read.csv(search_file)

fold_df$location <- as.factor(fold_df$location)
for (nm in names(fold_df)) {
  if (is.numeric(fold_df[[nm]]) && anyNA(fold_df[[nm]])) {
    fold_df[[nm]][is.na(fold_df[[nm]])] <- mean(fold_df[[nm]], na.rm = TRUE)
  }
}

strict <- res58[res58$pass_t_strict & res58$pass_w_strict, ]
strict <- strict[order(-(strict$gain_all + strict$gain_seen)), ]
K <- min(8, nrow(strict))
strict <- strict[seq_len(K), c("shrink", "u1_cap", "u2_cap", "min_node", "trees")]

build_pred_for_setting <- function(shrink, u1_cap, u2_cap, min_node, trees, seed0 = 7101) {
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
  do.call(rbind, lapply(seq_len(nrow(fold_df)), function(i) {
    f <- fold_df$fold_id[i]
    x <- pred53[pred53$fold_id == f, c("fold_id", "y_true", "seen_in_train", "pred_meta", "delta", "psi")]
    x$pred_setting <- x$pred_meta + u1_hat[i] * x$delta + u2_hat[i] * x$psi
    x
  }))
}

pred_list <- lapply(seq_len(K), function(i) {
  s <- strict[i, ]
  build_pred_for_setting(s$shrink, s$u1_cap, s$u2_cap, s$min_node, s$trees, seed0 = 7101 + i * 25)
})

base <- pred_list[[1]][, c("fold_id", "y_true", "seen_in_train", "pred_meta")]
for (i in seq_len(K)) base[[paste0("pred_", i)]] <- pred_list[[i]]$pred_setting
pred_cols <- paste0("pred_", seq_len(K))

folds <- unique(base$fold_id)
n_folds <- length(folds)

set.seed(71001)
n_cand <- 1000
wmat <- matrix(rexp(n_cand * K, rate = 1), nrow = n_cand, ncol = K)
wmat <- wmat / rowSums(wmat)

evaluate_weights_by_fold <- function(w) {
  pred <- as.numeric(as.matrix(base[, pred_cols, drop = FALSE]) %*% w)
  df <- base
  df$pred_w <- pred
  byf <- split(df, df$fold_id)
  do.call(rbind, lapply(names(byf), function(fid) {
    x <- byf[[fid]]
    seen <- x[x$seen_in_train, ]
    data.frame(
      fold_id = fid,
      rmse_meta_all = safe_rmse(x$y_true, x$pred_meta),
      rmse_new_all = safe_rmse(x$y_true, x$pred_w),
      rmse_meta_seen = safe_rmse(seen$y_true, seen$pred_meta),
      rmse_new_seen = safe_rmse(seen$y_true, seen$pred_w),
      stringsAsFactors = FALSE
    )
  }))
}

cand_fold_metrics <- lapply(seq_len(n_cand), function(i) evaluate_weights_by_fold(wmat[i, ]))

score_on_subset <- function(mat_df, use_folds) {
  z <- mat_df[mat_df$fold_id %in% use_folds, ]
  gain_all <- mean(z$rmse_meta_all - z$rmse_new_all)
  gain_seen <- mean(z$rmse_meta_seen - z$rmse_new_seen)
  gain_all + gain_seen
}

set.seed(71002)
n_rep <- 500
rep_rows <- vector("list", n_rep)

for (r in seq_len(n_rep)) {
  tr_folds <- sample(folds, size = floor(n_folds * 0.6), replace = FALSE)
  te_folds <- setdiff(folds, tr_folds)

  train_scores <- sapply(cand_fold_metrics, score_on_subset, use_folds = tr_folds)
  best_idx <- which.max(train_scores)
  best_df <- cand_fold_metrics[[best_idx]]

  te <- best_df[best_df$fold_id %in% te_folds, ]
  gain_all <- mean(te$rmse_meta_all - te$rmse_new_all)
  gain_seen <- mean(te$rmse_meta_seen - te$rmse_new_seen)

  t_all <- t.test(te$rmse_meta_all, te$rmse_new_all, paired = TRUE, alternative = "greater")$p.value
  t_seen <- t.test(te$rmse_meta_seen, te$rmse_new_seen, paired = TRUE, alternative = "greater")$p.value
  w_all <- suppressWarnings(wilcox.test(te$rmse_meta_all, te$rmse_new_all, paired = TRUE, alternative = "greater", exact = FALSE)$p.value)
  w_seen <- suppressWarnings(wilcox.test(te$rmse_meta_seen, te$rmse_new_seen, paired = TRUE, alternative = "greater", exact = FALSE)$p.value)

  rep_rows[[r]] <- data.frame(
    rep_id = r,
    best_idx = best_idx,
    gain_all = gain_all,
    gain_seen = gain_seen,
    t_all = t_all, t_seen = t_seen,
    w_all = w_all, w_seen = w_seen,
    pass_t_both = (t_all <= 0.05) & (t_seen <= 0.05),
    pass_w_both = (w_all <= 0.05) & (w_seen <= 0.05),
    pass_all = (t_all <= 0.05) & (t_seen <= 0.05) & (w_all <= 0.05) & (w_seen <= 0.05),
    stringsAsFactors = FALSE
  )
}

rep_df <- do.call(rbind, rep_rows)

summary_df <- data.frame(
  n_rep = n_rep,
  n_candidates = n_cand,
  mean_gain_all = mean(rep_df$gain_all),
  mean_gain_seen = mean(rep_df$gain_seen),
  gain_all_q05 = as.numeric(quantile(rep_df$gain_all, 0.05)),
  gain_seen_q05 = as.numeric(quantile(rep_df$gain_seen, 0.05)),
  pass_t_both_rate = mean(rep_df$pass_t_both),
  pass_w_both_rate = mean(rep_df$pass_w_both),
  pass_all_rate = mean(rep_df$pass_all),
  stringsAsFactors = FALSE
)

write.csv(rep_df, file.path(out_dir, "71_selection_bias_replicates.csv"), row.names = FALSE)
write.csv(summary_df, file.path(out_dir, "71_selection_bias_summary.csv"), row.names = FALSE)
write.csv(strict, file.path(out_dir, "71_settings_pool.csv"), row.names = FALSE)

message("Saved stage-71 selection-bias audit outputs.")
print(summary_df)
