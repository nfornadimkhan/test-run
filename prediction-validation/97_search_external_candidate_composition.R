## -----------------------------------------------------------------------------
## Stage 97: Search external candidate composition/weights across datasets
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/10_prediction_paths_and_helpers.R")

base_dir <- "/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation"
out_dir <- file.path(base_dir, "run_queue", "97_external_candidate_search")
ensure_dir(out_dir)

datasets <- c("dryad_rice", "dryad_wheat_sparse", "dryad_maize_met")

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

build_marker_embedding <- function(marker_mat, max_markers, n_pc = 20) {
  if (is.null(marker_mat) || nrow(marker_mat) == 0 || ncol(marker_mat) == 0) return(matrix(numeric(0), 0, 0))
  x <- marker_mat
  v <- apply(x, 2, function(z) { z <- z[is.finite(z)]; if (length(z) < 2) return(0); var(z) })
  keep <- which(is.finite(v) & v > 0)
  if (length(keep) == 0) return(matrix(numeric(0), 0, 0))
  x <- x[, keep, drop = FALSE]
  if (ncol(x) > max_markers) {
    set.seed(9700)
    x <- x[, sample.int(ncol(x), max_markers), drop = FALSE]
  }
  for (j in seq_len(ncol(x))) {
    med <- median(x[, j], na.rm = TRUE)
    if (!is.finite(med)) med <- 0
    x[!is.finite(x[, j]), j] <- med
  }
  x <- scale(x); x[!is.finite(x)] <- 0
  npc <- min(n_pc, ncol(x), max(1, nrow(x) - 1))
  pc <- prcomp(x, center = FALSE, scale. = FALSE, rank. = npc)
  emb <- pc$x[, seq_len(npc), drop = FALSE]
  rownames(emb) <- rownames(marker_mat)
  emb
}

get_expert_predictions <- function(dataset_key) {
  ext_dir <- file.path(base_dir, dataset_key)
  dat <- read.csv(file.path(ext_dir, paste0(dataset_key, "_canonical.csv")), stringsAsFactors = FALSE)
  fold_map <- read.csv(file.path(ext_dir, paste0(dataset_key, "_fold_map.csv")), stringsAsFactors = FALSE)
  markers_raw <- read.csv(file.path(ext_dir, "raw", "markers.csv"), stringsAsFactors = FALSE, check.names = FALSE)

  fold_map$env_id <- as.character(fold_map$env_id)
  dat$env_id <- as.character(dat$env_id)
  dat$geno_id <- as.character(dat$geno_id)
  dat <- merge(dat, fold_map, by = "env_id", all.x = TRUE)

  marker_mat <- build_marker_matrix(dataset_key, markers_raw, dat$geno_id)
  marker_emb <- build_marker_embedding(marker_mat, max_markers = ifelse(dataset_key %in% c("dryad_wheat_sparse", "dryad_maize_met"), 500, 250), n_pc = 20)

  folds <- unique(dat$fold_id)
  pred <- do.call(rbind, lapply(folds, function(fold_id) {
    tr <- dat[dat$fold_id != fold_id, , drop = FALSE]
    te <- dat[dat$fold_id == fold_id, , drop = FALSE]

    mu <- mean(tr$trait_value, na.rm = TRUE)
    geno_mean <- tapply(tr$trait_value, tr$geno_id, mean, na.rm = TRUE)

    te$pred_global <- mu
    te$pred_geno <- ifelse(te$geno_id %in% names(geno_mean), geno_mean[te$geno_id], mu)
    te$pred_marker <- mu

    if (nrow(marker_emb) > 0) {
      train_genos <- intersect(names(geno_mean), rownames(marker_emb))
      test_genos <- intersect(unique(te$geno_id), rownames(marker_emb))
      if (length(train_genos) >= 20 && length(test_genos) > 0) {
        y_train <- as.numeric(geno_mean[train_genos])
        x_train <- marker_emb[train_genos, , drop = FALSE]
        x_test <- marker_emb[test_genos, , drop = FALSE]
        fit <- lm(y_train ~ ., data = data.frame(y_train = y_train, x_train, check.names = FALSE))
        pred_g <- as.numeric(predict(fit, newdata = data.frame(x_test, check.names = FALSE)))
        names(pred_g) <- test_genos
        pred_g[!is.finite(pred_g)] <- mu
        idx <- te$geno_id %in% names(pred_g)
        te$pred_marker[idx] <- pred_g[te$geno_id[idx]]
      }
    }

    te$seen_in_train <- te$geno_id %in% unique(tr$geno_id)
    te
  }))

  pred
}

