source('CONFIG.R')
require(formhub); require(dplyr)

### LOAD DOWNLOAD(ed) EDUCATION DATA
# source("Download.R") # if you need to re-download data
edu_mopup_new <- readRDS("data/education_mopup_new.RDS")
edu_mopup_pilot <- readRDS("data/mopup_questionnaire_education_final.RDS")
edu_mopup <- readRDS("data/education_mopup.RDS")

### 1. NORMALIZE
source("0_normalize.R")
edu_mopup_all <- rbind(normalize_mopup(edu_mopup, 'mopup', 'education'),
                       normalize_mopup(edu_mopup_new, 'mopup_new', 'education'),
                       normalize_mopup(edu_mopup_pilot, 'mopup_pilot', 'education'))
rm(edu_mopup, edu_mopup_new, edu_mopup_pilot)
### 2. TODO: OUTLIERS

### 3. FACILITY LEVEL
source('3_facility_level.R')
edu_mopup_all <- education_mopup_facility_level(edu_mopup_all)
source('T0_indicator_checks.R')
missing_indicators(edu_mopup_all, facility_indicators, 'education')
necessary_indicators <- intersect(names(edu_mopup_all), 
    names(readRDS(sprintf("%s/Education_774_NMIS_Facility.rds", normalizePath(PATH_NMISFACILITY_DATA)))))
saveRDS(edu_mopup_all[necessary_indicators], 'data/output_data/Education_mopup_NMIS_Facility.rds')

### 4. LGA LEVEL
# source('4_lga_level.R')
# edu_lga <- education_mopup_lga_indicators(edu_mopup_all)
# missing_indicators(edu_lga, lga_indicators, 'education')

rm(list=ls())


### LOAD DOWNLOAD(ed) HEALTH DATA
# source("Download.R") # if you need to re-download data
health_mopup <- readRDS("data/health_mopup.RDS")
health_mopup_new <- readRDS("data/health_mopup_new.RDS")
health_mopup_pilot <- readRDS("data/mopup_questionnaire_health_final.RDS")

### 0. NORMALIZE
source("0_normalize.R")
health_mopup_all <- rbind(normalize_mopup(health_mopup, 'mopup', 'health'),
                          normalize_mopup(health_mopup_new, 'mopup_new', 'health'),
                          normalize_mopup(health_mopup_pilot, 'mopup_pilot', 'health'))
rm(health_mopup, health_mopup_new, health_mopup_pilot)

### 2. TODO: OUTLIERS

### 3. FACILITY LEVEL
source('3_facility_level.R')
health_mopup_all <- health_mopup_facility_level(health_mopup_all)
source('T0_indicator_checks.R')
missing_indicators(health_mopup_all, facility_indicators, 'health')
necessary_indicators <- intersect(names(health_mopup_all), 
    names(readRDS(sprintf("%s/Health_774_NMIS_Facility.rds", normalizePath(PATH_NMISFACILITY_DATA)))))
saveRDS(health_mopup_all[necessary_indicators], 'data/output_data/Health_mopup_NMIS_Facility.rds')

### 4. LGA LEVEL
# source('4_lga_level.R')
# health_lga <- health_mopup_lga_indicators(health_mopup_all)
# missing_indicators(health_lga, lga_indicators, 'health')
