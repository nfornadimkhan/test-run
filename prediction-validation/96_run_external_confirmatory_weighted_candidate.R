## -----------------------------------------------------------------------------
## Stage 96: External confirmatory run with plugged weighted-consensus candidate
##
## Candidate (fixed, no test leakage):
## - Expert A: global-mean predictor
## - Expert B: genotype-mean predictor (from training rows only)
## - Expert C: marker-PC regression predictor (from training rows only)
##
## Final candidate prediction:
##   pred_candidate = 0.20*global + 0.50*geno + 0.30*marker_pc
## Baseline:
##   pred_baseline = global
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/10_prediction_paths_and_helpers.R")

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) {
  stop("Usage: Rscript 96_run_external_confirmatory_weighted_candidate.R <dataset_key> <base_dir> [w_global w_geno w_marker]")
}

dataset_key <- args[1]
base_dir <- args[2]
w <- c(0.20, 0.50, 0.30)
if (length(args) >= 5) {
  w <- as.numeric(args[3:5])
  if (any(!is.finite(w)) || abs(sum(w) - 1) > 1e-8) {
    stop("Invalid weights. Require finite numbers summing to 1.")
  }
}
marker_seed <- suppressWarnings(as.integer(Sys.getenv("MARKER_SUBSAMPLE_SEED", unset = "9600")))
if (!is.finite(marker_seed)) marker_seed <- 9600
boot_seed_all <- suppressWarnings(as.integer(Sys.getenv("BOOTSTRAP_SEED_ALL", unset = "9601")))
if (!is.finite(boot_seed_all)) boot_seed_all <- 9601
boot_seed_seen <- suppressWarnings(as.integer(Sys.getenv("BOOTSTRAP_SEED_SEEN", unset = "9602")))
if (!is.finite(boot_seed_seen)) boot_seed_seen <- 9602

ext_dir <- file.path(base_dir, dataset_key)
canon_path <- file.path(ext_dir, paste0(dataset_key, "_canonical.csv"))
fold_path <- file.path(ext_dir, paste0(dataset_key, "_fold_map.csv"))
marker_path <- file.path(ext_dir, "raw", "markers.csv")

stopifnot(file.exists(canon_path), file.exists(fold_path), file.exists(marker_path))

dat <- read.csv(canon_path, stringsAsFactors = FALSE)
fold_map <- read.csv(fold_path, stringsAsFactors = FALSE)
markers_raw <- read.csv(marker_path, stringsAsFactors = FALSE, check.names = FALSE)

required_cols <- c("geno_id", "env_id", "trait_value")
miss <- setdiff(required_cols, names(dat))
if (length(miss) > 0) stop("Missing required canonical columns: ", paste(miss, collapse = ", "))

safe_rmse <- function(obs, pred) {
  ok <- complete.cases(obs, pred)
  if (sum(ok) == 0) return(NA_real_)
  sqrt(mean((obs[ok] - pred[ok])^2))
}

major_code <- function(x) {
  x <- x[!is.na(x) & x != "" & x != "N"]
  if (length(x) == 0) return(NA_character_)
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}

build_marker_matrix <- function(dataset_key, markers_raw, geno_ids) {
  geno_ids <- unique(as.character(geno_ids))

  if (dataset_key == "dryad_wheat_sparse" || dataset_key == "dryad_maize_met") {
    row_ids <- as.character(markers_raw[[1]])
    x <- as.matrix(markers_raw[, -1, drop = FALSE])
    suppressWarnings(storage.mode(x) <- "numeric")
    keep <- row_ids %in% geno_ids
    x <- x[keep, , drop = FALSE]
    rownames(x) <- row_ids[keep]
    return(x)
  }

  if (dataset_key == "dryad_rice" || dataset_key == "cimmyt_wheat") {
    geno_cols <- intersect(names(markers_raw), geno_ids)
    if (length(geno_cols) == 0) return(matrix(numeric(0), nrow = 0, ncol = 0))

    m <- as.matrix(markers_raw[, geno_cols, drop = FALSE])
    x_chr <- t(m)

    # Encode A/C/G/T as 1..4, others as NA
    map <- c(A = 1, C = 2, G = 3, T = 4)
    x_num <- matrix(NA_real_, nrow = nrow(x_chr), ncol = ncol(x_chr))
    for (j in seq_len(ncol(x_chr))) {
      colj <- x_chr[, j]
      v <- unname(map[colj])
      x_num[, j] <- as.numeric(v)
    }
    rownames(x_num) <- rownames(x_chr)
    return(x_num)
  }

  matrix(numeric(0), nrow = 0, ncol = 0)
}

