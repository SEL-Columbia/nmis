missing_edu <- read.csv("~/Dropbox/Nigeria/Nigeria 661 Baseline Data Cleaning/in_process_data/mop_up_matching_result/facility_missing_list_edu.csv", stringsAsFactors=FALSE)
missing_health <- read.csv("~/Dropbox/Nigeria/Nigeria 661 Baseline Data Cleaning/in_process_data/mop_up_matching_result/facility_missing_list_health.csv", stringsAsFactors=FALSE)

faciliy_list_health <- read.csv("~/Dropbox/Nigeria/Nigeria 661 Baseline Data Cleaning/archived_files/facility_lists/Facility list snapshot/FACILITY_LIST_hospitals_full_june_07.csv")
faciliy_list_edu <- read.csv("~/Dropbox/Nigeria/Nigeria 661 Baseline Data Cleaning/archived_files/facility_lists/Facility list snapshot/FACILITY_LIST_schools_full_june_07.csv")


baseline_health <- read.csv("~/Dropbox/Nigeria/Nigeria 661 Baseline Data Cleaning/output_data/data_774/final_output/Health_774_NMIS_Facility.csv",
                        stringsAsFactors=FALSE)
baseline_edu <- read.csv("~/Dropbox/Nigeria/Nigeria 661 Baseline Data Cleaning/output_data/data_774/final_output/Education_774_NMIS_Facility.csv",
                     stringsAsFactors=FALSE)

lgas <- read.csv("./data/lgas.csv", stringsAsFactors=FALSE)
lgas <- lgas %.% select(lga_id, unique_lga_2013)
baseline_edu$unique_lga <- NULL
baseline_edu <- inner_join(baseline_edu, lgas, by = "lga_id")

basel <- unique(baseline_edu$unique_lga_2013)
mopup <- unique(edu_mopup_all$unique_lga)

missed <- mopup[which(!mopup %in% basel)]
basel[which(!basel %in% mopup)]

setdiff(missed, lgas$unique_lga_2013)
new_uniq <- lgas$unique_lga
old_uniq <- lgas$unique_lga_2013

new_uniq[! new_uniq %in% old_uniq]
old_uniq[! old_uniq %in% new_uniq]
new_uniq


baseline_data_prep <- function(baseline_df){
    baseline_df$facility_id <- toupper(substr(baseline_df$facility_ID, 3, 6))
    baseline_df$survey_id <- baseline_df$uuid
    baseline_df <- baseline_df %.% select(unique_lga, facility_id, survey_id, gps)
    baseline_df$longitude <- get_lon(baseline_df$gps)
    baseline_df$latitude <- get_lat(baseline_df$gps)
    baseline_df <- baseline_df %.% dplyr::filter(!(is.na(latitude) & is.na(longitude)))
    
    return(baseline_df)
}

mopup_data_prep <- function(mopup_df){
    mopup_df$facility_id <- substr(mopup_df$facility_id, 2, 5)
    mopup_df <- mopup_df %.% select(unique_lga, facility_id, survey_id, gps)
    mopup_df$longitude <- get_lon(mopup_df$gps)
    mopup_df$latitude <- get_lat(mopup_df$gps)
    mopup_df <- mopup_df %.% dplyr::filter(!(is.na(latitude) & is.na(longitude)))
    return(mopup_df)
}

get_messed_facility_id <- function(mopup_df, baseline_df){
    messed <- c()
    for (uniq_lga in unique(mopup_df$unique_lga)){
        #     uniq_lga <- unique(mopup_edu$unique_lga)[1]    
        mopup_dat <- mopup_df %.% dplyr::filter(unique_lga == uniq_lga)
        basel_dat <- baseline_df %.% dplyr::filter(unique_lga == uniq_lga)
        common_facility_id <- dplyr::intersect(as.character(mopup_dat$facility_id), as.character(basel_dat$facility_id))
        messed <- c(messed, common_facility_id)
    }
    return(messed)
    
}

baseline_edu <- baseline_data_prep(baseline_edu)
edu_mopup_all <- mopup_data_prep(edu_mopup_all)
edu_messed_list <- get_messed_facility_id(edu_mopup_all, baseline_edu)


baseline_health <- baseline_data_prep(baseline_health)
health_mopup_all <- mopup_data_prep(health_mopup_all)
health_messed_list <- get_messed_facility_id(health_mopup_all, baseline_health)


edu_messed_mopup <- edu_mopup_all %.% filter(facility_id %in% edu_messed_list)
edu_messed_basel <- baseline_edu %.% filter(facility_id %in% edu_messed_list)
edu_pairs <- inner_join(edu_messed_mopup, edu_messed_basel, by="facility_id")


health_messed_mopup <- health_mopup_all %.% filter(facility_id %in% health_messed_list)
health_messed_basel <- baseline_health %.% filter(facility_id %in% health_messed_list)
health_pairs <- inner_join(health_messed_mopup, health_messed_basel, by="facility_id")

require(geosphere)
edu_pairs$dist <- distHaversine(cbind(edu_pairs$longitude.x, edu_pairs$latitude.x), 
                                cbind(edu_pairs$longitude.y, edu_pairs$latitude.y))

health_pairs$dist <- distHaversine(cbind(health_pairs$longitude.x, health_pairs$latitude.x), 
                                   cbind(health_pairs$longitude.y, health_pairs$latitude.y))

