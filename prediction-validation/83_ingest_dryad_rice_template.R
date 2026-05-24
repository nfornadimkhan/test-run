## -----------------------------------------------------------------------------
## Stage 83B: Ingest template for Dryad southern US rice MET dataset
## Dataset: 10.5061/dryad.j9kd51ctd
##
## Purpose:
## - Convert raw dataset files into canonical schema for external validation.
## - Produce QC and LOEO fold map artifacts.
##
## NOTE:
## - This is a template; update raw file paths after local download.
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/10_prediction_paths_and_helpers.R")

ext_dir <- file.path(prediction_output_dir, "external_validation", "dryad_rice")
ensure_dir(ext_dir)

# TODO: update these paths after dataset download/extraction.
raw_pheno_path <- file.path(ext_dir, "raw", "phenotype.csv")
raw_marker_path <- file.path(ext_dir, "raw", "markers.csv")
raw_ec_path <- file.path(ext_dir, "raw", "env_covariates.csv")

stop_if_missing <- function(path) {
  if (!file.exists(path)) stop("Missing required raw file: ", path)
}

stop_if_missing(raw_pheno_path)
stop_if_missing(raw_marker_path)

ph <- read.csv(raw_pheno_path, stringsAsFactors = FALSE, check.names = FALSE)
mk <- read.csv(raw_marker_path, stringsAsFactors = FALSE, check.names = FALSE)
ec <- if (file.exists(raw_ec_path)) read.csv(raw_ec_path, stringsAsFactors = FALSE, check.names = FALSE) else NULL

map_path <- "/Users/neon/Documents/Nadim's Brain/analysis/models/90_column_mapping_template_dryad_rice_2026-05-23.csv"
if (!file.exists(map_path)) stop("Missing mapping file: ", map_path)
map <- read.csv(map_path, stringsAsFactors = FALSE)
map <- map[map$dataset_key == "dryad_rice" & map$raw_file == "phenotype.csv", , drop = FALSE]

map_col <- function(canon_name) {
  row <- map[map$canonical_column == canon_name, , drop = FALSE]
  if (nrow(row) == 0) return("")
  as.character(row$raw_column[1])
}

pull_col <- function(df, raw_name, required = FALSE) {
  if (!nzchar(raw_name)) return(rep(NA, nrow(df)))
  if (!raw_name %in% names(df)) {
    if (required) stop("Required mapped column missing in phenotype file: ", raw_name)
    return(rep(NA, nrow(df)))
  }
  df[[raw_name]]
}

geno_col <- map_col("geno_id")
env_col <- map_col("env_id")
trait_col <- map_col("trait_value")
year_col <- map_col("year")
loc_col <- map_col("location")

canon <- data.frame(
  geno_id = as.character(pull_col(ph, geno_col, required = TRUE)),
  env_id = as.character(pull_col(ph, env_col, required = TRUE)),
  year = pull_col(ph, year_col, required = FALSE),
  location = as.character(pull_col(ph, loc_col, required = FALSE)),
  trait_value = suppressWarnings(as.numeric(pull_col(ph, trait_col, required = TRUE))),
  stringsAsFactors = FALSE
)

if (!is.null(ec)) {
  ec_cols <- setdiff(names(ec), c("env_id", "year", "location"))
  names(ec)[names(ec) == "env_id"] <- "env_id"
  canon <- merge(canon, ec[, c("env_id", ec_cols), drop = FALSE], by = "env_id", all.x = TRUE)
}

# QC
canon <- canon[!is.na(canon$geno_id) & !is.na(canon$env_id) & !is.na(canon$trait_value), ]
dup_n <- sum(duplicated(canon[, c("geno_id", "env_id")]))
n_env <- length(unique(canon$env_id))
n_rows <- nrow(canon)

# LOEO fold map
fold_map <- data.frame(
  env_id = sort(unique(canon$env_id)),
  fold_id = paste0("LOEO_", seq_along(sort(unique(canon$env_id)))),
  stringsAsFactors = FALSE
)

# Marker manifest
marker_manifest <- data.frame(
  source_file = raw_marker_path,
  n_rows = nrow(mk),
  n_cols = ncol(mk),
  marker_id_col = names(mk)[1],
  stringsAsFactors = FALSE
)

# Ingestion QC report
qc <- data.frame(
  dataset = "dryad_rice_10_5061_dryad_j9kd51ctd",
  n_rows = n_rows,
  n_env = n_env,
  duplicate_geno_env_rows = dup_n,
  pct_missing_trait_preclean = mean(is.na(ph$trait_value)),
  viable = (n_env >= 4 && n_rows >= 1000 && dup_n == 0),
  stringsAsFactors = FALSE
)

write.csv(canon, file.path(ext_dir, "dryad_rice_canonical.csv"), row.names = FALSE)
write.csv(marker_manifest, file.path(ext_dir, "dryad_rice_marker_manifest.csv"), row.names = FALSE)
write.csv(fold_map, file.path(ext_dir, "dryad_rice_fold_map.csv"), row.names = FALSE)
write.csv(qc, file.path(ext_dir, "dryad_rice_ingestion_qc.csv"), row.names = FALSE)

message("Stage 83B template ingestion artifacts written to: ", ext_dir)
