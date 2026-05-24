## -----------------------------------------------------------------------------
## Stage 14 helper file: fold-wise refit and prediction helpers for yield
##
## Why this file exists:
## The paper's next phase requires repeating the same operations many times:
## - choose one held-out environment
## - mask its phenotype values
## - refit a model on the remaining observed rows
## - predict the held-out rows
## - score prediction quality
##
## This helper file centralizes that logic so the later scripts can focus on
## "which model family are we evaluating?" rather than rewriting the same fold
## machinery repeatedly.
##
## Important prediction design used here:
## We do not train on one table and predict on a separate "newdata" table.
## Instead, we keep the held-out rows inside the same dataset and set their
## response to NA.
##
## Why:
## - factor levels such as genotype, year, and location remain visible
## - ASReml can predict the masked rows using the observed design structure
## - this is a natural mixed-model analogue of fold-wise cross-validation
##
## Evaluation note:
## We score both:
## - all held-out rows
## - only held-out rows whose genotype was already seen in training
##
## That distinction matters because this dataset has no genomic relationship
## matrix. Predicting an entirely unseen genotype is a different problem from
## predicting a seen genotype in a new environment.
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/10_prediction_paths_and_helpers.R")

ensure_package("asreml")
library(asreml)

cv_output_dir <- file.path(prediction_output_dir, "loeo_cv")
ensure_dir(cv_output_dir)

read_loeo_inputs <- function() {
  dat <- read_prediction_input()
  folds <- read.csv(file.path(prediction_output_dir, "11_loeo_folds.csv"))

  dat$G <- factor(dat$G)
  dat$L <- factor(dat$L)
  dat$Y <- factor(dat$Y)
  dat$ENV <- factor(dat$ENV)

  list(dat = dat, folds = folds)
}

subset_folds_for_run <- function(folds) {
  fold_limit <- Sys.getenv("FOLD_LIMIT", unset = "")
  if (nzchar(fold_limit)) {
    folds <- folds[seq_len(min(as.integer(fold_limit), nrow(folds))), , drop = FALSE]
  }
  folds
}

mask_fold_response <- function(dat, env_id) {
  dat2 <- dat
  dat2$y_true <- dat2$yld_bu_ac
  dat2$is_test <- dat2$env_id == env_id

  seen_train_genotypes <- unique(dat2$G[!dat2$is_test])
  dat2$seen_in_train <- dat2$G %in% seen_train_genotypes

  dat2$yld_bu_ac[dat2$is_test] <- NA_real_
  dat2
}

make_prediction_levels <- function(test_rows) {
  list(
    Y = as.character(test_rows$Y[1]),
    L = as.character(test_rows$L[1]),
    G = as.character(unique(test_rows$G))
  )
}

extract_fold_predictions <- function(model, scored_data, env_id, model_name, fold_id, pworkspace = "256mb") {
  test_rows <- scored_data[scored_data$is_test, ]
  pred_levels <- make_prediction_levels(test_rows)

  pred_obj <- predict(
    model,
    classify = "Y:L:G",
    levels = pred_levels,
    pworkspace = pworkspace,
    maxit = 2
  )

  pred_df <- pred_obj$pvals
  names(pred_df)[names(pred_df) == "predicted.value"] <- "predicted_value"
  names(pred_df)[names(pred_df) == "std.error"] <- "prediction_se"

  keep_truth <- unique(
    test_rows[, c("ENV", "env_id", "Y", "L", "G", "geno_ID", "y_true", "seen_in_train")]
  )

  out <- merge(pred_df, keep_truth, by = c("Y", "L", "G"), all.x = TRUE)
  out$model <- model_name
  out$fold_id <- fold_id
  out$prediction_status <- out$status
  out
}

safe_cor <- function(x, y) {
  ok <- complete.cases(x, y)
  if (sum(ok) < 2) return(NA_real_)
  cor(x[ok], y[ok])
}

safe_rmse <- function(obs, pred) {
  ok <- complete.cases(obs, pred)
  if (sum(ok) == 0) return(NA_real_)
  sqrt(mean((obs[ok] - pred[ok])^2))
}

safe_mspe <- function(obs, pred) {
  ok <- complete.cases(obs, pred)
  if (sum(ok) == 0) return(NA_real_)
  mean((obs[ok] - pred[ok])^2)
}

safe_bias <- function(obs, pred) {
  ok <- complete.cases(obs, pred)
  if (sum(ok) == 0) return(NA_real_)
  mean(pred[ok] - obs[ok])
}

score_prediction_rows <- function(pred_df, model_name, fold_id) {
  scopes <- list(
    all = pred_df,
    seen_genotypes = pred_df[pred_df$seen_in_train, , drop = FALSE]
  )

  do.call(
    rbind,
    lapply(names(scopes), function(scope_name) {
      x <- scopes[[scope_name]]
      x <- x[complete.cases(x$y_true, x$predicted_value), , drop = FALSE]

      data.frame(
        model = model_name,
        fold_id = fold_id,
        scope = scope_name,
        n_eval = nrow(x),
        correlation = safe_cor(x$y_true, x$predicted_value),
        rmse = safe_rmse(x$y_true, x$predicted_value),
        mspe = safe_mspe(x$y_true, x$predicted_value),
        mean_bias = safe_bias(x$y_true, x$predicted_value),
        stringsAsFactors = FALSE
      )
    })
  )
}

