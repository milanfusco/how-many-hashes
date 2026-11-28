# Restore the recorded packages into an ignored, project-local library.
root <- normalizePath(".")
lib <- file.path(root, "build", "R-library")
dir.create(lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(lib, .libPaths()))
options(repos = c(CRAN = "https://cloud.r-project.org"))
if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages("renv", lib = lib)
}
renv::restore(project = root, library = lib, lockfile = "renv.lock", prompt = FALSE)
