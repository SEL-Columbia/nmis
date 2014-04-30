source('CONFIG.R')
require(formhub); require(dplyr)

### LOAD DOWNLOAD(ed) EDUCATION DATA
# source("Download.R") # if you need to re-download data
edu_661 <- tbl_df(readRDS(FACILITY_FILE_774$EDUCATION))
edu_mopup <- readRDS("data/output_data/Education_mopup_NMIS_Facility.rds")

### 1. NORMALIZE (Note: this encompasses 2. OUTLIERS and 3. FACILITY LEVEL, for 661)
source("0_normalize.R")
edu_661 <- normalize_661(edu_661, '661', 'education')
common_indicators <- intersect(names(edu_661), names(edu_mopup))
edu_all <- rbind(edu_661[common_indicators], edu_mopup[common_indicators])
rm(edu_661, edu_mopup)

### 4. LGA LEVEL
source('4_lga_level.R')
edu_lga <- education_mopup_lga_indicators(edu_all)
saveRDS(edu_lga, 'data/output_data/Education_mopup_LGA_Aggregations.rds')
rm(edu_lga)


### LOAD DOWNLOAD(ed) Health DATA
# source("Download.R") # if you need to re-download data
health_661 <- tbl_df(readRDS(FACILITY_FILE_774$HEALTH))
health_mopup <- readRDS("data/output_data/Health_mopup_NMIS_Facility.rds")

### 1. NORMALIZE (Note: this encompasses 2. OUTLIERS and 3. FACILITY LEVEL, for 661)
health_661 <- normalize_661(health_661, '661', 'health')
common_indicators <- intersect(names(health_661), names(health_mopup))
health_all <- rbind(health_661[common_indicators], health_mopup[common_indicators])
rm(health_661, health_mopup)

### 4. LGA LEVEL
source('4_lga_level.R')
health_lga <- health_mopup_lga_indicators(health_all)
saveRDS(health_lga, 'data/output_data/Health_mopup_LGA_Aggregations.rds')
rm(health_lga)
