# How many hashes until two collide?

A reproducible study of how many distinct messages must be hashed before two
SHA-256 prefixes collide. The experiment runs 900 trials at each of three prefix
widths (8, 12, and 16 bits) and compares the observed waiting times with the
birthday model.

The repository includes an Jupyter notebook, Python simulation code, R
analyses, and LaTeX manuscripts. Start with
[the notebook](how-many-hashes.ipynb) to explore the experiment, or follow the
instructions below to regenerate the data, figures, and papers.

## Rebuild the study

Prerequisites:

- `uv`
- R (tested with version 4.6.2)
- Make
- A TeX installation with `latexmk`, `pdflatex`, and the proper packages

`.python-version` selects Python 3.14.2 for uv; the code requires Python 3.13 or
later. Python dependencies are pinned in `uv.lock`, and R dependencies are pinned
in `renv.lock`.

From the repository root:

```sh
make setup    # install Python and restore R packages; requires internet
make check    # exact data reproduction and PDF/PNG graphics regression checks
make papers   # regenerate data, tables, figures, and both papers
```

The resulting papers are `build/tex/part2/part2.pdf` and
`build/tex/part3/part3.pdf`. `make data` and `make figures` rebuild intermediate
outputs. Each build regenerates the data and figures from source.


## Data and notebook workflow

The recorded experiment uses master seed 37430101. `scripts/simulation.py` is the
shared implementation used by both
`scripts/generate.py` and the notebook. Trial IDs and seeds remain text in CSV
and R imports so 64-bit identifiers do not lose precision.

Open the notebook with the project's `.venv` interpreter and run it from the
repository root. It writes to `build/data/`. Alternative notebook settings produce
separate filenames; the paper build explicitly reads the recorded study settings.

For an interactive R plot, from the repository root:

```r
source("scripts/analysis.R")
result <- analyze_trials("build/data/trials_b16_n900_seed37430101.csv")
# Optional: pdf_path = "build/figures/diagnostic.pdf" or png_path = "...png"
```

## Reproducibility

`make papers` reproduces the simulation, descriptive summary CSVs, figure PDFs,
and document compilation. The manuscript tables and inferential results 
were entered by hand; they are not automatically populated from R.
See
[SPSS notes](archive/README.md).

The regression checks compare generated trial CSVs byte for byte against the
recorded SHA-256 checksums. 