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



