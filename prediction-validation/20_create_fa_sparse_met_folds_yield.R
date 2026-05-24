## -----------------------------------------------------------------------------
## Stage 20: Create FA-native sparse-MET validation folds for yield
##
## Goal:
## Build row-wise folds that mask genotype-environment cells while keeping every
## environment represented in training.
##
## Why this matters:
## Factor-analytic GEI models are naturally designed for predicting missing
## cells in an observed set of environments, not for extrapolating into a
## completely unseen environment.
##
## Output:
## - analysis/outputs/prediction_yield/20_fa_sparse_met_folds.csv
## - analysis/outputs/prediction_yield/20_fa_sparse_met_plan.csv
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/10_prediction_paths_and_helpers.R")

set.seed(20260524)

dat <- read_prediction_input()
dat$row_id <- seq_len(nrow(dat))

k_folds <- 5L

fold_list <- lapply(split(dat, dat$env_id), function(env_df) {
  env_df <- env_df[sample.int(nrow(env_df)), , drop = FALSE]
  env_df$fold_index <- rep(seq_len(k_folds), length.out = nrow(env_df))
  env_df[, c("row_id", "env_id", "year", "location", "geno_ID", "fold_index")]
})

folds <- do.call(rbind, fold_list)
folds$fold_id <- paste0("FA_SPARSE_", folds$fold_index)
folds <- folds[order(folds$fold_index, folds$env_id, folds$row_id), ]

write.csv(
  folds[, c("fold_id", "row_id", "env_id", "year", "location", "geno_ID")],
  file.path(prediction_output_dir, "20_fa_sparse_met_folds.csv"),
  row.names = FALSE
)

plan <- make_rowwise_fold_summary(
  folds = folds[, c("fold_id", "row_id")],
  dat = dat,
  row_id_col = "row_id",
  fold_col = "fold_id"
)

write.csv(
  plan,
  file.path(prediction_output_dir, "20_fa_sparse_met_plan.csv"),
  row.names = FALSE
)

message("Created FA-native sparse-MET folds for yield.")
print(plan)
