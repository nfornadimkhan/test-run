## -----------------------------------------------------------------------------
## Stage 0: Shared paths and helper functions
##
## Why this file exists:
## Every later script in this workflow needs the same folder paths and a few
## small utility functions. Instead of rewriting them in every file, we define
## them once here and source this file at the top of each stage script.
##
## Main ideas:
## - keep all input, script, and output folders centralized
## - define one consistent environment identifier
## - use safe summary functions that handle missing values
## - define a maize-specific growing-degree-day calculator
## - define maize biological stage windows from cumulative thermal time
## -----------------------------------------------------------------------------

options(stringsAsFactors = FALSE)

analysis_dir <- "/Users/neon/Documents/Nadim's Brain/analysis"
data_dir <- file.path(analysis_dir, "data")
scripts_dir <- file.path(analysis_dir, "scripts")
output_dir <- file.path(analysis_dir, "outputs")

if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

ensure_package <- function(pkg) {
  # Install a package only if it is missing.
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

make_env_id <- function(year, location) {
  # Environment = one specific year-location combination.
  paste(year, location, sep = "_")
}

safe_mean <- function(x) {
  # Mean that returns NA instead of failing on empty input.
  x <- x[!is.na(x)]
  if (length(x) == 0) return(NA_real_)
  mean(x)
}

safe_sum <- function(x) {
  # Sum that returns NA instead of 0 for completely missing input.
  x <- x[!is.na(x)]
  if (length(x) == 0) return(NA_real_)
  sum(x)
}

safe_count <- function(x) {
  # Count non-missing observations.
  x <- x[!is.na(x)]
  length(x)
}

ensure_dir <- function(path) {
  # Create a directory only if it does not exist yet.
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE)
  }
}

assert_required_columns <- function(df, required_cols, object_name = "data frame") {
  missing_cols <- setdiff(required_cols, names(df))
  if (length(missing_cols) > 0) {
    stop(
      paste0(
        object_name,
        " is missing required columns: ",
        paste(missing_cols, collapse = ", "),
        ". Rerun the upstream stage that is supposed to create them."
      ),
      call. = FALSE
    )
  }
}

extract_asreml_metrics <- function(model, model_name, nobs_used = NA_integer_) {
  # ASReml objects do not expose base-R logLik/AIC methods directly.
  # We therefore record:
  # - the fitted log-likelihood from the model object,
  # - residual variance (sigma2),
  # - counts of fixed and variance parameters,
  # - a simple information-criterion approximation built from those counts.
  #
  # This is enough for teaching model comparison and for tracking whether
  # richer covariance structures are actually buying likelihood improvement.
  vc <- summary(model)$varcomp
  n_fixed <- length(model$coefficients$fixed)
  n_varcomp <- nrow(vc)
  k_total <- n_fixed + n_varcomp
  loglik <- model$loglik
  data.frame(
    model = model_name,
    loglik = loglik,
    sigma2 = model$sigma2,
    n_fixed = n_fixed,
    n_varcomp = n_varcomp,
    k_total = k_total,
    approx_AIC = -2 * loglik + 2 * k_total,
    approx_BIC = if (is.na(nobs_used)) NA_real_ else -2 * loglik + log(nobs_used) * k_total,
    stringsAsFactors = FALSE
  )
}

stabilize_asreml_fit <- function(model, max_updates = 10, tol = 1e-5, stop_if_loglik_drops = TRUE) {
  # Some richer ASReml models stop with mild non-convergence warnings even when
  # they are already close to the optimum. This helper performs a few cautious
  # update() calls and keeps the best successful fit encountered.
  best_model <- model
  best_loglik <- model$loglik

  for (i in seq_len(max_updates)) {
    updated <- try(update(best_model), silent = TRUE)
    if (inherits(updated, "try-error")) {
      break
    }

    new_loglik <- updated$loglik
    if (isTRUE(stop_if_loglik_drops) && !is.na(new_loglik) && !is.na(best_loglik) && new_loglik < best_loglik - tol) {
      break
    }

    best_model <- updated

    if (!is.na(new_loglik) && !is.na(best_loglik) && abs(new_loglik - best_loglik) < tol) {
      best_loglik <- new_loglik
      break
    }

    best_loglik <- new_loglik
  }

  best_model
}

