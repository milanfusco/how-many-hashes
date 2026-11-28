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

# ---------- exact birthday model ----------
# S(k) = P(T > k) = prod_{j=0}^{k-1} (1 - j/M), k = 0..M
# F(k) = 1 - S(k);  E[T] = sum_{k=0}^{M} S(k)
model_grid <- function(bits_val, k_max) {
  M <- 2^bits_val
  k <- 0:k_max
  j <- k[k >= 1] - 1
  surv <- c(1, cumprod(1 - j / M))
  tibble(
    bits = factor(bits_val, levels = c(8L, 12L, 16L)),
    M = M, k = k, S = surv, F = 1 - surv
  )
}
exact_mean <- function(bits_val) {
  M <- 2^bits_val
  sum(c(1, cumprod(1 - (0:(M - 1)) / M)))
}
model_means <- tibble(
  bits = factor(c(8L, 12L, 16L), levels = c(8L, 12L, 16L)),
  model_mean = map_dbl(c(8L, 12L, 16L), exact_mean)
)
print(model_means)