## -----------------------------------------------------------------------------
## Stage 58: Hyperparameter search for regularized constrained model
##
## Objective: find settings that maximize gain while achieving stronger
## one-sided paired significance in both scopes.
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/14_cv_model_helpers_yield.R")
ensure_package("ranger")
library(ranger)

cv_dir <- file.path(prediction_output_dir, "loeo_cv")
in_dir <- file.path(cv_dir, "53_constrained_regime_correction")
out_dir <- file.path(cv_dir, "58_regularized_search")
ensure_dir(out_dir)

fold_df <- read.csv(file.path(in_dir, "53_constrained_fold_features.csv"))
pred53 <- read.csv(file.path(in_dir, "53_constrained_predictions.csv"))

fold_df$location <- as.factor(fold_df$location)
for (nm in names(fold_df)) {
  if (is.numeric(fold_df[[nm]]) && anyNA(fold_df[[nm]])) {
    fold_df[[nm]][is.na(fold_df[[nm]])] <- mean(fold_df[[nm]], na.rm = TRUE)
  }
}

score_setting <- function(shrink, u1_cap, u2_cap, min_node = 3, trees = 700, seed = 5801) {
  u1_hat <- numeric(nrow(fold_df))
  u2_hat <- numeric(nrow(fold_df))

  for (i in seq_len(nrow(fold_df))) {
    tr <- fold_df[-i, ]
    te <- fold_df[i, ]

    fit1 <- ranger(
      u1_oracle ~ . - fold_id - env_id - u2_oracle - rmse_oracle_all - rmse_oracle_seen,
      data = tr, num.trees = trees, min.node.size = min_node, seed = seed + i
    )
    fit2 <- ranger(
      u2_oracle ~ . - fold_id - env_id - u1_oracle - rmse_oracle_all - rmse_oracle_seen,
      data = tr, num.trees = trees, min.node.size = min_node, seed = seed + 1000 + i
    )

    raw_u1 <- as.numeric(predict(fit1, te)$predictions[1])
    raw_u2 <- as.numeric(predict(fit2, te)$predictions[1])
    u1_hat[i] <- max(-u1_cap, min(u1_cap, shrink * raw_u1))
    u2_hat[i] <- max(-u2_cap, min(u2_cap, shrink * raw_u2))
  }

  pred_out <- do.call(rbind, lapply(seq_len(nrow(fold_df)), function(i) {
    f <- fold_df$fold_id[i]
    x <- pred53[pred53$fold_id == f, ]
    x$pred_reg <- x$pred_meta + u1_hat[i] * x$delta + u2_hat[i] * x$psi
    x
  }))

  metrics <- do.call(rbind, lapply(split(pred_out, pred_out$fold_id), function(x) {
    all_df <- data.frame(
      fold_id = x$fold_id[1], scope = "all",
      rmse_meta = safe_rmse(x$y_true, x$pred_meta),
      rmse_new = safe_rmse(x$y_true, x$pred_reg),
      stringsAsFactors = FALSE
    )
    seen <- x[x$seen_in_train, ]
    seen_df <- data.frame(
      fold_id = x$fold_id[1], scope = "seen_genotypes",
      rmse_meta = safe_rmse(seen$y_true, seen$pred_meta),
      rmse_new = safe_rmse(seen$y_true, seen$pred_reg),
      stringsAsFactors = FALSE
    )
    rbind(all_df, seen_df)
  }))

  eval_scope <- function(sc) {
    z <- metrics[metrics$scope == sc, ]
    d <- z$rmse_meta - z$rmse_new
    tt1 <- t.test(z$rmse_meta, z$rmse_new, paired = TRUE, alternative = "greater")
    wt1 <- wilcox.test(z$rmse_meta, z$rmse_new, paired = TRUE, alternative = "greater", exact = FALSE)
    c(
      mean_gain = mean(d),
      median_gain = median(d),
      win_rate = mean(d > 0),
      t_one_sided_p = tt1$p.value,
      wilcox_one_sided_p = wt1$p.value
    )
  }

  a <- eval_scope("all")
  s <- eval_scope("seen_genotypes")

  data.frame(
    shrink = shrink,
    u1_cap = u1_cap,
    u2_cap = u2_cap,
    min_node = min_node,
    trees = trees,
    gain_all = a["mean_gain"],
    gain_seen = s["mean_gain"],
    p_t_all = a["t_one_sided_p"],
    p_t_seen = s["t_one_sided_p"],
    p_w_all = a["wilcox_one_sided_p"],
    p_w_seen = s["wilcox_one_sided_p"],
    win_all = a["win_rate"],
    win_seen = s["win_rate"],
    pass_t_strict = (a["t_one_sided_p"] <= 0.05) & (s["t_one_sided_p"] <= 0.05),
    pass_w_strict = (a["wilcox_one_sided_p"] <= 0.05) & (s["wilcox_one_sided_p"] <= 0.05),
    stringsAsFactors = FALSE
  )
}

grid <- expand.grid(
  shrink = c(0.55, 0.65, 0.70, 0.75, 0.85),
  u1_cap = c(0.40, 0.50, 0.60),
  u2_cap = c(0.70, 0.90, 1.10),
  min_node = c(2, 3, 4),
  stringsAsFactors = FALSE
)

res <- do.call(rbind, lapply(seq_len(nrow(grid)), function(i) {
  g <- grid[i, ]
  score_setting(g$shrink, g$u1_cap, g$u2_cap, min_node = g$min_node, trees = 700, seed = 5801 + i * 10)
}))

res$rank_score <- (res$gain_all + res$gain_seen) - 0.5 * (res$p_t_all + res$p_t_seen)
res <- res[order(-res$pass_t_strict, -res$pass_w_strict, -res$rank_score), ]

write.csv(res, file.path(out_dir, "58_regularized_search_results.csv"), row.names = FALSE)
write.csv(head(res, 20), file.path(out_dir, "58_regularized_search_top20.csv"), row.names = FALSE)

message("Saved stage-58 regularized search results.")
print(head(res, 20))
