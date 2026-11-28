# Prefer the restored project library; reject drift in any locked dependency.
lib <- file.path(getwd(), "build", "R-library")
if (!dir.exists(lib)) stop("Run make setup-r to restore the R dependencies first.")
.libPaths(lib, include.site = FALSE)
if (!requireNamespace("renv", quietly = TRUE)) stop("Run make setup-r first.")
locked <- renv::lockfile_read("renv.lock")$Packages
for (package in names(locked)) {
  installed <- tryCatch(as.character(packageVersion(package)), error = function(e) NA_character_)
  if (is.na(installed) || package_version(installed) != package_version(locked[[package]]$Version)) {
    stop(sprintf("%s must be version %s; run make setup-r.",
                 package, locked[[package]]$Version))
  }
}
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) stop("Usage: Rscript scripts/run-r.R path/to/script.R")
source(args[1], chdir = FALSE)
