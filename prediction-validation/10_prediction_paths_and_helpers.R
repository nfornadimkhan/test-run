## -----------------------------------------------------------------------------
## Prediction/Validation Stage 0: Shared helpers for the post-fitting paper steps
##
## Why this file exists:
## The earlier analysis pipeline had one helper file for preprocessing and model
## fitting. The prediction/validation phase needs its own folder structure and
## its own small utilities, but it should still reuse the main project helpers.
##
## Main ideas:
## - keep the prediction-validation outputs separate from the fitting outputs
## - detect which EC aliases are present in the current Stage 6 input file
## - create reusable fold-summary and metric helper functions
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/pre-processing/00_paths_and_helpers.R")

prediction_dir <- file.path(analysis_dir, "prediction-validation")
prediction_output_dir <- file.path(output_dir, "prediction_yield")
ensure_dir(prediction_output_dir)

prediction_input_path <- file.path(output_dir, "asreml_yield", "06_yield_asreml_input.csv")

read_prediction_input <- function() {
  dat <- read.csv(prediction_input_path)
  assert_required_columns(
    dat,
    c("env_id", "year", "location", "geno_ID", "yld_bu_ac", "G", "L", "Y", "ENV"),
    object_name = "Stage 6 ASReml input table"
  )
  dat
}

extract_prediction_metadata <- function(dat) {
  ec_aliases <- detect_available_ec_aliases(dat)
  data.frame(
    trait = "yld_bu_ac",
    n_rows = nrow(dat),
    n_genotypes = length(unique(dat$geno_ID)),
    n_environments = length(unique(dat$env_id)),
    n_locations = length(unique(dat$location)),
    n_years = length(unique(dat$year)),
    n_ec = length(ec_aliases),
    ec_aliases = paste(ec_aliases, collapse = ", "),
    stringsAsFactors = FALSE
  )
}

make_fold_summary <- function(folds, dat, fold_col = "fold_id") {
  do.call(
    rbind,
    lapply(split(folds, folds[[fold_col]]), function(x) {
      held_out_envs <- unique(x$env_id)
      held_out_rows <- dat[dat$env_id %in% held_out_envs, ]
      train_rows <- dat[!dat$env_id %in% held_out_envs, ]

      data.frame(
        fold_id = x[[fold_col]][1],
        n_test_env = length(unique(held_out_rows$env_id)),
        n_test_rows = nrow(held_out_rows),
        n_test_genotypes = length(unique(held_out_rows$geno_ID)),
        n_train_env = length(unique(train_rows$env_id)),
        n_train_rows = nrow(train_rows),
        n_train_genotypes = length(unique(train_rows$geno_ID)),
        stringsAsFactors = FALSE
      )
    })
  )
}

make_rowwise_fold_summary <- function(folds, dat, row_id_col = "row_id", fold_col = "fold_id") {
  dat_indexed <- dat
  dat_indexed[[row_id_col]] <- seq_len(nrow(dat_indexed))

  do.call(
    rbind,
    lapply(split(folds, folds[[fold_col]]), function(x) {
      test_ids <- x[[row_id_col]]
      held_out_rows <- dat_indexed[dat_indexed[[row_id_col]] %in% test_ids, , drop = FALSE]
      train_rows <- dat_indexed[!dat_indexed[[row_id_col]] %in% test_ids, , drop = FALSE]

      data.frame(
        fold_id = x[[fold_col]][1],
        n_test_env = length(unique(held_out_rows$env_id)),
        n_test_rows = nrow(held_out_rows),
        n_test_genotypes = length(unique(held_out_rows$geno_ID)),
        n_train_env = length(unique(train_rows$env_id)),
        n_train_rows = nrow(train_rows),
        n_train_genotypes = length(unique(train_rows$geno_ID)),
        stringsAsFactors = FALSE
      )
    })
  )
}