ec_terms_from_data <- function(dat) {
  detect_available_ec_aliases(dat)
}

make_dynamic_model_components <- function(dat) {
  ec_terms <- ec_terms_from_data(dat)
  n_ec <- length(ec_terms)
  ec_fixed_formula <- make_observed_ec_formula("yld_bu_ac", ec_aliases = ec_terms)

  rr_dimension <- n_ec + 1
  rr1_terms <- c("G", paste0("G:", ec_terms), "G:x0")
  rr2_terms <- c(paste0("G:", ec_terms), "G:z0", "G:x0", "G:x00")
  rfr_terms <- c("G", paste0("G:", ec_terms))

  fw1_rr_terms <- c(paste0("G:", ec_terms), "G:x0")
  fw2_rr_terms <- c(paste0("G:", ec_terms), "G:x0", "G:x00")

  list(
    ec_terms = ec_terms,
    n_ec = n_ec,
    ec_fixed_formula = ec_fixed_formula,
    rr1_random_formula = as.formula(
      paste0(
        "~ str(~ ", paste(rr1_terms, collapse = " + "),
        ", vmodel = ~ rr(", rr_dimension, ", 1):id(G)) + L + Y + Y:L + L:G + Y:G"
      )
    ),
    rr2_random_formula = as.formula(
      paste0(
        "~ str(~ ", paste(rr2_terms, collapse = " + "),
        ", vmodel = ~ rr(", rr_dimension, ", 2):id(G)) + L + Y + Y:L + L:G + Y:G"
      )
    ),
    rfr_random_formula = as.formula(
      paste0(
        "~ str(~ ", paste(rfr_terms, collapse = " + "),
        ", vmodel = ~ us(", rr_dimension, "):id(G)) + L + Y + Y:L + L:G + Y:G"
      )
    ),
    fw1_rr_random_formula = as.formula(
      paste0(
        "~ L:G + Y:G + str(~ ",
        paste(fw1_rr_terms, collapse = " + "),
        ", vmodel = ~ rr(", n_ec, ", 1):id(G))"
      )
    ),
    fw2_rr_random_formula = as.formula(
      paste0(
        "~ L:G + Y:G + str(~ ",
        paste(fw2_rr_terms, collapse = " + "),
        ", vmodel = ~ rr(", n_ec, ", 2):id(G))"
      )
    )
  )
}

