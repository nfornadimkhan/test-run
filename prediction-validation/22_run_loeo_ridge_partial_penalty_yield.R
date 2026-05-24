## Fast LOEO ridge reaction norm with partial penalty
source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/14_cv_model_helpers_yield.R")
ensure_package("glmnet")
library(glmnet)

out_dir <- file.path(cv_output_dir, "22_ridge_partial")
ensure_dir(out_dir)

fit_fold <- function(dat, fold_row, ec_cols, k_pc = 2) {
  d <- mask_fold_response(dat, fold_row$env_id)
  d <- d[complete.cases(d[, c("y_true","is_test","seen_in_train","G","Y","L",ec_cols)]), , drop=FALSE]

  env_tbl <- unique(d[, c("ENV", ec_cols)])
  rownames(env_tbl) <- as.character(env_tbl$ENV)
  tr_env <- unique(d$ENV[!d$is_test])
  Xtr_env <- scale(as.matrix(env_tbl[as.character(tr_env), ec_cols, drop=FALSE]))
  pca <- prcomp(Xtr_env, center=TRUE, scale.=TRUE)
  k <- min(k_pc, ncol(pca$x))
  Xall <- scale(as.matrix(env_tbl[, ec_cols, drop=FALSE]),
                center=attr(Xtr_env,"scaled:center"),
                scale=attr(Xtr_env,"scaled:scale"))
  scores <- Xall %*% pca$rotation[, seq_len(k), drop=FALSE]
  colnames(scores) <- paste0("PC", seq_len(k))
  d <- merge(d, data.frame(ENV=rownames(scores), scores, row.names=NULL), by="ENV", all.x=TRUE)

  pcs <- paste0("PC", seq_len(k))
  X <- model.matrix(as.formula(paste("~", paste(c("0+G+Y+L", pcs, paste0("G:", pcs)), collapse=" + "))), data=d)
  cn <- colnames(X); pf <- rep(1, length(cn))
  pf[grepl("^G", cn) & !grepl(":", cn)] <- 0
  pf[grepl("^Y", cn)] <- 0
  pf[grepl("^L", cn)] <- 0

  tr <- which(!d$is_test); te <- which(d$is_test)
  ytr <- d$y_true[tr]
  cv <- cv.glmnet(X[tr,,drop=FALSE], ytr, family="gaussian", alpha=0, nfolds=3,
                  standardize=FALSE, intercept=TRUE, penalty.factor=pf)
  fit <- glmnet(X[tr,,drop=FALSE], ytr, family="gaussian", alpha=0, lambda=cv$lambda.min,
                standardize=FALSE, intercept=TRUE, penalty.factor=pf)
  pred <- as.numeric(predict(fit, newx=X[te,,drop=FALSE], s=cv$lambda.min))
  out <- d[te, c("Y","L","G","ENV","env_id","geno_ID","y_true","seen_in_train"), drop=FALSE]
  out$predicted_value <- pred; out$model <- "ridge_partial"; out$fold_id <- fold_row$fold_id
  out$lambda <- cv$lambda.min; out$k_pc <- k
  met <- rbind(
    data.frame(model="ridge_partial", fold_id=fold_row$fold_id, scope="all", n_eval=nrow(out),
               correlation=safe_cor(out$y_true,out$predicted_value),
               rmse=safe_rmse(out$y_true,out$predicted_value),
               mspe=safe_mspe(out$y_true,out$predicted_value),
               mean_bias=safe_bias(out$y_true,out$predicted_value),
               lambda=cv$lambda.min, k_pc=k, stringsAsFactors=FALSE),
    data.frame(model="ridge_partial", fold_id=fold_row$fold_id, scope="seen_genotypes", n_eval=sum(out$seen_in_train),
               correlation=safe_cor(out$y_true[out$seen_in_train],out$predicted_value[out$seen_in_train]),
               rmse=safe_rmse(out$y_true[out$seen_in_train],out$predicted_value[out$seen_in_train]),
               mspe=safe_mspe(out$y_true[out$seen_in_train],out$predicted_value[out$seen_in_train]),
               mean_bias=safe_bias(out$y_true[out$seen_in_train],out$predicted_value[out$seen_in_train]),
               lambda=cv$lambda.min, k_pc=k, stringsAsFactors=FALSE)
  )
  list(pred=out, met=met)
}

inp <- read_loeo_inputs(); dat <- inp$dat; folds <- subset_folds_for_run(inp$folds); ec_cols <- detect_available_ec_aliases(dat)
preds <- list(); mets <- list()
for (i in seq_len(nrow(folds))) {
  message("Running ridge_partial on ", folds$fold_id[i])
  r <- fit_fold(dat, folds[i,,drop=FALSE], ec_cols, k_pc=2)
  preds[[i]] <- r$pred; mets[[i]] <- r$met
}
pred <- do.call(rbind, preds); met <- do.call(rbind, mets)
write.csv(pred, file.path(out_dir, "22_ridge_partial_predictions.csv"), row.names=FALSE)
write.csv(met, file.path(out_dir, "22_ridge_partial_metrics.csv"), row.names=FALSE)
sm <- aggregate(cbind(correlation,rmse,mspe,mean_bias)~model+scope,data=met,FUN=mean,na.rm=TRUE)
write.csv(sm, file.path(out_dir, "22_ridge_partial_summary_metrics.csv"), row.names=FALSE)
print(sm)
