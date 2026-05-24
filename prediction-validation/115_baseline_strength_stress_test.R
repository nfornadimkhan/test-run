## -----------------------------------------------------------------------------
## Stage 115: Baseline-strength stress test
##
## Tests promoted candidate vs multiple comparators:
## - global expert only
## - genotype-mean expert only
## - marker-PC expert only
## - best-single-expert oracle per dataset (ex post reference)
## -----------------------------------------------------------------------------

source('/Users/neon/Documents/Nadim\'s Brain/analysis/prediction-validation/10_prediction_paths_and_helpers.R')

base_dir <- '/Users/neon/Documents/Nadim\'s Brain/analysis/outputs/prediction_yield/external_validation'
datasets <- c('cimmyt_wheat','dryad_rice','dryad_wheat_sparse','dryad_maize_met')
out_dir <- file.path(base_dir,'run_queue','115_baseline_strength')
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
    x <- as.matrix(markers_raw[, -1, drop = FALSE]); suppressWarnings(storage.mode(x) <- 'numeric')
    keep <- row_ids %in% geno_ids
    x <- x[keep,,drop=FALSE]; rownames(x) <- row_ids[keep]
    return(x)
  }
  if (dataset_key %in% c('dryad_rice','cimmyt_wheat')) {
    geno_cols <- intersect(names(markers_raw), geno_ids)
    if(length(geno_cols)==0) return(matrix(numeric(0),0,0))
    m <- as.matrix(markers_raw[,geno_cols,drop=FALSE]); x_chr <- t(m)
    map <- c(A=1,C=2,G=3,T=4)
    x_num <- matrix(NA_real_, nrow=nrow(x_chr), ncol=ncol(x_chr))
    for(j in seq_len(ncol(x_chr))) x_num[,j] <- as.numeric(unname(map[x_chr[,j]]))
    rownames(x_num) <- rownames(x_chr)
    return(x_num)
  }
  matrix(numeric(0),0,0)
}

build_marker_embedding <- function(marker_mat, max_markers=500, n_pc=20) {
  if (is.null(marker_mat) || nrow(marker_mat)==0 || ncol(marker_mat)==0) return(matrix(numeric(0),0,0))
  x <- marker_mat
  v <- apply(x,2,function(z){z<-z[is.finite(z)]; if(length(z)<2) return(0); var(z)})
  keep <- which(is.finite(v) & v>0)
  if(length(keep)==0) return(matrix(numeric(0),0,0))
  x <- x[,keep,drop=FALSE]
  if(ncol(x)>max_markers){ set.seed(4242); x <- x[,sample.int(ncol(x),max_markers),drop=FALSE] }
  for(j in seq_len(ncol(x))){ med<-median(x[,j],na.rm=TRUE); if(!is.finite(med)) med<-0; x[!is.finite(x[,j]),j] <- med }
  x <- scale(x); x[!is.finite(x)] <- 0
  npc <- min(n_pc,ncol(x),max(1,nrow(x)-1))
  pc <- prcomp(x,center=FALSE,scale.=FALSE,rank.=npc)
  emb <- pc$x[,seq_len(npc),drop=FALSE]
  rownames(emb) <- rownames(marker_mat)
  emb
}

