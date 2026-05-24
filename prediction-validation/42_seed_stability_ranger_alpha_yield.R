## -----------------------------------------------------------------------------
## Stage 42: Seed-stability analysis for ranger-based alpha models
##
## Repeats alpha prediction across multiple random seeds and measures
## distribution of mean RMSE for:
## - ranger_base
## - ranger_shift
##
## Benchmarked against fixed stage-24 meta_alpha_blend summary RMSE.
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/14_cv_model_helpers_yield.R")
ensure_package("ranger")
library(ranger)

cv_dir <- file.path(prediction_output_dir, "loeo_cv")
in_dir <- file.path(cv_dir, "39_shift_aware_meta_blend")
out_dir <- file.path(cv_dir, "42_seed_stability_ranger_alpha")
ensure_dir(out_dir)

fold_df <- read.csv(file.path(in_dir, "39_shift_aware_meta_fold_features.csv"))
pred_df <- read.csv(file.path(in_dir, "39_shift_aware_meta_blend_predictions.csv"))
s28 <- read.csv(file.path(cv_dir, "28_validation_all_approaches", "28_summary_metrics.csv"))

fold_df$location <- as.factor(fold_df$location)

for (nm in names(fold_df)) {
  if (is.numeric(fold_df[[nm]]) && anyNA(fold_df[[nm]])) {
    fold_df[[nm]][is.na(fold_df[[nm]])] <- mean(fold_df[[nm]], na.rm = TRUE)
  }
}

base_feature_set <- c("base_rmse", "mean_pred", "sd_pred", "n_eval", "year", "location")
shift_feature_set <- c(
  base_feature_set,
  "shift_score", "EC1", "EC2", "EC3", "EC4", "EC5",
  "MeanTemp_season_sc", "RainSum_season_sc", "RadMean_season_sc",
  "ET0Sum_season_sc", "HotDays35_season_sc"
)

base_feature_set <- base_feature_set[base_feature_set %in% names(fold_df)]
shift_feature_set <- shift_feature_set[shift_feature_set %in% names(fold_df)]

clip01 <- function(x) pmax(0, pmin(1, x))

predict_alpha_for_seed <- function(model_type, seed) {
  fold_ids <- unique(fold_df$fold_id)
  out_rows <- vector("list", length(fold_ids))

  for (i in seq_along(fold_ids)) {
    fid <- fold_ids[i]
    tr <- fold_df[fold_df$fold_id != fid, , drop = FALSE]
    te <- fold_df[fold_df$fold_id == fid, , drop = FALSE]

    if (model_type == "ranger_base") {
      frm <- as.formula(paste("a_oracle ~", paste(base_feature_set, collapse = " + ")))
      fit <- ranger(
        frm, data = tr, num.trees = 600, min.node.size = 2,
        seed = seed
      )
    } else if (model_type == "ranger_shift") {
      frm <- as.formula(paste("a_oracle ~", paste(shift_feature_set, collapse = " + ")))
      fit <- ranger(
        frm, data = tr, num.trees = 700, min.node.size = 2,
        seed = seed
      )
    } else {
      stop("Unknown model_type")
    }

    a_hat <- clip01(as.numeric(predict(fit, data = te)$predictions[1]))
    x <- pred_df[pred_df$fold_id == fid, ]
    x$model_type <- model_type
    x$seed <- seed
    x$pred_seed <- a_hat * x$predicted_value + (1 - a_hat) * x$gmean_shrunk
    out_rows[[i]] <- x
  }

  out <- do.call(rbind, out_rows)

  met <- do.call(
    rbind,
    lapply(split(out, out$fold_id), function(x) {
      all_df <- data.frame(
        scope = "all",
        rmse = safe_rmse(x$y_true, x$pred_seed),
        correlation = safe_cor(x$y_true, x$pred_seed),
        stringsAsFactors = FALSE
      )
      seen <- x[x$seen_in_train, ]
      seen_df <- data.frame(
        scope = "seen_genotypes",
        rmse = safe_rmse(seen$y_true, seen$pred_seed),
        correlation = safe_cor(seen$y_true, seen$pred_seed),
        stringsAsFactors = FALSE
      )
      rbind(all_df, seen_df)
    })
  )

  summary <- aggregate(cbind(rmse, correlation) ~ scope, data = met, FUN = mean, na.rm = TRUE)
  summary$model_type <- model_type
  summary$seed <- seed
  summary
}

seed_grid <- 1:50
model_types <- c("ranger_base", "ranger_shift")

res <- list()
k <- 1
for (m in model_types) {
  for (s in seed_grid) {
    res[[k]] <- predict_alpha_for_seed(m, s)
    k <- k + 1
  }
}

seed_summary <- do.call(rbind, res)

meta_ref <- s28[s28$model == "meta_alpha_blend", c("scope", "rmse")]
names(meta_ref)[2] <- "rmse_meta_alpha_blend"
seed_summary <- merge(seed_summary, meta_ref, by = "scope", all.x = TRUE)
seed_summary$gain_vs_meta <- seed_summary$rmse_meta_alpha_blend - seed_summary$rmse

stability <- aggregate(
  cbind(rmse, gain_vs_meta) ~ model_type + scope,
  data = seed_summary,
  FUN = function(x) c(mean = mean(x), sd = sd(x), q05 = quantile(x, 0.05), q95 = quantile(x, 0.95))
)

flatten_col <- function(mat_col, prefix) {
  # aggregate() keeps quantile names as "5%" and "95%", so use positions.
  out <- data.frame(
    mat_col[, 1],
    mat_col[, 2],
    mat_col[, 3],
    mat_col[, 4],
    stringsAsFactors = FALSE
  )
  names(out) <- c(
    paste0(prefix, "_mean"),
    paste0(prefix, "_sd"),
    paste0(prefix, "_q05"),
    paste0(prefix, "_q95")
  )
  out
}

stab_out <- cbind(
  stability[c("model_type", "scope")],
  flatten_col(stability$rmse, "rmse"),
  flatten_col(stability$gain_vs_meta, "gain_vs_meta")
)

win_prob <- aggregate(gain_vs_meta ~ model_type + scope, data = seed_summary, FUN = function(x) mean(x > 0))
names(win_prob)[3] <- "prob_beat_meta_alpha_blend"
stab_out <- merge(stab_out, win_prob, by = c("model_type", "scope"), all.x = TRUE)

write.csv(seed_summary, file.path(out_dir, "42_seed_level_summary.csv"), row.names = FALSE)
write.csv(stab_out, file.path(out_dir, "42_seed_stability_summary.csv"), row.names = FALSE)

message("Saved stage-42 seed stability outputs.")
print(stab_out)
