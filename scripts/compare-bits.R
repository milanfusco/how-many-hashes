#!/usr/bin/env Rscript
# compare-bits.R — grouped descriptive graphics across bit widths

# Reads the three trial CSVs from build/data/, binds them, and produces faceted
# versions of the descriptive graphics from descriptive-analysis.R.
# Each output PDF has one panel per bit width (8, 12, 16), except for the
# overlaid ECDF and the mean-vs-width summary, which are single-panel.

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(readr)
  library(purrr)
})

# ---------- load ----------
results_dir <- "build/data"
files <- file.path(results_dir, sprintf("trials_b%d_n900_seed37430101.csv", c(8, 12, 16)))
if (!all(file.exists(files))) stop("Missing study CSVs; run make data first.")

data <- files |>
  map_dfr(~ read_csv(.x, col_types = cols(
    trial = col_integer(), trial_id = col_character(), bits = col_integer(),
    master_seed = col_character(), T = col_double()
  ))) |>
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

k_max_by_bits <- data |> group_by(bits) |>
  summarise(k_max = max(T), .groups = "drop")

model_curves <- pmap_dfr(
  list(as.integer(as.character(k_max_by_bits$bits)), k_max_by_bits$k_max),
  model_grid
)

exact_mean <- function(bits_val) {
  M <- 2^bits_val
  sum(c(1, cumprod(1 - (0:(M - 1)) / M)))
}
model_means <- tibble(
  bits = factor(c(8L, 12L, 16L), levels = c(8L, 12L, 16L)),
  model_mean = map_dbl(c(8L, 12L, 16L), exact_mean)
)
print(model_means)

# ---------- summary stats ----------
stats_by_bits <- data |>
  group_by(bits) |>
  summarise(
    n = n(),
    mean_T = mean(T),
    median_T = median(T),
    sd_T = sd(T),
    q25 = quantile(T, 0.25),
    q75 = quantile(T, 0.75),
    .groups = "drop"
  ) |>
  left_join(model_means, by = "bits") |>
  mutate(ratio = mean_T / sqrt(2^as.integer(as.character(bits))))
print(stats_by_bits)


# ---------- shared theme ----------
ink <- "#182F42"; blue <- "#21648A"; pale <- "#AFCEDB"; rust <- "#A74923"
theme_mine <- theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(color = ink, face = "bold"),
    plot.subtitle = element_text(color = ink),
    axis.text = element_text(color = ink),
    axis.title = element_text(color = ink),
    strip.text = element_text(color = ink, face = "bold", size = 10),
    panel.grid.minor = element_blank(),
    legend.position = "bottom",
    legend.title = element_blank()
  )
facet_labeller <- labeller(bits = function(b) paste0(b, "-bit"))

dir.create("build/figures", recursive = TRUE, showWarnings = FALSE)

# ---- Histograms, one panel / width ----
p_hist <- ggplot(data, aes(x = T)) +
  geom_histogram(bins = 30, fill = pale, color = "white", linewidth = 0.3) +
  geom_vline(data = stats_by_bits, aes(xintercept = mean_T),
             color = rust, linetype = "dashed", linewidth = 0.9) +
  geom_vline(data = stats_by_bits, aes(xintercept = median_T),
             color = blue, linetype = "solid", linewidth = 0.9) +
  facet_wrap(~ bits, scales = "free_x", labeller = facet_labeller) +
  labs(
    title = "First-collision waiting times by truncation width",
    subtitle = "Dashed red = mean; solid blue = median",
    x = "Hash evaluations through first collision, T",
    y = "Number of trials"
  ) +
  theme_mine
ggsave("build/figures/grouped-histograms.pdf", p_hist, width = 12, height = 4.5)

# ---- Boxplots, one panel per width (stacked vertically) ----
p_box <- ggplot(data, aes(x = T, y = "")) +
  geom_boxplot(fill = pale, outlier.color = rust, outlier.size = 1.5,
               width = 0.4) +
  geom_point(
    data = stats_by_bits, aes(x = mean_T, y = ""),
    shape = 23, size = 2.5, fill = rust, color = ink, inherit.aes = FALSE
  ) +
  facet_wrap(~ bits, scales = "free_x", nrow = 3, labeller = facet_labeller) +
  labs(
    title = "Spread of first-collision waiting times by width",
    subtitle = "Box = IQR, line = median, diamond = mean, points = outliers",
    x = "Hash evaluations through first collision, T",
    y = NULL
  ) +
  theme_mine +
  theme(axis.text.y = element_blank(), panel.grid.major.y = element_blank())
ggsave("build/figures/grouped-boxplots.pdf", p_box, width = 8, height = 4)

