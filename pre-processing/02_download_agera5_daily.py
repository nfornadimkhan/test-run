#!/usr/bin/env python3
"""
Stage 2A: Download AgERA5 daily NetCDF files for the G2F environments.

Why this script exists:
- AgERA5 is closer to the paper's environmental-data philosophy than Open-Meteo.
- CDS returns gridded daily climate files, not per-environment point tables.
- We therefore first download yearly, regional NetCDF files here, and then let
  the next R stage extract the nearest grid cell for each environment.

Important CDS requirements:
- ~/.cdsapirc must exist with the CDS API token
- the AgERA5 dataset licence must already be accepted in the browser

Dataset:
- sis-agrometeorological-indicators
- version 2.0
"""

from __future__ import annotations

import math
from pathlib import Path
import pandas as pd
import cdsapi


ANALYSIS_DIR = Path("/Users/neon/Documents/Nadim's Brain/analysis")
OUTPUT_DIR = ANALYSIS_DIR / "outputs"
RAW_DIR = OUTPUT_DIR / "agera5_raw"
RAW_DIR.mkdir(parents=True, exist_ok=True)

ENV_PATH = OUTPUT_DIR / "01_environments_G2F.csv"
MANIFEST_PATH = RAW_DIR / "agera5_manifest.csv"


REQUEST_SPECS = [
    {
        "variable": "2m_temperature",
        "statistic": "24_hour_mean",
        "slug": "tmean",
        "output_column": "temperature_2m_mean",
    },
    {
        "variable": "2m_temperature",
        "statistic": "24_hour_maximum",
        "slug": "tmax",
        "output_column": "temperature_2m_max",
    },
    {
        "variable": "2m_temperature",
        "statistic": "24_hour_minimum",
        "slug": "tmin",
        "output_column": "temperature_2m_min",
    },
    {
        "variable": "precipitation_flux",
        "statistic": "24_hour_mean",
        "slug": "precip",
        "output_column": "precipitation_sum",
    },
    {
        "variable": "solar_radiation_flux",
        "statistic": "24_hour_mean",
        "slug": "srad",
        "output_column": "shortwave_radiation_sum",
    },
    {
        "variable": "reference_evapotranspiration",
        "statistic": "24_hour_mean",
        "slug": "et0",
        "output_column": "et0_fao_evapotranspiration",
    },
    {
        "variable": "vapour_pressure_deficit_at_maximum_temperature",
        "statistic": "24_hour_mean",
        "slug": "vpdmax",
        "output_column": "vapour_pressure_deficit_at_maximum_temperature",
    },
    {
        "variable": "2m_relative_humidity_derived",
        "statistic": "24_hour_minimum",
        "slug": "rhmin",
        "output_column": "relative_humidity_derived_minimum",
    },
]


def compute_bbox(df: pd.DataFrame, margin_deg: float = 1.0) -> list[float]:
    north = min(90.0, math.ceil((df["latitude"].max() + margin_deg) * 10) / 10)
    south = max(-90.0, math.floor((df["latitude"].min() - margin_deg) * 10) / 10)
    east = min(180.0, math.ceil((df["longitude"].max() + margin_deg) * 10) / 10)
    west = max(-180.0, math.floor((df["longitude"].min() - margin_deg) * 10) / 10)
    return [north, west, south, east]


def months_needed_for_year(df: pd.DataFrame, year: int) -> list[str]:
    year_df = df[df["year"].astype(int) == year].copy()
    if year_df.empty:
        raise ValueError(f"No environments found for year {year}")

    year_df["planting.date"] = pd.to_datetime(year_df["planting.date"])
    year_df["harvest.date"] = pd.to_datetime(year_df["harvest.date"])

    start_month = int(year_df["planting.date"].dt.month.min())
    end_month = int(year_df["harvest.date"].dt.month.max())

    # Current G2F seasons do not wrap across calendar years. If that changes
    # later, this explicit check prevents silently requesting the wrong window.
    if end_month < start_month:
        raise ValueError(
            f"Year {year} appears to span a calendar-year boundary. "
            "Update the downloader logic before continuing."
        )

    return [f"{m:02d}" for m in range(start_month, end_month + 1)]


def build_request(year: int, bbox: list[float], spec: dict, months: list[str]) -> dict:
    return {
        "variable": spec["variable"],
        "statistic": [spec["statistic"]],
        "year": [str(year)],
        "month": months,
        "day": [f"{d:02d}" for d in range(1, 32)],
        "version": "2_0",
        "area": bbox,
    }


def main() -> None:
    env = pd.read_csv(ENV_PATH)
    years = sorted(env["year"].astype(int).unique().tolist())
    bbox = compute_bbox(env)

    client = cdsapi.Client()
    manifest_rows = []

    for year in years:
        months = months_needed_for_year(env, year)
        print(f"[year {year}] requesting months {months[0]} to {months[-1]}")
        for spec in REQUEST_SPECS:
            filename = f"agera5_{year}_{spec['slug']}.nc"
            target = RAW_DIR / filename

            manifest_rows.append(
                {
                    "year": year,
                    "variable": spec["variable"],
                    "statistic": spec["statistic"],
                    "slug": spec["slug"],
                    "output_column": spec["output_column"],
                    "file": str(target),
                }
            )

            if target.exists():
                print(f"[skip] {filename} already exists")
                continue

            print(f"[download] {filename}")
            request = build_request(year, bbox, spec, months)
            client.retrieve("sis-agrometeorological-indicators", request, str(target))

    pd.DataFrame(manifest_rows).to_csv(MANIFEST_PATH, index=False)
    print(f"Wrote manifest: {MANIFEST_PATH}")


if __name__ == "__main__":
    main()
