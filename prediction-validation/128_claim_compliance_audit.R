#!/usr/bin/env Rscript

suppressWarnings(suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(stringr)
  library(purrr)
  library(tidyr)
}))

root <- getwd()
models_dir <- file.path(root, "analysis", "models")
out_dir <- file.path(root, "analysis", "outputs", "prediction_yield", "external_validation", "run_queue", "128_claim_compliance")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

files <- list.files(models_dir, pattern = "\\.md$", full.names = TRUE)
if (length(files) == 0) stop("No model markdown files found")

forbidden_patterns <- tribble(
  ~rule_id, ~severity, ~pattern, ~reason,
  "F1", "high", "(?i)proved nobody in the world|no one in the world has ever", "Absolute global non-existence claim is not provable from finite search",
  "F2", "high", "(?i)first[- ]ever(?!.*bounded)", "Unbounded first-ever phrasing overstates evidence",
  "F3", "high", "(?i)universal(ly)? best|beats .*every", "Universal dominance contradicted by baseline-strength results"
)

required_patterns <- tribble(
  ~rule_id, ~pattern, ~reason,
  "R1", "(?i)bounded world-first|bounded novelty", "Bounded framing required",
  "R2", "(?i)not (a )?universal|not a universal|not a proof of global non-existence|finite search", "Explicit caveat required"
)

scan_file <- function(path) {
  lines <- readLines(path, warn = FALSE)
  txt <- paste(lines, collapse = "\n")

  forb <- forbidden_patterns %>%
    mutate(
      file = path,
      hit = map_lgl(pattern, ~ str_detect(txt, regex(.x))),
      n_hits = map_int(pattern, ~ str_count(txt, regex(.x)))
    ) %>%
    filter(hit)

  req <- required_patterns %>%
    mutate(
      file = path,
      hit = map_lgl(pattern, ~ str_detect(txt, regex(.x)))
    )

  tibble(
    file = path,
    has_forbidden = nrow(forb) > 0,
    n_forbidden_hits = sum(forb$n_hits %||% 0),
    has_bounded_phrase = req$hit[req$rule_id == "R1"],
    has_caveat_phrase = req$hit[req$rule_id == "R2"]
  ) -> summary

  list(summary = summary, forbidden = forb, required = req)
}

`%||%` <- function(a, b) if (is.null(a)) b else a

scans <- map(files, scan_file)
summary_tbl <- bind_rows(map(scans, "summary"))
forbidden_tbl <- bind_rows(map(scans, "forbidden"))
required_tbl <- bind_rows(map(scans, "required"))

# Contradiction risk: files that include forbidden or lack caveat when bounded phrase is present
risk_tbl <- summary_tbl %>%
  mutate(
    risk_level = case_when(
      has_forbidden ~ "HIGH",
      !has_bounded_phrase & !has_caveat_phrase ~ "MEDIUM",
      !has_caveat_phrase ~ "LOW",
      TRUE ~ "OK"
    )
  ) %>%
  arrange(desc(risk_level), desc(n_forbidden_hits), file)

overall <- tibble(
  n_files = nrow(summary_tbl),
  n_high_risk = sum(risk_tbl$risk_level == "HIGH"),
  n_medium_risk = sum(risk_tbl$risk_level == "MEDIUM"),
  n_low_risk = sum(risk_tbl$risk_level == "LOW"),
  n_ok = sum(risk_tbl$risk_level == "OK")
)

write_csv(summary_tbl, file.path(out_dir, "128_claim_scan_summary.csv"))
write_csv(forbidden_tbl, file.path(out_dir, "128_claim_forbidden_hits.csv"))
write_csv(required_tbl, file.path(out_dir, "128_claim_required_hits.csv"))
write_csv(risk_tbl, file.path(out_dir, "128_claim_risk_report.csv"))
write_csv(overall, file.path(out_dir, "128_claim_overall_stats.csv"))

cat("Stage 128 claim compliance audit generated:\n")
cat(sprintf("- %s\n", file.path(out_dir, "128_claim_scan_summary.csv")))
cat(sprintf("- %s\n", file.path(out_dir, "128_claim_forbidden_hits.csv")))
cat(sprintf("- %s\n", file.path(out_dir, "128_claim_required_hits.csv")))
cat(sprintf("- %s\n", file.path(out_dir, "128_claim_risk_report.csv")))
cat(sprintf("- %s\n", file.path(out_dir, "128_claim_overall_stats.csv")))
