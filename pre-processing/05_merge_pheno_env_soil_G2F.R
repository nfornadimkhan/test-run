## -----------------------------------------------------------------------------
## Stage 5: Merge phenotype, environment covariates, and soil
##
## Goal:
## Create modelling-ready tables where each phenotype row now also has the
## environmental and soil descriptors of its environment.
##
## Why this stage matters:
## Up to now we worked at the environment level. But phenotype is recorded at
## the genotype-in-environment level. This script brings those pieces together.
##
## Two outputs are created:
## - one using basic season-level covariates
## - one using stage-window covariates
##
## Inputs:
## - analysis/data/pheno_G2F.csv
## - analysis/data/soil_G2F.csv
## - analysis/outputs/01_environments_G2F.csv
## - analysis/outputs/03_environment_covariates_basic_G2F.csv
## - analysis/outputs/04_environment_covariates_stagewise_G2F.csv
##
## Outputs:
## - analysis/outputs/05_G2F_analysis_ready_basic.csv
## - analysis/outputs/05_G2F_analysis_ready_stagewise.csv
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/pre-processing/00_paths_and_helpers.R")

pheno <- read.csv(file.path(data_dir, "pheno_G2F.csv"))
info_env <- read.csv(file.path(output_dir, "01_environments_G2F.csv"))
soil <- read.csv(file.path(data_dir, "soil_G2F.csv"))
basic_cov <- read.csv(file.path(output_dir, "03_environment_covariates_basic_G2F.csv"))
stage_cov <- read.csv(file.path(output_dir, "04_environment_covariates_stagewise_G2F.csv"))

pheno$env_id <- make_env_id(pheno$year, pheno$location)
soil$env_id <- make_env_id(soil$year, soil$location)

# Merge phenotype with season-level environment covariates, then add soil.
basic_ready <- merge(pheno, basic_cov, by = c("env_id", "year", "location"), all.x = TRUE)
basic_ready <- merge(basic_ready, soil, by = c("env_id", "year", "location"), all.x = TRUE)

# Merge phenotype with stagewise environment covariates, then add soil.
stage_ready <- merge(pheno, stage_cov, by = c("env_id", "year", "location"), all.x = TRUE)
stage_ready <- merge(stage_ready, soil, by = c("env_id", "year", "location"), all.x = TRUE)

write.csv(
  basic_ready,
  file.path(output_dir, "05_G2F_analysis_ready_basic.csv"),
  row.names = FALSE
)

write.csv(
  stage_ready,
  file.path(output_dir, "05_G2F_analysis_ready_stagewise.csv"),
  row.names = FALSE
)

message("Wrote outputs/05_G2F_analysis_ready_basic.csv")
message("Wrote outputs/05_G2F_analysis_ready_stagewise.csv")
