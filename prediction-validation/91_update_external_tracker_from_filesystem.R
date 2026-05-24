## -----------------------------------------------------------------------------
## Stage 91: Auto-update external tracker from filesystem state
##
## Reads:
## - raw data folder existence
## - mapping template completion
## - stage-83 artifact existence
## - stage-84 template output existence
##
## Writes updated tracker CSV.
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/10_prediction_paths_and_helpers.R")

tracker_path <- "/Users/neon/Documents/Nadim's Brain/analysis/models/84_external_execution_tracker_2026-05-23.csv"
if (!file.exists(tracker_path)) stop("Missing tracker file: ", tracker_path)

trk <- read.csv(tracker_path, stringsAsFactors = FALSE)
base_ext <- file.path(prediction_output_dir, "external_validation")

mapping_file_for <- function(key) {
  if (key == "cimmyt_wheat") return("/Users/neon/Documents/Nadim's Brain/analysis/models/90_column_mapping_template_cimmyt_wheat_2026-05-23.csv")
  if (key == "dryad_rice") return("/Users/neon/Documents/Nadim's Brain/analysis/models/90_column_mapping_template_dryad_rice_2026-05-23.csv")
  if (key == "dryad_wheat_sparse") return("/Users/neon/Documents/Nadim's Brain/analysis/models/90_column_mapping_template_dryad_wheat_sparse_2026-05-23.csv")
  if (key == "dryad_maize_met") return("/Users/neon/Documents/Nadim's Brain/analysis/models/90_column_mapping_template_dryad_maize_met_2026-05-23.csv")
  NA_character_
}

mapping_complete <- function(path) {
  if (is.na(path) || !file.exists(path)) return(FALSE)
  x <- read.csv(path, stringsAsFactors = FALSE)
  req <- x[x$required == "yes", ]
  if (nrow(req) == 0) return(FALSE)
  all(trimws(ifelse(is.na(req$raw_column), "", req$raw_column)) != "")
}

for (i in seq_len(nrow(trk))) {
  key <- trk$dataset_key[i]
  ext_dir <- file.path(base_ext, key)
  raw_dir <- file.path(ext_dir, "raw")

  canon <- file.path(ext_dir, paste0(key, "_canonical.csv"))
  fold <- file.path(ext_dir, paste0(key, "_fold_map.csv"))
  qc <- file.path(ext_dir, paste0(key, "_ingestion_qc.csv"))
  conf_dir <- file.path(ext_dir, "confirmatory_template_outputs")
  cand_dir <- file.path(ext_dir, "confirmatory_candidate_outputs")
  cand_gate <- file.path(cand_dir, paste0(key, "_candidate_gate_result.csv"))

  raw_ok <- dir.exists(raw_dir) && file.exists(file.path(raw_dir, "phenotype.csv")) && file.exists(file.path(raw_dir, "markers.csv"))
  map_ok <- mapping_complete(mapping_file_for(key))
  ingest_ok <- file.exists(canon) && file.exists(fold) && file.exists(qc)
  conf_ok <- dir.exists(conf_dir) && length(list.files(conf_dir, pattern = "_template_summary.csv$", all.files = FALSE)) > 0
  cand_ok <- dir.exists(cand_dir) && file.exists(cand_gate)
  cand_pass <- FALSE
  if (cand_ok) {
    g <- read.csv(cand_gate, stringsAsFactors = FALSE)
    if ("pass_confirmatory" %in% names(g) && nrow(g) > 0) cand_pass <- isTRUE(g$pass_confirmatory[1])
  }

  trk$status_raw_download[i] <- ifelse(raw_ok, "done", "pending")
  trk$status_stage83_ingest[i] <- ifelse(ingest_ok, "done", "pending")
  trk$status_stage84_template_run[i] <- ifelse(conf_ok, "done", "pending")
  trk$status_candidate_plugged[i] <- ifelse(cand_ok, "done", "pending")
  trk$status_confirmatory_complete[i] <- ifelse(cand_ok, "done", "pending")

  if (!raw_ok) {
    trk$notes[i] <- "Missing raw/phenotype.csv and/or raw/markers.csv"
  } else if (!map_ok) {
    trk$notes[i] <- "Fill required raw_column fields in stage-90 mapping template"
  } else if (!ingest_ok) {
    trk$notes[i] <- "Run stage-83 ingestion script"
  } else if (!cand_ok) {
    if (!conf_ok) {
      trk$notes[i] <- "Run stage-84 confirmatory template script"
    } else {
      trk$notes[i] <- "Run stage-96 external candidate confirmatory script"
    }
  } else {
    if (cand_pass) {
      trk$notes[i] <- "Candidate run complete, confirmatory gate passed"
    } else {
      trk$notes[i] <- "Candidate run complete, confirmatory gate failed"
    }
    if (!conf_ok) {
      trk$notes[i] <- paste0(trk$notes[i], " (template stage skipped)")
    }
  }
}

write.csv(trk, tracker_path, row.names = FALSE)

out_dir <- file.path(base_ext, "run_queue")
ensure_dir(out_dir)
write.csv(trk, file.path(out_dir, "91_external_tracker_snapshot.csv"), row.names = FALSE)

message("Stage-91 tracker update complete.")
print(trk)
