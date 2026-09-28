# =============================================================================
# prepare_data.R
# Extract and prepare data from OlinkAnalyze's built-in npx_data1 dataset
# Source: OlinkAnalyze R package (official Olink Proteomics toolkit)
# =============================================================================

suppressPackageStartupMessages({
  library(OlinkAnalyze)
  library(dplyr)
})

data(npx_data1)

# 1. Dataset for app.R (Single panel, Baseline only)
# Filter: Inflammation panel, Baseline timepoint, non-NA Treatment, Pass QC
olink_baseline <- npx_data1 %>%
  filter(
    Panel == "Olink Inflammation",
    Time == "Baseline",
    !is.na(Treatment),
    QC_Warning == "Pass"
  ) %>%
  select(SampleID, Subject, Treatment, Assay, UniProt, OlinkID,
         NPX, LOD, MissingFreq, QC_Warning, PlateID)

write.csv(olink_baseline, "data/olink_inflammation_baseline.csv",
          row.names = FALSE)

cat("--- Dataset 1: Inflammation Baseline (app.R) ---\n")
cat("Rows:", nrow(olink_baseline), "\n")
cat("Subjects:", length(unique(olink_baseline$Subject)), "\n")
cat("Proteins:", length(unique(olink_baseline$Assay)), "\n")
cat("Saved to: data/olink_inflammation_baseline.csv\n\n")

# 2. Dataset for app_multipanel.R (Multi-panel: Inflammation + Cardiometabolic; Multi-timepoint: Baseline, Week 6, Week 12)
multipanel_data <- npx_data1 %>%
  filter(
    Panel %in% c("Olink Inflammation", "Olink Cardiometabolic"),
    Time %in% c("Baseline", "Week.6", "Week.12"),
    !is.na(Treatment),
    QC_Warning == "Pass"
  ) %>%
  mutate(
    Time_Label = case_when(
      Time == "Baseline" ~ "Baseline",
      Time == "Week.6"   ~ "Week 6",
      Time == "Week.12"  ~ "Week 12",
      TRUE ~ Time
    ),
    Panel_Label = case_when(
      Panel == "Olink Inflammation"    ~ "Inflammation",
      Panel == "Olink Cardiometabolic" ~ "Cardiometabolic",
      TRUE ~ Panel
    )
  ) %>%
  select(SampleID, Subject, Treatment, Time = Time_Label, Panel = Panel_Label,
         Assay, UniProt, OlinkID, NPX, LOD, MissingFreq, PlateID, Site)

write.csv(multipanel_data, "data/olink_multipanel_data.csv",
          row.names = FALSE)

cat("--- Dataset 2: Multi-panel & Multi-timepoint (app_multipanel.R) ---\n")
cat("Rows:", nrow(multipanel_data), "\n")
cat("Panels:", paste(unique(multipanel_data$Panel), collapse = ", "), "\n")
cat("Timepoints:", paste(unique(multipanel_data$Time), collapse = ", "), "\n")
cat("Subjects:", length(unique(multipanel_data$Subject)), "\n")
cat("Saved to: data/olink_multipanel_data.csv\n")
