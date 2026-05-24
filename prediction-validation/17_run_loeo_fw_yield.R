## -----------------------------------------------------------------------------
## Stage 17: Run fold-wise LOEO refits for the FW models
##
## Models covered:
## - fw1_us
## - fw2_us
##
## Why this stage matters:
## The paper uses FW as a synthetic-covariate alternative to direct observed-EC
## response structures.
##
## Outputs:
## - analysis/outputs/prediction_yield/loeo_cv/17_fw_predictions.csv
## - analysis/outputs/prediction_yield/loeo_cv/17_fw_metrics.csv
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/14_cv_model_helpers_yield.R")

inputs <- read_loeo_inputs()
dat <- inputs$dat
folds <- subset_folds_for_run(inputs$folds)

models_to_run <- c("fw1_us", "fw2_us")
results <- lapply(models_to_run, function(m) run_model_over_folds(m, dat, folds))

predictions <- do.call(rbind, lapply(results, `[[`, "predictions"))
metrics <- do.call(rbind, lapply(results, `[[`, "metrics"))

write.csv(
  predictions,
  file.path(cv_output_dir, "17_fw_predictions.csv"),
  row.names = FALSE
)

write.csv(
  metrics,
  file.path(cv_output_dir, "17_fw_metrics.csv"),
  row.names = FALSE
)

message("Saved LOEO FW prediction results.")
print(aggregate(cbind(correlation, rmse, mspe) ~ model + scope, data = metrics, FUN = mean))
