## -----------------------------------------------------------------------------
## Stage 4: Build stage-window environmental covariates
##
## Goal:
## Summarize weather separately for simple crop windows rather than only across
## the full season.
##
## Why this stage matters:
## In real GxE work, timing matters. Heat during flowering can matter more than
## the same heat during vegetative growth. This script is the first step toward
## that idea.
##
## Biological stage logic used here:
## We now use maize-specific cumulative GDD thresholds to assign each day to a
## crop-development window instead of splitting the season into equal thirds.
##
## Windows used:
## - early vegetative: emergence through V6
## - late vegetative: after V6 up to silking (R1)
## - flowering: silking through early reproductive development up to R3
## - grain fill: after R3 through maturity
##
## These windows are still a simplification, but they are biologically grounded
## in maize development rather than being arbitrary calendar fractions.
##
## Input:
## - analysis/outputs/02_daily_weather_G2F.csv
##
## The file above is produced by the AgERA5 grid-download + extraction path.
##
## Output:
## - analysis/outputs/04_environment_covariates_stagewise_G2F.csv
##
## Why this script exists in addition to Stage 3:
## Stage 3 asks:
##   "What was the whole season like on average?"
##
## Stage 4 asks:
##   "What were different parts of the season like?"
##
## This matters because the same heat or drought level can affect the crop very
## differently depending on whether it happens:
## - early in growth,
## - around flowering,
## - or during grain filling.
##
## The same mean / sum / count logic from Stage 3 is reused here, but now it is
## applied separately inside biologically anchored maize windows.
##
## Important maize-specific note:
## The GDD covariates here also use the maize-specific capped method:
## - lower threshold = 10 C
## - upper threshold = 30 C
## -----------------------------------------------------------------------------

source("/Users/neon/Documents/Nadim's Brain/analysis/pre-processing/00_paths_and_helpers.R")

weather_path <- file.path(output_dir, "02_daily_weather_G2F.csv")
daily_weather <- read.csv(weather_path)
daily_weather$date <- as.Date(daily_weather$date)
assert_required_columns(
  daily_weather,
  c(
    "env_id", "year", "location", "date",
    "temperature_2m_mean", "temperature_2m_max", "temperature_2m_min",
    "precipitation_sum", "shortwave_radiation_sum",
    "et0_fao_evapotranspiration",
    "vapour_pressure_deficit_at_maximum_temperature",
    "relative_humidity_derived_minimum"
  ),
  object_name = "Stage 2 daily weather table"
)

env_ids <- unique(daily_weather$env_id)
stage_rows <- vector("list", length(env_ids))

for (i in seq_along(env_ids)) {
  env_id <- env_ids[i]
  d <- daily_weather[daily_weather$env_id == env_id, ]
  d <- d[order(d$date), ]

  # Compute daily maize GDD and cumulative maize GDD from planting onward.
  # Cumulative GDD acts as a simple physiological clock for maize development.
  d$daily_gdd10 <- calc_gdd(
    d$temperature_2m_max,
    d$temperature_2m_min,
    base_temp = 10,
    upper_temp = 30
  )
  d$cumulative_gdd10 <- cumsum(d$daily_gdd10)

  # Assign every day to a maize biological window using cumulative GDD
  # thresholds from the helper file.
  d$stage_window <- assign_maize_biological_windows(d$cumulative_gdd10)

  summarize_stage <- function(stage_name) {
    # For one stage window, compute the same type of summaries we used at the
    # season level. This lets us compare whole-season vs timing-specific effects.
    x <- d[d$stage_window == stage_name, ]

    c(
      # Typical daily temperature within this stage
      safe_mean(x$temperature_2m_mean),
      # Total rainfall accumulated within this stage
      safe_sum(x$precipitation_sum),
      # Typical daily radiation within this stage
      safe_mean(x$shortwave_radiation_sum),
      # Typical daily VPD at maximum temperature within this stage
      safe_mean(x$vapour_pressure_deficit_at_maximum_temperature),
      # Typical daily derived minimum relative humidity within this stage
      safe_mean(x$relative_humidity_derived_minimum),
      # Total evapotranspiration demand within this stage
      safe_sum(x$et0_fao_evapotranspiration),
      # Number of very hot days within this stage
      sum(x$temperature_2m_max > 35, na.rm = TRUE),
      # Number of very dry days within this stage
      sum(x$precipitation_sum < 1, na.rm = TRUE),
      # Cumulative maize growing degree days within this stage
      # using lower threshold 10 C and upper threshold 30 C
      safe_sum(x$daily_gdd10),
      # Number of daily records in this stage window
      nrow(x)
    )
  }

  early <- summarize_stage("early_vegetative")
  late <- summarize_stage("late_vegetative")
  flower <- summarize_stage("flowering")
  grain <- summarize_stage("grain_fill")

  # One row per environment, but now with separate covariates for each maize
  # development window.
  stage_rows[[i]] <- data.frame(
    env_id = env_id,
    year = d$year[1],
    location = d$location[1],

    # Early vegetative window covariates (through V6)
    MeanTemp_early = early[1],
    RainSum_early = early[2],
    RadMean_early = early[3],
    VPDMax_mean_early = early[4],
    RHDerivedMin_mean_early = early[5],
    ET0Sum_early = early[6],
    HotDays35_early = early[7],
    DryDays1mm_early = early[8],
    GDD10_early = early[9],
    Days_early = early[10],

    # Late vegetative window covariates (after V6 to silking)
    MeanTemp_late_vegetative = late[1],
    RainSum_late_vegetative = late[2],
    RadMean_late_vegetative = late[3],
    VPDMax_mean_late_vegetative = late[4],
    RHDerivedMin_mean_late_vegetative = late[5],
    ET0Sum_late_vegetative = late[6],
    HotDays35_late_vegetative = late[7],
    DryDays1mm_late_vegetative = late[8],
    GDD10_late_vegetative = late[9],
    Days_late_vegetative = late[10],

    # Flowering window covariates (silking through early reproductive period)
    MeanTemp_flowering = flower[1],
    RainSum_flowering = flower[2],
    RadMean_flowering = flower[3],
    VPDMax_mean_flowering = flower[4],
    RHDerivedMin_mean_flowering = flower[5],
    ET0Sum_flowering = flower[6],
    HotDays35_flowering = flower[7],
    DryDays1mm_flowering = flower[8],
    GDD10_flowering = flower[9],
    Days_flowering = flower[10],

    # Grain-fill window covariates (R3 onward)
    MeanTemp_grainfill = grain[1],
    RainSum_grainfill = grain[2],
    RadMean_grainfill = grain[3],
    VPDMax_mean_grainfill = grain[4],
    RHDerivedMin_mean_grainfill = grain[5],
    ET0Sum_grainfill = grain[6],
    HotDays35_grainfill = grain[7],
    DryDays1mm_grainfill = grain[8],
    GDD10_grainfill = grain[9],
    Days_grainfill = grain[10],
    stringsAsFactors = FALSE
  )
}

# Final stagewise environment table: still one row per environment, but with
# several maize-development-window covariates instead of one season-wide set.
stage_covariates <- do.call(rbind, stage_rows)

write.csv(
  stage_covariates,
  file.path(output_dir, "04_environment_covariates_stagewise_G2F.csv"),
  row.names = FALSE
)

message("Wrote outputs/04_environment_covariates_stagewise_G2F.csv")
