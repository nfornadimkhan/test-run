## -----------------------------------------------------------------------------
## Stage 83A: Ingest template for CIMMYT wheat dataset
## Dataset: hdl:11529/10714
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/10_prediction_paths_and_helpers.R")

ext_dir <- file.path(prediction_output_dir, "external_validation", "cimmyt_wheat")
ensure_dir(ext_dir)

raw_pheno_path <- file.path(ext_dir, "raw", "phenotype.csv")
raw_marker_path <- file.path(ext_dir, "raw", "markers.csv")

if (!file.exists(raw_pheno_path)) stop("Missing required raw file: ", raw_pheno_path)
if (!file.exists(raw_marker_path)) stop("Missing required raw file: ", raw_marker_path)

ph <- read.csv(raw_pheno_path, stringsAsFactors = FALSE, check.names = FALSE)
mk <- read.csv(raw_marker_path, stringsAsFactors = FALSE, check.names = FALSE)

required_cols <- c("GNO", "Env", "YLD")
miss <- setdiff(required_cols, names(ph))
if (length(miss) > 0) stop("Missing phenotype columns: ", paste(miss, collapse = ", "))

ph$GNO <- as.character(ph$GNO)
ph$Env <- as.character(ph$Env)
ph$YLD <- suppressWarnings(as.numeric(ph$YLD))
ph <- ph[!is.na(ph$GNO) & !is.na(ph$Env) & !is.na(ph$YLD), , drop = FALSE]

# Aggregate replicate rows to canonical geno x env records
agg <- aggregate(YLD ~ GNO + Env, data = ph, FUN = mean, na.rm = TRUE)

canon <- data.frame(
  geno_id = as.character(agg$GNO),
  env_id = as.character(agg$Env),
  year = NA,
  location = as.character(agg$Env),
  trait_value = as.numeric(agg$YLD),
  stringsAsFactors = FALSE
)

canon <- canon[!is.na(canon$trait_value), , drop = FALSE]

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
  dataset = "cimmyt_wheat_hdl_11529_10714",
  n_rows = n_rows,
  n_env = n_env,
  duplicate_geno_env_rows = dup_n,
  pct_missing_trait_preclean = mean(is.na(suppressWarnings(as.numeric(ph$YLD)))),
  viable = (n_env >= 4 && n_rows >= 1000 && dup_n == 0),
  stringsAsFactors = FALSE
)

write.csv(canon, file.path(ext_dir, "cimmyt_wheat_canonical.csv"), row.names = FALSE)
write.csv(marker_manifest, file.path(ext_dir, "cimmyt_wheat_marker_manifest.csv"), row.names = FALSE)
write.csv(fold_map, file.path(ext_dir, "cimmyt_wheat_fold_map.csv"), row.names = FALSE)
write.csv(qc, file.path(ext_dir, "cimmyt_wheat_ingestion_qc.csv"), row.names = FALSE)

message("Stage 83A ingestion artifacts written to: ", ext_dir)
