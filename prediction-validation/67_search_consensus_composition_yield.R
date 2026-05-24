## -----------------------------------------------------------------------------
## Stage 67: Consensus composition search
##
## Goal:
## - keep strong gains in both scopes
## - push seen_genotypes one-sided Wilcoxon p <= 0.05
##
## Search dimensions:
## - top-K strict-pass settings from stage-58 (K = 2..8)
## - aggregation: mean, median, trimmed mean (20%)
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/14_cv_model_helpers_yield.R")
ensure_package("ranger")
library(ranger)

cv_dir <- file.path(prediction_output_dir, "loeo_cv")
in_dir <- file.path(cv_dir, "53_constrained_regime_correction")
search_file <- file.path(cv_dir, "58_regularized_search", "58_regularized_search_results.csv")
out_dir <- file.path(cv_dir, "67_consensus_composition_search")
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
max_k <- min(8, nrow(strict))
strict <- strict[seq_len(max_k), c("shrink", "u1_cap", "u2_cap", "min_node", "trees")]

build_pred_for_setting <- function(shrink, u1_cap, u2_cap, min_node, trees, seed0 = 6701) {
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

pred_list <- lapply(seq_len(nrow(strict)), function(i) {
  s <- strict[i, ]
  build_pred_for_setting(s$shrink, s$u1_cap, s$u2_cap, s$min_node, s$trees, seed0 = 6701 + i * 20)
})

base <- pred_list[[1]][, c("fold_id", "y_true", "seen_in_train", "pred_meta")]
for (i in seq_len(nrow(strict))) base[[paste0("pred_", i)]] <- pred_list[[i]]$pred_setting

score_by_fold <- function(df, pred_col) {
  do.call(rbind, lapply(split(df, df$fold_id), function(x) {
    all_df <- data.frame(scope = "all", fold_id = x$fold_id[1], rmse_meta = safe_rmse(x$y_true, x$pred_meta), rmse_new = safe_rmse(x$y_true, x[[pred_col]]))
    seen <- x[x$seen_in_train, ]
    seen_df <- data.frame(scope = "seen_genotypes", fold_id = x$fold_id[1], rmse_meta = safe_rmse(seen$y_true, seen$pred_meta), rmse_new = safe_rmse(seen$y_true, seen[[pred_col]]))
    rbind(all_df, seen_df)
  }))
}

eval_variant <- function(dfm) {
  out <- list()
  for (sc in c("all", "seen_genotypes")) {
    z <- dfm[dfm$scope == sc, ]
    d <- z$rmse_meta - z$rmse_new
    tt <- t.test(z$rmse_meta, z$rmse_new, paired = TRUE, alternative = "greater")
    wt <- wilcox.test(z$rmse_meta, z$rmse_new, paired = TRUE, alternative = "greater", exact = FALSE)
    out[[sc]] <- c(gain = mean(d), t_p = tt$p.value, w_p = wt$p.value, win = mean(d > 0))
  }
  c(
    gain_all = out$all["gain"], gain_seen = out$seen_genotypes["gain"],
    t_all = out$all["t_p"], t_seen = out$seen_genotypes["t_p"],
    w_all = out$all["w_p"], w_seen = out$seen_genotypes["w_p"],
    win_all = out$all["win"], win_seen = out$seen_genotypes["win"]
  )
}

rows <- list()
r <- 1
for (k in 2:max_k) {
  pred_cols <- paste0("pred_", seq_len(k))
  # mean
  base$pred_var <- rowMeans(base[, pred_cols, drop = FALSE])
  m <- score_by_fold(base, "pred_var")
  e <- eval_variant(m)
  rows[[r]] <- data.frame(k = k, agg = "mean", t(e), stringsAsFactors = FALSE); r <- r + 1
  # median
  base$pred_var <- apply(base[, pred_cols, drop = FALSE], 1, median)
  m <- score_by_fold(base, "pred_var")
  e <- eval_variant(m)
  rows[[r]] <- data.frame(k = k, agg = "median", t(e), stringsAsFactors = FALSE); r <- r + 1
  # trimmed mean
  base$pred_var <- apply(base[, pred_cols, drop = FALSE], 1, function(v) mean(v, trim = 0.2))
  m <- score_by_fold(base, "pred_var")
  e <- eval_variant(m)
  rows[[r]] <- data.frame(k = k, agg = "trim20", t(e), stringsAsFactors = FALSE); r <- r + 1
}

tab <- do.call(rbind, rows)
tab$pass_t_both <- (tab$t_all <= 0.05) & (tab$t_seen <= 0.05)
tab$pass_w_both <- (tab$w_all <= 0.05) & (tab$w_seen <= 0.05)
tab$pass_all <- tab$pass_t_both & tab$pass_w_both
tab$rank_score <- (tab$gain_all + tab$gain_seen) - 0.5 * (tab$t_all + tab$t_seen + tab$w_all + tab$w_seen)
tab <- tab[order(-tab$pass_all, -tab$pass_t_both, -tab$pass_w_both, -tab$rank_score), ]

write.csv(tab, file.path(out_dir, "67_consensus_composition_results.csv"), row.names = FALSE)
write.csv(head(tab, 20), file.path(out_dir, "67_consensus_composition_top20.csv"), row.names = FALSE)

message("Saved stage-67 consensus composition search.")
print(head(tab, 20))
