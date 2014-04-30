PATHS = RJSONIO::fromJSON("CONFIG.JSON")

sapply(PATHS, function(path) {
    if(!file.exists(path)) 
       stop("CONFIG.JSON contains non-existent file path:", path)
})

FACILITY_FILE_774 = list(EDUCATION = sprintf("%s/Education_774_NMIS_Facility.rds",
                                             PATHS['NMIS_774_FACILITY_DATA']),
                         HEALTH = sprintf("%s/Health_774_NMIS_Facility.rds",
                                          PATHS['NMIS_774_FACILITY_DATA']))
