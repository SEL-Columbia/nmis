source('CONFIG.R')
suppressPackageStartupMessages(require(plyr))
suppressPackageStartupMessages(require(formhub))
suppressPackageStartupMessages(require(dplyr))

source("nmis_functions.R"); source("1_normalize.R"); source("2_outlier_cleaning.R");
source("3_facility_level.R"); source('4_geospatial_outlier_cleaning.R'); source("5_lga_level.R"); 
source("6_necessary_indicators.R"); source("db.R")

############################## LOAD DOWNLOADED DATA ###################################
#EDUCATION
edu_mopup_new <- readRDS(sprintf("%s/education_mopup_new.RDS", CONFIG$MOPUP_DATA_DIR))
edu_mopup_pilot <- readRDS(sprintf("%s/mopup_questionnaire_education_final.RDS",CONFIG$MOPUP_DATA_DIR))
edu_mopup <- readRDS(sprintf("%s/education_mopup.RDS",CONFIG$MOPUP_DATA_DIR))
edu_baseline_2012 <- tbl_df(readRDS(CONFIG$BASELINE_EDUCATION))
edu_baseline_2012 <- normalize_2012(edu_baseline_2012, '2012', 'education')

#HEALTH
health_mopup <- readRDS(sprintf("%s/health_mopup.RDS",CONFIG$MOPUP_DATA_DIR))
health_mopup_new <- readRDS(sprintf("%s/health_mopup_new.RDS", CONFIG$MOPUP_DATA_DIR))
health_mopup_pilot <- readRDS(sprintf("%s/mopup_questionnaire_health_final.RDS",CONFIG$MOPUP_DATA_DIR))
health_baseline_2012 <- tbl_df(readRDS(CONFIG$BASELINE_HEALTH))
health_baseline_2012 <- normalize_2012(health_baseline_2012, '2012', 'health')

#WATER
water_baseline_2012 <- tbl_df(readRDS(CONFIG$BASELINE_WATER))

################################ NORMALIZE DATA #######################################
#EDUCATION
edu_mopup_all <- rbind(normalize_mopup(edu_mopup, 'mopup', 'education'),
                       normalize_mopup(edu_mopup_new, 'mopup_new', 'education'),
                       normalize_mopup(edu_mopup_pilot, 'mopup_pilot', 'education')
)


#HEALTH
health_mopup_all <- rbind(normalize_mopup(health_mopup, 'mopup', 'health'),
                          normalize_mopup(health_mopup_new, 'mopup_new', 'health'),
                          normalize_mopup(health_mopup_pilot, 'mopup_pilot', 'health')
                          
)

#WATER
water_baseline_2012 <- normalize_2012(water_baseline_2012, '2012', 'water')

################################ REMOVE OUTLIERS #####################################
#EDUCATION
edu_mopup_all <- education_outlier(edu_mopup_all)

#HEALTH
health_mopup_all <- health_outlier(health_mopup_all)


#WATER(NA)
################################ FACILITY DATA #######################################
#EDUCATION
edu_mopup_all <- education_mopup_facility_level(edu_mopup_all)
##find common indicators, and rbind the common set
common_indicators <- intersect(names(edu_baseline_2012), names(edu_mopup_all))
edu_all <- rbind(edu_baseline_2012[common_indicators], edu_mopup_all[common_indicators])

#HEALTH
health_mopup_all <- health_mopup_facility_level(health_mopup_all)
##find common indicators, and rbind the common set
common_indicators <- intersect(names(health_baseline_2012), names(health_mopup_all))
health_all <- rbind(health_baseline_2012[common_indicators], health_mopup_all[common_indicators])
health_all <- dplyr::filter(health_all, !is.na(gps))

#WATER
#NA

rm(edu_mopup, edu_mopup_new, edu_mopup_pilot, health_mopup, health_mopup_new, health_mopup_pilot)
###############################  SYNC DB  #############################################
##database sync
edu_all <- sync_db(edu_all)
health_all <- sync_db(health_all)
water_baseline_2012 <- sync_db(water_baseline_2012)

###############################  JOIN DATA  ############################################
master <- tbl_df(rbind.fill(edu_all, health_all, water_baseline_2012))

