## -----------------------------------------------------------------------------
## Stage 10: Prepare the prediction dataset for the paper-continuation phase
##
## Goal:
## Build a clean dataset for validation and prediction analysis from the current
## Stage 6 ASReml input table.
##
## Why this stage matters:
## The paper's next question is not "which model has the lowest AIC?"
## It is "which model predicts unseen environments better?"
##
## Before we create LOEO or LYLO folds, we need one stable dataset that:
## - contains the target trait
## - contains the environment identifiers
## - records which EC aliases are actually present
##
## This is especially important here because the project is in transition from
## an older 5-EC setup to a newer 8-EC AgERA5 setup.
##
## Outputs:
## - analysis/outputs/prediction_yield/10_yield_prediction_dataset.csv
## - analysis/outputs/prediction_yield/10_yield_prediction_metadata.csv
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/10_prediction_paths_and_helpers.R")

dat <- read_prediction_input()
meta <- extract_prediction_metadata(dat)

write.csv(
  dat,
  file.path(prediction_output_dir, "10_yield_prediction_dataset.csv"),
  row.names = FALSE
)

write.csv(
  meta,
  file.path(prediction_output_dir, "10_yield_prediction_metadata.csv"),
  row.names = FALSE
)

message("Prepared prediction dataset for yield.")
print(meta)
