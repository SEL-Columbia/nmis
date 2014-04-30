######################################################################################################
#Mopup Integration: Functions Script##################################################################
######################################################################################################

#loading multiple packages############################################################################
  load_packages_with_install = function(packages) {
    for (re_lib in packages)
    {
      if (! re_lib %in% installed.packages())
      {
        install.packages(re_lib)    
      }
      suppressPackageStartupMessages(require(re_lib,character.only = TRUE))
    }
  }
  
  load_packages_with_install(c("plyr", "doBy", "stringr", "digest", "gdata",
                               "maptools", "shapefiles", "sp", "spatstat", "geosphere"))

#functions for outlier removal##########################################################################
  outlierOutputList = list() #for generating a running list of what is being knocked out
  outlierreplace = function(df, c, rowpredicate, replaceVal=NA) {
    naCount1 <- length(which(is.na(df[,c])))
    df[,c] <- replace(df[,c], rowpredicate, replaceVal)
    naCount2 <- length(which(is.na(df[,c])))
    print(str_c(naCount2-naCount1, " outliers replaced for field: ", c)) #comment-out line if not desired
    outlierOutputList <<- c(outlierOutputList, 
                            str_c(naCount2-naCount1, " outliers replaced for field: ", c))
    df
  }

# checks if value is between two thresholds (min, max); convenience function
# if inclusive = TRUE, then value can be equal to min or max
  between <- function(value, min, max, inclusive=F) { 
    if(inclusive) { 
      value >= min & value <= max 
    } else { 
      value > min & value < max 
    }
  }

