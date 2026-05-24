## -----------------------------------------------------------------------------
## Stage 6: Prepare a trait-specific ASReml input table for yield
##
## Goal:
## Turn the merged analysis-ready table into a cleaner dataset for reproducing
## the model-comparison workflow from the GxE regression paper using ASReml.
##
## Why this stage exists:
## The paper compares model families on one trait at a time.
## We follow the same logic here and begin with maize yield (`yld_bu_ac`).
##
## Why we start with the basic season-level covariates:
## - the paper's main comparison starts from observed environment covariates
## - we currently have 22 environments, so we keep the model on season-level ECs
##   rather than jumping straight to the much larger stagewise table
## - once this works, the same logic can be extended to stagewise ECs later
##
## Output files:
## - analysis/outputs/asreml_yield/06_yield_asreml_input.csv
## - analysis/outputs/asreml_yield/06_yield_env_covariates_scaled.csv
##
## Selected observed environmental covariates:
## EC1 = MeanTemp_season
## EC2 = MaxTemp_mean_season
## EC3 = MinTemp_mean_season
## EC4 = RainSum_season
## EC5 = RadMean_season
## EC6 = ET0Sum_season
## EC7 = VPDMax_mean_season
## EC8 = RHDerivedMin_mean_season
##
## These are scaled at the environment level, not row by row.
## That matters because environments are the objects carrying the covariates.
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/pre-processing/00_paths_and_helpers.R")

asreml_yield_dir <- file.path(output_dir, "asreml_yield")
ensure_dir(asreml_yield_dir)

input_path <- file.path(output_dir, "05_G2F_analysis_ready_basic.csv")
dat <- read.csv(input_path)
assert_required_columns(
  dat,
  c("env_id", "year", "location", "geno_ID", "yld_bu_ac", observed_ec_base_cols),
  object_name = "Stage 5 merged analysis table"
)

# Keep only rows where the target trait is observed.
dat <- dat[!is.na(dat$yld_bu_ac), ]

# Build a one-row-per-environment table for scaling environmental covariates.
# These are the observed season-level ECs that later models will regress on.
env_cov <- unique(dat[, c("env_id", "year", "location", observed_ec_base_cols)])

# Scale the observed ECs across environments.
# This mirrors the logic in the paper, where the EC table is standardized before
# richer regression structures are fitted and compared.
scale_cols <- observed_ec_base_cols

for (v in scale_cols) {
  env_cov[[paste0(v, "_sc")]] <- as.numeric(scale(env_cov[[v]]))
}

# Create EC1..EC8 aliases so the later ASReml scripts can follow the same model
# notation as the paper and its example code while still keeping human-readable
# covariate names in the data.
for (i in seq_along(observed_ec_base_cols)) {
  raw_name <- observed_ec_base_cols[[i]]
  env_cov[[observed_ec_aliases[[i]]]] <- env_cov[[paste0(raw_name, "_sc")]]
}

# Merge the environment-level scaled ECs back onto the phenotype rows.
keep_env_cols <- c(
  "env_id",
  observed_ec_aliases,
  paste0(observed_ec_base_cols, "_sc")
)
dat2 <- merge(dat, env_cov[, keep_env_cols], by = "env_id", all.x = TRUE)

# Build factors and dummy variables used by the ASReml model families.
dat2$G <- factor(dat2$geno_ID)
dat2$L <- factor(dat2$location)
dat2$Y <- factor(dat2$year)
dat2$ENV <- factor(dat2$env_id)
dat2$x0 <- 0
dat2$x00 <- 0
dat2$z0 <- 1

write.csv(
  dat2,
  file.path(asreml_yield_dir, "06_yield_asreml_input.csv"),
  row.names = FALSE
)

write.csv(
  env_cov,
  file.path(asreml_yield_dir, "06_yield_env_covariates_scaled.csv"),
  row.names = FALSE
)

message("Wrote outputs/asreml_yield/06_yield_asreml_input.csv")
message("Wrote outputs/asreml_yield/06_yield_env_covariates_scaled.csv")
