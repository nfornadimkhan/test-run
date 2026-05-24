## -----------------------------------------------------------------------------
## Stage 15: Run fold-wise LOEO refits for the baseline family
##
## Models covered:
## - baseline
## - baseline_ec
##
## Why start here:
## These are the cheapest and conceptually cleanest models.
## They let you understand the mechanics of paper-style validation before moving
## to richer RRR, RFR, and FW structures.
##
## Outputs:
## - analysis/outputs/prediction_yield/loeo_cv/15_baseline_family_predictions.csv
## - analysis/outputs/prediction_yield/loeo_cv/15_baseline_family_metrics.csv
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/14_cv_model_helpers_yield.R")

inputs <- read_loeo_inputs()
dat <- inputs$dat
folds <- subset_folds_for_run(inputs$folds)

models_to_run <- c("baseline", "baseline_ec")
results <- lapply(models_to_run, function(m) run_model_over_folds(m, dat, folds))

predictions <- do.call(rbind, lapply(results, `[[`, "predictions"))
metrics <- do.call(rbind, lapply(results, `[[`, "metrics"))

write.csv(
  predictions,
  file.path(cv_output_dir, "15_baseline_family_predictions.csv"),
  row.names = FALSE
)

write.csv(
  metrics,
  file.path(cv_output_dir, "15_baseline_family_metrics.csv"),
  row.names = FALSE
)

message("Saved LOEO baseline-family prediction results.")
print(aggregate(cbind(correlation, rmse, mspe) ~ model + scope, data = metrics, FUN = mean))
