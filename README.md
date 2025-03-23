# MIMIC-CLIF-Transformation

## Overview
This repository contains an R script to transform vital signs data from the MIMIC-III dataset (`chartevents.csv`) into the CLIF Vitals format. The transformed data is formatted according to the Clinical Informatics Framework (CLIF) specifications, ready for data quality assessment using the CLIF Lighthouse tool.

---

## Directory Structure
```
MIMIC-CLIF-Transformation/
├── data/
│   ├── chartevents.csv        # Raw MIMIC-III vital signs data
│   └── mappings.csv           # ItemID mappings to CLIF vital categories
├── outputs/
│   └── clif_vitals.parquet    # Transformed data in CLIF format (output)
├── CLIF_formatting.R          # R script for transformation
├── data_quality_results/      # Folder for evaluation results
│   ├── Vitals_category_summary_statistics.csv
│   ├── Vitals_missingness.csv
│   ├── Vitals_validation_results.csv
│   ├── Vitals_vital_category_value_distribution.png
│   └── Vitals_vital_name_mapping.csv
└── README.md                  # Documentation for project setup and execution
```

---

## Requirements
- **R (>= 4.0)**
- **R packages:**
  - `data.table`
  - `dplyr`
  - `lubridate`
  - `arrow`
  - `here`

Install the required packages in R:

```r
install.packages(c("data.table", "dplyr", "lubridate", "arrow", "here"))
```

---

## Running the Script

To execute the transformation script from your terminal, navigate to the project directory and run:

```bash
cd /yourpath
Rscript CLIF_formatting.R
```

**Output**:  
The script generates `clif_vitals.parquet` in the `outputs/` folder.

---

## Data Quality Evaluation

The resulting `clif_vitals.parquet` file should be uploaded to the **CLIF Lighthouse** tool to evaluate data quality, including checks for completeness, accuracy, and consistency. The tool can be downloaded from the link below.

**CLIF Lighthouse**:  
https://github.com/Common-Longitudinal-ICU-data-Format/CLIF-Lighthouse

The results of the evaluation are in the `data_quality_results` folder.

---

## Notes on Implementation
- Vital signs units are standardized (e.g., Fahrenheit converted to Celsius, pounds to kilograms).
- Outliers are identified and replaced with `NA` based on defined physiological thresholds.
- Path management is handled using the R package `here`, allowing easy portability of the project.

---

## Author
- **June Yun**  
  - Date: **2025-03-20**
