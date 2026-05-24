## -----------------------------------------------------------------------------
## Stage 19: LOEO for penalized reaction-norm model (fast shrinkage baseline)
##
## Model:
## y ~ G + Y + L + EC + G:EC
##
## Fitted with elastic net / lasso-ridge path (glmnet) and fold-wise CV on
## training rows only. This is a strongly regularized reaction norm and can
## outperform unpenalized/random-effect parameterizations when EC effects are
## weakly identifiable.
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/14_cv_model_helpers_yield.R")

ensure_package("glmnet")
library(glmnet)

glmnet_out_dir <- file.path(cv_output_dir, "19_glmnet_reaction_norm")
ensure_dir(glmnet_out_dir)

rmse <- function(obs, pred) sqrt(mean((obs - pred)^2))

fit_one_fold_glmnet <- function(dat, fold_row, ec_cols, alpha_grid = c(0, 0.25, 0.5, 0.75, 1)) {
  env_id <- fold_row$env_id
  fold_id <- fold_row$fold_id

  d <- mask_fold_response(dat, env_id)
  d <- d[complete.cases(d[, c("y_true", "is_test", "seen_in_train", "G", "Y", "L", ec_cols)]), , drop = FALSE]

  # Standardize ECs globally in-fold to stabilize penalty.
  for (ec in ec_cols) d[[ec]] <- as.numeric(scale(d[[ec]]))

  # sparse model matrix with reaction-norm interaction terms
  rhs <- paste(c("0 + G + Y + L", ec_cols, paste0("G:", ec_cols)), collapse = " + ")
  X <- model.matrix(as.formula(paste("~", rhs)), data = d)

  train_idx <- which(!d$is_test)
  test_idx <- which(d$is_test)
  y_train <- d$y_true[train_idx]

  # tune alpha and lambda on training only
  best <- list(alpha = NA_real_, lambda = NA_real_, cvm = Inf)
  set.seed(42)
  for (a in alpha_grid) {
    cvfit <- cv.glmnet(
      x = X[train_idx, , drop = FALSE],
      y = y_train,
      family = "gaussian",
      alpha = a,
      nfolds = 5,
      standardize = FALSE,
      intercept = TRUE
    )
    this_cvm <- min(cvfit$cvm, na.rm = TRUE)
    if (is.finite(this_cvm) && this_cvm < best$cvm) {
      best$alpha <- a
      best$lambda <- cvfit$lambda.min
      best$cvm <- this_cvm
    }
  }

  fit <- glmnet(
    x = X[train_idx, , drop = FALSE],
    y = y_train,
    family = "gaussian",
    alpha = best$alpha,
    lambda = best$lambda,
    standardize = FALSE,
    intercept = TRUE
  )

  pred <- as.numeric(predict(fit, newx = X[test_idx, , drop = FALSE], s = best$lambda))

  out <- d[test_idx, c("Y", "L", "G", "ENV", "env_id", "geno_ID", "y_true", "seen_in_train"), drop = FALSE]
  out$predicted_value <- pred
  out$model <- "glmnet_rn"
  out$fold_id <- fold_id
  out$alpha <- best$alpha
  out$lambda <- best$lambda

  metrics <- rbind(
    data.frame(
      model = "glmnet_rn",
      fold_id = fold_id,
      scope = "all",
      n_eval = nrow(out),
      correlation = safe_cor(out$y_true, out$predicted_value),
      rmse = safe_rmse(out$y_true, out$predicted_value),
      mspe = safe_mspe(out$y_true, out$predicted_value),
      mean_bias = safe_bias(out$y_true, out$predicted_value),
      alpha = best$alpha,
      lambda = best$lambda,
      stringsAsFactors = FALSE
    ),
    data.frame(
      model = "glmnet_rn",
      fold_id = fold_id,
      scope = "seen_genotypes",
      n_eval = sum(out$seen_in_train),
      correlation = safe_cor(out$y_true[out$seen_in_train], out$predicted_value[out$seen_in_train]),
      rmse = safe_rmse(out$y_true[out$seen_in_train], out$predicted_value[out$seen_in_train]),
      mspe = safe_mspe(out$y_true[out$seen_in_train], out$predicted_value[out$seen_in_train]),
      mean_bias = safe_bias(out$y_true[out$seen_in_train], out$predicted_value[out$seen_in_train]),
      alpha = best$alpha,
      lambda = best$lambda,
      stringsAsFactors = FALSE
    )
  )

  list(predictions = out, metrics = metrics)
}

inputs <- read_loeo_inputs()
dat <- inputs$dat
folds <- subset_folds_for_run(inputs$folds)
ec_cols <- detect_available_ec_aliases(dat)

pred_list <- vector("list", nrow(folds))
met_list <- vector("list", nrow(folds))

for (i in seq_len(nrow(folds))) {
  fr <- folds[i, , drop = FALSE]
  message("Running glmnet_rn on ", fr$fold_id)
  res <- fit_one_fold_glmnet(dat, fr, ec_cols = ec_cols)
  pred_list[[i]] <- res$predictions
  met_list[[i]] <- res$metrics
}

predictions <- do.call(rbind, pred_list)
metrics <- do.call(rbind, met_list)

write.csv(predictions, file.path(glmnet_out_dir, "19_glmnet_rn_predictions.csv"), row.names = FALSE)
write.csv(metrics, file.path(glmnet_out_dir, "19_glmnet_rn_metrics.csv"), row.names = FALSE)

summary_metrics <- aggregate(cbind(correlation, rmse, mspe, mean_bias) ~ model + scope, data = metrics, FUN = mean, na.rm = TRUE)
write.csv(summary_metrics, file.path(glmnet_out_dir, "19_glmnet_rn_summary_metrics.csv"), row.names = FALSE)

message("Saved LOEO glmnet reaction-norm results.")
print(summary_metrics)

