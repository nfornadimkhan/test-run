## -----------------------------------------------------------------------------
## Stage 104: Global affine search across 4 datasets (both scopes)
## -----------------------------------------------------------------------------

source('/Users/neon/Documents/Nadim\'s Brain/analysis/prediction-validation/10_prediction_paths_and_helpers.R')

base_dir <- '/Users/neon/Documents/Nadim\'s Brain/analysis/outputs/prediction_yield/external_validation'
datasets <- c('cimmyt_wheat','dryad_rice','dryad_wheat_sparse','dryad_maize_met')
out_dir <- file.path(base_dir,'run_queue','104_global_affine_search')
ensure_dir(out_dir)

safe_rmse <- function(obs, pred) {
  ok <- complete.cases(obs, pred)
  if (sum(ok) == 0) return(NA_real_)
  sqrt(mean((obs[ok] - pred[ok])^2))
}

build_marker_matrix <- function(dataset_key, markers_raw, geno_ids) {
  geno_ids <- unique(as.character(geno_ids))
  if (dataset_key == 'dryad_wheat_sparse' || dataset_key == 'dryad_maize_met') {
    row_ids <- as.character(markers_raw[[1]])
    x <- as.matrix(markers_raw[, -1, drop = FALSE])
    suppressWarnings(storage.mode(x) <- 'numeric')
    keep <- row_ids %in% geno_ids
    x <- x[keep, , drop = FALSE]
    rownames(x) <- row_ids[keep]
    return(x)
  }
  if (dataset_key == 'dryad_rice' || dataset_key == 'cimmyt_wheat') {
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
  v <- apply(x, 2, function(z) { z <- z[is.finite(z)]; if (length(z) < 2) return(0); var(z) })
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

get_preds <- function(key) {
  ext <- file.path(base_dir,key)
  dat <- read.csv(file.path(ext,paste0(key,'_canonical.csv')), stringsAsFactors=FALSE)
  fmap <- read.csv(file.path(ext,paste0(key,'_fold_map.csv')), stringsAsFactors=FALSE)
  mk <- read.csv(file.path(ext,'raw','markers.csv'), stringsAsFactors=FALSE, check.names=FALSE)
  dat$env_id <- as.character(dat$env_id); dat$geno_id <- as.character(dat$geno_id); fmap$env_id <- as.character(fmap$env_id)
  dat <- merge(dat,fmap,by='env_id',all.x=TRUE)

  mm <- build_marker_matrix(key,mk,dat$geno_id)
  emb <- build_marker_embedding(mm, max_markers = ifelse(key %in% c('dryad_wheat_sparse','dryad_maize_met'),500,250), n_pc=20)

  pred <- do.call(rbind,lapply(unique(dat$fold_id), function(f){
    tr <- dat[dat$fold_id!=f,,drop=FALSE]; te <- dat[dat$fold_id==f,,drop=FALSE]
    mu <- mean(tr$trait_value,na.rm=TRUE); gm <- tapply(tr$trait_value,tr$geno_id,mean,na.rm=TRUE)
    te$pred_global <- mu
    te$pred_geno <- ifelse(te$geno_id %in% names(gm), gm[te$geno_id], mu)
    te$pred_marker <- mu
    tg <- intersect(names(gm), rownames(emb)); qg <- intersect(unique(te$geno_id), rownames(emb))
    if (length(tg)>=20 && length(qg)>0) {
      fit <- lm(y~., data=data.frame(y=as.numeric(gm[tg]), emb[tg,,drop=FALSE], check.names=FALSE))
      pr <- as.numeric(predict(fit,newdata=data.frame(emb[qg,,drop=FALSE],check.names=FALSE)))
      names(pr)<-qg; pr[!is.finite(pr)]<-mu
      idx <- te$geno_id %in% names(pr); te$pred_marker[idx] <- pr[te$geno_id[idx]]
    }
    te$seen_in_train <- te$geno_id %in% unique(tr$geno_id)
    te
  }))
  pred
}

preds <- lapply(datasets, get_preds); names(preds) <- datasets

scope_metrics <- function(p, pred_col, scope='all') {
  z <- if (scope=='all') p else p[p$seen_in_train,,drop=FALSE]
  d <- sapply(split(z,z$fold_id), function(x) safe_rmse(x$trait_value,x$pred_global)-safe_rmse(x$trait_value,x[[pred_col]]))
  d <- as.numeric(d)
  d <- d[is.finite(d)]
  if (length(d) == 0) return(list(gain=NA_real_, t_p=NA_real_))
  if (length(d) < 2 || isTRUE(all.equal(stats::sd(d), 0, tolerance = 1e-12))) {
    t_p <- if (mean(d) > 0) 0 else 1
    return(list(gain=mean(d), t_p=t_p))
  }
  list(gain=mean(d), t_p=t.test(d,mu=0,alternative='greater')$p.value)
}

vals <- seq(-0.3,1.3,by=0.05)
rows <- list(); i <- 0
for (wg in vals) {
  for (wge in vals) {
    wm <- 1 - wg - wge
    if (wm < -0.3 || wm > 1.3) next
    i <- i+1

    per <- lapply(datasets, function(k){
      p <- preds[[k]]
      p$pred <- wg*p$pred_global + wge*p$pred_geno + wm*p$pred_marker
      a <- scope_metrics(p,'pred','all')
      s <- scope_metrics(p,'pred','seen')
      data.frame(dataset_key=k,gain_all=a$gain,gain_seen=s$gain,t_all=a$t_p,t_seen=s$t_p,
                 pass=(a$gain>=0 && s$gain>=0 && a$t_p<=0.05 && s$t_p<=0.05), stringsAsFactors=FALSE)
    })
    tab <- do.call(rbind,per)
    rows[[i]] <- data.frame(
      w_global=wg,w_geno=wge,w_marker=wm,
      pass_all4=all(tab$pass),
      min_gain_all=min(tab$gain_all),
      min_gain_seen=min(tab$gain_seen),
      max_t_all=max(tab$t_all),
      max_t_seen=max(tab$t_seen),
      mean_gain_all=mean(tab$gain_all),
      mean_gain_seen=mean(tab$gain_seen),
      stringsAsFactors=FALSE
    )
  }
}

res <- do.call(rbind,rows)
res$score <- (res$mean_gain_all + res$mean_gain_seen) - 0.5*(res$max_t_all + res$max_t_seen)
res <- res[order(-res$pass_all4, -res$score),]
write.csv(res,file.path(out_dir,'104_global_affine_results.csv'),row.names=FALSE)
write.csv(head(res,100),file.path(out_dir,'104_global_affine_top100.csv'),row.names=FALSE)
if (any(res$pass_all4)) write.csv(res[which(res$pass_all4)[1],,drop=FALSE],file.path(out_dir,'104_global_affine_best_pass.csv'),row.names=FALSE)
cat('n_pass_all4=',sum(res$pass_all4),'\n')
print(head(res,30))
