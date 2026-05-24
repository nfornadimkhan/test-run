## -----------------------------------------------------------------------------
## Stage 92: External preflight validator
##
## Checks, per dataset:
## - raw/phenotype.csv exists
## - raw/markers.csv exists
## - required mapping rows have non-empty raw_column values
##
## Outputs a single readiness table for go/no-go execution.
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/10_prediction_paths_and_helpers.R")

base_ext <- file.path(prediction_output_dir, "external_validation")
out_dir <- file.path(base_ext, "run_queue")
ensure_dir(out_dir)

datasets <- data.frame(
  dataset_key = c("cimmyt_wheat", "dryad_rice", "dryad_wheat_sparse", "dryad_maize_met"),
  mapping_file = c(
    "/Users/neon/Documents/Nadim's Brain/analysis/models/90_column_mapping_template_cimmyt_wheat_2026-05-23.csv",
    "/Users/neon/Documents/Nadim's Brain/analysis/models/90_column_mapping_template_dryad_rice_2026-05-23.csv",
    "/Users/neon/Documents/Nadim's Brain/analysis/models/90_column_mapping_template_dryad_wheat_sparse_2026-05-23.csv",
    "/Users/neon/Documents/Nadim's Brain/analysis/models/90_column_mapping_template_dryad_maize_met_2026-05-23.csv"
  ),
  stringsAsFactors = FALSE
)

mapping_ok <- function(path) {
  if (!nzchar(path) || !file.exists(path)) return(FALSE)
  x <- read.csv(path, stringsAsFactors = FALSE)
  req <- x[x$required == "yes", ]
  if (nrow(req) == 0) return(FALSE)
  all(trimws(ifelse(is.na(req$raw_column), "", req$raw_column)) != "")
}

rows <- lapply(seq_len(nrow(datasets)), function(i) {
  key <- datasets$dataset_key[i]
  mfile <- datasets$mapping_file[i]
  raw_dir <- file.path(base_ext, key, "raw")
  ph_ok <- file.exists(file.path(raw_dir, "phenotype.csv"))
  mk_ok <- file.exists(file.path(raw_dir, "markers.csv"))
  mp_ok <- mapping_ok(mfile)
  ready <- ph_ok && mk_ok && mp_ok

  msg <- if (!ph_ok || !mk_ok) {
    "missing raw phenotype/markers files"
  } else if (!mp_ok) {
    "mapping template incomplete or missing"
  } else {
    "ready for stage-83 ingestion"
  }

  data.frame(
    dataset_key = key,
    phenotype_present = ph_ok,
    markers_present = mk_ok,
    mapping_complete = mp_ok,
    ready_for_ingestion = ready,
    status_message = msg,
    stringsAsFactors = FALSE
  )
})

preflight <- do.call(rbind, rows)
write.csv(preflight, file.path(out_dir, "92_external_preflight_status.csv"), row.names = FALSE)

message("Saved stage-92 external preflight status.")
print(preflight)
