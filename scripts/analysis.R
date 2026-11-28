# Run in an R console from the repository root after running the notebook.
# source("scripts/analysis.R")
# result <- analyze_trials("build/data/trials_b16_n900_seed37430101.csv")
# result$trials[1:5, ]
# To write the same figure to a PDF or PNG, pass pdf_path or png_path.

analyze_trials <- function(csv_path, pdf_path = NULL, png_path = NULL) {
  # An ID is a label. Reading it as text preserves every decimal digit.
  dat <- read.csv(
    csv_path,
    colClasses = c(
      trial = "numeric",
      trial_id = "character",
      bits = "integer",
      master_seed = "character",
      T = "numeric"
    ),
    stringsAsFactors = FALSE
  )
  required <- c("trial", "trial_id", "bits", "master_seed", "T")
  if (
    !all(required %in% names(dat)) || nrow(dat) == 0L || anyNA(dat[required])
  ) {
    stop(
      "The CSV must contain complete trial, trial_id, bits, master_seed and T columns."
    )
  }
  if (
    length(unique(dat$bits)) != 1L ||
      length(unique(dat$master_seed)) != 1L ||
      anyDuplicated(dat$trial_id) ||
      !all(dat$trial == seq_len(nrow(dat)))
  ) {
    stop(
      "Supply one dataset with a single width and seed, ordered trials and unique IDs."
    )
  }

  bits <- dat$bits[1]
  if (bits < 1L || bits > 256L) {
    stop("The retained width must be between 1 and 256 bits.")
  }
  M <- 2^bits
  waits <- dat$T
  if (
    any(!is.finite(waits) | waits != floor(waits) | waits < 2 | waits > M + 1)
  ) {
    stop("Each waiting time must be a whole number between 2 and M + 1.")
  }
  statistics <- data.frame(
    trials = length(waits),
    bits = bits,
    mean_T = mean(waits),
    median_T = median(waits),
    sample_sd = sd(waits),
    min_T = min(waits),
    max_T = max(waits)
  )
  print(statistics, row.names = FALSE, digits = 6)

  # At draw k, the preceding k - 1 labels must all differ for a trial to survive.
  # Summing logs computes the product from the notebook without rounding 1 - F.
  k <- 0:max(waits)
  log_survival <- c(0, cumsum(log1p(-head(k, -1L) / M)))
  model_cdf <- -expm1(log_survival)
  observed_cdf <- ecdf(waits)

  if (!is.null(pdf_path) && !is.null(png_path)) {
    stop("Pass either pdf_path or png_path, not both.")
  }
  if (!is.null(pdf_path)) {
    pdf(pdf_path, width = 11, height = 5.6, useDingbats = FALSE)
  } else if (!is.null(png_path)) {
    png(png_path, width = 11, height = 5.6, units = "in", res = 150)
  }
  old_par <- par(no.readonly = TRUE)
  on.exit(
    {
      par(old_par)
      if (!is.null(pdf_path) || !is.null(png_path)) dev.off()
    },
    add = TRUE
  )

  ink <- "#182F42"
  blue <- "#21648A"
  pale <- "#AFCEDB"
  rust <- "#A74923"
  par(
    mfrow = c(1, 2),
    mar = c(4.6, 4.1, 2.5, 1.1),
    oma = c(0, 0, 3.1, 0.2),
    las = 1,
    col.main = ink,
    col.lab = ink,
    fg = ink,
    bty = "l"
  )

  x_label <- "Hash evaluations through the first repeat"
  hist(
    waits,
    breaks = pretty(c(0, max(waits)), n = 15),
    main = "How long did trials last?",
    xlab = x_label,
    ylab = "Number of trials",
    col = pale,
    border = "white"
  )
  abline(v = median(waits), col = blue, lwd = 2, lty = 2)
  legend(
    "topright",
    legend = paste("Sample median", format(median(waits))),
    lty = 2,
    lwd = 2,
    col = blue,
    bty = "n",
    cex = 0.85
  )

  plot(
    k,
    model_cdf,
    type = "n",
    xaxs = "i",
    xlim = range(k),
    ylim = c(0, 1),
    main = "What fraction finished by draw k?",
    xlab = "Draw number, k",
    ylab = "Cumulative probability"
  )
  abline(h = 0.5, col = "#B7BFC4", lty = 3)
  lines(k, observed_cdf(k), type = "s", col = blue, lwd = 2.2)
  lines(k, model_cdf, type = "s", col = rust, lwd = 1.5, lty = 2)
  legend(
    "bottomright",
    legend = c("Observed trials", "Birthday model"),
    lty = c(1, 2),
    lwd = c(2.2, 1.5),
    col = c(blue, rust),
    bty = "n",
    cex = 0.85
  )
  mtext(
    sprintf("First collisions in %d-bit SHA-256 prefixes", bits),
    outer = TRUE,
    side = 3,
    line = 1.45,
    cex = 1.25,
    font = 2,
    col = ink
  )
  mtext(
    sprintf(
      "%s trials   |   %s possible labels   |   seed %s",
      format(nrow(dat), big.mark = ","),
      format(M, big.mark = ",", scientific = FALSE),
      dat$master_seed[1]
    ),
    outer = TRUE,
    side = 3,
    line = 0.2,
    cex = 0.88,
    col = ink
  )

  invisible(list(
    trials = dat,
    summary = statistics,
    cdf = data.frame(k = k, observed = observed_cdf(k), model = model_cdf)
  ))
}
