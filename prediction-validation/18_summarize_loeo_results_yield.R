## -----------------------------------------------------------------------------
## Stage 18: Combine LOEO prediction results across model families
##
## Goal:
## Pull together the baseline, RRR/RFR, and FW fold-wise metrics into one table
## so you can compare prediction quality across model families.
##
## Outputs:
## - analysis/outputs/prediction_yield/loeo_cv/18_loeo_metrics_all_models.csv
## - analysis/outputs/prediction_yield/loeo_cv/18_loeo_metrics_summary.csv
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/10_prediction_paths_and_helpers.R")

metric_files <- c(
  file.path(prediction_output_dir, "loeo_cv", "15_baseline_family_metrics.csv"),
  file.path(prediction_output_dir, "loeo_cv", "16_rrr_rfr_metrics.csv"),
  file.path(prediction_output_dir, "loeo_cv", "17_fw_metrics.csv")
)

metric_files <- metric_files[file.exists(metric_files)]
if (length(metric_files) == 0) {
  stop("No LOEO metric files found yet. Run Stages 15-17 first.", call. = FALSE)
}

all_metrics <- do.call(rbind, lapply(metric_files, read.csv))

summary_metrics <- aggregate(
  cbind(correlation, rmse, mspe, mean_bias, n_eval) ~ model + scope,
  data = all_metrics,
  FUN = mean
)

write.csv(
  all_metrics,
  file.path(prediction_output_dir, "loeo_cv", "18_loeo_metrics_all_models.csv"),
  row.names = FALSE
)

write.csv(
  summary_metrics,
  file.path(prediction_output_dir, "loeo_cv", "18_loeo_metrics_summary.csv"),
  row.names = FALSE
)

message("Combined LOEO results across model families.")
print(summary_metrics[order(summary_metrics$rmse), ])
