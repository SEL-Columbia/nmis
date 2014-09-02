require(rjson)
require(dplyr)
require(foreach)
source("./zip.R")



RJson_ouput <- function(OUTPUT_DIR, CONFIG){
    
    # Create ZIP FILES BEFORE JSON OUTPUT
    zip_datas(CONFIG)
    
    print("WRITING JSON FILES")
    # register Multi cores
    # Read csv into R
    health_gap <- read.csv(file=sprintf('%s/Health_GAP_SHEETS_LGA_level.csv', CONFIG$OUTPUT_DIR), stringsAsFactors=F)
    edu_gap <- read.csv(file = sprintf('%s/Education_GAP_SHEETS_LGA_level.csv', CONFIG$OUTPUT_DIR), stringsAsFactors=F) 
                     
    
    health_lga <- read.csv(file=sprintf('%s/Health_Mopup_and_Baseline_LGA_Aggregations.csv', CONFIG$OUTPUT_DIR), stringsAsFactors=F) %.% 
                        dplyr::select(-lga, -state, -longitude, -latitude, matches("."))
    edu_lga <- read.csv(file=sprintf('%s/Education_Mopup_and_Baseline_LGA_Aggregations.csv', CONFIG$OUTPUT_DIR), stringsAsFactors=F) %.% 
                        dplyr::select(-lga, -state, -longitude, -latitude, matches("."))
    water_lga <- read.csv(file=sprintf('%s/Water_Mopup_and_Baseline_LGA_Aggregations.csv', CONFIG$OUTPUT_DIR), stringsAsFactors=F) %.% 
                        dplyr::select(-lga, -state, -longitude, -latitude, matches("."))
    external_lga <- read.csv(file=sprintf('%s/Overview_Baseline_LGA_Aggregations.csv', CONFIG$OUTPUT_DIR), stringsAsFactors=F)
                        
    
    edu_all <- read.csv(file=sprintf('%s/Education_Mopup_and_Baseline_NMIS_Facility.csv', CONFIG$OUTPUT_DIR), stringsAsFactors=F)
    health_all <- read.csv(file=sprintf('%s/Health_Mopup_and_Baseline_NMIS_Facility.csv', CONFIG$OUTPUT_DIR), stringsAsFactors=F)
    water_all <- read.csv(file=sprintf('%s/Water_Mopup_and_Baseline_NMIS_Facility.csv', CONFIG$OUTPUT_DIR), stringsAsFactors=F)
    
    # join lga level data
    lga_gap <- external_lga %.% 
                        dplyr::left_join(health_lga, by = "unique_lga") %.% 
                        dplyr::left_join(edu_lga, by = "unique_lga") %.% 
                        dplyr::left_join(water_lga, by = "unique_lga") %.% 
                        
                        dplyr::left_join(health_gap, by = "unique_lga") %.% 
                        dplyr::left_join(edu_gap, by = "unique_lga")
    
    # combine all facility level data                        
    total_facility_df <- plyr::rbind.fill(edu_all, health_all, water_all)
        
    
    
    # utility function that turns Data.frame into named list
    df_to_list <- function(df){
        df_list <- split(df, rownames(df), drop=FALSE)
        df_list <- lapply(df_list, as.list)
        df_list
    }
    
    # Creating output folder
    OUTPUT_DIR <- normalizePath(OUTPUT_DIR)
    if (!file.exists(OUTPUT_DIR)){
        dir.create(OUTPUT_DIR)
    }
    
    # creating lgas level list
    lgas <- df_to_list(lga_gap)

    selective_apply <- function(agg, cb){
        if(.Platform$OS.type == 'windows'){
           return(lapply(agg, cb))
        } else {
           require('doMC')
           registerDoMC(4)
           return(mclapply(agg, cb))
        }
    }
    
    selective_apply(lgas, function(lga){
        current_lga <- lga$unique_lga
        facility_df <- total_facility_df %.% filter(unique_lga == current_lga)
        facility_list <- as.list(as.data.frame(t(facility_df)))
        # remove names of the facility_list, 
        # so that the output will be a list of hash table instead of 
        # hash table with key=sequence
        names(facility_list) <- NULL
        
        lga[["facilities"]] <- facility_list
        
        output_json <- toJSON(lga)
        # R converts all data types into string during the row split process, 
        # hack to render a proper json output
        output_json <- gsub('\" TRUE\"', replacement = 'true', output_json)
        output_json <- gsub('\"FALSE\"', replacement = 'false', output_json)
        output_json <- gsub('\"NA\"', replacement = 'null', output_json)
        
        file_name <- paste(current_lga, "json", sep=".")
        output_dir <- normalizePath(paste(OUTPUT_DIR, file_name, sep="/"))
        
        write(output_json, output_dir)
        
    })
}
