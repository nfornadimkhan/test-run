## -----------------------------------------------------------------------------
## Stage 103: Corrected maize affine search with BOTH scopes gate
## -----------------------------------------------------------------------------

source('/Users/neon/Documents/Nadim\'s Brain/analysis/prediction-validation/10_prediction_paths_and_helpers.R')

base_dir <- '/Users/neon/Documents/Nadim\'s Brain/analysis/outputs/prediction_yield/external_validation'
dataset_key <- 'dryad_maize_met'
out_dir <- file.path(base_dir, 'run_queue', '103_maize_affine_bothscope_search')
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

  seen_train <- unique(tr$geno_id)
  te$seen_in_train <- te$geno_id %in% seen_train
  te
}))

scope_eval <- function(df, pred_col, scope_name) {
  z <- if (scope_name == 'all') df else df[df$seen_in_train, , drop = FALSE]
  gains <- sapply(split(z, z$fold_id), function(x) {
    safe_rmse(x$trait_value, x$pred_global) - safe_rmse(x$trait_value, x[[pred_col]])
  })
  gains <- as.numeric(gains)
  t_p <- t.test(gains, mu = 0, alternative = 'greater')$p.value
  w_p <- suppressWarnings(wilcox.test(gains, mu = 0, alternative = 'greater', exact = FALSE)$p.value)
  B <- 20000
  idx <- matrix(sample.int(length(gains), length(gains) * B, replace = TRUE), nrow = B)
  bmeans <- rowMeans(matrix(gains[idx], nrow = B))
  list(mean_gain = mean(gains), t_p = t_p, w_p = w_p, boot_p = mean(bmeans > 0))
}

vals <- seq(-0.5, 1.5, by = 0.05)
rows <- list(); i <- 0
for (wg in vals) {
  for (wge in vals) {
    wm <- 1 - wg - wge
    if (wm < -0.5 || wm > 1.5) next
    i <- i + 1

    pred$pred <- wg * pred$pred_global + wge * pred$pred_geno + wm * pred$pred_marker
    set.seed(10301)
    a <- scope_eval(pred, 'pred', 'all')
    set.seed(10302)
    s <- scope_eval(pred, 'pred', 'seen_genotypes')

    strict <- (a$mean_gain >= 0 && s$mean_gain >= 0 && a$t_p <= 0.05 && s$t_p <= 0.05 && a$boot_p >= 0.95 && s$boot_p >= 0.95)

    rows[[i]] <- data.frame(
      w_global = wg, w_geno = wge, w_marker = wm,
      gain_all = a$mean_gain, gain_seen = s$mean_gain,
      t_all = a$t_p, t_seen = s$t_p,
      w_all = a$w_p, w_seen = s$w_p,
      boot_all = a$boot_p, boot_seen = s$boot_p,
      strict_pass = strict,
      stringsAsFactors = FALSE
    )
  }
}

res <- do.call(rbind, rows)
res$score <- (res$gain_all + res$gain_seen) - 0.5 * (res$t_all + res$t_seen)
res <- res[order(-res$strict_pass, -res$score), ]

write.csv(res, file.path(out_dir, '103_maize_affine_bothscope_results.csv'), row.names = FALSE)
write.csv(head(res, 100), file.path(out_dir, '103_maize_affine_bothscope_top100.csv'), row.names = FALSE)

cat('n_strict_pass=', sum(res$strict_pass), '\n')
print(head(res, 30))
