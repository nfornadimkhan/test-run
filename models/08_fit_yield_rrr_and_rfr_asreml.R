## -----------------------------------------------------------------------------
## Stage 8: Fit richer ASReml GxE regression models for yield
##
## Goal:
## Move from fixed EC effects to genotype-specific EC response structures.
##
## Models in this stage:
## - RRR1 : reduced-rank regression with one latent response axis
## - RRR2 : reduced-rank regression with two latent response axes
## - RFR  : random factorial regression with an unstructured covariance matrix
##
## Why this stage matters:
## The paper's key question is not whether ECs matter at all.
## It is whether genotype response to ECs is better represented by:
## - a compressed latent structure (`RRR`), or
## - a fully flexible covariance structure (`RFR`)
##
## Important practical point:
## On real data, `RFR` is usually harder to fit than `RRR`.
## If `RFR` shows restraints, unstable jumps, or weakly identified covariance
## elements, that is not a failure of the teaching script. It is the exact
## phenomenon the paper warns about.
##
## Outputs:
## - rr1_yield_asreml.rds
## - rr2_yield_asreml.rds
## - rfr_yield_asreml.rds
## - 08_yield_rrr_rfr_metrics.csv
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/pre-processing/00_paths_and_helpers.R")

ensure_package("asreml")
library(asreml)

asreml_yield_dir <- file.path(output_dir, "asreml_yield")
ensure_dir(asreml_yield_dir)

dat <- read.csv(file.path(asreml_yield_dir, "06_yield_asreml_input.csv"))
dat$G <- factor(dat$G)
dat$L <- factor(dat$L)
dat$Y <- factor(dat$Y)
dat$ENV <- factor(dat$ENV)

asreml.options(maxit = 40, extra = 2)

ec_terms <- detect_available_ec_aliases(dat)
ec_fixed_formula <- make_observed_ec_formula("yld_bu_ac", ec_aliases = ec_terms)
n_ec <- length(ec_terms)
rr_dimension <- n_ec + 1
rr1_terms <- c("G", paste0("G:", ec_terms), "G:x0")
rr2_terms <- c(paste0("G:", ec_terms), "G:z0", "G:x0", "G:x00")
rfr_terms <- c("G", paste0("G:", ec_terms))

rr1_random_formula <- as.formula(
  paste0(
    "~ str(~ ",
    paste(rr1_terms, collapse = " + "),
    ", vmodel = ~ rr(",
    rr_dimension,
    ", 1):id(G)) + L + Y + Y:L + L:G + Y:G"
  )
)

rr2_random_formula <- as.formula(
  paste0(
    "~ str(~ ",
    paste(rr2_terms, collapse = " + "),
    ", vmodel = ~ rr(",
    rr_dimension,
    ", 2):id(G)) + L + Y + Y:L + L:G + Y:G"
  )
)

rfr_random_formula <- as.formula(
  paste0(
    "~ str(~ ",
    paste(rfr_terms, collapse = " + "),
    ", vmodel = ~ us(",
    rr_dimension,
    "):id(G)) + L + Y + Y:L + L:G + Y:G"
  )
)

# RRR1:
# The dummy covariate x0 = 0 is used because the ASReml rr() setup expects one
# extra placeholder term in this parameterization.
rr1 <- asreml(
  fixed = ec_fixed_formula,
  random = rr1_random_formula,
  data = dat,
  na.action = na.method(x = "include"),
  wald = list(denDF = "algebraic")
)

# RRR2:
# The second reduced-rank model needs the extra z0/x0/x00 placeholders, matching
# the logic in the paper's example code.
rr2 <- try(
  asreml(
    fixed = ec_fixed_formula,
    random = rr2_random_formula,
    data = dat,
    na.action = na.method(x = "include"),
    wald = list(denDF = "algebraic")
  ),
  silent = TRUE
)

# RFR / US:
# This is the richest observed-covariate response model.
# It often converges more slowly and may leave some covariance elements weakly
# estimated. That is a substantive modeling lesson, not just a software detail.
rfr <- try(
  asreml(
    fixed = ec_fixed_formula,
    random = rfr_random_formula,
    data = dat,
    na.action = na.method(x = "include"),
    wald = list(denDF = "algebraic")
  ),
  silent = TRUE
)

saveRDS(rr1, file.path(asreml_yield_dir, "rr1_yield_asreml.rds"))

metrics_list <- list(
  extract_asreml_metrics(rr1, "rrr1", nobs_used = nrow(dat))
)

if (!inherits(rr2, "try-error")) {
  saveRDS(rr2, file.path(asreml_yield_dir, "rr2_yield_asreml.rds"))
  metrics_list[[length(metrics_list) + 1]] <- extract_asreml_metrics(rr2, "rrr2", nobs_used = nrow(dat))
}

if (!inherits(rfr, "try-error")) {
  saveRDS(rfr, file.path(asreml_yield_dir, "rfr_yield_asreml.rds"))
  metrics_list[[length(metrics_list) + 1]] <- extract_asreml_metrics(rfr, "rfr_us", nobs_used = nrow(dat))
}

metrics <- do.call(rbind, metrics_list)

write.csv(
  metrics,
  file.path(asreml_yield_dir, "08_yield_rrr_rfr_metrics.csv"),
  row.names = FALSE
)

message("Saved richer ASReml yield fits")
print(metrics)

if (inherits(rr2, "try-error")) {
  message("RRR2 did not finish successfully in this run.")
}

if (inherits(rfr, "try-error")) {
  message("RFR / US did not finish successfully in this run.")
}
