## -----------------------------------------------------------------------------
## Stage 1: Define environments
##
## Goal:
## Build one clean environment table where each row represents a unique
## year-location combination.
##
## Why this stage matters:
## Weather is fetched at the environment level, not at the genotype row level.
## So before downloading weather, we must know exactly what each environment is.
##
## Input:
## - analysis/data/info_environments_G2F.csv
##
## Output:
## - analysis/outputs/01_environments_G2F.csv
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/pre-processing/00_paths_and_helpers.R")

info_path <- file.path(data_dir, "info_environments_G2F.csv")
env_info <- read.csv(info_path)

# Clean and standardize key fields so later joins and API calls are consistent.
env_info$year <- as.integer(env_info$year)
env_info$location <- trimws(env_info$location)
env_info$planting.date <- as.Date(env_info$planting.date)
env_info$harvest.date <- as.Date(env_info$harvest.date)
env_info$env_id <- make_env_id(env_info$year, env_info$location)

# Sort for readability and remove any accidental duplicated environment entries.
env_info <- env_info[order(env_info$year, env_info$location), ]
env_info <- env_info[!duplicated(env_info$env_id), ]

# Crop duration will later help us interpret season length and weather windows.
env_info$season_length_days <- as.integer(env_info$harvest.date - env_info$planting.date) + 1L

# Check whether any environment is missing the fields required to fetch weather.
check_cols <- c("env_id", "year", "location", "latitude", "longitude", "planting.date", "harvest.date")
missing_any <- env_info[!complete.cases(env_info[, check_cols]), check_cols]

message("Number of unique environments: ", nrow(env_info))
message("Any environments with missing key fields: ", nrow(missing_any))

write.csv(
  env_info,
  file.path(output_dir, "01_environments_G2F.csv"),
  row.names = FALSE
)

message("Wrote outputs/01_environments_G2F.csv")