########################## GEOSPATIAL OUTLIER CLEANING #################################
master <- master %.%
  dplyr::group_by(unique_lga) %.%
  dplyr::mutate(spatial_outlier=cluster_lga(latitude, longitude))

spatial_outliers <- subset(master, spatial_outlier==T) %.%
  dplyr::select(-spatial_outlier)

write.csv(spatial_outliers, row.names=F,
          file=sprintf('%s/Spatial_Outliers_Mopup_and_Baseline_NMIS_Facility.csv', CONFIG$OUTPUT_DIR))

master <- subset(master, spatial_outlier==F) %.%
  dplyr::select(-spatial_outlier)

rm(spatial_outliers)
################################ SPLIT DATA ###########################################
drop_na_all <- function(df){
  return(df[,unlist(lapply(df, function(x) !all(is.na(x))))])
}

edu_all <- drop_na_all(subset(master, sector=='education'))
health_all <- drop_na_all(subset(master, sector=='health'))
water_baseline_2012 <- drop_na_all(subset(master, sector=='water'))
water_baseline_2012$latitude = NA
water_baseline_2012$longitude = NA

rm(master)
############################### LGA LEVEL #############################################
#aggregate
edu_lga <- education_mopup_lga_indicators(edu_all)
edu_gap <- education_gap_sheet_indicators(edu_all)

##aggregate
health_lga <- health_mopup_lga_indicators(health_all)
health_gap <- health_gap_sheet_indicators(health_all)

#WATER
#What is nwater used for?
nwater <- get_necessary_indicators()[['facility']][['water']]
##aggregate
water_lga <- water_lga_indicators(water_baseline_2012)

########## EXTERNAL DATA ###################################################
external_data_2012 <- tbl_df(readRDS(CONFIG$BASELINE_EXTERNAL))
external_data_2012 <- normalize_external(external_data_2012)
write.csv(output_indicators(external_data_2012, 'lga', 'overview'), row.names=F,
          file=sprintf('%s/Overview_Baseline_LGA_Aggregations.csv', CONFIG$OUTPUT_DIR))

########## OUTPUT DATA #####################################################
#EDUCATION
write.csv(output_indicators(edu_all, 'facility', 'education'), row.names=F,
          file = sprintf('%s/Education_Mopup_and_Baseline_NMIS_Facility.csv', CONFIG$OUTPUT_DIR))
write.csv(output_indicators(edu_lga, 'lga', 'education'), row.names=F,
          file = sprintf('%s/Education_Mopup_and_Baseline_LGA_Aggregations.csv', CONFIG$OUTPUT_DIR))
write.csv(edu_gap, row.names=F,        ## TODO: output_indicators for gap sheets?
          file = sprintf('%s/Education_GAP_SHEETS_LGA_level.csv', CONFIG$OUTPUT_DIR))

#HEALTH
write.csv(output_indicators(health_all, 'facility', 'health'), row.names=F,
          file = sprintf('%s/Health_Mopup_and_Baseline_NMIS_Facility.csv', CONFIG$OUTPUT_DIR))
write.csv(output_indicators(health_lga, 'lga', 'health'), row.names=F,
          file = sprintf('%s/Health_Mopup_and_Baseline_LGA_Aggregations.csv', CONFIG$OUTPUT_DIR))
write.csv(health_gap, row.names=F,
          file = sprintf('%s/Health_GAP_SHEETS_LGA_level.csv', CONFIG$OUTPUT_DIR))

#WATER
write.csv(output_indicators(water_baseline_2012, 'facility', 'water'), row.names=F,
          file=sprintf('%s/Water_Mopup_and_Baseline_NMIS_Facility.csv', CONFIG$OUTPUT_DIR))
write.csv(output_indicators(water_lga, 'lga', 'water'), row.names=F,
          file=sprintf('%s/Water_Mopup_and_Baseline_LGA_Aggregations.csv', CONFIG$OUTPUT_DIR))
rm(list=setdiff(ls(), "CONFIG"))

########## JSON OUTPUT ###################################################
source("7_write_Json.R");
invisible(RJson_ouput(OUTPUT_DIR="../static/lgas/", CONFIG))
