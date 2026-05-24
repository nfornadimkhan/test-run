## -----------------------------------------------------------------------------
## Stage 83C: Ingest template for Dryad sparse wheat dataset
## Dataset: 10.5061/dryad.vx0k6dk3p
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/10_prediction_paths_and_helpers.R")

ext_dir <- file.path(prediction_output_dir, "external_validation", "dryad_wheat_sparse")
ensure_dir(ext_dir)

raw_pheno_path <- file.path(ext_dir, "raw", "phenotype.csv")
raw_marker_path <- file.path(ext_dir, "raw", "markers.csv")

if (!file.exists(raw_pheno_path)) stop("Missing required raw file: ", raw_pheno_path)
if (!file.exists(raw_marker_path)) stop("Missing required raw file: ", raw_marker_path)

ph <- read.csv(raw_pheno_path, stringsAsFactors = FALSE, check.names = FALSE)
mk <- read.csv(raw_marker_path, stringsAsFactors = FALSE, check.names = FALSE)

if (ncol(ph) < 2) stop("Phenotype matrix must have at least one env column.")

geno_col <- names(ph)[1]
env_cols <- names(ph)[-1]

canon <- reshape(
  ph,
  varying = env_cols,
  v.names = "trait_value",
  timevar = "env_id",
  times = env_cols,
  direction = "long"
)

canon <- canon[, c(1, which(names(canon) == "env_id"), which(names(canon) == "trait_value"))]
names(canon)[1] <- "geno_id"
canon$geno_id <- as.character(canon$geno_id)
canon$env_id <- as.character(canon$env_id)
canon$trait_value <- suppressWarnings(as.numeric(canon$trait_value))
canon$year <- NA
canon$location <- NA
canon <- canon[!is.na(canon$geno_id) & !is.na(canon$env_id) & !is.na(canon$trait_value), ]

# QC
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
  dataset = "dryad_wheat_sparse_10_5061_dryad_vx0k6dk3p",
  n_rows = n_rows,
  n_env = n_env,
  duplicate_geno_env_rows = dup_n,
  pct_missing_trait_preclean = mean(is.na(as.matrix(ph[, -1, drop = FALSE]))),
  viable = (n_env >= 4 && n_rows >= 1000 && dup_n == 0),
  stringsAsFactors = FALSE
)

write.csv(canon, file.path(ext_dir, "dryad_wheat_sparse_canonical.csv"), row.names = FALSE)
write.csv(marker_manifest, file.path(ext_dir, "dryad_wheat_sparse_marker_manifest.csv"), row.names = FALSE)
write.csv(fold_map, file.path(ext_dir, "dryad_wheat_sparse_fold_map.csv"), row.names = FALSE)
write.csv(qc, file.path(ext_dir, "dryad_wheat_sparse_ingestion_qc.csv"), row.names = FALSE)

message("Stage 83C template ingestion artifacts written to: ", ext_dir)
