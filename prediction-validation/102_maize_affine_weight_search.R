## -----------------------------------------------------------------------------
## Stage 102: Maize affine-weight search to recover strict confirmatory pass
## -----------------------------------------------------------------------------

source('/Users/neon/Documents/Nadim\'s Brain/analysis/prediction-validation/10_prediction_paths_and_helpers.R')

base_dir <- '/Users/neon/Documents/Nadim\'s Brain/analysis/outputs/prediction_yield/external_validation'
dataset_key <- 'dryad_maize_met'
out_dir <- file.path(base_dir, 'run_queue', '102_maize_affine_search')
ensure_dir(out_dir)

safe_rmse <- function(obs, pred) {
  ok <- complete.cases(obs, pred)
  if (sum(ok) == 0) return(NA_real_)
  sqrt(mean((obs[ok] - pred[ok])^2))
}

ext_dir <- file.path(base_dir, dataset_key)
dat <- read.csv(file.path(ext_dir, paste0(dataset_key, '_canonical.csv')), stringsAsFactors = FALSE)
fold_map <- read.csv(file.path(ext_dir, paste0(dataset_key, '_fold_map.csv')), stringsAsFactors = FALSE)
mk <- read.csv(file.path(ext_dir, 'raw', 'markers.csv'), stringsAsFactors = FALSE, check.names = FALSE)

dat$env_id <- as.character(dat$env_id)
dat$geno_id <- as.character(dat$geno_id)
fold_map$env_id <- as.character(fold_map$env_id)
dat <- merge(dat, fold_map, by = 'env_id', all.x = TRUE)

# marker embedding
row_ids <- as.character(mk[[1]])
X <- as.matrix(mk[, -1, drop = FALSE])
suppressWarnings(storage.mode(X) <- 'numeric')
keep <- row_ids %in% unique(dat$geno_id)
X <- X[keep, , drop = FALSE]
rownames(X) <- row_ids[keep]

v <- apply(X, 2, function(z) {
  z <- z[is.finite(z)]
  if (length(z) < 2) return(0)
  var(z)
})
X <- X[, which(is.finite(v) & v > 0), drop = FALSE]
if (ncol(X) > 500) {
  set.seed(4242)
  X <- X[, sample.int(ncol(X), 500), drop = FALSE]
}
for (j in seq_len(ncol(X))) {
  med <- median(X[, j], na.rm = TRUE)
  if (!is.finite(med)) med <- 0
  X[!is.finite(X[, j]), j] <- med
}
X <- scale(X)
X[!is.finite(X)] <- 0
pc <- prcomp(X, center = FALSE, scale. = FALSE, rank. = min(20, ncol(X), max(1, nrow(X) - 1)))
emb <- pc$x[, seq_len(min(20, ncol(pc$x))), drop = FALSE]
rownames(emb) <- rownames(X)

# precompute fold expert predictions
folds <- unique(dat$fold_id)
pred <- do.call(rbind, lapply(folds, function(f) {
  tr <- dat[dat$fold_id != f, , drop = FALSE]
  te <- dat[dat$fold_id == f, , drop = FALSE]

  mu <- mean(tr$trait_value, na.rm = TRUE)
  gm <- tapply(tr$trait_value, tr$geno_id, mean, na.rm = TRUE)

  te$pred_global <- mu
  te$pred_geno <- ifelse(te$geno_id %in% names(gm), gm[te$geno_id], mu)
  te$pred_marker <- mu

  tg <- intersect(names(gm), rownames(emb))
  qg <- intersect(unique(te$geno_id), rownames(emb))
  if (length(tg) >= 20 && length(qg) > 0) {
    fit <- lm(y ~ ., data = data.frame(y = as.numeric(gm[tg]), emb[tg, , drop = FALSE], check.names = FALSE))
    pr <- as.numeric(predict(fit, newdata = data.frame(emb[qg, , drop = FALSE], check.names = FALSE)))
    names(pr) <- qg
    pr[!is.finite(pr)] <- mu
    idx <- te$geno_id %in% names(pr)
    te$pred_marker[idx] <- pr[te$geno_id[idx]]
  }

  te
}))

score_weights <- function(wg, wge, wm) {
  p <- pred
  p$pred <- wg * p$pred_global + wge * p$pred_geno + wm * p$pred_marker
  gains <- sapply(split(p, p$fold_id), function(x) {
    safe_rmse(x$trait_value, x$pred_global) - safe_rmse(x$trait_value, x$pred)
  })
  gains <- as.numeric(gains)
  t_p <- t.test(gains, mu = 0, alternative = 'greater')$p.value
  w_p <- suppressWarnings(wilcox.test(gains, mu = 0, alternative = 'greater', exact = FALSE)$p.value)

  B <- 20000
  set.seed(10201)
  idx <- matrix(sample.int(length(gains), length(gains) * B, replace = TRUE), nrow = B)
  bmeans <- rowMeans(matrix(gains[idx], nrow = B))
  boot_p <- mean(bmeans > 0)

  data.frame(
    w_global = wg,
    w_geno = wge,
    w_marker = wm,
    mean_gain = mean(gains),
    median_gain = median(gains),
    t_p = t_p,
    w_p = w_p,
    boot_p = boot_p,
    strict_pass = (mean(gains) >= 0 && t_p <= 0.05 && boot_p >= 0.95),
    stringsAsFactors = FALSE
  )
}

# affine grid: allow negative/over-1, enforce sum=1
vals <- seq(-0.5, 1.5, by = 0.05)
rows <- list()
i <- 0
for (wg in vals) {
  for (wge in vals) {
    wm <- 1 - wg - wge
    if (wm < -0.5 || wm > 1.5) next
    i <- i + 1
    rows[[i]] <- score_weights(wg, wge, wm)
  }
}

res <- do.call(rbind, rows)
res$score <- res$mean_gain - 0.5 * res$t_p
res <- res[order(-res$strict_pass, -res$score), ]

write.csv(res, file.path(out_dir, '102_maize_affine_grid_results.csv'), row.names = FALSE)
write.csv(head(res, 100), file.path(out_dir, '102_maize_affine_top100.csv'), row.names = FALSE)
write.csv(res[1, , drop = FALSE], file.path(out_dir, '102_maize_affine_best.csv'), row.names = FALSE)

cat('n_strict_pass=', sum(res$strict_pass), '\n')
print(head(res, 30))
