zip_datas <- function(CONFIG){
    
    ## Relative path of the to-be-zipped zip files
    nmis_zip <- "../static/download/nmis_dataset.zip" 
    raw_zip <- "../static/download/nmis_raw_data.zip" 
    
    ## find all MOPUP output data
    nmis_csvs <- c(normalizePath(sprintf('%s/Health_Mopup_and_Baseline_LGA_Aggregations.csv', CONFIG$OUTPUT_DIR)),
                   normalizePath(sprintf('%s/Education_Mopup_and_Baseline_LGA_Aggregations.csv', CONFIG$OUTPUT_DIR)),
                   normalizePath(sprintf('%s/Water_Mopup_and_Baseline_LGA_Aggregations.csv', CONFIG$OUTPUT_DIR)),
                   normalizePath(sprintf('%s/Education_Mopup_and_Baseline_NMIS_Facility.csv', CONFIG$OUTPUT_DIR)),
                   normalizePath(sprintf('%s/Health_Mopup_and_Baseline_NMIS_Facility.csv', CONFIG$OUTPUT_DIR)),
                   normalizePath(sprintf('%s/Water_Mopup_and_Baseline_NMIS_Facility.csv', CONFIG$OUTPUT_DIR)))
    
    ### find all RAW DATA
    ## find all RAW MOPUP data
    raw_mopup_csv <- grep("\\.csv$", ignore.case = T, value = T,
                          x = normalizePath(file.path(CONFIG$MOPUP_DATA_DIR,
                                                      list.files(CONFIG$MOPUP_DATA_DIR))))
    ## find all RAW BASELINE data
    # HARD coded file names of baseline data
    pilot_113_files <- c("Educ_Baseline_PhaseII_all_merged_cleaned_2011Nov21.csv",
                         "Pilot_Education_cleaned_2011Nov17.csv",
                         "Health_PhII_RoundI&II&III_Clean_2011.10.21.csv",
                         "Pilot_Data_Health_Clean_2011.11.18.csv",
                         "Water_Baseline_PhaseII_all_merged_cleaned_2011Nov21.csv",
                         "Pilot_Water_cleaned_2011Aug29.csv")
    
    six61_files <- c("Education_661_Merged.csv", 
                     "Health_661_Merged.csv",
                     "Water_661_Merged.csv")
    
    # file path of raw baseline data
    raw_six61_csv <- normalizePath(file.path(CONFIG$RAW_661_DIR, six61_files))
    raw_pilot_113_csv <- normalizePath(file.path(CONFIG$RAW_113_PILOT_DIR, pilot_113_files))
    
    ## Combine all raw data file path into one collection
    all_raw_csvs <- c(raw_mopup_csv, raw_six61_csv, raw_pilot_113_csv)
    
    ## Json data
    json_files <- normalizePath(file.path("../static/lgas/", list.files("../static/lgas/")))
    
    ### Output part
    ## check and create TMP folders
    if(!file.exists("~/tmp")) {dir.create("~/tmp/")}
    if(!file.exists("~/tmp/nmis_dataset/")) {dir.create("~/tmp/nmis_dataset/")}
    if(!file.exists("~/tmp/nmis_dataset/lgas")) {dir.create("~/tmp/nmis_dataset/lgas")}
    if(!file.exists("~/tmp/nmis_raw_data/")) {dir.create("~/tmp/nmis_raw_data/")}
    
    
    ## copy file to nmis data and raw data folders
    # nmis final output data
    sapply(nmis_csvs, function(file){
        file.copy(from = file, to = "~/tmp/nmis_dataset/", overwrite = T)
    })
    #json
    sapply(json_files, function(file){
        file.copy(from = file, to = "~/tmp/nmis_dataset/lgas/", overwrite = T)
    })
    # all raw data
    sapply(all_raw_csvs, function(file){
        file.copy(from = file, to = "~/tmp/nmis_raw_data/", overwrite = T)
    })
    

    
    ### zipping it! 
    zip(nmis_zip, normalizePath("~/tmp/nmis_dataset/"))
    print("NMIS DATA ZIP CREATED.")
    zip(raw_zip, normalizePath("~/tmp/nmis_raw_data/"))
    print("RAW DATA ZIP CREATED.")
    
}