summ_scope <- function(metrics_df, scope_name) {
  z <- metrics_df[metrics_df$scope == scope_name, , drop = FALSE]
  d <- z$gain
  t_p <- if (length(d) >= 2) t.test(d, mu = 0, alternative = "greater")$p.value else NA_real_
  w_p <- if (length(d) >= 1) suppressWarnings(wilcox.test(d, mu = 0, alternative = "greater", exact = FALSE)$p.value) else NA_real_
  data.frame(scope = scope_name, mean_gain = mean(d), t_p = t_p, w_p = w_p, stringsAsFactors = FALSE)
}

# simplex grid for 3 experts
vals <- seq(0, 1, by = 0.05)
weights <- do.call(rbind, lapply(vals, function(w1) {
  do.call(rbind, lapply(vals, function(w2) {
    w3 <- 1 - w1 - w2
    if (w3 < -1e-9) return(NULL)
    data.frame(w_global = w1, w_geno = w2, w_marker = max(0, w3))
  }))
}))
weights <- unique(weights)

all_preds <- lapply(datasets, get_expert_predictions)
names(all_preds) <- datasets

rows <- list()
for (i in seq_len(nrow(weights))) {
  w <- weights[i, ]
  dataset_rows <- list()

  for (dk in datasets) {
    p <- all_preds[[dk]]
    p$pred <- w$w_global * p$pred_global + w$w_geno * p$pred_geno + w$w_marker * p$pred_marker

    met <- do.call(rbind, lapply(split(p, p$fold_id), function(x) {
      seen <- x[x$seen_in_train, , drop = FALSE]
      rbind(
        data.frame(fold_id = x$fold_id[1], scope = "all", gain = safe_rmse(x$trait_value, x$pred_global) - safe_rmse(x$trait_value, x$pred), stringsAsFactors = FALSE),
        data.frame(fold_id = x$fold_id[1], scope = "seen_genotypes", gain = safe_rmse(seen$trait_value, seen$pred_global) - safe_rmse(seen$trait_value, seen$pred), stringsAsFactors = FALSE)
      )
    }))

    s_all <- summ_scope(met, "all")
    s_seen <- summ_scope(met, "seen_genotypes")

    dataset_rows[[dk]] <- data.frame(
      dataset_key = dk,
      w_global = w$w_global,
      w_geno = w$w_geno,
      w_marker = w$w_marker,
      gain_all = s_all$mean_gain,
      gain_seen = s_seen$mean_gain,
      t_all = s_all$t_p,
      t_seen = s_seen$t_p,
      w_all = s_all$w_p,
      w_seen = s_seen$w_p,
      pass_t = is.finite(s_all$t_p) && is.finite(s_seen$t_p) && s_all$t_p <= 0.05 && s_seen$t_p <= 0.05,
      pass_gain = is.finite(s_all$mean_gain) && is.finite(s_seen$mean_gain) && s_all$mean_gain >= 0 && s_seen$mean_gain >= 0,
      stringsAsFactors = FALSE
    )
  }

  dtab <- do.call(rbind, dataset_rows)
  agg <- data.frame(
    w_global = w$w_global,
    w_geno = w$w_geno,
    w_marker = w$w_marker,
    min_gain_all = min(dtab$gain_all, na.rm = TRUE),
    min_gain_seen = min(dtab$gain_seen, na.rm = TRUE),
    max_t_all = max(dtab$t_all, na.rm = TRUE),
    max_t_seen = max(dtab$t_seen, na.rm = TRUE),
    mean_gain_all = mean(dtab$gain_all, na.rm = TRUE),
    mean_gain_seen = mean(dtab$gain_seen, na.rm = TRUE),
    pass_gain_both_datasets = all(dtab$pass_gain),
    pass_t_both_datasets = all(dtab$pass_t),
    stringsAsFactors = FALSE
  )
  agg$score <- agg$mean_gain_all + agg$mean_gain_seen - 0.3 * (agg$max_t_all + agg$max_t_seen)

  rows[[i]] <- cbind(agg, n_datasets = nrow(dtab))
}

agg_tab <- do.call(rbind, rows)
agg_tab <- agg_tab[order(-agg_tab$pass_gain_both_datasets, -agg_tab$pass_t_both_datasets, -agg_tab$score), ]

write.csv(agg_tab, file.path(out_dir, "97_weight_search_aggregate.csv"), row.names = FALSE)
write.csv(head(agg_tab, 100), file.path(out_dir, "97_weight_search_top100.csv"), row.names = FALSE)

best <- agg_tab[1, ]
write.csv(best, file.path(out_dir, "97_selected_weights.csv"), row.names = FALSE)

cat("Saved stage-97 search results\n")
print(head(agg_tab, 20))
