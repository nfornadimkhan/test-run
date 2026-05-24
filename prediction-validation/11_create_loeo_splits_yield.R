## -----------------------------------------------------------------------------
## Stage 11: Create LOEO validation folds for yield
##
## LOEO = Leave One Environment Out
##
## Goal:
## Build one fold per environment so that each validation run tests prediction
## into an environment that was not used in training.
##
## Why this matters:
## This is the paper's first practical future-environment style validation
## question. It is much more meaningful than random row-wise splitting because
## environments, not individual rows, are the prediction targets in GxE work.
##
## Output:
## - analysis/outputs/prediction_yield/11_loeo_folds.csv
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/10_prediction_paths_and_helpers.R")

dat <- read_prediction_input()
envs <- unique(dat[, c("env_id", "year", "location")])
envs <- envs[order(envs$year, envs$location), ]

loeo_folds <- data.frame(
  fold_id = paste0("LOEO_", seq_len(nrow(envs))),
  env_id = envs$env_id,
  year = envs$year,
  location = envs$location,
  stringsAsFactors = FALSE
)

write.csv(
  loeo_folds,
  file.path(prediction_output_dir, "11_loeo_folds.csv"),
  row.names = FALSE
)

message("Created LOEO folds for yield.")
print(head(loeo_folds, 10))