build_marker_embedding <- function(marker_mat, max_markers = 500, n_pc = 20) {
  if (is.null(marker_mat) || nrow(marker_mat) == 0 || ncol(marker_mat) == 0) {
    return(matrix(numeric(0), nrow = 0, ncol = 0))
  }

  x <- marker_mat

  # Keep variable columns only
  v <- apply(x, 2, function(z) {
    z <- z[is.finite(z)]
    if (length(z) < 2) return(0)
    var(z)
  })
  keep <- which(is.finite(v) & v > 0)
  if (length(keep) == 0) return(matrix(numeric(0), nrow = 0, ncol = 0))
  x <- x[, keep, drop = FALSE]

  # Limit dimensionality for speed
  if (ncol(x) > max_markers) {
    set.seed(marker_seed)
    idx <- sample.int(ncol(x), max_markers)
    x <- x[, idx, drop = FALSE]
  }

  # Median impute per marker
  for (j in seq_len(ncol(x))) {
    med <- median(x[, j], na.rm = TRUE)
    if (!is.finite(med)) med <- 0
    x[!is.finite(x[, j]), j] <- med
  }

  x <- scale(x)
  x[!is.finite(x)] <- 0

  npc <- min(n_pc, ncol(x), max(1, nrow(x) - 1))
  pc <- prcomp(x, center = FALSE, scale. = FALSE, rank. = npc)
  emb <- pc$x[, seq_len(npc), drop = FALSE]
  rownames(emb) <- rownames(marker_mat)
  emb
}

fold_map$env_id <- as.character(fold_map$env_id)
dat$env_id <- as.character(dat$env_id)
dat$geno_id <- as.character(dat$geno_id)
dat <- merge(dat, fold_map, by = "env_id", all.x = TRUE)
if (any(is.na(dat$fold_id))) stop("Some canonical rows missing fold_id after merge")

marker_mat <- build_marker_matrix(dataset_key, markers_raw, dat$geno_id)
marker_emb <- build_marker_embedding(marker_mat, max_markers = ifelse(dataset_key %in% c("dryad_wheat_sparse", "dryad_maize_met"), 500, 250), n_pc = 20)

predict_fold <- function(df, fold_id, marker_emb, w) {
  tr <- df[df$fold_id != fold_id, , drop = FALSE]
  te <- df[df$fold_id == fold_id, , drop = FALSE]

  mu <- mean(tr$trait_value, na.rm = TRUE)
  geno_mean <- tapply(tr$trait_value, tr$geno_id, mean, na.rm = TRUE)

  te$pred_global <- mu
  te$pred_geno <- ifelse(te$geno_id %in% names(geno_mean), geno_mean[te$geno_id], mu)
  te$pred_marker <- mu

  if (!is.null(marker_emb) && nrow(marker_emb) > 0) {
    train_genos <- intersect(names(geno_mean), rownames(marker_emb))
    test_genos <- intersect(unique(te$geno_id), rownames(marker_emb))

    if (length(train_genos) >= 20 && length(test_genos) > 0) {
      y_train <- as.numeric(geno_mean[train_genos])
      x_train <- marker_emb[train_genos, , drop = FALSE]
      x_test <- marker_emb[test_genos, , drop = FALSE]

      df_train <- data.frame(y = y_train, x_train, check.names = FALSE)
      fit <- lm(y ~ ., data = df_train)

      df_test <- data.frame(x_test, check.names = FALSE)
      pred_g <- as.numeric(predict(fit, newdata = df_test))
      names(pred_g) <- test_genos
      pred_g[!is.finite(pred_g)] <- mu

      idx <- te$geno_id %in% names(pred_g)
      te$pred_marker[idx] <- pred_g[te$geno_id[idx]]
    }
  }

  te$pred_baseline <- te$pred_global
  te$pred_candidate <- w[1] * te$pred_global + w[2] * te$pred_geno + w[3] * te$pred_marker

  seen_train_genos <- unique(tr$geno_id)
  te$seen_in_train <- te$geno_id %in% seen_train_genos
  te
}

folds <- unique(dat$fold_id)
pred <- do.call(rbind, lapply(folds, function(f) predict_fold(dat, f, marker_emb, w = w)))

