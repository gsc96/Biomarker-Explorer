# biomarker-explorer

## About This Project

This project was developed as a hands-on demonstration of building interactive web applications in **R Shiny** and performing targeted proteomics workflows. 

Rather than using toy datasets, this project utilizes `npx_data1`, a 'realistic' benchmark dataset provided by the official [`OlinkAnalyze`](https://github.com/Olink-Proteomics/OlinkAnalyze) R package from Olink Proteomics. 

Olink's Proximity Extension Assay (PEA) technology measures protein abundance in **NPX** (*Normalized Protein eXpression*), an arbitrary relative unit on a $log_2$ scale where a 1-unit increase corresponds to a doubling in protein concentration.

The dataset simulates a longitudinal clinical trial and features:
- **Two 92-protein panels:** the **Olink Inflammation** panel and the **Olink Cardiometabolic** panel (totaling 184 unique biomarkers).
- **Three timepoints:** **Baseline** (prior to therapy), **Week 6** (mid-treatment), and **Week 12** (endpoint).
- **Clinical cohorts:** Patients randomized into **Treated** and **Untreated** groups across different clinical study sites.
- **Quality Control (QC):** Built-in sample quality indicators (`QC_Warning`), which were filtered to ensure only high-quality data entered the downstream exploration.

---

## The Shiny Application (`app_multipanel.R`)

To make these multi-dimensional data accessible, I built a lightweight, demonstrative **Shiny** dashboard. The application is intentionally designed to be easy to navigate:

1. **Panel & Timepoint Exploration:** Users can select between the **Inflammation** and **Cardiometabolic** panels, and jump across timepoints (**Baseline**, **Week 6**, or **Week 12**).
2. **Reactive Protein Selection:** Switching panels dynamically updates the protein dropdown list to reflect the 92 biomarkers available in that panel.
3. **Distribution Visualizations:** Users can toggle between **Boxplots** and **Violin plots**, with individual patient NPX values overlaid as jittered points to transparently show sample dispersion.
4. **Summary & Statistical Testing:** For every selected condition, the app calculates descriptive summary statistics ($N$, Mean, SD, Median) and runs a non-parametric **Wilcoxon rank-sum test** (Mann-Whitney U) to compare the Treated versus Untreated groups.

---

## Exploratory Data Analysis & OlinkAnalyze (`eda_report.Rmd`)

In parallel with the Shiny application, I conducted an in-depth Exploratory Data Analysis (EDA) to understand the structure of the data and test the native analytical capabilities provided by the `OlinkAnalyze` package. 

Documented in **`eda_report.Rmd`** (and rendered as a self-contained **`eda_report.html`**), this analysis walks through:
- **Data Quality & QC Rates:** Examining sample-level and plate-level quality flags.
- **Batch & Plate Effects:** Visualizing global NPX distributions across plates and runs using `olink_dist_plot()`.
- **Dimensionality Reduction:** Applying both **Principal Component Analysis (PCA)** and **Uniform Manifold Approximation and Projection (UMAP)** using `olink_pca_plot()` and `olink_umap_plot()` to check for cohort clustering and potential site or batch biases.
- **Differential Expression:** Testing for biomarker differences between study arms with multiple testing correction via the Benjamini-Hochberg False Discovery Rate (FDR) procedure.

---

## Repository Structure

```
biomarker-explorer/
├── app_multipanel.R               # Main interactive Shiny application
├── app.R                          # Lightweight single-panel baseline app
├── eda_report.Rmd                 # Complete Exploratory Data Analysis in R Markdown
├── eda_report.html                # Standalone rendered HTML EDA report
├── data/
│   ├── generate_data.R            # Script extracting & preparing data from OlinkAnalyze
│   ├── olink_multipanel_data.csv  # 184 proteins across 3 longitudinal timepoints
│   └── olink_inflammation_baseline.csv # Single panel baseline dataset
└── README.md                      # Project story and documentation
```
