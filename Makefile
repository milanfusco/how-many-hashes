PYTHON ?= .venv/bin/python
RSCRIPT ?= Rscript
LATEXMK ?= latexmk
RUN_R = $(RSCRIPT) --vanilla scripts/run-r.R

.PHONY: all setup setup-python setup-r data figures papers check

all: papers

setup: setup-python setup-r

setup-python:
	uv sync --locked

setup-r:
	$(RSCRIPT) --vanilla scripts/restore-r.R

data:
	$(PYTHON) scripts/generate.py

figures: data
	$(RUN_R) scripts/descriptive-analysis.R
	$(RUN_R) scripts/compare-bits.R

papers: figures
	mkdir -p build/tex/part2 build/tex/part3
	cd tex/part2 && $(LATEXMK) -pdf -interaction=nonstopmode -halt-on-error -outdir=../../build/tex/part2 part2.tex
	cd tex/part3 && $(LATEXMK) -pdf -interaction=nonstopmode -halt-on-error -outdir=../../build/tex/part3 part3.tex
	cd tex/presentation && $(LATEXMK) -pdf -interaction=nonstopmode -halt-on-error -outdir=../../build/tex/presentation presentation.tex
check: data
	$(PYTHON) -m unittest discover -s tests -v
	$(RUN_R) tests/graphics-device.R
