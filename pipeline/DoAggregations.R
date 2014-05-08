source('CONFIG.R')
require(formhub); require(dplyr)

### LOAD DOWNLOAD(ed) EDUCATION DATA
# source("Download.R") # if you need to re-download data
edu_661 <- tbl_df(readRDS(CONFIG$BASELINE_EDUCATION))
edu_mopup <- readRDS(sprintf('%s/Education_mopup_NMIS_Facility.rds', CONFIG$OUTPUT_DIR))

### 1. NORMALIZE (Note: this encompasses 2. OUTLIERS and 3. FACILITY LEVEL, for 661)
source("0_normalize.R")
edu_661 <- normalize_661(edu_661, '661', 'education')
common_indicators <- intersect(names(edu_661), names(edu_mopup))
edu_all <- rbind(edu_661[common_indicators], edu_mopup[common_indicators])
rm(edu_661, edu_mopup)
write.csv(edu_all, sprintf('%s/Education_mopup_NMIS_Facility.csv', 
                           CONFIG$OUTPUT_DIR), row.names=F)

### 4. LGA LEVEL
source('4_lga_level.R')
edu_lga <- education_mopup_lga_indicators(edu_all)
#saveRDS(edu_lga, sprintf('%s/Education_mopup_LGA_Aggregations.rds',
#            CONFIG$OUTPUT_DIR))
write.csv(edu_lga, sprintf('%s/Education_mopup_LGA_Aggregations.csv',
            CONFIG$OUTPUT_DIR), row.names=F)
rm(edu_lga)


### LOAD DOWNLOAD(ed) Health DATA
# source("Download.R") # if you need to re-download data
source("0_normalize.R")
health_661 <- tbl_df(readRDS(CONFIG$BASELINE_HEALTH))
health_mopup <- readRDS(sprintf('%s/Health_mopup_NMIS_Facility.rds', CONFIG$OUTPUT_DIR))

### 1. NORMALIZE (Note: this encompasses 2. OUTLIERS and 3. FACILITY LEVEL, for 661)
health_661 <- normalize_661(health_661, '661', 'health')
common_indicators <- intersect(names(health_661), names(health_mopup))
health_all <- rbind(health_661[common_indicators], health_mopup[common_indicators])
rm(health_661, health_mopup)
write.csv(health_all, sprintf('%s/Health_mopup_NMIS_Facility.csv', 
                           CONFIG$OUTPUT_DIR), row.names=F)

### 4. LGA LEVEL
source('4_lga_level.R')
health_lga <- health_mopup_lga_indicators(health_all)
#saveRDS(health_lga, sprintf('%s/Health_mopup_LGA_Aggregations.rds', CONFIG$OUTPUT_DIR))
write.csv(health_lga, sprintf('%s/Health_mopup_LGA_Aggregations.csv',
            CONFIG$OUTPUT_DIR), row.names=F)
rm(health_lga)
