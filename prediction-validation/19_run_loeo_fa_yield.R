## -----------------------------------------------------------------------------
## Stage 19: Run fold-wise LOEO refits for factor-analytic models
##
## Default model covered:
## - fa2
##
## Why this stage matters:
## It tests whether a latent GEI structure learned from observed environments can
## still predict a completely held-out environment under the same LOEO design
## used for RRR2.
##
## Important caution:
## Pure FA models are not naturally designed for extrapolation into brand-new
## environments, because environment loadings are estimated from the observed
## GxE table itself. This script therefore doubles as a direct stress test of
## that limitation.
##
## Outputs:
## - analysis/outputs/prediction_yield/loeo_cv/19_fa_predictions.csv
## - analysis/outputs/prediction_yield/loeo_cv/19_fa_metrics.csv
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/14_cv_model_helpers_yield.R")

inputs <- read_loeo_inputs()
dat <- inputs$dat
folds <- subset_folds_for_run(inputs$folds)

models_to_run <- Sys.getenv("FA_MODELS", unset = "fa2")
models_to_run <- trimws(strsplit(models_to_run, ",", fixed = TRUE)[[1]])
models_to_run <- models_to_run[nzchar(models_to_run)]

results <- lapply(models_to_run, function(m) run_model_over_folds(m, dat, folds))

predictions <- do.call(rbind, lapply(results, `[[`, "predictions"))
metrics <- do.call(rbind, lapply(results, `[[`, "metrics"))

write.csv(
  predictions,
  file.path(cv_output_dir, "19_fa_predictions.csv"),
  row.names = FALSE
)

write.csv(
  metrics,
  file.path(cv_output_dir, "19_fa_metrics.csv"),
  row.names = FALSE
)

message("Saved LOEO FA prediction results.")
print(aggregate(cbind(correlation, rmse, mspe) ~ model + scope, data = metrics, FUN = mean))
