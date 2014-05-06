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


