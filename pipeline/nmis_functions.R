######################################################################################################
#Mopup Integration: Functions Script##################################################################
######################################################################################################

# Formats a percentage given scalar numerator and denominator
## NOTE: If changed, split_percent_columns will also have to be changed
percent_format <- function(numerator, denominator) {
    ifelse(is.finite(numerator) & is.finite(denominator) & (denominator > 0),
           sprintf("%1.0f%% (%i/%i)", 100 * numerator / denominator, numerator, denominator),
           "NA"
    )
}

pct_convtr <- function(col){
    return(ifelse(is.finite(col), 
                  paste(format(round(col*100, digits=0), nsmall=0, trim=T), "%", sep=""),
                  NA))
}


# Utility function that takes a data_frame, where a part of the data is percent_format-ted
# Output is a data_frame, where each of those indicators instead as three different column.
# eg. percent_functional column (percent_formatted) would turn 3 numerical columns:
# percent_functional_percent, percent_functional_numerator, percent_functional_denominator
split_percent_columns <- function(data_frame) {
    stopifnot(!any(str_detect(names(data_frame), "[.]")))
    # Helper: check whether a column is percent_formatted
    is_in_percent_format <- function(column) { any(stringr::str_detect(column, "%")) }
    
    # Numbers from percent_format. ie, "Inverse" the percent format operation.
    data_frame_from_percent_format <- function(col_in_percent_format) {
        # If nothing is percent formatted, don't even bother
        if(!is_in_percent_format(col_in_percent_format)) return(col_in_percent_format)
        
        # Else, the real logic starts
        splitted <- str_extract_all(col_in_percent_format, '[0-9]+')
        ldply(splitted, function(vec) {
            if(length(vec) == 3) { # could extract everything
                vec = as.numeric(vec)
                data.frame(percent = vec[1], numerator = vec[2], denominator = vec[3])    
            } else {               # couldn't extract everything, infinity or NA in source
                data.frame(percent = NA, numerator = NA, denominator = NA)
            }
        })
    }
    
    # Now we run data_frame_from_percent_format on only those columns that are percent_formatted
    res <- colwise(data_frame_from_percent_format)(data_frame)
    # colwise results in nested data frame, unnest them:
    nested_cols <- unlist(colwise(is.data.frame)(res))
    nested_cols <- names(nested_cols)[nested_cols]
    unnested_cols <- setdiff(names(res), nested_cols)
    res <- cbind(res[,unnested_cols], do.call(cbind, res[,nested_cols]))
    # colwise joins by ".", but we want to join by "_", so do that, and return
    names(res) <- str_replace(names(res), "[.]", "_")
    res
}

# Ratio: produces the ratio of a numerator and a denominator column. Includes functionality to:
# (1) exclude observation with NA in either numerator or denominator
# (2) output something in the format: 87% (87 out of 100)
ratio <- function(numerator, denominator, format="none") {
    df <- na.omit(data.frame(num=numerator, den=denominator))
    switch(format, 
           none = return(round(sum(df$num) / sum(df$den))),
           percent = return(percent_format(sum(df$num), sum(df$den))),
           ratio = return(str_c(round(sum(df$num) / sum(df$den)), " : 1")))
}

# Percent: produces the percent true for a boolean-valued column. Includes functionality to:
# (1) drop NA
# (2) output something in the format: 87% (87 out of 100)
# (3) an optional filter, which prefilters the vector before calculating percent
percent <- function(boolean_vector, filter=NULL) {
    stopifnot(class(boolean_vector) == 'logical')
    if (!is.null(filter)) {
        stopifnot(class(filter) == 'logical')
        boolean_vector = boolean_vector[filter]
    }
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
    ind = function(x) { 
        if (is.list(x$indicators)) {
            c(unlist(sapply(x$indicators, ind))) # specifically for water nested indicators
        } else {
            x$indicators
        }
    }

    indicators_for_sector = function(sector, all_indicators) {
        unlist(sapply(all_indicators[[sector]], ind))
    }
    
    ## "EXTRAS": Indicators hardcoded in the NMIS code
    facility_level_extras = c("formhub_photo_id", "facility_name", "gps", "survey_id", "unique_lga")
    lga_level_extras = c("lga", "unique_lga", "state", "latitude", "longitude")
    ## facility level: education and health indicators should include anything in the overview tab as well
    facility_indicators = RJSONIO::fromJSON("../static/explore/facilities_view.json")
    facility_indicators$education <- unique(c(indicators_for_sector('education', facility_indicators), 
                                       indicators_for_sector('overview', facility_indicators),
                                       facility_level_extras))
    facility_indicators$health <- unique(c(indicators_for_sector('health', facility_indicators), 
                                    indicators_for_sector('overview', facility_indicators),
                                    facility_level_extras))
    facility_indicators$water <- unique(c(indicators_for_sector('water', facility_indicators), 
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
    lga_indicators$water <- c(indicators_for_sector('water', lga_indicators),
                                  overview_json[[2]][3][[1]]$indicators,
                                  lga_level_extras)
    lga_indicators$overview <- c(overview_json$overview,
                                 unlist(sapply(overview_json$mdg_status, ind)),
                                 lga_level_extras)
    
    ### RETURN
    list(facility=list(health=facility_indicators$health, 
                       education=facility_indicators$education,
                       water=facility_indicators$water), 
         lga=list(health=lga_indicators$health, 
                  education=lga_indicators$education,
                  water=lga_indicators$water,
                  overview=lga_indicators$overview))
}

# Hash functions to generate facility UID
gen_num = function() {
    return(sample.int(26^5-1, 1, replace=F))
}

base26 = function(num, dig_str="") {
    dig = num %% 26
    letter = toupper(letters)[dig+1]
    dig_str = paste(letter, dig_str, sep="")
    if (num %/% 26 >= 1) {
        base26(num %/% 26, dig_str)
    } else {
        append_a = paste(rep("A", 5 - nchar(dig_str)), collapse="", sep="")
        dig_str = paste(append_a, dig_str, sep="")
        return(dig_str)
    }
}

gen_facility_id = function(){
    return(base26(gen_num()))
}

# time conversions
iso8601DateTimeConvert <- function(x) { ymd_hms(str_extract(x, '^[^+Z]*(T| )[^+Z-]*')) } #TODO: get rid of this

get_epoch <- function(x) {as.integer(as.POSIXct(iso8601DateTimeConvert(x)))}
        
sector_prefix <- function(facility_id, sector) {
    return(ifelse(is.na(facility_id), 
                  NA,
                  paste(toupper(substr(sector, 1, 1)), toupper(facility_id), sep='')))
}

parse_gps <- function(gps){
    return(do.call(rbind, strsplit(as.character(gps), ' ')))
}
get_lat <- function(gps){
    return(as.numeric(parse_gps(gps)[,1]))
}
get_lon <- function(gps){
    return(as.numeric(parse_gps(gps)[,2]))
}