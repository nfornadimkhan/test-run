## -----------------------------------------------------------------------------
## Stage 21: LOEO penalized reaction norm with partial penalties
##
## Key change:
## - Unpenalized: G, Y, L main effects
## - Penalized: EC PCs and G:EC-PC interactions
##
## This preserves baseline genetic/location/year signal while shrinking the
## high-dimensional GxE part.
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/14_cv_model_helpers_yield.R")

ensure_package("glmnet")
library(glmnet)

out_dir <- file.path(cv_output_dir, "21_glmnet_partial_penalty")
ensure_dir(out_dir)

fit_one_fold <- function(dat, fold_row, ec_cols, k_pc = 3, alpha_grid = c(0.1, 0.5, 0.9)) {
  env_id <- fold_row$env_id
  fold_id <- fold_row$fold_id
  d <- mask_fold_response(dat, env_id)
  d <- d[complete.cases(d[, c("y_true", "is_test", "seen_in_train", "G", "Y", "L", ec_cols)]), , drop = FALSE]

  env_tbl <- unique(d[, c("ENV", ec_cols)])
  rownames(env_tbl) <- as.character(env_tbl$ENV)
  train_env <- unique(d$ENV[!d$is_test])
  Xenv_train <- scale(as.matrix(env_tbl[as.character(train_env), ec_cols, drop = FALSE]))
  pca <- prcomp(Xenv_train, center = TRUE, scale. = TRUE)
  k <- min(k_pc, ncol(pca$x))

  Xenv_all <- scale(
    as.matrix(env_tbl[, ec_cols, drop = FALSE]),
    center = attr(Xenv_train, "scaled:center"),
    scale = attr(Xenv_train, "scaled:scale")
  )
  scores_all <- Xenv_all %*% pca$rotation[, seq_len(k), drop = FALSE]
  colnames(scores_all) <- paste0("PC", seq_len(k))
  env_scores <- data.frame(ENV = rownames(scores_all), scores_all, row.names = NULL)
  d <- merge(d, env_scores, by = "ENV", all.x = TRUE)

  pc_cols <- paste0("PC", seq_len(k))
  rhs <- paste(c("0 + G + Y + L", pc_cols, paste0("G:", pc_cols)), collapse = " + ")
  X <- model.matrix(as.formula(paste("~", rhs)), data = d)

  # penalty factors: do NOT penalize G/Y/L main effects
  cn <- colnames(X)
  pf <- rep(1, length(cn))
  pf[grepl("^G", cn) & !grepl(":", cn)] <- 0
  pf[grepl("^Y", cn)] <- 0
  pf[grepl("^L", cn)] <- 0

  train_idx <- which(!d$is_test)
  test_idx <- which(d$is_test)
  y_train <- d$y_true[train_idx]

  best <- list(alpha = NA_real_, lambda = NA_real_, cvm = Inf)
  set.seed(42)
  for (a in alpha_grid) {
    cvfit <- cv.glmnet(
      x = X[train_idx, , drop = FALSE],
      y = y_train,
      family = "gaussian",
      alpha = a,
      nfolds = 3,
      standardize = FALSE,
      intercept = TRUE,
      penalty.factor = pf
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
    intercept = TRUE,
    penalty.factor = pf
  )

  pred <- as.numeric(predict(fit, newx = X[test_idx, , drop = FALSE], s = best$lambda))
  out <- d[test_idx, c("Y", "L", "G", "ENV", "env_id", "geno_ID", "y_true", "seen_in_train"), drop = FALSE]
  out$predicted_value <- pred
  out$model <- "glmnet_partial"
  out$fold_id <- fold_id
  out$alpha <- best$alpha
  out$lambda <- best$lambda
  out$k_pc <- k

  metrics <- rbind(
    data.frame(model = "glmnet_partial", fold_id = fold_id, scope = "all", n_eval = nrow(out),
               correlation = safe_cor(out$y_true, out$predicted_value),
               rmse = safe_rmse(out$y_true, out$predicted_value),
               mspe = safe_mspe(out$y_true, out$predicted_value),
               mean_bias = safe_bias(out$y_true, out$predicted_value),
               alpha = best$alpha, lambda = best$lambda, k_pc = k, stringsAsFactors = FALSE),
    data.frame(model = "glmnet_partial", fold_id = fold_id, scope = "seen_genotypes", n_eval = sum(out$seen_in_train),
               correlation = safe_cor(out$y_true[out$seen_in_train], out$predicted_value[out$seen_in_train]),
               rmse = safe_rmse(out$y_true[out$seen_in_train], out$predicted_value[out$seen_in_train]),
               mspe = safe_mspe(out$y_true[out$seen_in_train], out$predicted_value[out$seen_in_train]),
               mean_bias = safe_bias(out$y_true[out$seen_in_train], out$predicted_value[out$seen_in_train]),
               alpha = best$alpha, lambda = best$lambda, k_pc = k, stringsAsFactors = FALSE)
  )
  list(predictions = out, metrics = metrics)
}

inputs <- read_loeo_inputs()
dat <- inputs$dat
folds <- subset_folds_for_run(inputs$folds)
ec_cols <- detect_available_ec_aliases(dat)

pred_file <- file.path(out_dir, "21_glmnet_partial_predictions.csv")
met_file <- file.path(out_dir, "21_glmnet_partial_metrics.csv")
if (file.exists(pred_file)) file.remove(pred_file)
if (file.exists(met_file)) file.remove(met_file)

preds <- list()
mets <- list()
for (i in seq_len(nrow(folds))) {
  fr <- folds[i, , drop = FALSE]
  message("Running glmnet_partial on ", fr$fold_id)
  res <- fit_one_fold(dat, fr, ec_cols = ec_cols)
  preds[[i]] <- res$predictions
  mets[[i]] <- res$metrics
  write.table(res$predictions, pred_file, sep = ",", row.names = FALSE, col.names = !file.exists(pred_file), append = file.exists(pred_file))
  write.table(res$metrics, met_file, sep = ",", row.names = FALSE, col.names = !file.exists(met_file), append = file.exists(met_file))
}

predictions <- do.call(rbind, preds)
metrics <- do.call(rbind, mets)
summary_metrics <- aggregate(cbind(correlation, rmse, mspe, mean_bias) ~ model + scope, data = metrics, FUN = mean, na.rm = TRUE)
write.csv(summary_metrics, file.path(out_dir, "21_glmnet_partial_summary_metrics.csv"), row.names = FALSE)
message("Saved LOEO glmnet partial-penalty results.")
print(summary_metrics)

