source(if (file.exists("scripts/analysis.R")) "scripts/analysis.R" else "analysis.R")
csv <- if (dir.exists("build/data")) "build/data/trials_b16_n900_seed37430101.csv" else "results/trials_b16_n900_seed37430101.csv"
for (format in c("pdf", "png")) {
  outer <- tempfile(fileext = ".pdf")
  pdf(outer)
  par(bg = "ivory")
  before <- dev.cur()
  output <- tempfile(fileext = paste0(".", format))
  args <- list(csv_path = csv)
  args[[paste0(format, "_path")]] <- output
  do.call(analyze_trials, args)
  stopifnot(identical(dev.cur(), before), par("bg") == "ivory", file.info(output)$size > 0)
  dev.off()
  unlink(c(outer, output))
}
cat("PDF and PNG writers preserve the caller's graphics device.\n")
