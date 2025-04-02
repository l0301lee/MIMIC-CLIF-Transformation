# Load necessary libraries
library(data.table)
library(dplyr)
library(lubridate)
library(arrow)
library(here)

# Define file paths using here()
chartevents_path <- here("data", "chartevents.csv")
mappings_path <- here("data", "mappings.csv")
output_path <- here("outputs", "clif_vitals.parquet")

# Read data files
chartevents <- fread(chartevents_path) # MIMIC-III data
mappings <- fread(mappings_path) # ItemID to CLIF vitals mappings
colnames(mappings)[16] <- "meas_site_alt"


# Drop unnecessary columns that might cause issues
mappings <- mappings %>%
  rename(label = `label = vital_name`) %>%
  select(itemid, vital_category, label, meas_site_name) %>%
  filter(vital_category != "NO MAPPING")

# Ensure each `itemid` has a unique mapping (keep first occurrence)
mappings_unique <- mappings %>%
  distinct(itemid, .keep_all = TRUE)

# Standardize datetime format for CLIF Vitals (UTC format)
chartevents[, charttime := parse_date_time(charttime, orders = "%m/%d/%Y %H:%M", tz = "UTC")]
chartevents[, storetime := parse_date_time(storetime, orders = "%m/%d/%Y %H:%M", tz = "UTC")]

# Select relevant columns
chartevents_selected <- chartevents %>%
  select(subject_id, hadm_id, stay_id, charttime, itemid, valuenum, valueuom)

# Merge with mappings to get CLIF vital categories
chartevents_mapped <- chartevents_selected %>%
  inner_join(mappings_unique, by = "itemid") %>% 
  filter(vital_category != "NO MAPPING")

# used inner_join() because I only want rows that have known mappings.
# if I used left_join(), I'd get all chartevents_selected rows, and unmatched ones would have NA in vital_category

# Fix data type mismatches before final transformation
clif_vitals <- chartevents_mapped %>%
  rename(
    hospitalization_id = stay_id,
    recorded_dttm = charttime,
    vital_name = label,
    vital_category = vital_category,
    vital_value = valuenum,
    meas_site_name = meas_site_name
  ) %>%
  mutate(
    hospitalization_id = as.character(hospitalization_id),
    recorded_dttm = as.POSIXct(recorded_dttm, format = "%Y-%m-%d %H:%M:%S", tz = "UTC")
  ) %>%
  select(hospitalization_id, recorded_dttm, vital_name, vital_category, vital_value, meas_site_name, valueuom)

# Convert measurement units
clif_vitals <- clif_vitals %>%
  mutate(
    vital_value = case_when(
      vital_category == "temp_c" & valueuom == "F" ~ (vital_value - 32) * (5/9),
      vital_category == "height_cm" & valueuom == "in" ~ vital_value * 2.54,
      vital_category == "weight_kg" & valueuom == "lb" ~ vital_value / 2.205,
      TRUE ~ vital_value
    )
  ) %>%
  select(-valueuom)

# Define threshold table with updated vital names and conversions
thresholds <- data.table(
  vital_category = c("height_cm", "weight_kg", "sbp", "dbp", "map", 
                     "heart_rate", "respiratory_rate", "spo2", "temp_c"),
  lower_limit = c(30 * 2.54, 30, 0, 0, 0, 0, 0, 50, 32),
  upper_limit = c(96 * 2.54, 1100, 300, 200, 250, 300, 60, 100, 44)
)

replace_outliers_custom <- function(df, thresholds) {
  df <- merge(df, thresholds, by = "vital_category", all.x = TRUE)
  df[, vital_value := ifelse(vital_value < lower_limit | vital_value > upper_limit, NA, vital_value)]
  df[, c("lower_limit", "upper_limit") := NULL]
  return(df)
}

# Apply the outlier function
clif_vitals <- replace_outliers_custom(clif_vitals, thresholds)

# Create outputs directory if it doesn't exist
if (!dir.exists(here("outputs"))) {
  dir.create(here("outputs"))
}

# Save as Parquet file
write_parquet(clif_vitals, output_path)
