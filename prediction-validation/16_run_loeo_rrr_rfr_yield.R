## -----------------------------------------------------------------------------
## Stage 16: Run fold-wise LOEO refits for RRR and RFR models
##
## Models covered:
## - rrr1
## - rrr2
## - rfr_us
##
## Why this stage matters:
## These models carry the main reaction-norm message of the paper.
## If they predict held-out environments better than baseline_ec, then the extra
## genotype-specific response structure is earning its complexity.
##
## Outputs:
## - analysis/outputs/prediction_yield/loeo_cv/16_rrr_rfr_predictions.csv
## - analysis/outputs/prediction_yield/loeo_cv/16_rrr_rfr_metrics.csv
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/14_cv_model_helpers_yield.R")

inputs <- read_loeo_inputs()
dat <- inputs$dat
folds <- subset_folds_for_run(inputs$folds)

models_to_run <- c("rrr1", "rrr2", "rfr_us")
results <- lapply(models_to_run, function(m) run_model_over_folds(m, dat, folds))

predictions <- do.call(rbind, lapply(results, `[[`, "predictions"))
metrics <- do.call(rbind, lapply(results, `[[`, "metrics"))

write.csv(
  predictions,
  file.path(cv_output_dir, "16_rrr_rfr_predictions.csv"),
  row.names = FALSE
)

write.csv(
  metrics,
  file.path(cv_output_dir, "16_rrr_rfr_metrics.csv"),
  row.names = FALSE
)

message("Saved LOEO RRR/RFR prediction results.")
print(aggregate(cbind(correlation, rmse, mspe) ~ model + scope, data = metrics, FUN = mean))
