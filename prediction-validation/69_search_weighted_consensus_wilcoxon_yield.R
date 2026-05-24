## -----------------------------------------------------------------------------
## Stage 69: Weighted consensus search targeting Wilcoxon gate
##
## Uses top strict-pass stage-58 settings and random convex weights.
## Objective: minimize seen_genotypes one-sided Wilcoxon p while preserving gains.
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/14_cv_model_helpers_yield.R")
ensure_package("ranger")
library(ranger)

cv_dir <- file.path(prediction_output_dir, "loeo_cv")
in_dir <- file.path(cv_dir, "53_constrained_regime_correction")
search_file <- file.path(cv_dir, "58_regularized_search", "58_regularized_search_results.csv")
out_dir <- file.path(cv_dir, "69_weighted_consensus_search")
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

build_pred_for_setting <- function(shrink, u1_cap, u2_cap, min_node, trees, seed0 = 6901) {
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
  build_pred_for_setting(s$shrink, s$u1_cap, s$u2_cap, s$min_node, s$trees, seed0 = 6901 + i * 25)
})

base <- pred_list[[1]][, c("fold_id", "y_true", "seen_in_train", "pred_meta")]
for (i in seq_len(K)) base[[paste0("pred_", i)]] <- pred_list[[i]]$pred_setting
pred_cols <- paste0("pred_", seq_len(K))

score_weights <- function(w) {
  pmat <- as.matrix(base[, pred_cols, drop = FALSE])
  pred <- as.numeric(pmat %*% w)
  df <- base
  df$pred_w <- pred

  eval_scope <- function(sc) {
    x <- if (sc == "all") df else df[df$seen_in_train, ]
    byf <- split(x, x$fold_id)
    rm_meta <- sapply(byf, function(z) safe_rmse(z$y_true, z$pred_meta))
    rm_new <- sapply(byf, function(z) safe_rmse(z$y_true, z$pred_w))
    d <- rm_meta - rm_new
    tt <- t.test(rm_meta, rm_new, paired = TRUE, alternative = "greater")
    wt <- suppressWarnings(wilcox.test(rm_meta, rm_new, paired = TRUE, alternative = "greater", exact = FALSE))
    c(gain = mean(d), t_p = tt$p.value, w_p = wt$p.value, win = mean(d > 0))
  }

  a <- eval_scope("all")
  s <- eval_scope("seen_genotypes")
  out <- c(
    a_gain = as.numeric(a["gain"]),
    s_gain = as.numeric(s["gain"]),
    a_t = as.numeric(a["t_p"]),
    s_t = as.numeric(s["t_p"]),
    a_w = as.numeric(a["w_p"]),
    s_w = as.numeric(s["w_p"]),
    a_win = as.numeric(a["win"]),
    s_win = as.numeric(s["win"])
  )
  if (any(!is.finite(out))) {
    out[!is.finite(out)] <- NA_real_
  }
  out
}

set.seed(69001)
n_rand <- 5000
wmat <- matrix(rexp(n_rand * K, rate = 1), nrow = n_rand, ncol = K)
wmat <- wmat / rowSums(wmat)

rows <- vector("list", n_rand)
for (i in seq_len(n_rand)) {
  w <- wmat[i, ]
  sc <- score_weights(w)
  if (any(is.na(sc))) {
    rows[[i]] <- data.frame(
      id = i, a_gain = NA_real_, s_gain = NA_real_,
      a_t = NA_real_, s_t = NA_real_, a_w = NA_real_, s_w = NA_real_,
      a_win = NA_real_, s_win = NA_real_,
      pass_t_both = FALSE, pass_w_both = FALSE, pass_all = FALSE,
      stringsAsFactors = FALSE
    )
    next
  }

  rows[[i]] <- data.frame(
    id = i,
    a_gain = sc["a_gain"], s_gain = sc["s_gain"],
    a_t = sc["a_t"], s_t = sc["s_t"],
    a_w = sc["a_w"], s_w = sc["s_w"],
    a_win = sc["a_win"], s_win = sc["s_win"],
    pass_t_both = (sc["a_t"] <= 0.05) & (sc["s_t"] <= 0.05),
    pass_w_both = (sc["a_w"] <= 0.05) & (sc["s_w"] <= 0.05),
    pass_all = ((sc["a_t"] <= 0.05) & (sc["s_t"] <= 0.05) & (sc["a_w"] <= 0.05) & (sc["s_w"] <= 0.05)),
    stringsAsFactors = FALSE
  )
}

tab <- do.call(rbind, rows)
tab$rank_score <- (tab$a_gain + tab$s_gain) - 0.7 * (tab$a_w + tab$s_w) - 0.3 * (tab$a_t + tab$s_t)
tab <- tab[order(-tab$pass_all, -tab$pass_t_both, -tab$pass_w_both, -tab$rank_score), ]

best_id <- tab$id[1]
best_w <- wmat[best_id, ]
weights_out <- data.frame(setting = seq_len(K), weight = best_w)
settings_out <- cbind(setting = seq_len(K), strict)

write.csv(tab, file.path(out_dir, "69_weighted_consensus_results.csv"), row.names = FALSE)
write.csv(head(tab, 30), file.path(out_dir, "69_weighted_consensus_top30.csv"), row.names = FALSE)
write.csv(weights_out, file.path(out_dir, "69_best_weights.csv"), row.names = FALSE)
write.csv(settings_out, file.path(out_dir, "69_settings_used.csv"), row.names = FALSE)

message("Saved stage-69 weighted consensus search.")
print(head(tab, 30))
