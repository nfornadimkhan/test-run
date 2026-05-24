## -----------------------------------------------------------------------------
## Stage 7: Fit the first two ASReml yield models
##
## Goal:
## Reproduce the paper's opening comparison on the maize yield data:
## 1. baseline model without explicit EC main effects
## 2. baseline model with fixed EC main effects
##
## Why start here:
## These two models teach the backbone of the whole study.
## Everything richer later asks:
## "Do genotype-specific EC responses improve on this backbone?"
##
## Backbone used here:
## random = G + L + Y + Y:L + L:G + Y:G
##
## Interpretation:
## - G     : overall genotype differences
## - L     : location differences
## - Y     : year differences
## - Y:L   : environment differences not explained by year or location alone
## - L:G   : genotype response specific to location
## - Y:G   : genotype response specific to year
##
## Outputs:
## - baseline_yield_asreml.rds
## - baseline_ec_yield_asreml.rds
## - 07_yield_baseline_metrics.csv
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
ec_terms <- detect_available_ec_aliases(dat)

# Keep ASReml behavior close to the paper examples:
# - allow a few extra iterations
# - use algebraic denominator DF for teaching-oriented Wald output
asreml.options(maxit = 40, extra = 2)

baseline <- asreml(
  fixed = yld_bu_ac ~ 1,
  random = ~ G + L + Y + Y:L + L:G + Y:G,
  data = dat,
  na.action = na.method(x = "include"),
  wald = list(denDF = "algebraic")
)

ec_fixed_formula <- make_observed_ec_formula("yld_bu_ac", ec_aliases = ec_terms)

baseline_ec <- asreml(
  fixed = ec_fixed_formula,
  random = ~ G + L + Y + Y:L + L:G + Y:G,
  data = dat,
  na.action = na.method(x = "include"),
  wald = list(denDF = "algebraic")
)

saveRDS(baseline, file.path(asreml_yield_dir, "baseline_yield_asreml.rds"))
saveRDS(baseline_ec, file.path(asreml_yield_dir, "baseline_ec_yield_asreml.rds"))

metrics <- rbind(
  extract_asreml_metrics(baseline, "baseline", nobs_used = nrow(dat)),
  extract_asreml_metrics(baseline_ec, "baseline_ec", nobs_used = nrow(dat))
)

write.csv(
  metrics,
  file.path(asreml_yield_dir, "07_yield_baseline_metrics.csv"),
  row.names = FALSE
)

message("Saved baseline and baseline_EC ASReml fits for yield")
print(metrics)
print(wald(baseline_ec))
