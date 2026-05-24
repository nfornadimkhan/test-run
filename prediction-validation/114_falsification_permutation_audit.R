## -----------------------------------------------------------------------------
## Stage 114: Falsification audit via label permutation
##
## Tests promoted candidate against null scenarios:
## A) permute training trait labels within each outer fold train set
## B) permute test trait labels within each outer fold test set (sanity collapse)
##
## If discovery is real, pass rates and gains should collapse under both nulls.
## -----------------------------------------------------------------------------

source('/Users/neon/Documents/Nadim\'s Brain/analysis/prediction-validation/10_prediction_paths_and_helpers.R')

base_dir <- '/Users/neon/Documents/Nadim\'s Brain/analysis/outputs/prediction_yield/external_validation'
datasets <- c('cimmyt_wheat','dryad_rice','dryad_wheat_sparse','dryad_maize_met')
out_dir <- file.path(base_dir,'run_queue','114_falsification')
ensure_dir(out_dir)

w <- c(0.80,0.25,-0.05)

safe_rmse <- function(obs,pred){
  ok <- complete.cases(obs,pred)
  if(sum(ok)==0) return(NA_real_)
  sqrt(mean((obs[ok]-pred[ok])^2))
}

build_marker_matrix <- function(dataset_key, markers_raw, geno_ids) {
  geno_ids <- unique(as.character(geno_ids))

  if (dataset_key %in% c('dryad_wheat_sparse','dryad_maize_met')) {
    row_ids <- as.character(markers_raw[[1]])
    x <- as.matrix(markers_raw[, -1, drop = FALSE])
    suppressWarnings(storage.mode(x) <- 'numeric')
    keep <- row_ids %in% geno_ids
    x <- x[keep, , drop = FALSE]
    rownames(x) <- row_ids[keep]
    return(x)
  }

  if (dataset_key %in% c('dryad_rice','cimmyt_wheat')) {
    geno_cols <- intersect(names(markers_raw), geno_ids)
    if (length(geno_cols) == 0) return(matrix(numeric(0),0,0))
    m <- as.matrix(markers_raw[, geno_cols, drop = FALSE])
    x_chr <- t(m)
    map <- c(A=1,C=2,G=3,T=4)
    x_num <- matrix(NA_real_, nrow=nrow(x_chr), ncol=ncol(x_chr))
    for (j in seq_len(ncol(x_chr))) x_num[,j] <- as.numeric(unname(map[x_chr[,j]]))
    rownames(x_num) <- rownames(x_chr)
    return(x_num)
  }

  matrix(numeric(0),0,0)
}

build_marker_embedding <- function(marker_mat, max_markers=500, n_pc=20) {
  if (is.null(marker_mat) || nrow(marker_mat)==0 || ncol(marker_mat)==0) return(matrix(numeric(0),0,0))
  x <- marker_mat
  v <- apply(x,2,function(z){ z <- z[is.finite(z)]; if(length(z)<2) return(0); var(z) })
  keep <- which(is.finite(v) & v > 0)
  if(length(keep)==0) return(matrix(numeric(0),0,0))
  x <- x[,keep,drop=FALSE]
  if(ncol(x)>max_markers){ set.seed(4242); x <- x[,sample.int(ncol(x),max_markers),drop=FALSE] }
  for(j in seq_len(ncol(x))){ med <- median(x[,j],na.rm=TRUE); if(!is.finite(med)) med <- 0; x[!is.finite(x[,j]),j] <- med }
  x <- scale(x); x[!is.finite(x)] <- 0
  npc <- min(n_pc,ncol(x),max(1,nrow(x)-1))
  pc <- prcomp(x,center=FALSE,scale.=FALSE,rank.=npc)
  emb <- pc$x[,seq_len(npc),drop=FALSE]
  rownames(emb) <- rownames(marker_mat)
  emb
}

expert_preds_for_split <- function(train_df,test_df,marker_emb){
  mu <- mean(train_df$trait_value,na.rm=TRUE)
  gm <- tapply(train_df$trait_value,train_df$geno_id,mean,na.rm=TRUE)
  out <- test_df
  out$pred_global <- mu
  out$pred_geno <- ifelse(out$geno_id %in% names(gm), gm[out$geno_id], mu)
  out$pred_marker <- mu

  if(!is.null(marker_emb) && nrow(marker_emb)>0){
    tg <- intersect(names(gm), rownames(marker_emb))
    qg <- intersect(unique(out$geno_id), rownames(marker_emb))
    if(length(tg)>=20 && length(qg)>0){
      fit <- lm(y~., data=data.frame(y=as.numeric(gm[tg]), marker_emb[tg,,drop=FALSE], check.names=FALSE))
      pr <- as.numeric(predict(fit,newdata=data.frame(marker_emb[qg,,drop=FALSE], check.names=FALSE)))
      names(pr) <- qg
      pr[!is.finite(pr)] <- mu
      idx <- out$geno_id %in% names(pr)
      out$pred_marker[idx] <- pr[out$geno_id[idx]]
    }
  }
  out
}

