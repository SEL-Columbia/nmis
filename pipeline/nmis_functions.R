######################################################################################################
#Mopup Integration: Functions Script##################################################################
######################################################################################################

# Formats a percentage given scalar numerator and denominator
percent_format <- function(numerator, denominator) {
    sprintf("%1.0f%% (%i out of %i)", 100 * numerator / denominator, numerator, denominator)
}

# Ratio: produces the ratio of a numerator and a denominator column. Includes functionality to:
# (1) exclude observation with NA in either numerator or denominator
# (2) output something in the format: 87% (87 out of 100)
ratio <- function(numerator, denominator, as.percent=FALSE) {
    df <- na.omit(data.frame(num=numerator, den=denominator))
    if(as.percent) return(percent_format(sum(df$num), sum(df$den)))
    else return(round(sum(df$num) / sum(df$den)))
}

# Percent: produces the percent true for a boolean-valued column. Includes functionality to:
# (1) drop NA
# (2) output something in the format: 87% (87 out of 100)
percent <- function(boolean_vector) {
    stopifnot(class(boolean_vector) == 'logical')
    percent_format(sum(boolean_vector, na.rm=T), length(na.omit(boolean_vector)))
}

# between is a helper function that returns a boolan TRUE if the value falls in
# between min and max, with a flag "inclusive" set to False by default
between <- function(value, min, max, inclusive=F) { 
  if(inclusive) { 
    value >= min & value <= max 
  } else { 
    value > min & value < max 
  }
}

# outside is a helper function that returns a boolan TRUE if the value falls
# outside of min and max, with a flag "inclusive" set to False by default
# outside is just a reverse call of between
outside <- function(value, min, max, inclusive=F) {
    !(between(value, min, max, !inclusive))
}

## Get the indicators that are necessary for NMIS.
## Reads from json files within ../static/explore, in addition to adding some "hard-coded" indicators.
## Returns a two-element list, one with name lga_level, and the other facility_level
get_necessary_indicators <- function() {
    indicators_for_sector = function(sector, all_indicators) {
        unlist(sapply(all_indicators[[sector]], 
                             function(x) { x$indicators }))
    }
    ## "EXTRAS": Indicators hardcoded in the NMIS code
    facility_level_extras = c("formhub_photo_id", "facility_name", "gps", "uuid")
    lga_level_extras = c("lga", "unique_lga", "state", "latitude", "longitude")
    ## facility level: education and health indicators should include anything in the overview tab as well
    facility_indicators = RJSONIO::fromJSON("../static/explore/facilities_view.json")
    facility_indicators$education <- unique(c(indicators_for_sector('education', facility_indicators), 
                                       indicators_for_sector('overview', facility_indicators),
                                       facility_level_extras))
    facility_indicators$health <- unique(c(indicators_for_sector('health', facility_indicators), 
                                    indicators_for_sector('overview', facility_indicators),
                                    facility_level_extras))
    ## lga level: education and health indicators should include specific items in the overview tab as well
    lga_indicators = RJSONIO::fromJSON("../static/explore/lga_view.json")
    overview_json = RJSONIO::fromJSON("../static/explore/lga_overview.json")
    ### NOTE: THE FOLLOWING IS A BIT BRITTLE
    lga_indicators$health <- c(indicators_for_sector('health', lga_indicators),
                               overview_json[[2]][1][[1]]$indicators,
                               lga_level_extras)
    lga_indicators$education <- c(indicators_for_sector('education', lga_indicators),
                                  overview_json[[2]][2][[1]]$indicators,
                                  lga_level_extras)
    ### RETURN
    list(facility=list(health=facility_indicators$health, education=facility_indicators$education), 
         lga=list(health=lga_indicators$health, education=lga_indicators$education))
}