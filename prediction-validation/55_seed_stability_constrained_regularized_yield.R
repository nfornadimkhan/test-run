## -----------------------------------------------------------------------------
## Stage 55: Seed stability for stage-54 constrained regularized model
##
## Refit fold-level u1/u2 meta-models across many seeds and evaluate how often
## the method beats meta_alpha_blend on mean RMSE.
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/14_cv_model_helpers_yield.R")
ensure_package("ranger")
library(ranger)

cv_dir <- file.path(prediction_output_dir, "loeo_cv")
in_dir <- file.path(cv_dir, "53_constrained_regime_correction")
out_dir <- file.path(cv_dir, "55_seed_stability_constrained_regularized")
ensure_dir(out_dir)

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

run_seed <- function(seed) {
  u1_hat <- numeric(nrow(fold_df))
  u2_hat <- numeric(nrow(fold_df))

  for (i in seq_len(nrow(fold_df))) {
    tr <- fold_df[-i, ]
    te <- fold_df[i, ]
    fit1 <- ranger(u1_oracle ~ . - fold_id - env_id - u2_oracle - rmse_oracle_all - rmse_oracle_seen,
                   data = tr, num.trees = 700, min.node.size = 3, seed = seed)
    fit2 <- ranger(u2_oracle ~ . - fold_id - env_id - u1_oracle - rmse_oracle_all - rmse_oracle_seen,
                   data = tr, num.trees = 700, min.node.size = 3, seed = seed + 1000)
    u1_hat[i] <- max(-u1_cap, min(u1_cap, shrink * as.numeric(predict(fit1, te)$predictions[1])))
    u2_hat[i] <- max(-u2_cap, min(u2_cap, shrink * as.numeric(predict(fit2, te)$predictions[1])))
  }

  pred_out <- do.call(rbind, lapply(seq_len(nrow(fold_df)), function(i) {
    f <- fold_df$fold_id[i]
    x <- pred53[pred53$fold_id == f, ]
    x$pred_reg <- x$pred_meta + u1_hat[i] * x$delta + u2_hat[i] * x$psi
    x
  }))

  s <- do.call(rbind, lapply(split(pred_out, pred_out$fold_id), function(x) {
    all_df <- data.frame(
      scope = "all",
      rmse_meta = safe_rmse(x$y_true, x$pred_meta),
      rmse_reg = safe_rmse(x$y_true, x$pred_reg),
      stringsAsFactors = FALSE
    )
    seen <- x[x$seen_in_train, ]
    seen_df <- data.frame(
      scope = "seen_genotypes",
      rmse_meta = safe_rmse(seen$y_true, seen$pred_meta),
      rmse_reg = safe_rmse(seen$y_true, seen$pred_reg),
      stringsAsFactors = FALSE
    )
    rbind(all_df, seen_df)
  }))

  agg <- aggregate(cbind(rmse_meta, rmse_reg) ~ scope, data = s, FUN = mean)
  agg$gain <- agg$rmse_meta - agg$rmse_reg
  agg$seed <- seed
  agg
}

seed_grid <- 1:50
res <- do.call(rbind, lapply(seed_grid, run_seed))

stab <- aggregate(gain ~ scope, data = res, FUN = function(x) c(mean = mean(x), sd = sd(x), q05 = quantile(x, 0.05), q95 = quantile(x, 0.95), p_pos = mean(x > 0)))

stab_out <- data.frame(
  scope = stab$scope,
  gain_mean = stab$gain[, 1],
  gain_sd = stab$gain[, 2],
  gain_q05 = stab$gain[, 3],
  gain_q95 = stab$gain[, 4],
  prob_gain_positive = stab$gain[, 5],
  stringsAsFactors = FALSE
)

write.csv(res, file.path(out_dir, "55_seed_level_gain.csv"), row.names = FALSE)
write.csv(stab_out, file.path(out_dir, "55_seed_stability_summary.csv"), row.names = FALSE)

message("Saved stage-55 seed stability outputs.")
print(stab_out)
