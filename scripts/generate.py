#!/usr/bin/env python3
"""Regenerate the study's three datasets from the recorded parameters."""
from simulation import experiment_driver, save_trials


def main():
    for bits in (8, 12, 16):
        rows = experiment_driver(900, bits, 37430101)
        path = save_trials(rows)
        print(f"Wrote {len(rows)} trials to {path}")


if __name__ == "__main__":
    main()
