## -----------------------------------------------------------------------------
## Stage 2B: Extract AgERA5 grid data to one daily table per environment
##
## Goal:
## Convert the AgERA5 regional NetCDF downloads into the daily long table
## used by the downstream covariate-building stages.
##
## Why this stage matters:
## AgERA5 is gridded climate data. Our models need environment-specific time
## series. So this stage does the grid-to-environment matching.
##
## Matching logic:
## - read yearly AgERA5 NetCDF files
## - for each environment, select the nearest AgERA5 grid cell
## - keep only the dates inside that environment's planting-to-harvest window
## - build one combined daily table with standardized column names
##
## Requirements:
## - reticulate must be available
## - bundled Python environment must have xarray, pandas, numpy, netCDF4
##
## Inputs:
## - analysis/outputs/01_environments_G2F.csv
## - analysis/outputs/agera5_raw/*.nc
## - analysis/outputs/agera5_raw/agera5_manifest.csv
##
## Output:
## - analysis/outputs/02_daily_weather_G2F.csv
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/pre-processing/00_paths_and_helpers.R")

ensure_package("reticulate")
library(reticulate)

python_bin <- "/Users/neon/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3"
Sys.setenv(RETICULATE_PYTHON = python_bin)
use_python(python_bin, required = TRUE)

pd <- import("pandas")
xr <- import("xarray")

env_path <- file.path(output_dir, "01_environments_G2F.csv")
manifest_path <- file.path(output_dir, "agera5_raw", "agera5_manifest.csv")

env_info <- read.csv(env_path)
manifest <- read.csv(manifest_path)

env_info$planting.date <- as.Date(env_info$planting.date)
env_info$harvest.date <- as.Date(env_info$harvest.date)

detect_coord_name <- function(names_vec, candidates) {
  hit <- candidates[candidates %in% names_vec]
  if (length(hit) == 0) stop("Could not detect required coordinate name.")
  hit[[1]]
}

extract_for_environment <- function(nc_path, env_row, output_column) {
  ds <- xr$open_dataset(nc_path)
  on.exit(ds$close(), add = TRUE)

  coord_names <- py_to_r(ds$coords$keys())
  lat_name <- detect_coord_name(coord_names, c("lat", "latitude"))
  lon_name <- detect_coord_name(coord_names, c("lon", "longitude"))
  time_name <- detect_coord_name(coord_names, c("time", "valid_time"))

  var_name <- py_to_r(ds$data_vars$keys())[[1]]

  selector <- setNames(
    list(env_row$latitude, env_row$longitude),
    c(lat_name, lon_name)
  )
  sub <- ds$sel(selector, method = "nearest")

  # Convert only the selected point series to a small dataframe.
  df_py <- sub[[var_name]]$to_dataframe()$reset_index()
  df <- py_to_r(df_py)

  value_name <- setdiff(names(df), c(time_name, lat_name, lon_name))
  if (length(value_name) != 1) {
    stop("Expected exactly one AgERA5 value column after point extraction.")
  }

  names(df)[names(df) == value_name] <- output_column
  names(df)[names(df) == time_name] <- "date"
  names(df)[names(df) == lat_name] <- "grid_latitude"
  names(df)[names(df) == lon_name] <- "grid_longitude"

  df$date <- as.Date(df$date)
  df <- df[df$date >= env_row$planting.date & df$date <= env_row$harvest.date, ]

  df$env_id <- env_row$env_id
  df$year <- env_row$year
  df$location <- env_row$location
  df$latitude <- env_row$latitude
  df$longitude <- env_row$longitude
  df$planting.date <- env_row$planting.date
  df$harvest.date <- env_row$harvest.date

  df
}

base_daily <- do.call(
  rbind,
  lapply(seq_len(nrow(env_info)), function(i) {
    row <- env_info[i, ]
    data.frame(
      env_id = row$env_id,
      year = row$year,
      location = row$location,
      date = seq.Date(row$planting.date, row$harvest.date, by = "day"),
      latitude = row$latitude,
      longitude = row$longitude,
      planting.date = row$planting.date,
      harvest.date = row$harvest.date,
      stringsAsFactors = FALSE
    )
  })
)

daily_weather <- base_daily

for (i in seq_len(nrow(manifest))) {
  item <- manifest[i, ]
  message("Extracting ", basename(item$file), " (", i, "/", nrow(manifest), ")")

  env_subset <- env_info[env_info$year == item$year, ]

  extracted_list <- lapply(seq_len(nrow(env_subset)), function(j) {
    extract_for_environment(
      nc_path = item$file,
      env_row = env_subset[j, ],
      output_column = item$output_column
    )
  })

  extracted <- do.call(rbind, extracted_list)

  keep_cols <- c("env_id", "date", item$output_column)
  daily_weather <- merge(
    daily_weather,
    extracted[, keep_cols, drop = FALSE],
    by = c("env_id", "date"),
    all.x = TRUE
  )
}

write.csv(
  daily_weather,
  file.path(output_dir, "02_daily_weather_G2F.csv"),
  row.names = FALSE
)

message("Wrote outputs/02_daily_weather_G2F.csv from AgERA5")
