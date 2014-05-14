######################################################################################################
#Mopup Integration: clean up before final output Cleaning##################################################################
######################################################################################################
require(dplyr)
source('nmis_functions.R')
source('CONFIG.R')
output_indicators <- function(df, lgas, level, sector) {
    colnames(df)[colnames(df)=='unique_lga'] <- 'unique_lga_2013'
    df <- df %.% join(lgas, by='unique_lga_2013')
    df <- df[get_necessary_indicators()[[level]][[sector]]]
    return(df)
}


