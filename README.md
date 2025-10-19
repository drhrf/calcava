# calcava – Shiny App for Calcium Imaging Data Analysis

**calcava** is an interactive [Shiny](https://shiny.posit.co/) application built in R for analyzing calcium imaging data.  
It allows researchers to explore, visualize, and quantify calcium dynamics across multiple cells or ROIs, focusing on **peak detection**, **baseline characterization**, and **interval-based descriptive statistics**.

---

## Overview

Calcium imaging experiments often generate large time-series datasets with fluorescence ratios (e.g., F340/380) across many cells. This application provides a streamlined pipeline to:

- Load and preprocess raw `.xlsx` fluorescence data.
- Visualize complete traces and highlight responsive events.
- Calculate baseline, cut-off thresholds, and response metrics.
- Analyze calcium dynamics within a specific time interval.
- Compute descriptive statistics such as responsive cell counts, response amplitude, and area under the curve (AUC).

---

## Example Output

Below is an example of the application interface showing the four main visualization panels:

![Shiny App Screenshot](Screenshot%202025-10-19%20at%2016.10.49.jpeg)

---

## Input Data Format

The application expects an Excel file (`.xlsx`) where:

- **Column 1:** Time (in seconds) labeled as `Time (sec)`  
- **Columns 2+ :** Fluorescence ratio values (`F340/380`) for each cell or ROI

Example structure:

| Time (sec) | Cell_1 | Cell_2 | Cell_3 | ... |
|------------|--------|--------|--------|-----|
| 0          | 0.72   | 0.68   | 0.75   | ... |
| 1          | 0.71   | 0.69   | 0.74   | ... |
| ...        | ...    | ...    | ...    | ... |

---

## Features

### 1. Data Preprocessing
- Automatic removal of `NA` rows.
- Baseline calculated from the first 30 time points.
- Cut-off defined as `baseline + 5 × SD`.

### 2. Visualization
- **Gráfico Completo:** Full time-series traces for all cells.
- **Pós-Cut (≥ cut):** Responsive regions above threshold.
- **Baseline (≤ cut):** Sub-threshold activity visualization.
- **Resposta Média:** Mean population response over time.

### 3. Interval Analysis
- Focused analysis within a user-defined time window.
- Calculates:
  - Total number of cells.
  - Responsive cell count and percentage.
  - Response amplitude relative to baseline.
  - AUC (area under the curve).
  - Experiment duration in seconds.

---

## How to Run

### 1. Install Required Packages

```R
install.packages(c("shiny", "tidyverse", "readxl", "DescTools", "gridExtra"))
```

### 2. Launch the App

```R
shiny::runApp("app.R")
```

## Output Tables

The “Estatística descritiva (por intervalo)” tab outputs a summary table including:

Variável                           Valor
Total_de_celulas                   50
Celulas_responsivas                32
Percentual_de_celulas_responsivas  64.0
Intensidade_no_baseline            0.72
Ponto_de_corte                     1.10
Percentual_de_aumento_de_calcio    155.5
Area_abaixo_da_curva               205.34
Duracao_do_experimento             200

## Repository Structure

calcava/
│
├─ app.R              # Main Shiny application script
├─ README.md          # Documentation (this file)
├─ example_data.xlsx  # Example dataset
└─ Screenshot 2025-10-19 at 16.10.49.jpeg 

## Repository Structure

This project is released under the MIT License.
Feel free to modify, reuse, and distribute with proper attribution.

## Citation

If you use this tool in a scientific publication, please cite this repository:

Freitas HR. calcava: Shiny application for calcium imaging data analysis. GitHub Repository: https://github.com/drhrf/calcava

