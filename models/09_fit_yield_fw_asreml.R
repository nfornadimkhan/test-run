## -----------------------------------------------------------------------------
## Stage 9: Fit synthetic-covariate FW models for yield
##
## Goal:
## Reproduce the paper's two-step synthetic-covariate idea in ASReml.
##
## What happens here:
## Step 1: derive synthetic environmental scores from observed ECs
## Step 2: fit genotype response on those synthetic scores with an
##         unstructured covariance model
##
## Models:
## - FW1-US : one synthetic environmental score
## - FW2-US : two synthetic environmental scores
##
## Why this is advanced:
## This stage is conceptually important but numerically heavier than the earlier
## models. It is normal for these fits to need more iterations or to be less
## stable than baseline or RRR models.
##
## Outputs:
## - fw1_rr_step_yield_asreml.rds
## - fw1_us_step_yield_asreml.rds
## - fw2_rr_step_yield_asreml.rds
## - fw2_us_step_yield_asreml.rds   (only if the fit succeeds)
## - 09_yield_fw_metrics.csv
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

asreml.options(maxit = 60, extra = 2)

ec_terms <- detect_available_ec_aliases(dat)
ec_fixed_formula <- make_observed_ec_formula("yld_bu_ac", ec_aliases = ec_terms)
n_ec <- length(ec_terms)
fw1_rr_terms <- c(paste0("G:", ec_terms), "G:x0")
fw2_rr_terms <- c(paste0("G:", ec_terms), "G:x0", "G:x00")

fw1_rr_random_formula <- as.formula(
  paste0(
    "~ L:G + Y:G + str(~ ",
    paste(fw1_rr_terms, collapse = " + "),
    ", vmodel = ~ rr(",
    n_ec,
    ", 1):id(G))"
  )
)

fw2_rr_random_formula <- as.formula(
  paste0(
    "~ L:G + Y:G + str(~ ",
    paste(fw2_rr_terms, collapse = " + "),
    ", vmodel = ~ rr(",
    n_ec,
    ", 2):id(G))"
  )
)

FW_1_rr_step <- asreml(
  fixed = yld_bu_ac ~ G + L + Y + Y:L,
  random = fw1_rr_random_formula,
  data = dat,
  na.action = na.method(x = "include"),
  wald = list(denDF = "algebraic")
)

vc1 <- summary(FW_1_rr_step)$varcomp
lambda1 <- vc1[grep("fa", rownames(vc1), fixed = TRUE), "component"]

env_cov <- unique(dat[, c("ENV", ec_terms)])
z1 <- as.numeric(t(lambda1 %*% t(env_cov[, ec_terms])))
z1_env <- data.frame(ENV = env_cov$ENV, z1 = z1)
dat_fw1 <- merge(dat, z1_env, by = "ENV")

FW_1_us_step <- asreml(
  fixed = yld_bu_ac ~ z1,
  random = ~ str(~ G + G:z1, vmodel = ~ us(2):id(G)) + L + Y + Y:L + L:G + Y:G,
  data = dat_fw1,
  na.action = na.method(x = "include"),
  wald = list(denDF = "algebraic")
)

FW_2_rr_step <- asreml(
  fixed = yld_bu_ac ~ G + L + Y + Y:L,
  random = fw2_rr_random_formula,
  data = dat,
  na.action = na.method(x = "include"),
  wald = list(denDF = "algebraic")
)

vc2 <- summary(FW_2_rr_step)$varcomp
lambdas <- vc2[grep("fa", rownames(vc2), fixed = TRUE), "component"]
lambda_a <- lambdas[1:n_ec]
lambda_b <- lambdas[(n_ec + 1):(2 * n_ec)]
z1_fw2 <- as.numeric(t(lambda_a %*% t(env_cov[, ec_terms])))
z2_fw2 <- as.numeric(t(lambda_b %*% t(env_cov[, ec_terms])))
z_env <- data.frame(ENV = env_cov$ENV, z1 = z1_fw2, z2 = z2_fw2)
dat_fw2 <- merge(dat, z_env, by = "ENV")

FW_2_us_step <- try(
  asreml(
    fixed = yld_bu_ac ~ z1 + z2,
    random = ~ str(~ G + G:z1 + G:z2, vmodel = ~ us(3):id(G)) + L + Y + Y:L + L:G + Y:G,
    data = dat_fw2,
    na.action = na.method(x = "include"),
    wald = list(denDF = "algebraic"),
    maxit = 10000
  ),
  silent = TRUE
)

saveRDS(FW_1_rr_step, file.path(asreml_yield_dir, "fw1_rr_step_yield_asreml.rds"))
saveRDS(FW_1_us_step, file.path(asreml_yield_dir, "fw1_us_step_yield_asreml.rds"))
saveRDS(FW_2_rr_step, file.path(asreml_yield_dir, "fw2_rr_step_yield_asreml.rds"))

metrics_list <- list(
  extract_asreml_metrics(FW_1_rr_step, "fw1_rr_step", nobs_used = nrow(dat)),
  extract_asreml_metrics(FW_1_us_step, "fw1_us_step", nobs_used = nrow(dat_fw1)),
  extract_asreml_metrics(FW_2_rr_step, "fw2_rr_step", nobs_used = nrow(dat))
)

if (!inherits(FW_2_us_step, "try-error")) {
  saveRDS(FW_2_us_step, file.path(asreml_yield_dir, "fw2_us_step_yield_asreml.rds"))
  metrics_list[[length(metrics_list) + 1]] <- extract_asreml_metrics(FW_2_us_step, "fw2_us_step", nobs_used = nrow(dat_fw2))
}

metrics <- do.call(rbind, metrics_list)

write.csv(
  metrics,
  file.path(asreml_yield_dir, "09_yield_fw_metrics.csv"),
  row.names = FALSE
)

message("Saved synthetic-covariate FW ASReml fits for yield")
print(metrics)

if (inherits(FW_2_us_step, "try-error")) {
  message("FW2-US did not finish successfully in this run.")
}
