## -----------------------------------------------------------------------------
## Stage 18: LOEO for a kernelized reaction-norm model (new-environment target)
##
## Model idea:
## y = mu + g + e(EC-kernel) + ge(genotype-specific EC-kernel response) + error
##
## Implemented with BGLR using three components:
## - BRR on genotype incidence (g)
## - RKHS with environment kernel mapped to row level (e)
## - RKHS with GxE kernel = I[same genotype] * K_env(row_i, row_j) (ge)
##
## Why this matters:
## - Environment kernel supports interpolation/extrapolation across environments
##   by EC similarity.
## - GxE kernel allows genotype-specific environmental responses while shrinking
##   complexity.
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/14_cv_model_helpers_yield.R")

ensure_package("BGLR")
library(BGLR)

kernel_cv_output <- file.path(cv_output_dir, "18_kernel_reaction_norm")
ensure_dir(kernel_cv_output)

rbf_kernel <- function(X, gamma = NULL) {
  D2 <- as.matrix(stats::dist(X))^2
  if (is.null(gamma)) {
    med <- stats::median(D2[D2 > 0], na.rm = TRUE)
    if (!is.finite(med) || med <= 0) med <- 1
    gamma <- 1 / med
  }
  exp(-gamma * D2)
}

safe_metrics <- function(df, model_name, fold_id, scope_name) {
  x <- df
  if (scope_name == "seen_genotypes") x <- x[x$seen_in_train, , drop = FALSE]
  x <- x[complete.cases(x$y_true, x$predicted_value), , drop = FALSE]
  data.frame(
    model = model_name,
    fold_id = fold_id,
    scope = scope_name,
    n_eval = nrow(x),
    correlation = safe_cor(x$y_true, x$predicted_value),
    rmse = safe_rmse(x$y_true, x$predicted_value),
    mspe = safe_mspe(x$y_true, x$predicted_value),
    mean_bias = safe_bias(x$y_true, x$predicted_value),
    stringsAsFactors = FALSE
  )
}

fit_one_fold_kernel <- function(dat, fold_row, ec_cols, nIter = 12000, burnIn = 4000, thin = 10) {
  env_id <- fold_row$env_id
  fold_id <- fold_row$fold_id
  dat_masked <- mask_fold_response(dat, env_id)

  # Keep rows with full ECs for kernel computation.
  keep <- complete.cases(dat_masked[, c(ec_cols, "G", "ENV", "yld_bu_ac", "y_true", "is_test", "seen_in_train", "geno_ID", "Y", "L", "env_id")])
  d <- dat_masked[keep, , drop = FALSE]

  # Design for genotype main effect.
  Xg <- model.matrix(~ 0 + G, data = d)

  # Environment kernel at environment level, then row-level projection.
  env_tab <- unique(d[, c("ENV", ec_cols)])
  rownames(env_tab) <- as.character(env_tab$ENV)
  Xe <- as.matrix(env_tab[, ec_cols, drop = FALSE])
  Ke_env <- rbf_kernel(Xe)
  Ke_env <- Ke_env / mean(diag(Ke_env))

  env_levels <- as.character(d$ENV)
  Ke_row <- Ke_env[env_levels, env_levels, drop = FALSE]

  # GxE kernel: genotype match * environment similarity.
  Gmatch <- outer(as.character(d$G), as.character(d$G), FUN = "==") * 1
  Kge_row <- Gmatch * Ke_row
  Kge_row <- Kge_row / mean(diag(Kge_row))

  y <- d$yld_bu_ac

  ETA <- list(
    list(X = Xg, model = "BRR"),
    list(K = Ke_row, model = "RKHS"),
    list(K = Kge_row, model = "RKHS")
  )

  fit <- BGLR::BGLR(
    y = y,
    ETA = ETA,
    nIter = nIter,
    burnIn = burnIn,
    thin = thin,
    verbose = FALSE
  )

  pred <- fit$yHat
  out <- d[, c("Y", "L", "G", "ENV", "env_id", "geno_ID", "y_true", "is_test", "seen_in_train")]
  out$predicted_value <- pred
  out$model <- "kernel_rn"
  out$fold_id <- fold_id
  out <- out[out$is_test, , drop = FALSE]

  metrics <- rbind(
    safe_metrics(out, "kernel_rn", fold_id, "all"),
    safe_metrics(out, "kernel_rn", fold_id, "seen_genotypes")
  )

  list(predictions = out, metrics = metrics)
}

inputs <- read_loeo_inputs()
dat <- inputs$dat
folds <- subset_folds_for_run(inputs$folds)

ec_cols <- detect_available_ec_aliases(dat)

# Standardize ECs for robust kernel distances.
for (ec in ec_cols) {
  dat[[ec]] <- as.numeric(scale(dat[[ec]]))
}

pred_list <- vector("list", nrow(folds))
met_list <- vector("list", nrow(folds))

for (i in seq_len(nrow(folds))) {
  fr <- folds[i, , drop = FALSE]
  message("Running kernel_rn on ", fr$fold_id)
  res <- fit_one_fold_kernel(dat, fr, ec_cols = ec_cols)
  pred_list[[i]] <- res$predictions
  met_list[[i]] <- res$metrics
}

predictions <- do.call(rbind, pred_list)
metrics <- do.call(rbind, met_list)

write.csv(
  predictions,
  file.path(kernel_cv_output, "18_kernel_rn_predictions.csv"),
  row.names = FALSE
)

write.csv(
  metrics,
  file.path(kernel_cv_output, "18_kernel_rn_metrics.csv"),
  row.names = FALSE
)

summary_metrics <- aggregate(cbind(correlation, rmse, mspe, mean_bias) ~ model + scope, data = metrics, FUN = mean, na.rm = TRUE)
write.csv(
  summary_metrics,
  file.path(kernel_cv_output, "18_kernel_rn_summary_metrics.csv"),
  row.names = FALSE
)

message("Saved LOEO kernel reaction-norm results.")
print(summary_metrics)