# ---- Normal Q-Q, one panel per width ----
p_qq <- ggplot(data, aes(sample = T)) +
  stat_qq(color = blue, size = 0.7) +
  stat_qq_line(color = rust, linetype = "dashed", linewidth = 0.8) +
  facet_wrap(~ bits, scales = "free", labeller = facet_labeller) +
  labs(
    title = "Normal Q-Q plots: departure from normality",
    subtitle = "S-shape indicates right skew at all three widths",
    x = "Theoretical normal quantiles",
    y = "Sample quantiles of T"
  ) +
  theme_mine
ggsave("build/figures/grouped-qq.pdf", p_qq, width = 12, height = 4.5)

# ---- ECDF vs model CDF, one panel per width ----
p_ecdf_facet <- ggplot() +
  stat_ecdf(data = data, aes(x = T, color = "Observed"), linewidth = 1) +
  geom_line(data = model_curves,
            aes(x = k, y = F, color = "Birthday model"),
            linewidth = 0.9, linetype = "dashed") +
  scale_color_manual(values = c("Observed" = blue, "Birthday model" = rust)) +
  facet_wrap(~ bits, scales = "free_x", labeller = facet_labeller) +
  coord_cartesian(ylim = c(0, 1)) +
  labs(
    title = "Empirical vs exact-model CDF by width",
    subtitle = "Tight tracking supports the birthday model at each width",
    x = "Draw number, k",
    y = "P(T <= k)"
  ) +
  theme_mine
ggsave("build/figures/grouped-ecdf.pdf", p_ecdf_facet, width = 12, height = 4.5)

# ---- ECDF overlay (all widths on one plot) ----
p_ecdf_overlay <- ggplot() +
  stat_ecdf(data = data,
            aes(x = T, color = bits, linetype = "Observed"),
            linewidth = 1) +
  geom_line(data = model_curves,
            aes(x = k, y = F, color = bits, linetype = "Birthday model"),
            linewidth = 0.9) +
  scale_linetype_manual(values = c("Observed" = "solid",
                                   "Birthday model" = "dashed")) +
  scale_color_manual(values = c("8" = "#7CB1D4",
                                "12" = "#4A86A8",
                                "16" = "#1F4566")) +
  coord_cartesian(xlim = c(0, 1100), ylim = c(0, 1)) +
  labs(
    title = "Empirical CDFs across truncation widths",
    subtitle = "Solid = observed; dashed = exact birthday model",
    x = "Draw number, k",
    y = "P(T <= k)"
  ) +
  theme_mine
ggsave("build/figures/overlay-ecdf.pdf", p_ecdf_overlay, width = 8.5, height = 5.5)

# ---- Trial scatter, one panel per width ----
p_scatter <- ggplot(data, aes(x = trial, y = T)) +
  geom_point(color = blue, alpha = 0.5, size = 0.6) +
  facet_wrap(~ bits, scales = "free_y", labeller = facet_labeller) +
  labs(
    title = "Waiting times by trial order",
    subtitle = "No apparent serial structure; widths share a common shape",
    x = "Trial number",
    y = "Hash evaluations through first collision, T"
  ) +
  theme_mine
ggsave("build/figures/grouped-scatter.pdf", p_scatter, width = 9, height = 4.5)


# ---- Mean vs width, with exact-model overlay ----
p_means <- ggplot(stats_by_bits, aes(x = bits, y = mean_T)) +
  geom_errorbar(
    aes(ymin = mean_T - qt(0.975, n - 1) * sd_T / sqrt(n),
        ymax = mean_T + qt(0.975, n - 1) * sd_T / sqrt(n)),
    width = 0.1, color = blue, linewidth = 0.7
  ) +
  geom_line(aes(group = 1, color = "Observed mean"), linewidth = 1) +
  geom_point(aes(color = "Observed mean"), size = 3) +
  geom_line(aes(y = model_mean, group = 1, color = "Birthday model"),
            linewidth = 1, linetype = "dashed") +
  geom_point(aes(y = model_mean, color = "Birthday model"),
             size = 3, shape = 17) +
  scale_color_manual(values = c("Observed mean" = blue,
                                "Birthday model" = rust)) +
  scale_x_discrete(labels = function(b) paste0(
    b, "-bit\n(M = ", scales::comma(2^as.integer(as.character(b))), ")"
  )) +
  labs(
    title = "Mean waiting time grows with sqrt(M)",
    subtitle = paste(
      "Error bars: 95% t-intervals for the mean.",
      "Triangles: exact model mean."
    ),
    x = "Truncation width",
    y = "Mean hash evaluations through first collision"
  ) +
  theme_mine
ggsave("build/figures/means-vs-bits.pdf", p_means, width = 8, height = 5.5)

cat("\nAll figures written to build/figures/.\n")
print(list.files("build/figures", pattern = "\\.pdf$"))
dir.create("build/tables", recursive = TRUE, showWarnings = FALSE)
write.csv(stats_by_bits, "build/tables/comparison-summary.csv", row.names = FALSE)
