######################################################################################################
#Mopup Integration: clean up before final output Cleaning##################################################################
######################################################################################################
require(dplyr)
source('nmis_functions.R')
source('CONFIG.R')

lga_data <- read.csv("data/lgas.csv") %.% 
    dplyr::select(matches('lga'), pop_2006, area_sq_km, latitude, longitude, state, zone, lga_id)

output_indicators <- function(df, level, sector) {
    needed_indicators = get_necessary_indicators()[[level]][[sector]]
    df <- df %.% 
        select(unique_lga_2013 = unique_lga, matches('.')) %.% # rename unique_lga to unique_lga_2013
        join(lga_data, by='unique_lga_2013')
    if(!all(needed_indicators %in% names(df))) {
        stop(sprintf("Missing %s-level indicators for %s: ", level, sector),
             paste(setdiff(needed_indicators, names(df)), collapse = ", "))
    }
    df <- df[needed_indicators]
    return(df)
}


