## -----------------------------------------------------------------------------
## Stage 74: Confirmatory gate audit for weighted-consensus candidate
##
## Candidate source:
## - stage-69 best weighted candidate
##
## Confirmatory gate (small-sample aware):
## 1) gain_all >= 0.8 and gain_seen >= 0.8
## 2) one-sided paired t-test p <= 0.05 in both scopes
## 3) bootstrap P(gain > 0) >= 0.95 in both scopes
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/14_cv_model_helpers_yield.R")
ensure_package("ranger")
library(ranger)

cv_dir <- file.path(prediction_output_dir, "loeo_cv")
in_dir <- file.path(cv_dir, "53_constrained_regime_correction")
s69_dir <- file.path(cv_dir, "69_weighted_consensus_search")
out_dir <- file.path(cv_dir, "74_confirmatory_gate_audit")
ensure_dir(out_dir)

fold_df <- read.csv(file.path(in_dir, "53_constrained_fold_features.csv"))
pred53 <- read.csv(file.path(in_dir, "53_constrained_predictions.csv"))
settings <- read.csv(file.path(s69_dir, "69_settings_used.csv"))
weights <- read.csv(file.path(s69_dir, "69_best_weights.csv"))
tab69 <- read.csv(file.path(s69_dir, "69_weighted_consensus_results.csv"))

fold_df$location <- as.factor(fold_df$location)
for (nm in names(fold_df)) {
  if (is.numeric(fold_df[[nm]]) && anyNA(fold_df[[nm]])) {
    fold_df[[nm]][is.na(fold_df[[nm]])] <- mean(fold_df[[nm]], na.rm = TRUE)
  }
}

build_pred_for_setting <- function(shrink, u1_cap, u2_cap, min_node, trees, seed0 = 7401) {
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

K <- nrow(settings)
pred_list <- lapply(seq_len(K), function(i) {
  s <- settings[i, ]
  build_pred_for_setting(s$shrink, s$u1_cap, s$u2_cap, s$min_node, s$trees, seed0 = 7401 + i * 25)
})

base <- pred_list[[1]][, c("fold_id", "y_true", "seen_in_train", "pred_meta")]
for (i in seq_len(K)) base[[paste0("pred_", i)]] <- pred_list[[i]]$pred_setting
pred_cols <- paste0("pred_", seq_len(K))
w <- weights$weight
base$pred_weighted <- as.numeric(as.matrix(base[, pred_cols, drop = FALSE]) %*% w)

metrics <- do.call(rbind, lapply(split(base, base$fold_id), function(x) {
  seen <- x[x$seen_in_train, ]
  rbind(
    data.frame(scope = "all", fold_id = x$fold_id[1],
               rmse_meta = safe_rmse(x$y_true, x$pred_meta),
               rmse_new = safe_rmse(x$y_true, x$pred_weighted),
               stringsAsFactors = FALSE),
    data.frame(scope = "seen_genotypes", fold_id = x$fold_id[1],
               rmse_meta = safe_rmse(seen$y_true, seen$pred_meta),
               rmse_new = safe_rmse(seen$y_true, seen$pred_weighted),
               stringsAsFactors = FALSE)
  )
}))

summarize_scope <- function(sc, B = 20000) {
  z <- metrics[metrics$scope == sc, ]
  d <- z$rmse_meta - z$rmse_new
  tt <- t.test(z$rmse_meta, z$rmse_new, paired = TRUE, alternative = "greater")
  set.seed(ifelse(sc == "all", 7411, 7412))
  idx <- matrix(sample.int(length(d), length(d) * B, replace = TRUE), nrow = B)
  bmeans <- rowMeans(matrix(d[idx], nrow = B))
  data.frame(
    scope = sc,
    mean_gain = mean(d),
    median_gain = median(d),
    t_one_sided_p = tt$p.value,
    boot_prob_gain_positive = mean(bmeans > 0),
    boot_q025 = as.numeric(quantile(bmeans, 0.025)),
    boot_q975 = as.numeric(quantile(bmeans, 0.975)),
    stringsAsFactors = FALSE
  )
}

res <- rbind(summarize_scope("all"), summarize_scope("seen_genotypes"))

gate <- data.frame(
  gain_floor = all(res$mean_gain >= 0.8),
  t_p_pass = all(res$t_one_sided_p <= 0.05),
  boot_pass = all(res$boot_prob_gain_positive >= 0.95),
  stringsAsFactors = FALSE
)
gate$pass_confirmatory <- gate$gain_floor & gate$t_p_pass & gate$boot_pass

write.csv(base, file.path(out_dir, "74_weighted_candidate_predictions.csv"), row.names = FALSE)
write.csv(metrics, file.path(out_dir, "74_weighted_candidate_metrics_by_fold.csv"), row.names = FALSE)
write.csv(res, file.path(out_dir, "74_confirmatory_scope_summary.csv"), row.names = FALSE)
write.csv(gate, file.path(out_dir, "74_confirmatory_gate_result.csv"), row.names = FALSE)

message("Saved stage-74 confirmatory gate audit outputs.")
print(res)
print(gate)