eval_dataset <- function(ds, mode=c('none','perm_train','perm_test'), seed=1L){
  mode <- match.arg(mode)
  ext <- file.path(base_dir,ds)
  dat <- read.csv(file.path(ext,paste0(ds,'_canonical.csv')), stringsAsFactors=FALSE)
  fmap <- read.csv(file.path(ext,paste0(ds,'_fold_map.csv')), stringsAsFactors=FALSE)
  mk <- read.csv(file.path(ext,'raw','markers.csv'), stringsAsFactors=FALSE, check.names=FALSE)

  dat$env_id <- as.character(dat$env_id); dat$geno_id <- as.character(dat$geno_id)
  fmap$env_id <- as.character(fmap$env_id)
  dat <- merge(dat,fmap,by='env_id',all.x=TRUE)

  mm <- build_marker_matrix(ds,mk,dat$geno_id)
  emb <- build_marker_embedding(mm, max_markers=ifelse(ds %in% c('dryad_wheat_sparse','dryad_maize_met'),500,250), n_pc=20)

  set.seed(seed)
  folds <- unique(dat$fold_id)
  pred <- do.call(rbind,lapply(folds,function(f){
    tr <- dat[dat$fold_id!=f,,drop=FALSE]
    te <- dat[dat$fold_id==f,,drop=FALSE]

    if(mode=='perm_train') tr$trait_value <- sample(tr$trait_value)
    if(mode=='perm_test') te$trait_value <- sample(te$trait_value)

    px <- expert_preds_for_split(tr,te,emb)
    px$pred_baseline <- px$pred_global
    px$pred_candidate <- w[1]*px$pred_global + w[2]*px$pred_geno + w[3]*px$pred_marker
    px$seen_in_train <- px$geno_id %in% unique(tr$geno_id)
    px
  }))

  met <- do.call(rbind,lapply(split(pred,pred$fold_id),function(x){
    seen <- x[x$seen_in_train,,drop=FALSE]
    rbind(
      data.frame(scope='all',gain=safe_rmse(x$trait_value,x$pred_baseline)-safe_rmse(x$trait_value,x$pred_candidate)),
      data.frame(scope='seen_genotypes',gain=safe_rmse(seen$trait_value,seen$pred_baseline)-safe_rmse(seen$trait_value,seen$pred_candidate))
    )
  }))

  scope_eval <- function(sc){
    d <- met$gain[met$scope==sc]
    d <- d[is.finite(d)]
    t_p <- if(length(d)>=2) t.test(d,mu=0,alternative='greater')$p.value else NA_real_
    B <- 5000
    if(length(d)>=1){
      idx <- matrix(sample.int(length(d), length(d)*B, replace=TRUE), nrow=B)
      bm <- rowMeans(matrix(d[idx],nrow=B))
      bp <- mean(bm>0)
    } else {
      bp <- NA_real_
    }
    list(gain=mean(d), t_p=t_p, boot=bp)
  }

  a <- scope_eval('all')
  s <- scope_eval('seen_genotypes')
  pass <- isTRUE(a$gain>=0) && isTRUE(s$gain>=0) && isTRUE(a$t_p<=0.05) && isTRUE(s$t_p<=0.05) && isTRUE(a$boot>=0.95) && isTRUE(s$boot>=0.95)

  data.frame(
    dataset_key=ds, mode=mode, seed=seed,
    gain_all=a$gain, gain_seen=s$gain,
    t_all=a$t_p, t_seen=s$t_p,
    boot_all=a$boot, boot_seen=s$boot,
    pass_confirmatory=pass,
    stringsAsFactors=FALSE
  )
}

rows <- list(); i <- 0
for(ds in datasets){
  # true run (no permutation)
  i <- i+1; rows[[i]] <- eval_dataset(ds,'none',seed=2026)
  # falsification runs
  for (sd in c(101,202,303,404,505)) {
    i <- i+1; rows[[i]] <- eval_dataset(ds,'perm_train',seed=sd)
    i <- i+1; rows[[i]] <- eval_dataset(ds,'perm_test',seed=sd)
  }
}

res <- do.call(rbind,rows)
write.csv(res,file.path(out_dir,'114_falsification_detail.csv'),row.names=FALSE)

agg <- aggregate(as.numeric(pass_confirmatory) ~ mode + dataset_key, data=res, FUN=mean)
names(agg)[3] <- 'pass_rate'
write.csv(agg,file.path(out_dir,'114_falsification_pass_rates.csv'),row.names=FALSE)

sep <- aggregate(cbind(gain_all,gain_seen) ~ mode, data=res, FUN=mean)
write.csv(sep,file.path(out_dir,'114_falsification_gain_summary.csv'),row.names=FALSE)

print(agg)
print(sep)
