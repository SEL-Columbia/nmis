######################################################################################################
#Mopup Integration: Functions Script##################################################################
######################################################################################################

#indicator functions##########################################################################
ratio <- function(numerator, denominator) {
    df <- na.omit(data.frame(num=numerator, den=denominator))
    sum(df$num) / sum(df$den)
}

between <- function(value, min, max, inclusive=F) { 
  if(inclusive) { 
    value >= min & value <= max 
  } else { 
    value > min & value < max 
  }
}

outside <- function(value, min, max, inclusive=F) {
    !(between(value, min, max, !inclusive))
}


