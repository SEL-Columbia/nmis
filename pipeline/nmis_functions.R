######################################################################################################
#Mopup Integration: Functions Script##################################################################
######################################################################################################

#indicator functions##########################################################################
ratio <- function(numerator, denominator) {
    df <- na.omit(data.frame(num=numerator, den=denominator))
    sum(df$num) / sum(df$den)
}

outlier_list <- function(df, lst) {
    table = data.table(df)
    for (formula, col in lst) {
        table[eval(formula), `:=`(col, NA)]
    }
    as.data.frame(table)
}
