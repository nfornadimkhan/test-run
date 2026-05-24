## -----------------------------------------------------------------------------
## Stage 40: LOEO alpha-model search for blend predictor
##
## Uses stage-39 fold features/predictions and evaluates multiple alpha models:
## - constant alpha
## - linear models (base / shift-aware)
## - ranger models (base / shift-aware)
##
## Prediction equation:
## yhat = alpha_hat * predicted_value + (1 - alpha_hat) * gmean_shrunk
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/14_cv_model_helpers_yield.R")
ensure_package("ranger")
library(ranger)

cv_dir <- file.path(prediction_output_dir, "loeo_cv")
in_dir <- file.path(cv_dir, "39_shift_aware_meta_blend")
out_dir <- file.path(cv_dir, "40_alpha_model_search")
ensure_dir(out_dir)

fold_df <- read.csv(file.path(in_dir, "39_shift_aware_meta_fold_features.csv"))
pred_df <- read.csv(file.path(in_dir, "39_shift_aware_meta_blend_predictions.csv"))

fold_df$location <- as.factor(fold_df$location)

rmse <- function(y, p) sqrt(mean((y - p)^2, na.rm = TRUE))
clip01 <- function(x) pmax(0, pmin(1, x))

base_feature_set <- c("base_rmse", "mean_pred", "sd_pred", "n_eval", "year", "location")
shift_feature_set <- c(
  base_feature_set,
  "shift_score", "EC1", "EC2", "EC3", "EC4", "EC5",
  "MeanTemp_season_sc", "RainSum_season_sc", "RadMean_season_sc",
  "ET0Sum_season_sc", "HotDays35_season_sc"
)

base_feature_set <- base_feature_set[base_feature_set %in% names(fold_df)]
shift_feature_set <- shift_feature_set[shift_feature_set %in% names(fold_df)]

for (nm in names(fold_df)) {
  if (is.numeric(fold_df[[nm]]) && anyNA(fold_df[[nm]])) {
    fold_df[[nm]][is.na(fold_df[[nm]])] <- mean(fold_df[[nm]], na.rm = TRUE)
  }
}

get_alpha_pred <- function(train_rows, test_row, method) {
  if (method == "constant") {
    return(mean(train_rows$a_oracle, na.rm = TRUE))
  }

  if (method == "lm_base") {
    frm <- as.formula(paste("a_oracle ~", paste(base_feature_set, collapse = " + ")))
    fit <- lm(frm, data = train_rows)
    return(as.numeric(predict(fit, newdata = test_row)))
  }

  if (method == "lm_shift") {
    frm <- as.formula(paste("a_oracle ~", paste(shift_feature_set, collapse = " + ")))
    fit <- lm(frm, data = train_rows)
    return(as.numeric(predict(fit, newdata = test_row)))
  }

  if (method == "ranger_base") {
    frm <- as.formula(paste("a_oracle ~", paste(base_feature_set, collapse = " + ")))
    fit <- ranger(frm, data = train_rows, num.trees = 600, min.node.size = 2)
    return(as.numeric(predict(fit, data = test_row)$predictions[1]))
  }

  if (method == "ranger_shift") {
    frm <- as.formula(paste("a_oracle ~", paste(shift_feature_set, collapse = " + ")))
    fit <- ranger(frm, data = train_rows, num.trees = 700, min.node.size = 2)
    return(as.numeric(predict(fit, data = test_row)$predictions[1]))
  }

  stop("Unknown method: ", method)
}

methods <- c("constant", "lm_base", "lm_shift", "ranger_base", "ranger_shift")
fold_ids <- unique(fold_df$fold_id)

pred_all <- list()
metrics_all <- list()

for (m in methods) {
  out_rows <- list()

  for (i in seq_along(fold_ids)) {
    fid <- fold_ids[i]
    tr <- fold_df[fold_df$fold_id != fid, , drop = FALSE]
    te <- fold_df[fold_df$fold_id == fid, , drop = FALSE]

    a_hat <- clip01(get_alpha_pred(tr, te, m))

    x <- pred_df[pred_df$fold_id == fid, ]
    x$model <- paste0("alpha_search_", m)
    x$alpha_hat <- a_hat
    x$pred_alpha_search <- a_hat * x$predicted_value + (1 - a_hat) * x$gmean_shrunk
    out_rows[[i]] <- x
  }

  out_m <- do.call(rbind, out_rows)
  pred_all[[m]] <- out_m

  met_m <- do.call(
    rbind,
    lapply(split(out_m, out_m$fold_id), function(x) {
      all_df <- data.frame(
        model = unique(x$model),
        fold_id = x$fold_id[1],
        scope = "all",
        n_eval = nrow(x),
        correlation = safe_cor(x$y_true, x$pred_alpha_search),
        rmse = safe_rmse(x$y_true, x$pred_alpha_search),
        mspe = safe_mspe(x$y_true, x$pred_alpha_search),
        mean_bias = safe_bias(x$y_true, x$pred_alpha_search),
        stringsAsFactors = FALSE
      )
      seen <- x[x$seen_in_train, ]
      seen_df <- data.frame(
        model = unique(x$model),
        fold_id = x$fold_id[1],
        scope = "seen_genotypes",
        n_eval = nrow(seen),
        correlation = safe_cor(seen$y_true, seen$pred_alpha_search),
        rmse = safe_rmse(seen$y_true, seen$pred_alpha_search),
        mspe = safe_mspe(seen$y_true, seen$pred_alpha_search),
        mean_bias = safe_bias(seen$y_true, seen$pred_alpha_search),
        stringsAsFactors = FALSE
      )
      rbind(all_df, seen_df)
    })
  )

  metrics_all[[m]] <- met_m
}

pred_out <- do.call(rbind, pred_all)
metrics_by_fold <- do.call(rbind, metrics_all)

summary_metrics <- aggregate(
  cbind(correlation, rmse, mspe, mean_bias) ~ model + scope,
  data = metrics_by_fold,
  FUN = mean,
  na.rm = TRUE
)

summary_metrics <- summary_metrics[order(summary_metrics$scope, summary_metrics$rmse), ]

write.csv(pred_out, file.path(out_dir, "40_alpha_model_search_predictions.csv"), row.names = FALSE)
write.csv(metrics_by_fold, file.path(out_dir, "40_alpha_model_search_metrics_by_fold.csv"), row.names = FALSE)
write.csv(summary_metrics, file.path(out_dir, "40_alpha_model_search_summary_metrics.csv"), row.names = FALSE)

message("Saved stage-40 alpha-model-search outputs.")
print(summary_metrics)