expert_preds_for_split <- function(train_df,test_df,marker_emb){
  mu <- mean(train_df$trait_value,na.rm=TRUE)
  gm <- tapply(train_df$trait_value, train_df$geno_id, mean, na.rm=TRUE)
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

eval_dataset <- function(ds){
  ext <- file.path(base_dir,ds)
  dat <- read.csv(file.path(ext,paste0(ds,'_canonical.csv')), stringsAsFactors=FALSE)
  fmap <- read.csv(file.path(ext,paste0(ds,'_fold_map.csv')), stringsAsFactors=FALSE)
  mk <- read.csv(file.path(ext,'raw','markers.csv'), stringsAsFactors=FALSE, check.names=FALSE)
  dat$env_id <- as.character(dat$env_id); dat$geno_id <- as.character(dat$geno_id); fmap$env_id <- as.character(fmap$env_id)
  dat <- merge(dat,fmap,by='env_id',all.x=TRUE)

  mm <- build_marker_matrix(ds,mk,dat$geno_id)
  emb <- build_marker_embedding(mm, max_markers=ifelse(ds %in% c('dryad_wheat_sparse','dryad_maize_met'),500,250), n_pc=20)

  pred <- do.call(rbind,lapply(unique(dat$fold_id), function(f){
    tr <- dat[dat$fold_id!=f,,drop=FALSE]
    te <- dat[dat$fold_id==f,,drop=FALSE]
    px <- expert_preds_for_split(tr,te,emb)
    px$pred_candidate <- w[1]*px$pred_global + w[2]*px$pred_geno + w[3]*px$pred_marker
    px$seen_in_train <- px$geno_id %in% unique(tr$geno_id)
    px
  }))

  # fold metrics by model and scope
  models <- c('pred_global','pred_geno','pred_marker','pred_candidate')
  met <- do.call(rbind,lapply(split(pred,pred$fold_id), function(x){
    seen <- x[x$seen_in_train,,drop=FALSE]
    do.call(rbind,lapply(models, function(m){
      rbind(
        data.frame(fold_id=x$fold_id[1],scope='all',model=m,rmse=safe_rmse(x$trait_value,x[[m]]),stringsAsFactors=FALSE),
        data.frame(fold_id=x$fold_id[1],scope='seen_genotypes',model=m,rmse=safe_rmse(seen$trait_value,seen[[m]]),stringsAsFactors=FALSE)
      )
    }))
  }))

  # identify best single expert by mean RMSE per scope (oracle reference)
  expert_means <- aggregate(rmse ~ scope + model, data=met[met$model!='pred_candidate',], FUN=mean)
  best_exp <- do.call(rbind,lapply(split(expert_means, expert_means$scope), function(z) z[which.min(z$rmse),]))

  # comparisons: candidate vs each comparator
  comps <- c('pred_global','pred_geno','pred_marker')
  cmp_rows <- list(); k <- 0
  for (sc in unique(met$scope)) {
    cand <- met[met$scope==sc & met$model=='pred_candidate', c('fold_id','rmse')]
    for (cname in comps) {
      cmp <- met[met$scope==sc & met$model==cname, c('fold_id','rmse')]
      z <- merge(cand,cmp,by='fold_id',suffixes=c('_cand','_cmp'))
      d <- z$rmse_cmp - z$rmse_cand
      t_p <- if (length(d)>=2) t.test(d,mu=0,alternative='greater')$p.value else NA_real_
      k <- k+1
      cmp_rows[[k]] <- data.frame(dataset_key=ds, scope=sc, comparator=cname,
                                  mean_gain_vs_comparator=mean(d), t_p=t_p,
                                  win_rate=mean(d>0), best_model_scope=NA_character_, stringsAsFactors=FALSE)
    }
    # vs best-single-expert (oracle ex post for scope)
    best_model <- best_exp$model[best_exp$scope==sc][1]
    cmp <- met[met$scope==sc & met$model==best_model, c('fold_id','rmse')]
    z <- merge(cand,cmp,by='fold_id',suffixes=c('_cand','_cmp'))
    d <- z$rmse_cmp - z$rmse_cand
    t_p <- if (length(d)>=2) t.test(d,mu=0,alternative='greater')$p.value else NA_real_
    k <- k+1
    cmp_rows[[k]] <- data.frame(dataset_key=ds, scope=sc, comparator='best_single_expert_oracle',
                                mean_gain_vs_comparator=mean(d), t_p=t_p,
                                win_rate=mean(d>0), best_model_scope=best_model, stringsAsFactors=FALSE)
  }

  list(metrics=met, comparisons=do.call(rbind,cmp_rows), best=best_exp)
}

all_cmp <- list(); all_best <- list(); all_met <- list(); i <- 0
for (ds in datasets) {
  out <- eval_dataset(ds)
  i <- i+1
  all_cmp[[i]] <- out$comparisons
  all_best[[i]] <- cbind(dataset_key=ds, out$best)
  all_met[[i]] <- cbind(dataset_key=ds, out$metrics)
}

cmp_tab <- do.call(rbind,all_cmp)
best_tab <- do.call(rbind,all_best)
met_tab <- do.call(rbind,all_met)

write.csv(cmp_tab,file.path(out_dir,'115_candidate_vs_strong_baselines.csv'),row.names=FALSE)
write.csv(best_tab,file.path(out_dir,'115_best_single_expert_by_scope.csv'),row.names=FALSE)
write.csv(met_tab,file.path(out_dir,'115_fold_rmse_by_model.csv'),row.names=FALSE)

print(cmp_tab)
