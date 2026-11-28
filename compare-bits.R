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

data <- files |>
  map_dfr(read_csv, show_col_types = FALSE) |>
  mutate(
    bits = factor(bits, levels = c(8L, 12L, 16L)),
    M = 2^as.integer(as.character(bits))
  ) |>
  arrange(bits, trial)

cat(sprintf("Loaded %d rows across %d widths.\n",
            nrow(data), n_distinct(data$bits)))
print(data |> count(bits, M, name = "trials"))