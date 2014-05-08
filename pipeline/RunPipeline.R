source('CONFIG.R')
require(formhub); require(dplyr)

################ EDUCATION ####################################################
source("nmis_functions.R"); source("0_normalize.R"); source("2_outlier_cleaning.R");
source("3_facility_level.R"); source("4_lga_level.R")

### LOAD DOWNLOAD(ed) EDUCATION DATA
edu_mopup_new <- readRDS(sprintf("%s/education_mopup_new.RDS", CONFIG$MOPUP_DATA_DIR))
edu_mopup_pilot <- readRDS(sprintf("%s/mopup_questionnaire_education_final.RDS",CONFIG$MOPUP_DATA_DIR))
edu_mopup <- readRDS(sprintf("%s/education_mopup.RDS",CONFIG$MOPUP_DATA_DIR))

### 0. NORMALIZE (and merge)
edu_mopup_all <- rbind(normalize_mopup(edu_mopup, 'mopup', 'education'),
                       normalize_mopup(edu_mopup_new, 'mopup_new', 'education'),
                       normalize_mopup(edu_mopup_pilot, 'mopup_pilot', 'education'))
rm(edu_mopup, edu_mopup_new, edu_mopup_pilot)

### 2. OUTLIERS
edu_mopup_all <- education_outlier(edu_mopup_all)

### 3. FACILITY LEVEL
edu_mopup_all <- education_mopup_facility_level(edu_mopup_all)

### 4. LGA LEVEL
## 4.1 load in 2012 data
edu_baseline_2012 <- tbl_df(readRDS(CONFIG$BASELINE_EDUCATION))
edu_baseline_2012 <- normalize_2012(edu_baseline_2012, '2012', 'education')
## 4.2 find common indicators, and rbind the common set
common_indicators <- intersect(names(edu_baseline_2012), names(edu_mopup_all))
edu_all <- rbind(edu_baseline_2012[common_indicators], edu_mopup_all[common_indicators])
rm(edu_baseline_2012, edu_mopup_all)
## 4.3 aggregate
edu_lga <- education_mopup_lga_indicators(edu_all)

### 5. OUTPUT
necessary_ef_indicators <- get_necessary_indicators()$facility$education
saveRDS(edu_mopup_all[necessary_indicators], sprintf('%s/Education_mopup_NMIS_Facility.rds', CONFIG$OUTPUT_DIR))
write.csv(edu_all[necessary_indicators], sprintf('%s/Education_mopup_NMIS_Facility.csv', CONFIG$OUTPUT_DIR), 
          row.names=F)

#TODO: necessary indicators subset 
#edu_lga <- edu_lga[get_necessary_indicators()$lga$education]
write.csv(edu_lga, sprintf('%s/Education_mopup_LGA_Aggregations.csv', CONFIG$OUTPUT_DIR), 
          row.names=F)
rm(list=setdiff(ls(), "CONFIG"))

################ HEALTH ####################################################
source("nmis_functions.R"); source("0_normalize.R"); source("2_outlier_cleaning.R");
source("3_facility_level.R"); source("4_lga_level.R")

### LOAD DOWNLOAD(ed) HEALTH DATA
health_mopup <- readRDS(sprintf("%s/health_mopup.RDS",CONFIG$MOPUP_DATA_DIR))
health_mopup_new <- readRDS(sprintf("%s/health_mopup_new.RDS", CONFIG$MOPUP_DATA_DIR))
health_mopup_pilot <- readRDS(sprintf("%s/mopup_questionnaire_health_final.RDS",CONFIG$MOPUP_DATA_DIR))

### 0. NORMALIZE (and merge)
health_mopup_all <- rbind(normalize_mopup(health_mopup, 'mopup', 'health'),
                          normalize_mopup(health_mopup_new, 'mopup_new', 'health'),
                          normalize_mopup(health_mopup_pilot, 'mopup_pilot', 'health'))
rm(health_mopup, health_mopup_new, health_mopup_pilot)

### 2. OUTLIERS
health_mopup_all <- health_outlier(health_mopup_all)

### 3. FACILITY LEVEL
health_mopup_all <- health_mopup_facility_level(health_mopup_all)

### 4. LGA LEVEL
## 4.1 load in 2012 data
health_baseline_2012 <- tbl_df(readRDS(CONFIG$BASELINE_HEALTH))
health_baseline_2012 <- normalize_2012(health_baseline_2012, '2012', 'health')
## 4.2 find common indicators, and rbind the common set
common_indicators <- intersect(names(health_baseline_2012), names(health_mopup_all))
health_all <- rbind(health_baseline_2012[common_indicators], health_mopup_all[common_indicators])
rm(health_baseline_2012, health_mopup_all)
## 4.3 aggregate
health_lga <- health_mopup_lga_indicators(health_all)

## 5. OUTPUT
health_all <- health_all[get_necessary_indicators()$facility$health]
saveRDS(health_all, sprintf('%s/Health_mopup_NMIS_Facility.rds', CONFIG$OUTPUT_DIR))
write.csv(health_all, sprintf('%s/Health_mopup_NMIS_Facility.csv', CONFIG$OUTPUT_DIR),
          row.names=F)
#TODO: necessary indicators subset 
#health_lga <- health_lga[get_necessary_indicators()$lga$health]
write.csv(health_lga, sprintf('%s/Health_mopup_LGA_Aggregations.csv',
            CONFIG$OUTPUT_DIR), row.names=F)