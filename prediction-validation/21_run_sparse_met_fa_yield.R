## -----------------------------------------------------------------------------
## Stage 21: Run FA models on FA-native sparse-MET folds for yield
##
## Default model:
## - fa2
##
## Prediction design:
## - mask genotype-environment cells
## - keep all environments represented in training
## - predict missing cells in already-observed environments
##
## Outputs:
## - analysis/outputs/prediction_yield/sparse_met_cv/21_fa_predictions.csv
## - analysis/outputs/prediction_yield/sparse_met_cv/21_fa_metrics.csv
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/14_cv_model_helpers_yield.R")

sparse_cv_output_dir <- file.path(prediction_output_dir, "sparse_met_cv")
ensure_dir(sparse_cv_output_dir)

read_sparse_met_inputs <- function() {
  dat <- read_prediction_input()
  folds <- read.csv(file.path(prediction_output_dir, "20_fa_sparse_met_folds.csv"))

  dat$row_id <- seq_len(nrow(dat))
  dat$G <- factor(dat$G)
  dat$L <- factor(dat$L)
  dat$Y <- factor(dat$Y)
  dat$ENV <- factor(dat$ENV)

  list(dat = dat, folds = folds)
}

subset_sparse_folds_for_run <- function(folds) {
  fold_ids <- unique(folds$fold_id)
  fold_limit <- Sys.getenv("FOLD_LIMIT", unset = "")
  if (nzchar(fold_limit)) {
    keep_ids <- fold_ids[seq_len(min(as.integer(fold_limit), length(fold_ids)))]
    folds <- folds[folds$fold_id %in% keep_ids, , drop = FALSE]
  }
  folds
}

mask_sparse_fold_response <- function(dat, fold_rows) {
  dat2 <- dat
  test_ids <- fold_rows$row_id
  dat2$y_true <- dat2$yld_bu_ac
  dat2$is_test <- dat2$row_id %in% test_ids

  seen_train_genotypes <- unique(dat2$G[!dat2$is_test])
  dat2$seen_in_train <- dat2$G %in% seen_train_genotypes

  dat2$yld_bu_ac[dat2$is_test] <- NA_real_
  dat2
}

extract_sparse_fold_predictions <- function(model, scored_data, model_name, fold_id, pworkspace = "256mb") {
  test_rows <- scored_data[scored_data$is_test, , drop = FALSE]

  if (startsWith(model_name, "fa")) {
    pred_obj <- predict(
      model,
      classify = "ENV:G",
      levels = list(
        ENV = as.character(unique(test_rows$ENV)),
        G = as.character(unique(test_rows$G))
      ),
      pworkspace = pworkspace,
      maxit = 2
    )
    merge_keys <- c("ENV", "G")
    keep_truth <- unique(
      test_rows[, c("ENV", "env_id", "Y", "L", "G", "geno_ID", "y_true", "seen_in_train")]
    )
  } else {
    pred_obj <- predict(
      model,
      classify = "Y:L:G",
      levels = list(
        Y = as.character(unique(test_rows$Y)),
        L = as.character(unique(test_rows$L)),
        G = as.character(unique(test_rows$G))
      ),
      pworkspace = pworkspace,
      maxit = 2
    )
    merge_keys <- c("Y", "L", "G")
    keep_truth <- unique(
      test_rows[, c("ENV", "env_id", "Y", "L", "G", "geno_ID", "y_true", "seen_in_train")]
    )
  }

  pred_df <- pred_obj$pvals
  names(pred_df)[names(pred_df) == "predicted.value"] <- "predicted_value"
  names(pred_df)[names(pred_df) == "std.error"] <- "prediction_se"

  out <- merge(pred_df, keep_truth, by = merge_keys, all.x = TRUE)
  out$model <- model_name
  out$fold_id <- fold_id
  out$prediction_status <- out$status
  out
}

run_sparse_one_fold_one_model <- function(dat, fold_rows, model_name) {
  fold_id <- fold_rows$fold_id[[1]]
  dat_masked <- mask_sparse_fold_response(dat, fold_rows)
  components <- make_dynamic_model_components(dat_masked)

  message("Running ", model_name, " on ", fold_id)
  fit_obj <- fit_prediction_model(model_name, dat_masked, components)

  pred_df <- extract_sparse_fold_predictions(
    model = fit_obj$model,
    scored_data = fit_obj$scored_data,
    model_name = model_name,
    fold_id = fold_id
  )

  metric_df <- score_prediction_rows(pred_df, model_name, fold_id)
  list(predictions = pred_df, metrics = metric_df)
}

run_sparse_model_over_folds <- function(model_name, dat, folds) {
  fold_split <- split(folds, folds$fold_id)
  pred_list <- vector("list", length(fold_split))
  metric_list <- vector("list", length(fold_split))

  for (i in seq_along(fold_split)) {
    res <- run_sparse_one_fold_one_model(dat, fold_split[[i]], model_name)
    pred_list[[i]] <- res$predictions
    metric_list[[i]] <- res$metrics
  }

  list(
    predictions = do.call(rbind, pred_list),
    metrics = do.call(rbind, metric_list)
  )
}

inputs <- read_sparse_met_inputs()
dat <- inputs$dat
folds <- subset_sparse_folds_for_run(inputs$folds)

models_to_run <- Sys.getenv("FA_MODELS", unset = "fa2")
models_to_run <- trimws(strsplit(models_to_run, ",", fixed = TRUE)[[1]])
models_to_run <- models_to_run[nzchar(models_to_run)]

results <- lapply(models_to_run, function(m) run_sparse_model_over_folds(m, dat, folds))

predictions <- do.call(rbind, lapply(results, `[[`, "predictions"))
metrics <- do.call(rbind, lapply(results, `[[`, "metrics"))

write.csv(
  predictions,
  file.path(sparse_cv_output_dir, "21_fa_predictions.csv"),
  row.names = FALSE
)

write.csv(
  metrics,
  file.path(sparse_cv_output_dir, "21_fa_metrics.csv"),
  row.names = FALSE
)

message("Saved sparse-MET FA prediction results.")
print(aggregate(cbind(correlation, rmse, mspe) ~ model + scope, data = metrics, FUN = mean))
