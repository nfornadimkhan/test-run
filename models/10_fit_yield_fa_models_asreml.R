## -----------------------------------------------------------------------------
## Stage 10: Fit factor-analytic ASReml yield models
##
## Goal:
## Compare latent GEI structures FA1, FA2, and FA3 against the observed-EC
## regression models already fitted in earlier stages.
##
## Important interpretation note:
## These FA models infer latent environment structure from the GxE pattern
## itself. They do not use observed ECs to build genotype-specific slopes the
## way RRR/RFR do.
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/pre-processing/00_paths_and_helpers.R")

ensure_package("asreml")
library(asreml)

asreml_yield_dir <- file.path(output_dir, "asreml_yield")
ensure_dir(asreml_yield_dir)

dat <- read.csv(file.path(asreml_yield_dir, "06_yield_asreml_input.csv"))
assert_required_columns(dat, c("yld_bu_ac", "G", "ENV"), object_name = "Stage 6 ASReml yield input")

dat$G <- factor(dat$G)
dat$ENV <- factor(dat$ENV)

ec_terms <- detect_available_ec_aliases(dat)
ec_fixed_formula <- make_observed_ec_formula("yld_bu_ac", ec_aliases = ec_terms)

asreml.options(maxit = 80, extra = 4, ai.sing = TRUE, fail = "soft")

fit_fa_model <- function(rank_k) {
  raw_fit <- asreml(
    fixed = ec_fixed_formula,
    random = as.formula(paste0("~ G + ENV + fa(ENV, ", rank_k, "):G")),
    data = dat,
    na.action = na.method(x = "include"),
    wald = list(denDF = "algebraic")
  )

  stabilize_asreml_fit(raw_fit, max_updates = 8, tol = 1e-5)
}

fa1 <- fit_fa_model(1)
fa2 <- fit_fa_model(2)
fa3 <- fit_fa_model(3)

saveRDS(fa1, file.path(asreml_yield_dir, "fa1_yield_asreml.rds"))
saveRDS(fa2, file.path(asreml_yield_dir, "fa2_yield_asreml.rds"))
saveRDS(fa3, file.path(asreml_yield_dir, "fa3_yield_asreml.rds"))

fa_metrics <- do.call(
  rbind,
  list(
    extract_asreml_metrics(fa1, "fa1", nobs_used = nrow(dat)),
    extract_asreml_metrics(fa2, "fa2", nobs_used = nrow(dat)),
    extract_asreml_metrics(fa3, "fa3", nobs_used = nrow(dat))
  )
)

write.csv(
  fa_metrics,
  file.path(asreml_yield_dir, "10_yield_fa_metrics.csv"),
  row.names = FALSE
)

existing_metrics <- list()
for (metrics_file in c("07_yield_baseline_metrics.csv", "08_yield_rrr_rfr_metrics.csv", "09_yield_fw_metrics.csv")) {
  full_path <- file.path(asreml_yield_dir, metrics_file)
  if (file.exists(full_path)) {
    existing_metrics[[length(existing_metrics) + 1]] <- read.csv(full_path)
  }
}

comparison <- do.call(rbind, c(existing_metrics, list(fa_metrics)))
comparison <- comparison[!comparison$model %in% c("fw1_rr_step", "fw2_rr_step"), , drop = FALSE]
comparison <- comparison[order(comparison$approx_AIC), ]

write.csv(
  comparison,
  file.path(asreml_yield_dir, "10_yield_model_comparison_with_fa.csv"),
  row.names = FALSE
)

message("Saved FA1/FA2/FA3 ASReml yield fits")
print(fa_metrics)
