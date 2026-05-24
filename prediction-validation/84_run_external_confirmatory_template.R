## -----------------------------------------------------------------------------
## Stage 84: External confirmatory orchestrator template
##
## Purpose:
## - run standardized checks on canonical external datasets
## - create comparable confirmatory output skeletons
##
## NOTE:
## - This template expects canonical files from stage-83 ingestion.
## - Plug in the finalized candidate predictor function where marked.
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/10_prediction_paths_and_helpers.R")

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) {
  stop("Usage: Rscript 84_run_external_confirmatory_template.R <dataset_key> <base_dir>")
}

dataset_key <- args[1]
base_dir <- args[2]

ext_dir <- file.path(base_dir, dataset_key)
canon_path <- file.path(ext_dir, paste0(dataset_key, "_canonical.csv"))
fold_path <- file.path(ext_dir, paste0(dataset_key, "_fold_map.csv"))
qc_path <- file.path(ext_dir, paste0(dataset_key, "_ingestion_qc.csv"))

stopifnot(file.exists(canon_path), file.exists(fold_path), file.exists(qc_path))

dat <- read.csv(canon_path, stringsAsFactors = FALSE)
fold_map <- read.csv(fold_path, stringsAsFactors = FALSE)
qc <- read.csv(qc_path, stringsAsFactors = FALSE)

required_cols <- c("geno_id", "env_id", "trait_value")
missing_cols <- setdiff(required_cols, names(dat))
if (length(missing_cols) > 0) stop("Missing columns: ", paste(missing_cols, collapse = ", "))

out_dir <- file.path(ext_dir, "confirmatory_template_outputs")
ensure_dir(out_dir)

# Merge fold assignment
dat <- merge(dat, fold_map, by = "env_id", all.x = TRUE)
if (any(is.na(dat$fold_id))) stop("Some rows missing fold_id after merge.")

# Baseline placeholder predictor (global mean by fold training only).
# Replace this block with the final weighted-consensus candidate implementation.
folds <- unique(dat$fold_id)
pred_rows <- vector("list", length(folds))
for (i in seq_along(folds)) {
  f <- folds[i]
  tr <- dat[dat$fold_id != f, ]
  te <- dat[dat$fold_id == f, ]
  mu <- mean(tr$trait_value, na.rm = TRUE)
  te$pred_baseline_template <- mu
  te$pred_candidate_template <- mu
  pred_rows[[i]] <- te
}
pred <- do.call(rbind, pred_rows)

safe_rmse <- function(y, p) sqrt(mean((y - p)^2, na.rm = TRUE))
by_fold <- split(pred, pred$fold_id)
metrics <- do.call(rbind, lapply(by_fold, function(x) {
  data.frame(
    fold_id = x$fold_id[1],
    rmse_baseline = safe_rmse(x$trait_value, x$pred_baseline_template),
    rmse_candidate = safe_rmse(x$trait_value, x$pred_candidate_template),
    gain = safe_rmse(x$trait_value, x$pred_baseline_template) - safe_rmse(x$trait_value, x$pred_candidate_template),
    stringsAsFactors = FALSE
  )
}))

summary_df <- data.frame(
  dataset_key = dataset_key,
  n_rows = nrow(dat),
  n_env = length(unique(dat$env_id)),
  n_folds = length(unique(dat$fold_id)),
  mean_gain = mean(metrics$gain, na.rm = TRUE),
  stringsAsFactors = FALSE
)

write.csv(pred, file.path(out_dir, paste0(dataset_key, "_template_predictions.csv")), row.names = FALSE)
write.csv(metrics, file.path(out_dir, paste0(dataset_key, "_template_fold_metrics.csv")), row.names = FALSE)
write.csv(summary_df, file.path(out_dir, paste0(dataset_key, "_template_summary.csv")), row.names = FALSE)
write.csv(qc, file.path(out_dir, paste0(dataset_key, "_input_qc_snapshot.csv")), row.names = FALSE)

message("Stage-84 template run complete for dataset: ", dataset_key)
print(summary_df)