fit_prediction_model <- function(model_name, dat_masked, components) {
  asreml.options(maxit = 60, extra = 2, ai.sing = TRUE, fail = "soft")
  assign(".cv_prediction_data", dat_masked, envir = .GlobalEnv)
  assign(".cv_ec_fixed_formula", components$ec_fixed_formula, envir = .GlobalEnv)
  assign(".cv_rr1_random_formula", components$rr1_random_formula, envir = .GlobalEnv)
  assign(".cv_rr2_random_formula", components$rr2_random_formula, envir = .GlobalEnv)
  assign(".cv_rfr_random_formula", components$rfr_random_formula, envir = .GlobalEnv)
  assign(".cv_fw1_rr_random_formula", components$fw1_rr_random_formula, envir = .GlobalEnv)
  assign(".cv_fw2_rr_random_formula", components$fw2_rr_random_formula, envir = .GlobalEnv)

  if (model_name == "baseline") {
    fit <- asreml(
      fixed = yld_bu_ac ~ 1,
      random = ~ G + L + Y + Y:L + L:G + Y:G,
      data = .cv_prediction_data,
      na.action = na.method(x = "include")
    )
    return(list(model = fit, scored_data = dat_masked))
  }

  if (model_name == "baseline_ec") {
    fit <- asreml(
      fixed = .cv_ec_fixed_formula,
      random = ~ G + L + Y + Y:L + L:G + Y:G,
      data = .cv_prediction_data,
      na.action = na.method(x = "include")
    )
    return(list(model = fit, scored_data = dat_masked))
  }

  if (model_name == "rrr1") {
    fit <- asreml(
      fixed = .cv_ec_fixed_formula,
      random = .cv_rr1_random_formula,
      data = .cv_prediction_data,
      na.action = na.method(x = "include")
    )
    return(list(model = fit, scored_data = dat_masked))
  }

  if (model_name == "rrr2") {
    fit <- asreml(
      fixed = .cv_ec_fixed_formula,
      random = .cv_rr2_random_formula,
      data = .cv_prediction_data,
      na.action = na.method(x = "include")
    )
    return(list(model = fit, scored_data = dat_masked))
  }

  if (model_name == "rfr_us") {
    fit <- asreml(
      fixed = .cv_ec_fixed_formula,
      random = .cv_rfr_random_formula,
      data = .cv_prediction_data,
      na.action = na.method(x = "include")
    )
    return(list(model = fit, scored_data = dat_masked))
  }

  if (model_name %in% c("fa1", "fa2", "fa3")) {
    asreml.options(maxit = 20, extra = 0, ai.sing = TRUE, fail = "soft")
    fa_rank <- sub("fa", "", model_name, fixed = TRUE)
    assign(
      ".cv_fa_random_formula",
      as.formula(paste0("~ G + ENV + fa(ENV, ", fa_rank, "):G")),
      envir = .GlobalEnv
    )
    fit <- asreml(
      fixed = .cv_ec_fixed_formula,
      random = .cv_fa_random_formula,
      data = .cv_prediction_data,
      na.action = na.method(x = "include")
    )
    return(list(model = fit, scored_data = dat_masked))
  }

  if (model_name == "fw1_us") {
    rr_step <- asreml(
      fixed = yld_bu_ac ~ G + L + Y + Y:L,
      random = .cv_fw1_rr_random_formula,
      data = .cv_prediction_data,
      na.action = na.method(x = "include")
    )

    vc1 <- summary(rr_step)$varcomp
    lambda1 <- vc1[grep("fa", rownames(vc1), fixed = TRUE), "component"]
    lambda1 <- lambda1[seq_len(components$n_ec)]

    env_cov <- unique(dat_masked[, c("ENV", components$ec_terms)])
    z1 <- as.numeric(t(lambda1 %*% t(env_cov[, components$ec_terms])))
    z1_env <- data.frame(ENV = env_cov$ENV, z1 = z1)
    dat_fw1 <- merge(dat_masked, z1_env, by = "ENV")
    assign(".cv_prediction_data_fw1", dat_fw1, envir = .GlobalEnv)

    us_step <- asreml(
      fixed = yld_bu_ac ~ z1,
      random = ~ str(~ G + G:z1, vmodel = ~ us(2):id(G)) + L + Y + Y:L + L:G + Y:G,
      data = .cv_prediction_data_fw1,
      na.action = na.method(x = "include")
    )

    return(list(model = us_step, scored_data = dat_fw1, rr_step = rr_step))
  }

  if (model_name == "fw2_us") {
    rr_step <- asreml(
      fixed = yld_bu_ac ~ G + L + Y + Y:L,
      random = .cv_fw2_rr_random_formula,
      data = .cv_prediction_data,
      na.action = na.method(x = "include")
    )

    vc2 <- summary(rr_step)$varcomp
    lambdas <- vc2[grep("fa", rownames(vc2), fixed = TRUE), "component"]
    lambda_a <- lambdas[1:components$n_ec]
    lambda_b <- lambdas[(components$n_ec + 1):(2 * components$n_ec)]

    env_cov <- unique(dat_masked[, c("ENV", components$ec_terms)])
    z1 <- as.numeric(t(lambda_a %*% t(env_cov[, components$ec_terms])))
    z2 <- as.numeric(t(lambda_b %*% t(env_cov[, components$ec_terms])))
    z_env <- data.frame(ENV = env_cov$ENV, z1 = z1, z2 = z2)
    dat_fw2 <- merge(dat_masked, z_env, by = "ENV")
    assign(".cv_prediction_data_fw2", dat_fw2, envir = .GlobalEnv)

    us_step <- asreml(
      fixed = yld_bu_ac ~ z1 + z2,
      random = ~ str(~ G + G:z1 + G:z2, vmodel = ~ us(3):id(G)) + L + Y + Y:L + L:G + Y:G,
      data = .cv_prediction_data_fw2,
      na.action = na.method(x = "include"),
      maxit = 10000
    )

    return(list(model = us_step, scored_data = dat_fw2, rr_step = rr_step))
  }

  stop("Unknown model name: ", model_name, call. = FALSE)
}

run_one_fold_one_model <- function(dat, fold_row, model_name) {
  fold_id <- fold_row$fold_id[[1]]
  env_id <- fold_row$env_id[[1]]

  dat_masked <- mask_fold_response(dat, env_id)
  components <- make_dynamic_model_components(dat_masked)

  message("  fitting ", model_name, " on held-out env ", env_id)
  fit_obj <- fit_prediction_model(model_name, dat_masked, components)
  message("  predicting ", model_name, " on held-out env ", env_id)
  pred_df <- extract_fold_predictions(
    model = fit_obj$model,
    scored_data = fit_obj$scored_data,
    env_id = env_id,
    model_name = model_name,
    fold_id = fold_id
  )
  metric_df <- score_prediction_rows(pred_df, model_name, fold_id)

  list(predictions = pred_df, metrics = metric_df)
}

run_model_over_folds <- function(model_name, dat, folds) {
  pred_list <- vector("list", nrow(folds))
  metric_list <- vector("list", nrow(folds))

  for (i in seq_len(nrow(folds))) {
    fold_row <- folds[i, , drop = FALSE]
    message("Running ", model_name, " on ", fold_row$fold_id)
    res <- run_one_fold_one_model(dat, fold_row, model_name)
    pred_list[[i]] <- res$predictions
    metric_list[[i]] <- res$metrics
  }

  list(
    predictions = do.call(rbind, pred_list),
    metrics = do.call(rbind, metric_list)
  )
}
