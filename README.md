# How many hashes until two collide? 
A study of first-collision waiting times


## Run the study

1. From the repository root, run `uv sync --locked` to install the Python dependencies.
2. Open `how-many-hashes.ipynb` in an editor with Jupyter support, select the project's `.venv` Python interpreter, and run all cells with the repository root as the working directory. The notebook creates `results/` and writes trial CSVs there.
3. From the repository root, open an R console and run these commands.

```r
source("analysis.R")
result <- analyze_trials(file.path("results/trials_b16_n900_seed37430101.csv"))
```

The filename records the bit width, trial count, and seed. If you change those settings, use the path printed by the notebook. Git ignores generated trial CSVs.

Relative paths use the working directory. Check `Path.cwd()` in the notebook or `getwd()` in R if you cannot find the results. To run R from another directory, pass absolute paths to both `source()` and `analyze_trials()`.

[![Architecture diagram](https://gitdiagram.com/diagram-badge.svg)](https://gitdiagram.com/milanfusco/how-many-hashes?utm_source=readme&utm_medium=badge)
```mermaid
flowchart TD

subgraph group_simulation["Collision simulation"]
  node_notebook["Run trials"]
  node_trial_csv["Trial CSV"]
end

subgraph group_analysis["Trial analysis"]
  node_r_analysis["Analyze trials<br/>[analysis.R]"]
  node_result["Analysis result"]
end

node_researcher(("Researcher"))

node_researcher -->|"runs cells"| node_notebook
node_notebook -->|"writes trials"| node_trial_csv
node_researcher -->|"runs analysis"| node_r_analysis
node_trial_csv -->|"provides trials"| node_r_analysis
node_r_analysis -->|"returns result"| node_result

click node_notebook "https://github.com/milanfusco/how-many-hashes/blob/main/how-many-hashes.ipynb"
click node_r_analysis "https://github.com/milanfusco/how-many-hashes/blob/main/analysis.R"

classDef toneNeutral fill:#f8fafc,stroke:#334155,stroke-width:1.5px,color:#0f172a
classDef toneBlue fill:#dbeafe,stroke:#2563eb,stroke-width:1.5px,color:#172554
classDef toneAmber fill:#fef3c7,stroke:#d97706,stroke-width:1.5px,color:#78350f
classDef toneMint fill:#dcfce7,stroke:#16a34a,stroke-width:1.5px,color:#14532d
classDef toneRose fill:#ffe4e6,stroke:#e11d48,stroke-width:1.5px,color:#881337
classDef toneIndigo fill:#e0e7ff,stroke:#4f46e5,stroke-width:1.5px,color:#312e81
classDef toneTeal fill:#ccfbf1,stroke:#0f766e,stroke-width:1.5px,color:#134e4a
class node_notebook,node_trial_csv toneBlue
class node_r_analysis,node_result toneAmber
class node_researcher toneIndigo
```