calc_gdd <- function(tmax, tmin, base_temp = 10, upper_temp = 30) {
  # Maize-specific capped growing degree day calculation.
  #
  # This is the Celsius version of the common maize 86/50 F method:
  # - lower threshold = 10 C
  # - upper threshold = 30 C
  #
  # Daily steps:
  # 1. cap Tmax at the upper threshold
  # 2. raise Tmin up to the base threshold if it is lower
  # 3. average the adjusted Tmax and Tmin
  # 4. subtract the base temperature
  # 5. truncate negative values to zero
  #
  # Formula:
  #   Tmax* = min(Tmax, 30)
  #   Tmin* = max(Tmin, 10)
  #   GDD_d = max(((Tmax* + Tmin*) / 2) - 10, 0)
  tmax_adj <- pmin(tmax, upper_temp)
  tmin_adj <- pmax(tmin, base_temp)
  tmean_adj <- (tmax_adj + tmin_adj) / 2
  pmax(tmean_adj - base_temp, 0)
}

maize_stage_breakpoints_c <- list(
  # These thresholds are based on extension corn-stage GDD references typically
  # reported in Fahrenheit GDD units and converted here to Celsius GDD units
  # by multiplying by 5/9.
  #
  # Approximate average stage thresholds from a Delaware extension table:
  # V6  = 556 F-GDD  -> 308.9 C-GDD
  # R1  = 1486 F-GDD -> 825.6 C-GDD
  # R3  = 1891 F-GDD -> 1050.6 C-GDD
  # R6  = 2824 F-GDD -> 1568.9 C-GDD
  #
  # We use them to form broader biologically meaningful windows:
  # - early vegetative: emergence through V6
  # - late vegetative: after V6 up to silking (R1)
  # - flowering: silking through early kernel set up to R3
  # - grain fill: after R3 through maturity
  V6 = 556 * 5 / 9,
  R1 = 1486 * 5 / 9,
  R3 = 1891 * 5 / 9,
  R6 = 2824 * 5 / 9
)

assign_maize_biological_windows <- function(cumulative_gdd_c) {
  bp <- maize_stage_breakpoints_c
  ifelse(
    cumulative_gdd_c <= bp$V6,
    "early_vegetative",
    ifelse(
      cumulative_gdd_c <= bp$R1,
      "late_vegetative",
      ifelse(
        cumulative_gdd_c <= bp$R3,
        "flowering",
        "grain_fill"
      )
    )
  )
}

observed_ec_base_cols <- c(
  "MeanTemp_season",
  "MaxTemp_mean_season",
  "MinTemp_mean_season",
  "RainSum_season",
  "RadMean_season",
  "ET0Sum_season",
  "VPDMax_mean_season",
  "RHDerivedMin_mean_season"
)

observed_ec_aliases <- paste0("EC", seq_along(observed_ec_base_cols))

detect_available_ec_aliases <- function(df, max_ec = 8) {
  # During the AgERA5 migration we may temporarily have older Stage 6 outputs
  # with only EC1..EC5. This helper lets the model scripts use whatever EC
  # block is actually present instead of failing immediately.
  aliases <- paste0("EC", seq_len(max_ec))
  present <- aliases[aliases %in% names(df)]
  if (length(present) == 0) {
    stop("No EC columns found in the input table.", call. = FALSE)
  }
  present
}

make_observed_ec_formula <- function(response, include_intercept = TRUE, ec_aliases = observed_ec_aliases) {
  # Build formulas like:
  #   y ~ EC1 + EC2 + ... + EC8
  # so later model scripts do not need to hard-code the number of ECs.
  rhs <- paste(ec_aliases, collapse = " + ")
  if (!include_intercept) {
    rhs <- paste("0 +", rhs)
  }
  as.formula(paste(response, "~", rhs))
}

make_gxe_term_vector <- function(ec_aliases = observed_ec_aliases, prefix = "G", include_intercept_term = FALSE) {
  # Build vectors like:
  #   G:EC1, G:EC2, ..., G:EC8
  # which are then reused in RRR, RFR, and FW model formulas.
  terms <- paste0(prefix, ":", ec_aliases)
  if (include_intercept_term) {
    terms <- c(paste0(prefix), terms)
  }
  terms
}
