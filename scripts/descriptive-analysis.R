# Run from the repository root: Rscript scripts/descriptive-analysis.R
df <- read.csv("build/data/trials_b16_n900_seed37430101.csv",
               colClasses = c(trial_id = "character", master_seed = "character"))
T <- df$T
n <- length(T)
ci <- t.test(T)$conf.int
summary <- data.frame(n = n, mean = mean(T), sd = sd(T), variance = var(T),
                      min = min(T), q1 = unname(quantile(T, .25)),
                      median = median(T), q3 = unname(quantile(T, .75)),
                      max = max(T), iqr = IQR(T), se = sd(T) / sqrt(n),
                      ci_lower = ci[1], ci_upper = ci[2])
dir.create("build/tables", recursive = TRUE, showWarnings = FALSE)
write.csv(summary, "build/tables/part2-summary.csv", row.names = FALSE)
print(summary)

dir.create("build/figures", recursive = TRUE, showWarnings = FALSE)
save_plot <- function(name, draw) {
  pdf(file.path("build/figures", paste0("part2-", name, ".pdf")),
      width = 7, height = 4.5, useDingbats = FALSE)
  on.exit(dev.off())
  draw()
}
save_plot("histogram", function() {
  hist(T, breaks = 25, main = "First-Collision Waiting Times",
       xlab = "Hash evaluations")
  abline(v = mean(T), col = "darkred", lty = 2, lwd = 2)
})
save_plot("boxplot", function() {
  boxplot(T, horizontal = TRUE, main = "Waiting-Time Distribution")
})
save_plot("normal-qq", function() {
  qqnorm(T, main = "Normal Q-Q plot of T")
  qqline(T, col = "darkred", lwd = 2)
})
save_plot("ecdf", function() {
  plot(ecdf(T), main = "Empirical CDF", xlab = "Hash evaluations", ylab = "P(T <= k)")
})
save_plot("trial-order", function() {
  plot(df$trial, T, pch = 16, cex = .5, main = "Waiting Times by Trial",
       xlab = "Trial number", ylab = "Hash evaluations")
})
