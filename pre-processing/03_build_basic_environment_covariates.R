## -----------------------------------------------------------------------------
## Stage 3: Build basic season-level environmental covariates
##
## Goal:
## Convert daily weather into one summary row per environment.
##
## Why this stage matters:
## Most GxE regression models do not use raw daily weather directly. They use
## covariates such as season mean temperature or total rainfall.
##
## This script creates the first beginner-level covariates:
## - season mean temperature
## - season mean VPD at maximum temperature
## - season mean derived minimum relative humidity
## - season rainfall total
## - season mean radiation
## - evapotranspiration total
## - hot-day count
## - dry-day count
## - growing degree days
##
## Input:
## - analysis/outputs/02_daily_weather_G2F.csv
##
## The file above is produced by the AgERA5 grid-download + extraction path.
##
## Output:
## - analysis/outputs/03_environment_covariates_basic_G2F.csv
##
## How to think about the covariates:
##
## 1. Variables summarized with MEAN
##    Use mean when the question is:
##    "What was a typical day like during this season?"
##
##    Examples:
##    - MeanTemp_season
##    - MaxTemp_mean_season
##    - MinTemp_mean_season
##    - RadMean_season
##    - VPDMax_mean_season
##    - RHDerivedMin_mean_season
##
## 2. Variables summarized with SUM
##    Use sum when the question is:
##    "How much accumulated over the season?"
##
##    Examples:
##    - RainSum_season
##    - ET0Sum_season
##    - GDD10_season
##
## 3. Variables summarized with COUNT
##    Use counts when the question is:
##    "How often did a stress event happen?"
##
##    Examples:
##    - HotDays35_season
##    - DryDays1mm_season
##
## This is the main statistical move of the script:
## many daily rows for one environment -> one biologically interpretable row
## of environmental covariates for that environment.
##
## Important maize-specific note:
## GDD here uses a maize development convention, not the earlier uncapped
## teaching version. We use:
## - lower threshold = 10 C
## - upper threshold = 30 C
##
## Daily maize GDD:
##   Tmax* = min(Tmax, 30)
##   Tmin* = max(Tmin, 10)
##   GDD_d = max(((Tmax* + Tmin*) / 2) - 10, 0)
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
covariate_rows <- vector("list", length(env_ids))

for (i in seq_along(env_ids)) {
  env_id <- env_ids[i]
  d <- daily_weather[daily_weather$env_id == env_id, ]

  # At this point, d contains all daily weather rows for one environment
  # (one year-location crop period). The rest of the code turns that daily
  # time series into season-level summaries.

  # GDD is computed day by day, then summed over the full season.
  #
  # Daily maize formula:
  #   Tmax*_d = min(tmax_d, 30)
  #   Tmin*_d = max(tmin_d, 10)
  #   GDD_d = max(((Tmax*_d + Tmin*_d) / 2) - 10, 0)
  #
  # Interpretation:
  # We measure usable maize heat above 10 C while preventing extremely high
  # temperatures from contributing without limit above 30 C.
  gdd10 <- calc_gdd(
    d$temperature_2m_max,
    d$temperature_2m_min,
    base_temp = 10,
    upper_temp = 30
  )

  # This creates one summary row per environment.
  covariate_rows[[i]] <- data.frame(
    env_id = env_id,
    year = d$year[1],
    location = d$location[1],

    # MeanTemp_season:
    # average of daily mean temperature
    # question answered: what was a typical thermal day like?
    MeanTemp_season = safe_mean(d$temperature_2m_mean),

    # MaxTemp_mean_season:
    # average of the daily maximum temperature
    # question answered: across the season, how hot were the typical daily highs?
    MaxTemp_mean_season = safe_mean(d$temperature_2m_max),

    # MinTemp_mean_season:
    # average of the daily minimum temperature
    # question answered: across the season, how cool were the typical daily lows?
    MinTemp_mean_season = safe_mean(d$temperature_2m_min),

    # RainSum_season:
    # total rainfall across the season
    # use sum because rainfall is an accumulated water input
    RainSum_season = safe_sum(d$precipitation_sum),

    # RadMean_season:
    # average daily shortwave radiation over the season
    # use mean because this is a "typical day" light/energy descriptor
    RadMean_season = safe_mean(d$shortwave_radiation_sum),

    # VPDMax_mean_season:
    # average daily vapour pressure deficit at daily maximum temperature
    # use mean because it describes typical daytime atmospheric dryness
    VPDMax_mean_season = safe_mean(d$vapour_pressure_deficit_at_maximum_temperature),

    # RHDerivedMin_mean_season:
    # average daily derived minimum relative humidity
    # use mean because it describes typical lowest daily humidity conditions
    RHDerivedMin_mean_season = safe_mean(d$relative_humidity_derived_minimum),

    # ET0Sum_season:
    # total reference evapotranspiration over the season
    # use sum because ET0 represents cumulative atmospheric drying demand
    ET0Sum_season = safe_sum(d$et0_fao_evapotranspiration),

    # HotDays35_season:
    # number of days where maximum temperature exceeded 35 C
    # use count because extreme-event frequency can matter more than the season mean
    HotDays35_season = sum(d$temperature_2m_max > 35, na.rm = TRUE),

    # DryDays1mm_season:
    # number of days with less than 1 mm precipitation
    # use count because repeated dry days can indicate water stress frequency
    DryDays1mm_season = sum(d$precipitation_sum < 1, na.rm = TRUE),

    # GDD10_season:
    # sum of daily maize growing degree days using:
    # - lower threshold 10 C
    # - upper threshold 30 C
    # use sum because maize development responds to cumulative usable heat
    GDD10_season = safe_sum(gdd10),

    # SeasonLength_days:
    # simply how many daily records were present in the crop window
    # useful for interpretation and later QC
    SeasonLength_days = nrow(d),
    stringsAsFactors = FALSE
  )
}

# Bind all per-environment summary rows into one final environment-level table.
basic_covariates <- do.call(rbind, covariate_rows)

write.csv(
  basic_covariates,
  file.path(output_dir, "03_environment_covariates_basic_G2F.csv"),
  row.names = FALSE
)

message("Wrote outputs/03_environment_covariates_basic_G2F.csv")
