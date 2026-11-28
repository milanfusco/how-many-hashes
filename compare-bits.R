#!/usr/bin/env Rscript
# compare-bits.R — grouped descriptive graphics across bit widths

suppressPackageStartupMessages({
  library(tidyverse)
})

# ---------- load ----------
results_dir <- "results"
files <- list.files(
  results_dir,
  pattern = "^trials_b(8|12|16)_n900_seed\\d+\\.csv$",
  full.names = TRUE
)
if (length(files) != 3L) {
  stop(sprintf(
    "Expected 3 CSVs in %s/ matching trials_b{8,12,16}_n900_seed*.csv; found %d.",
    results_dir, length(files)
  ))
}