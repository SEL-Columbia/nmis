require(rjson)
require(dplyr)
require(foreach)
library(doMC)




RJson_ouput <- function(BASE_DIR, nmis_lga, gap_sheet, edu_774,
                        health_774, water_774){
    registerDoMC(4)
    # join gap_sheet to lga_level as per chris' request
    nmis_lga <- merge(nmis_lga, gap_sheet, by="lga_id", all=TRUE)
    
    # utility function that turns Data.frame into named list
    df_to_list <- function(df){
        df_list <- split(df, rownames(df), drop=FALSE)
        df_list <- lapply(df_list, as.list)
        df_list
    }
    
    # Creating output folder
    BASE_DIR <- normalizePath(BASE_DIR)
    if (!file.exists(BASE_DIR)){
        dir.create(BASE_DIR)
    }
    
    # creating lgas level list
    lgas <- df_to_list(nmis_lga)
    
    # for each lga combine faciliti level indicators and append to
    # lga level indicators
    
    total_facility_df <- rbind_list(edu_774, health_774, water_774)
    
    mclapply(lgas, function(lga){
        current_lga <- lga$unique_lga
        facility_df <- total_facility_df %.% filter(unique_lga == current_lga)
        facility_list <- (as.list(as.data.frame(t(facility_df))))
        # remove names of the facility_list, 
        # so that the output will be a list of hash table instead of 
        # hash table with key=sequence
        names(facility_list) <- NULL
        
        lga[["facilities"]] <- facility_list
        
        output_json <- toJSON(lga)
        
        file_name <- paste(current_lga, "json", sep=".")
        output_dir <- paste(BASE_DIR, file_name, sep="/")
        
        write(output_json, output_dir)
        
    })
}