#geospatial cleaning###################################################################################
  lga_boudary_dist <- function(df, gps_col)
  {
    ni_shp <- readRDS('data/input_data/nga_lgas_with_corrected_id.rds')
    regions <- setNames(slot(ni_shp, "polygons"), ni_shp@data$lga_id)
    
    regions <- lapply(regions, function(x) SpatialPolygons(list(x)))
    windows <- lapply(regions, as.owin)
    
    dist_funs <- lapply(windows, distfun)
    
    gps <- strsplit(as.character(df[, gps_col]), split=' ')
    lat <- as.numeric(unlist(lapply(gps, function(x) x[1])))
    long <- as.numeric(unlist(lapply(gps, function(x) x[2])))
    
    #Error handling kick out records with unvalid gps values like 'None'
    idx <- which(!(is.na(lat) | is.na(lat)))
    if (length(idx) != 0)
    {
      warning(paste(length(which(is.na(lat) | is.na(lat))),
                    'facility has invalid gps value, 
                    and records dropped from data', sep=''))
    }
    df <- df[idx,]
    lat <- lat[idx]
    long <- long[idx]
    rm(idx)
  
  #Create spatial_point with lat&long 
    hxy <- cbind(long, lat)
  
  # prints warning message and replace NAs with north pole
    if (length(which(is.na(hxy[,1]))) > 0 )
    {
      warning(paste(length(which(is.na(hxy[,1]))), 
                    "facility don't have GPS value, unable to locate state and were dropped from the data"))
    }
    df <- df[which(!(is.na(hxy[,1] | is.na(hxy[,2])))),]
    #     hxy[which(is.na(hxy[,1])),] <- c(180, 90)
    hxy <- hxy[which(!(is.na(hxy[,1] | is.na(hxy[,2])))),]
    #xy_cp <- apply(hxy, MARGIN=1, FUN=list)
    xy_cp <- hxy
    hxy <- SpatialPoints(hxy)
  
  
  # locate states based on x&y coordinate and shapefile
    output <- NULL
    l_ply(names(regions), function(rid) {
      r = regions[[rid]]
      #print(over(pts, r))
      output <<- replace(output,
                         over(hxy, r) == 1,
                         rid)})
    
  # record true LGA location and labeled LGA location 
    df$lga_valid <- output
    df$lga_orig <- as.character(df$lga_id)
  
  # Testing out-of-countary points(out of shapefile)
    if (length(which(is.na(df$lga_valid))) > 0 )
    {
      warning(paste(length(which(is.na(df$lga_valid))), 
                    "facility have XY coordinate outside of Nigeria coordinate, unable to locate state and were dropped from the data"))
    }
  #df <- subset(df, !is.na(lga_valid))
  
  # Testing out-of-LGA points
    if( length(which(df$lga_valid != df$lga_orig)) > 0  ) 
    {
      warning(paste(length(which(df$lga_valid != df$lga_orig)), 
                    "facility have out-of-boundary issue"))
    }
    print(paste(nrow(df), "Total Facilities after those without GPS "))
    df2 <- subset(df, lga_valid == lga_orig)
    xy_cp <- xy_cp[(df$lga_valid != df$lga_orig) | is.na(df$lga_valid), ]
    df <- subset(df, (lga_valid != lga_orig) | is.na(lga_valid))
    
    if (nrow(df) != nrow(xy_cp))
    {
      warning("number of out-of-LGA facility doesnt match")
    }
    print(paste(nrow(df2), "facilities NOT have out-of-LGA issue"))
    print(paste(nrow(df), "facilities HAVE out-of-LGA issue"))
    
  ######################################################
  ##### Need to optimize this part in next iteration#### 
  ######################################################
  
  print("dist_function")
  dist_euc <- rep(NA, nrow(df))
  system.time(l_ply(names(dist_funs), function(rid) 
  {r = dist_funs[[rid]]
   idx <- which(df$lga_id == rid)
   dist_euc[idx] <<- r(xy_cp)[idx] }))
  
  
  df$dist_euc <- dist_euc
  org_xy <- xy_cp
  fake_xy <- org_xy + dist_euc/sqrt(2)
  df$dist_fake <- distVincentySphere(org_xy,fake_xy)/1000
  
  final <- rbind.fill(df, df2)
  hist(final$dist_fake, nclass=200)
  
  return(final)
  
  }

#merging########################################################################################
  # Merge two dataframes, dropping redundant columns in dataframe2 if necessary
  # note: by.x and by.y are not supported
  merge_non_redundant <- function(df1, df2, by, by.x=NA, by.y=NA, printDropped=F, ...) {
    stopifnot(is.na(by.x) && is.na(by.y))
    df2uniquecols <- names(df2)[! names(df2) %in% names(df1)]
    df2unique <- df2[,c(df2uniquecols, by)]
    if (printDropped) {
      print(paste(c('Dropping columns during merge: ', 
                  names(df2)[names(df2) %in% names(df1)]), collapse=' '))
    }
    merge(df1, df2unique, by, ...)
  }
  
  # a version of merge that throws up an error if there are redundant columns
  merge_strict <- function(df1, df2, ...) {
    merged <- merge(df1, df2, ...)
    stopifnot(all(names(merged) %in% c(names(df1), names(df2))))
    merged
  }

#indicator functions##########################################################################
ratio <- function(numerator, denominator) {
    df <- na.omit(data.frame(num=numerator, den=denominator))
    sum(df$num) / sum(df$den)
}

bool_proportion <- function(numerator_TF, denominator_TF) {
  if(is.null(numerator_TF) | is.null(denominator_TF)) {
    print("bool_proportion called on empty column")
    NA
  } else {
    if (class(numerator_TF) == 'character') {
      if (length(c(which(str_detect(numerator_TF, ignore.case("yes|no|true|false"))), 
                   which(is.na(numerator_TF)))) / length(numerator_TF) > 0.4) {
        numerator_TF <- as.logical(recodeVar(tolower(numerator_TF), src=list(c("yes", "true"), c("no", "false")), 
                                             tgt=list(TRUE, FALSE), default=NA, keep.na=T))
      }
      else {
        warning("Cannot recode Boolean value, check the data first!")
      }
    } else if (class(denominator_TF) == 'character') {
      if (length(c(which(str_detect(denominator_TF, ignore.case("yes|no|true|false"))), 
                   which(is.na(denominator_TF)))) / length(denominator_TF) > 0.4) {
        denominator_TF <- as.logical(recodeVar(tolower(denominator_TF), src=list(c("yes", "true"), c("no", "false")), 
                                               tgt=list(TRUE, FALSE), default=NA, keep.na=T))
      } else {
        warning("Cannot recode Boolean value, check the data first!")
      }
    }
    df <- data.frame(cbind(num=numerator_TF, den=denominator_TF))
    df <- na.omit(df)
    sum((df$num & df$den), na.rm=TRUE) / sum(df$den, na.rm=TRUE)
  }
}
