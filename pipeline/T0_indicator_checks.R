source('CONFIG.R')
nmis_file <- function(fname) { sprintf('%s/%s', PATH_NMISREPO, fname)}

facility_indicators = RJSONIO::fromJSON(nmis_file("static/explore/facilities_view.json"))
facility_indicators$health <- c(facility_indicators$health, facility_indicators$overview)
facility_indicators$education <- c(facility_indicators$education, facility_indicators$overview)

lga_indicators = RJSONIO::fromJSON(nmis_file("static/explore/lga_view.json"))
overview_indicators = RJSONIO::fromJSON(nmis_file("static/explore/lga_overview.json"))
lga_indicators$health <- c(lga_indicators$health, overview_indicators[[2]][1])
lga_indicators$education <- c(lga_indicators$education, overview_indicators[[2]][2])

indicators_for_sector = function(sector, all_nmis_indicators) {
    unique(unlist(llply(all_nmis_indicators[[sector]], 
                        function(x) { x$indicators })))
}
rm(overview_indicators)

## Check missing indicators according to NMIS facility_view.json
missing_indicators = function(df, nmis_indicators, sector) {   
    sector_indicators = indicators_for_sector(sector, nmis_indicators)
    return(sector_indicators[!sector_indicators %in% names(df)])
}
