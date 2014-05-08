source('CONFIG.R')
require(formhub); require(dplyr)

### LOAD DOWNLOAD(ed) EDUCATION DATA
    # source("Download.R") # if you need to re-download data
edu_mopup_new <- readRDS(sprintf("%s/education_mopup_new.RDS", CONFIG$MOPUP_DATA_DIR))
edu_mopup_pilot <- readRDS(sprintf("%s/mopup_questionnaire_education_final.RDS",CONFIG$MOPUP_DATA_DIR))
edu_mopup <- readRDS(sprintf("%s/education_mopup.RDS",CONFIG$MOPUP_DATA_DIR))

### 1. NORMALIZE
source("0_normalize.R")
edu_mopup_all <- rbind(normalize_mopup(edu_mopup, 'mopup', 'education'),
                       normalize_mopup(edu_mopup_new, 'mopup_new', 'education'),
                       normalize_mopup(edu_mopup_pilot, 'mopup_pilot', 'education'))
rm(edu_mopup, edu_mopup_new, edu_mopup_pilot)

### 2. OUTLIERS
source('2_outlier_cleaning.R')
edu_mopup_all <- education_outlier(edu_mopup_all)

### 3. FACILITY LEVEL
source('3_facility_level.R')
edu_mopup_all <- education_mopup_facility_level(edu_mopup_all)
source('T0_indicator_checks.R')
missing_indicators(edu_mopup_all, facility_indicators, 'education')
necessary_indicators <- intersect(names(edu_mopup_all), 
    names(readRDS(CONFIG$BASELINE_EDUCATION)))
edu_mopup_all <- edu_mopup_all[necessary_indicators]

### 4. LGA LEVEL
source('4_lga_level.R')
edu_661 <- tbl_df(readRDS(CONFIG$BASELINE_EDUCATION))
edu_661 <- normalize_661(edu_661, '661', 'education')
common_indicators <- intersect(names(edu_661), names(edu_mopup_all))
edu_all <- rbind(edu_661[common_indicators], edu_mopup_all[common_indicators])
rm(edu_661, edu_mopup_all)
write.csv(edu_all, sprintf('%s/Education_mopup_NMIS_Facility.csv', 
                           CONFIG$OUTPUT_DIR), row.names=F)
edu_lga <- education_mopup_lga_indicators(edu_all)
write.csv(edu_lga, sprintf('%s/Education_mopup_LGA_Aggregations.csv',
            CONFIG$OUTPUT_DIR), row.names=F)
rm(edu_lga)


rm(list=setdiff(ls(), "CONFIG"))


### LOAD DOWNLOAD(ed) HEALTH DATA
# source("Download.R") # if you need to re-download data
health_mopup <- readRDS(sprintf("%s/health_mopup.RDS",CONFIG$MOPUP_DATA_DIR))
health_mopup_new <- readRDS(sprintf("%s/health_mopup_new.RDS", CONFIG$MOPUP_DATA_DIR))
health_mopup_pilot <- readRDS(sprintf("%s/mopup_questionnaire_health_final.RDS",CONFIG$MOPUP_DATA_DIR))
### 0. NORMALIZE
source("0_normalize.R")
health_mopup_all <- rbind(normalize_mopup(health_mopup, 'mopup', 'health'),
                          normalize_mopup(health_mopup_new, 'mopup_new', 'health'),
                          normalize_mopup(health_mopup_pilot, 'mopup_pilot', 'health'))
rm(health_mopup, health_mopup_new, health_mopup_pilot)

### 2. TODO: OUTLIERS
source("2_outlier_cleaning.R")
health_mopup_all <- health_outlier(health_mopup_all)

### 3. FACILITY LEVEL
source('3_facility_level.R')
health_mopup_all <- health_mopup_facility_level(health_mopup_all)
source('T0_indicator_checks.R')
missing_indicators(health_mopup_all, facility_indicators, 'health')
necessary_indicators <- intersect(names(health_mopup_all), 
    names(readRDS(CONFIG$BASELINE_HEALTH)))
health_mopup_all <- health_mopup_all[necessary_indicators]

### 4. LGA LEVEL
health_661 <- tbl_df(readRDS(CONFIG$BASELINE_HEALTH))
health_661 <- normalize_661(health_661, '661', 'health')
common_indicators <- intersect(names(health_661), names(health_mopup_all))
health_all <- rbind(health_661[common_indicators], health_mopup_all[common_indicators])
rm(health_661, health_mopup)
write.csv(health_all, sprintf('%s/Health_mopup_NMIS_Facility.csv', 
                           CONFIG$OUTPUT_DIR), row.names=F)
source('4_lga_level.R')
health_lga <- health_mopup_lga_indicators(health_all)
write.csv(health_lga, sprintf('%s/Health_mopup_LGA_Aggregations.csv',
            CONFIG$OUTPUT_DIR), row.names=F)
rm(health_lga)

