require(rjson)
require(dplyr)
require(foreach)
require(doMC)




RJson_ouput <- function(OUTPUT_DIR, CONFIG){
    registerDoMC(4)
    # Read csv into R
    health_gap <- read.csv(file=sprintf('%s/Health_GAP_SHEETS_LGA_level.csv', CONFIG$OUTPUT_DIR))
    edu_gap <- read.csv(file = sprintf('%s/Education_GAP_SHEETS_LGA_level.csv', CONFIG$OUTPUT_DIR)) 
                     
    
    health_lga <- read.csv(file=sprintf('%s/Health_Mopup_and_Baseline_LGA_Aggregations.csv', CONFIG$OUTPUT_DIR)) %.% 
                        select(-lga, -state, -longitude, -latitude, matches("."))
    edu_lga <- read.csv(file=sprintf('%s/Education_Mopup_and_Baseline_LGA_Aggregations.csv', CONFIG$OUTPUT_DIR)) %.% 
                        select(-lga, -state, -longitude, -latitude, matches("."))
    water_lga <- read.csv(file=sprintf('%s/Water_Mopup_and_Baseline_LGA_Aggregations.csv', CONFIG$OUTPUT_DIR)) %.% 
                        select(-lga, -state, -longitude, -latitude, matches("."))
    external_lga <- read.csv(file=sprintf('%s/Overview_Baseline_LGA_Aggregations.csv', CONFIG$OUTPUT_DIR))
                        
    
    edu_all <- read.csv(file=sprintf('%s/Education_Mopup_and_Baseline_NMIS_Facility.csv', CONFIG$OUTPUT_DIR))
    health_all <- read.csv(file=sprintf('%s/Health_Mopup_and_Baseline_NMIS_Facility.csv', CONFIG$OUTPUT_DIR))
    water_all <- read.csv(file=sprintf('%s/Water_Mopup_and_Baseline_NMIS_Facility.csv', CONFIG$OUTPUT_DIR))
    
    # join lga level data
    lga_gap <- external_lga %.% 
                        inner_join(health_lga, by = "unique_lga") %.% 
                        inner_join(edu_lga, by = "unique_lga") %.% 
                        inner_join(water_lga, by = "unique_lga") %.% 
                        
                        inner_join(health_gap, by = "unique_lga") %.% 
                        inner_join(edu_gap, by = "unique_lga")
    
    # combine all facility level data                        
    total_facility_df <- rbind_list(edu_all, health_all, water_all)
        
    
    
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
    
    mclapply(lgas, function(lga){
        current_lga <- lga$unique_lga
        facility_df <- total_facility_df %.% filter(unique_lga == current_lga)
        facility_list <- as.list(as.data.frame(t(facility_df)))
        # remove names of the facility_list, 
        # so that the output will be a list of hash table instead of 
        # hash table with key=sequence
        names(facility_list) <- NULL
        
        lga[["facilities"]] <- facility_list
        
        output_json <- toJSON(lga)
        
        file_name <- paste(current_lga, "json", sep=".")
        output_dir <- paste(OUTPUT_DIR, file_name, sep="/")
        
        write(output_json, output_dir)
        
    })
}
