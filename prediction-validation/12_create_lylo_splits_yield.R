## -----------------------------------------------------------------------------
## Stage 12: Create LYLO validation folds for yield
##
## LYLO = Leave Year-Location Out
##
## Goal:
## Build folds that make the year-location identity explicit as the held-out
## unit. In this dataset, the environment itself is defined by year + location,
## so LYLO and LOEO are closely related. We still write LYLO separately because
## the paper's logic distinguishes the prediction problem conceptually.
##
## Why this stage exists if env_id already equals year + location:
## It forces us to think clearly about what is being held out:
## - not a random subset of rows
## - not a genotype subset
## - but a complete year-location environment
##
## Output:
## - analysis/outputs/prediction_yield/12_lylo_folds.csv
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/10_prediction_paths_and_helpers.R")

dat <- read_prediction_input()
envs <- unique(dat[, c("env_id", "year", "location")])
envs <- envs[order(envs$year, envs$location), ]

lylo_folds <- data.frame(
  fold_id = paste0("LYLO_", envs$year, "_", envs$location),
  env_id = envs$env_id,
  year = envs$year,
  location = envs$location,
  stringsAsFactors = FALSE
)

write.csv(
  lylo_folds,
  file.path(prediction_output_dir, "12_lylo_folds.csv"),
  row.names = FALSE
)

message("Created LYLO folds for yield.")
print(head(lylo_folds, 10))
