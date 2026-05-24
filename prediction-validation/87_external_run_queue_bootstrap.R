## -----------------------------------------------------------------------------
## Stage 87: External run-queue bootstrap
##
## Purpose:
## - inspect external dataset folders
## - detect readiness for stage-83 and stage-84
## - emit exact next command per dataset
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/10_prediction_paths_and_helpers.R")

tracker_path <- "/Users/neon/Documents/Nadim's Brain/analysis/models/84_external_execution_tracker_2026-05-23.csv"
if (!file.exists(tracker_path)) stop("Missing tracker: ", tracker_path)

trk <- read.csv(tracker_path, stringsAsFactors = FALSE)
base_ext <- file.path(prediction_output_dir, "external_validation")
ensure_dir(base_ext)

dataset_to_stage83 <- function(key) {
  if (key == "cimmyt_wheat") return("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/83_ingest_cimmyt_wheat_template.R")
  if (key == "dryad_rice") return("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/83_ingest_dryad_rice_template.R")
  NA_character_
}

rows <- lapply(seq_len(nrow(trk)), function(i) {
  key <- trk$dataset_key[i]
  ext_dir <- file.path(base_ext, key)
  raw_dir <- file.path(ext_dir, "raw")
  canon <- file.path(ext_dir, paste0(key, "_canonical.csv"))
  fold <- file.path(ext_dir, paste0(key, "_fold_map.csv"))
  qc <- file.path(ext_dir, paste0(key, "_ingestion_qc.csv"))
  conf_dir <- file.path(ext_dir, "confirmatory_template_outputs")

  raw_ready <- dir.exists(raw_dir) && length(list.files(raw_dir, all.files = FALSE)) > 0
  ingest_ready <- file.exists(canon) && file.exists(fold) && file.exists(qc)
  conf_ready <- dir.exists(conf_dir) && length(list.files(conf_dir, pattern = "_template_summary.csv$", all.files = FALSE)) > 0

  next_action <- if (!raw_ready) {
    "Place raw files in external_validation/<dataset_key>/raw/"
  } else if (!ingest_ready) {
    s83 <- dataset_to_stage83(key)
    if (is.na(s83)) "Create dataset-specific stage-83 script for this key"
    else paste("Run:", "Rscript", shQuote(s83))
  } else if (!conf_ready) {
    paste(
      "Run:",
      "Rscript",
      shQuote("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/84_run_external_confirmatory_template.R"),
      key,
      shQuote(base_ext)
    )
  } else {
    "Completed template confirmatory run"
  }

  data.frame(
    dataset_key = key,
    raw_ready = raw_ready,
    ingest_ready = ingest_ready,
    confirmatory_template_ready = conf_ready,
    next_action = next_action,
    stringsAsFactors = FALSE
  )
})

queue <- do.call(rbind, rows)
out_dir <- file.path(base_ext, "run_queue")
ensure_dir(out_dir)
write.csv(queue, file.path(out_dir, "87_external_run_queue_status.csv"), row.names = FALSE)

message("Saved stage-87 external run queue.")
print(queue)