metrics <- do.call(rbind, lapply(split(pred, pred$fold_id), function(x) {
  seen <- x[x$seen_in_train, , drop = FALSE]
  rbind(
    data.frame(
      fold_id = x$fold_id[1], scope = "all",
      rmse_baseline = safe_rmse(x$trait_value, x$pred_baseline),
      rmse_candidate = safe_rmse(x$trait_value, x$pred_candidate),
      gain = safe_rmse(x$trait_value, x$pred_baseline) - safe_rmse(x$trait_value, x$pred_candidate),
      stringsAsFactors = FALSE
    ),
    data.frame(
      fold_id = x$fold_id[1], scope = "seen_genotypes",
      rmse_baseline = safe_rmse(seen$trait_value, seen$pred_baseline),
      rmse_candidate = safe_rmse(seen$trait_value, seen$pred_candidate),
      gain = safe_rmse(seen$trait_value, seen$pred_baseline) - safe_rmse(seen$trait_value, seen$pred_candidate),
      stringsAsFactors = FALSE
    )
  )
}))

summarize_scope <- function(sc, B = 20000) {
  z <- metrics[metrics$scope == sc, , drop = FALSE]
  d <- z$gain
  d <- d[is.finite(d)]

  if (length(d) < 2) {
    return(data.frame(
      scope = sc, mean_gain = mean(d), median_gain = median(d),
      t_one_sided_p = NA_real_, wilcoxon_one_sided_p = NA_real_,
      boot_prob_gain_positive = NA_real_, boot_q025 = NA_real_, boot_q975 = NA_real_,
      stringsAsFactors = FALSE
    ))
  }

  t_res <- t.test(d, mu = 0, alternative = "greater")
  w_res <- suppressWarnings(wilcox.test(d, mu = 0, alternative = "greater", exact = FALSE))

  set.seed(ifelse(sc == "all", boot_seed_all, boot_seed_seen))
  idx <- matrix(sample.int(length(d), length(d) * B, replace = TRUE), nrow = B)
  bmeans <- rowMeans(matrix(d[idx], nrow = B))

  data.frame(
    scope = sc,
    mean_gain = mean(d),
    median_gain = median(d),
    t_one_sided_p = t_res$p.value,
    wilcoxon_one_sided_p = w_res$p.value,
    boot_prob_gain_positive = mean(bmeans > 0),
    boot_q025 = as.numeric(quantile(bmeans, 0.025, na.rm = TRUE)),
    boot_q975 = as.numeric(quantile(bmeans, 0.975, na.rm = TRUE)),
    stringsAsFactors = FALSE
  )
}

scope_summary <- rbind(summarize_scope("all"), summarize_scope("seen_genotypes"))

gate <- data.frame(
  gain_floor_pass = all(scope_summary$mean_gain >= 0.0, na.rm = TRUE),
  t_pass = all(scope_summary$t_one_sided_p <= 0.05, na.rm = TRUE),
  boot_pass = all(scope_summary$boot_prob_gain_positive >= 0.95, na.rm = TRUE),
  stringsAsFactors = FALSE
)
gate$pass_confirmatory <- gate$gain_floor_pass & gate$t_pass & gate$boot_pass

overall <- data.frame(
  dataset_key = dataset_key,
  n_rows = nrow(dat),
  n_env = length(unique(dat$env_id)),
  n_folds = length(unique(dat$fold_id)),
  weights = paste0("global=", w[1], ",geno=", w[2], ",marker=", w[3]),
  w_global = w[1],
  w_geno = w[2],
  w_marker = w[3],
  marker_embedding_rows = nrow(marker_emb),
  marker_embedding_cols = ncol(marker_emb),
  stringsAsFactors = FALSE
)

out_dir <- file.path(ext_dir, "confirmatory_candidate_outputs")
ensure_dir(out_dir)

write.csv(pred, file.path(out_dir, paste0(dataset_key, "_candidate_predictions.csv")), row.names = FALSE)
write.csv(metrics, file.path(out_dir, paste0(dataset_key, "_candidate_fold_metrics.csv")), row.names = FALSE)
write.csv(scope_summary, file.path(out_dir, paste0(dataset_key, "_candidate_scope_summary.csv")), row.names = FALSE)
write.csv(gate, file.path(out_dir, paste0(dataset_key, "_candidate_gate_result.csv")), row.names = FALSE)
write.csv(overall, file.path(out_dir, paste0(dataset_key, "_candidate_run_manifest.csv")), row.names = FALSE)

message("Stage-96 candidate confirmatory run complete for dataset: ", dataset_key)
print(overall)
print(scope_summary)
print(gate)
