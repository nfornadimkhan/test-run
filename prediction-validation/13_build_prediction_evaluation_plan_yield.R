## -----------------------------------------------------------------------------
## Stage 13: Summarize the prediction evaluation plan for yield
##
## Goal:
## Turn the fold definitions into a simple inspection table before any expensive
## refitting begins.
##
## Why this matters:
## In the paper, validation design is not a technical afterthought.
## It defines the prediction question itself.
##
## This stage helps you inspect:
## - how many folds there are
## - how many rows are in each training set
## - how many rows are in each test set
## - whether the held-out environments are balanced enough for a meaningful run
##
## Output:
## - analysis/outputs/prediction_yield/13_prediction_evaluation_plan.csv
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/10_prediction_paths_and_helpers.R")

dat <- read_prediction_input()
loeo <- read.csv(file.path(prediction_output_dir, "11_loeo_folds.csv"))
lylo <- read.csv(file.path(prediction_output_dir, "12_lylo_folds.csv"))

loeo_summary <- make_fold_summary(loeo, dat)
loeo_summary$validation_scheme <- "LOEO"

lylo_summary <- make_fold_summary(lylo, dat)
lylo_summary$validation_scheme <- "LYLO"

plan <- rbind(loeo_summary, lylo_summary)

write.csv(
  plan,
  file.path(prediction_output_dir, "13_prediction_evaluation_plan.csv"),
  row.names = FALSE
)

message("Built prediction evaluation plan for yield.")
print(head(plan, 10))
