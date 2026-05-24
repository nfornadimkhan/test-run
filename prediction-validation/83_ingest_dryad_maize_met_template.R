## -----------------------------------------------------------------------------
## Stage 83D: Ingest template for Dryad maize MET dataset
## Dataset: 10.5061/dryad.9w0vt4bc2
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/10_prediction_paths_and_helpers.R")

ext_dir <- file.path(prediction_output_dir, "external_validation", "dryad_maize_met")
ensure_dir(ext_dir)

raw_pheno_path <- file.path(ext_dir, "raw", "phenotype.csv")
raw_marker_path <- file.path(ext_dir, "raw", "markers.csv")

if (!file.exists(raw_pheno_path)) stop("Missing required raw file: ", raw_pheno_path)
if (!file.exists(raw_marker_path)) stop("Missing required raw file: ", raw_marker_path)

ph <- read.csv(raw_pheno_path, stringsAsFactors = FALSE, check.names = FALSE)
mk <- read.csv(raw_marker_path, stringsAsFactors = FALSE, check.names = FALSE)

required_cols <- c("H", "Env", "GY_BLUE")
miss <- setdiff(required_cols, names(ph))
if (length(miss) > 0) stop("Missing phenotype columns: ", paste(miss, collapse = ", "))

canon <- data.frame(
  geno_id = as.character(ph$H),
  env_id = as.character(ph$Env),
  year = suppressWarnings(as.integer(sub("^([0-9]{4}).*", "\\1", as.character(ph$Env)))),
  location = as.character(ph$Env),
  trait_value = suppressWarnings(as.numeric(ph$GY_BLUE)),
  stringsAsFactors = FALSE
)

canon <- canon[!is.na(canon$geno_id) & !is.na(canon$env_id) & !is.na(canon$trait_value), ]

n_env <- length(unique(canon$env_id))
n_rows <- nrow(canon)
dup_n <- sum(duplicated(canon[, c("geno_id", "env_id")]))

fold_map <- data.frame(
  env_id = sort(unique(canon$env_id)),
  fold_id = paste0("LOEO_", seq_along(sort(unique(canon$env_id)))),
  stringsAsFactors = FALSE
)

marker_manifest <- data.frame(
  source_file = raw_marker_path,
  n_rows = nrow(mk),
  n_cols = ncol(mk),
  marker_id_col = names(mk)[1],
  stringsAsFactors = FALSE
)

qc <- data.frame(
  dataset = "dryad_maize_met_10_5061_dryad_9w0vt4bc2",
  n_rows = n_rows,
  n_env = n_env,
  duplicate_geno_env_rows = dup_n,
  pct_missing_trait_preclean = mean(is.na(suppressWarnings(as.numeric(ph$GY_BLUE)))),
  viable = (n_env >= 4 && n_rows >= 1000 && dup_n == 0),
  stringsAsFactors = FALSE
)

write.csv(canon, file.path(ext_dir, "dryad_maize_met_canonical.csv"), row.names = FALSE)
write.csv(marker_manifest, file.path(ext_dir, "dryad_maize_met_marker_manifest.csv"), row.names = FALSE)
write.csv(fold_map, file.path(ext_dir, "dryad_maize_met_fold_map.csv"), row.names = FALSE)
write.csv(qc, file.path(ext_dir, "dryad_maize_met_ingestion_qc.csv"), row.names = FALSE)

message("Stage 83D ingestion artifacts written to: ", ext_dir)
