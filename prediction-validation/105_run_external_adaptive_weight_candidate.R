## -----------------------------------------------------------------------------
## Stage 105: External adaptive-weight candidate (training-only selection)
##
## For each outer LOEO fold:
## - Build experts from outer-training rows only
## - Run inner LOEO on outer-training environments
## - Select weight triplet minimizing inner mean RMSE
## - Apply selected weights to outer-test environment
##
## This is a strict no-test-leakage adaptive mixture policy.
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/10_prediction_paths_and_helpers.R")

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) {
  stop("Usage: Rscript 105_run_external_adaptive_weight_candidate.R <dataset_key> <base_dir>")
}

dataset_key <- args[1]
base_dir <- args[2]

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
    map <- c(A = 1, C = 2, G = 3, T = 4)
    x_num <- matrix(NA_real_, nrow = nrow(x_chr), ncol = ncol(x_chr))
    for (j in seq_len(ncol(x_chr))) x_num[, j] <- as.numeric(unname(map[x_chr[, j]]))
    rownames(x_num) <- rownames(x_chr)
    return(x_num)
  }

  matrix(numeric(0), nrow = 0, ncol = 0)
}

build_marker_embedding <- function(marker_mat, max_markers = 500, n_pc = 20) {
  if (is.null(marker_mat) || nrow(marker_mat) == 0 || ncol(marker_mat) == 0) return(matrix(numeric(0), 0, 0))

  x <- marker_mat
  v <- apply(x, 2, function(z) {
    z <- z[is.finite(z)]
    if (length(z) < 2) return(0)
    var(z)
  })
  keep <- which(is.finite(v) & v > 0)
  if (length(keep) == 0) return(matrix(numeric(0), 0, 0))
  x <- x[, keep, drop = FALSE]

  if (ncol(x) > max_markers) {
    set.seed(4242)
    x <- x[, sample.int(ncol(x), max_markers), drop = FALSE]
  }

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

expert_preds_for_split <- function(train_df, test_df, marker_emb) {
  mu <- mean(train_df$trait_value, na.rm = TRUE)
  geno_mean <- tapply(train_df$trait_value, train_df$geno_id, mean, na.rm = TRUE)

  out <- test_df
  out$pred_global <- mu
  out$pred_geno <- ifelse(out$geno_id %in% names(geno_mean), geno_mean[out$geno_id], mu)
  out$pred_marker <- mu

  if (!is.null(marker_emb) && nrow(marker_emb) > 0) {
    train_genos <- intersect(names(geno_mean), rownames(marker_emb))
    test_genos <- intersect(unique(out$geno_id), rownames(marker_emb))
    if (length(train_genos) >= 20 && length(test_genos) > 0) {
      y_train <- as.numeric(geno_mean[train_genos])
      x_train <- marker_emb[train_genos, , drop = FALSE]
      x_test <- marker_emb[test_genos, , drop = FALSE]
      fit <- lm(y ~ ., data = data.frame(y = y_train, x_train, check.names = FALSE))
      pred_g <- as.numeric(predict(fit, newdata = data.frame(x_test, check.names = FALSE)))
      names(pred_g) <- test_genos
      pred_g[!is.finite(pred_g)] <- mu
      idx <- out$geno_id %in% names(pred_g)
      out$pred_marker[idx] <- pred_g[out$geno_id[idx]]
    }
  }

  out
}

select_weights_inner <- function(train_outer, marker_emb, weight_pool) {
  envs <- unique(train_outer$env_id)
  if (length(envs) < 2) {
    return(weight_pool[1, , drop = FALSE])
  }

  inner_rows <- lapply(seq_len(nrow(weight_pool)), function(i) {
    w <- as.numeric(weight_pool[i, ])
    rmses <- c()
    for (e in envs) {
      tr <- train_outer[train_outer$env_id != e, , drop = FALSE]
      te <- train_outer[train_outer$env_id == e, , drop = FALSE]
      if (nrow(tr) == 0 || nrow(te) == 0) next
      px <- expert_preds_for_split(tr, te, marker_emb)
      pred <- w[1] * px$pred_global + w[2] * px$pred_geno + w[3] * px$pred_marker
      rmses <- c(rmses, safe_rmse(px$trait_value, pred))
    }
    data.frame(
      w_global = w[1],
      w_geno = w[2],
      w_marker = w[3],
      inner_rmse = mean(rmses, na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  })

  tab <- do.call(rbind, inner_rows)
  tab <- tab[order(tab$inner_rmse), ]
  tab[1, c("w_global", "w_geno", "w_marker"), drop = FALSE]
}

# candidate pool: includes robust convex region + mild affine neighborhood
conv_vals <- seq(0, 1, by = 0.05)
conv_pool <- do.call(rbind, lapply(conv_vals, function(a) {
  do.call(rbind, lapply(conv_vals, function(b) {
    c <- 1 - a - b
    if (c < -1e-12) return(NULL)
    data.frame(w_global = a, w_geno = b, w_marker = max(0, c))
  }))
}))
conv_pool <- unique(conv_pool)

aff_vals <- seq(-0.15, 1.15, by = 0.05)
aff_pool <- do.call(rbind, lapply(aff_vals, function(a) {
  do.call(rbind, lapply(aff_vals, function(b) {
    c <- 1 - a - b
    if (c < -0.15 || c > 1.15) return(NULL)
    data.frame(w_global = a, w_geno = b, w_marker = c)
  }))
}))
aff_pool <- unique(aff_pool)

# keep only near-frontier affine points for stability
aff_pool <- aff_pool[abs(aff_pool$w_marker) <= 0.15, , drop = FALSE]
weight_pool <- unique(rbind(conv_pool, aff_pool))

# prep data
fold_map$env_id <- as.character(fold_map$env_id)
dat$env_id <- as.character(dat$env_id)
dat$geno_id <- as.character(dat$geno_id)
dat <- merge(dat, fold_map, by = "env_id", all.x = TRUE)
if (any(is.na(dat$fold_id))) stop("Some canonical rows missing fold_id after merge")

# For large-env datasets, reduce inner-search pool to keep runtime bounded.
if (length(unique(dat$env_id)) > 10) {
  cv2 <- seq(0, 1, by = 0.2)
  coarse <- do.call(rbind, lapply(cv2, function(a) {
    do.call(rbind, lapply(cv2, function(b) {
      c <- 1 - a - b
      if (c < -1e-12) return(NULL)
      data.frame(w_global = a, w_geno = b, w_marker = max(0, c))
    }))
  }))
  weight_pool <- unique(coarse)
}

marker_mat <- build_marker_matrix(dataset_key, markers_raw, dat$geno_id)
marker_emb <- build_marker_embedding(marker_mat, max_markers = ifelse(dataset_key %in% c("dryad_wheat_sparse", "dryad_maize_met"), 500, 250), n_pc = 20)

outer_folds <- unique(dat$fold_id)
pred_rows <- list()
sel_rows <- list()

for (f in outer_folds) {
  tr_outer <- dat[dat$fold_id != f, , drop = FALSE]
  te_outer <- dat[dat$fold_id == f, , drop = FALSE]

  wsel <- select_weights_inner(tr_outer, marker_emb, weight_pool)
  w <- as.numeric(wsel[1, ])

  px <- expert_preds_for_split(tr_outer, te_outer, marker_emb)
  px$pred_baseline <- px$pred_global
  px$pred_candidate <- w[1] * px$pred_global + w[2] * px$pred_geno + w[3] * px$pred_marker
  px$seen_in_train <- px$geno_id %in% unique(tr_outer$geno_id)
  px$selected_w_global <- w[1]
  px$selected_w_geno <- w[2]
  px$selected_w_marker <- w[3]

  pred_rows[[f]] <- px
  sel_rows[[f]] <- data.frame(fold_id = f, w_global = w[1], w_geno = w[2], w_marker = w[3], stringsAsFactors = FALSE)
}

pred <- do.call(rbind, pred_rows)
selected <- do.call(rbind, sel_rows)

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

  if (length(d) < 2 || isTRUE(all.equal(stats::sd(d), 0, tolerance = 1e-12))) {
    t_p <- ifelse(mean(d, na.rm = TRUE) > 0, 0, 1)
    w_p <- ifelse(mean(d, na.rm = TRUE) > 0, 0, 1)
    set.seed(ifelse(sc == "all", 10501, 10502))
    idx <- matrix(sample.int(length(d), length(d) * B, replace = TRUE), nrow = B)
    bmeans <- rowMeans(matrix(d[idx], nrow = B))
    return(data.frame(
      scope = sc,
      mean_gain = mean(d),
      median_gain = median(d),
      t_one_sided_p = t_p,
      wilcoxon_one_sided_p = w_p,
      boot_prob_gain_positive = mean(bmeans > 0),
      boot_q025 = as.numeric(quantile(bmeans, 0.025, na.rm = TRUE)),
      boot_q975 = as.numeric(quantile(bmeans, 0.975, na.rm = TRUE)),
      stringsAsFactors = FALSE
    ))
  }

  t_res <- t.test(d, mu = 0, alternative = "greater")
  w_res <- suppressWarnings(wilcox.test(d, mu = 0, alternative = "greater", exact = FALSE))
  set.seed(ifelse(sc == "all", 10501, 10502))
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
  gain_floor_pass = all(scope_summary$mean_gain >= 0, na.rm = TRUE),
  t_pass = all(scope_summary$t_one_sided_p <= 0.05, na.rm = TRUE),
  boot_pass = all(scope_summary$boot_prob_gain_positive >= 0.95, na.rm = TRUE),
  stringsAsFactors = FALSE
)
gate$pass_confirmatory <- gate$gain_floor_pass & gate$t_pass & gate$boot_pass

manifest <- data.frame(
  dataset_key = dataset_key,
  n_rows = nrow(dat),
  n_env = length(unique(dat$env_id)),
  n_folds = length(unique(dat$fold_id)),
  policy = "inner_loeo_adaptive_weight_selection",
  mean_selected_w_global = mean(selected$w_global),
  mean_selected_w_geno = mean(selected$w_geno),
  mean_selected_w_marker = mean(selected$w_marker),
  stringsAsFactors = FALSE
)

out_dir <- file.path(ext_dir, "confirmatory_candidate_outputs")
ensure_dir(out_dir)

write.csv(pred, file.path(out_dir, paste0(dataset_key, "_candidate_predictions.csv")), row.names = FALSE)
write.csv(metrics, file.path(out_dir, paste0(dataset_key, "_candidate_fold_metrics.csv")), row.names = FALSE)
write.csv(scope_summary, file.path(out_dir, paste0(dataset_key, "_candidate_scope_summary.csv")), row.names = FALSE)
write.csv(gate, file.path(out_dir, paste0(dataset_key, "_candidate_gate_result.csv")), row.names = FALSE)
write.csv(manifest, file.path(out_dir, paste0(dataset_key, "_candidate_run_manifest.csv")), row.names = FALSE)
write.csv(selected, file.path(out_dir, paste0(dataset_key, "_candidate_selected_weights_by_fold.csv")), row.names = FALSE)

message("Stage-105 adaptive candidate run complete for dataset: ", dataset_key)
print(manifest)
print(scope_summary)
print(gate)
