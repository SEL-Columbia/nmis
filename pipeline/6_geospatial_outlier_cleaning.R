require(data.table)
require(dplyr)
require(fpc)
require(ggplot2)
require(plyr)
require(sp)

options(stringsASFactors=FALSE)

# Gets the full directory of output data (all csv files)
csvs <- list.files('data/output_data', full.names=T)
# Filters through the list of csv files for only NMIS facility data
facility_data <- csvs[grepl(csvs, pattern='NMIS')]

# Read all the csv data into memory
df_facilities <- lapply(facility_data, function(x) cbind(fread(x, header=TRUE), csv=x))
# Rowise concatenation of the data, then cast to data.frame 
df_facilities <- rbindlist(df_facilities, fill = T, use.names=T) 
df_facilities <- as.data.frame(df_facilities)

# This function takes a column of strings and splits them to 
# fit the destination data.frame columns as numerics
numeric_column_split <- function(to_split, destination){
  split <- strsplit(to_split, ' ')
  to_bind <- NULL
  for (idx in 1:length(colnames(destination))){
    to_bind <- cbind(to_bind, as.numeric(lapply(split, '[[', idx)))
  }
  out <- rbind(destination,to_bind)
  colnames(out) <- colnames(destination)
  return(out)
}

# Build a destination frame for the string formatted coords, 
# parse the coords and populate the destination frame with the output
gps <- data.frame(latitude=numeric(), longitude=numeric(), altitude=numeric(), accuracy=numeric())
gps <- numeric_column_split(df_facilities$gps, gps)
# Join with unique_lga column
gps$lga <- df_facilities$unique_lga

#This function normalizes data column-wise to the closed interval [0, 1]
normalize <- plyr::colwise(function(x) (x - min(x)) / (max(x) - min(x)))

cluster_lga <- function(get_lga, data=gps){  
  #-----------------------------------------------------------------------
  #-------------------------Outlier Detection-----------------------------
  #-----------------------------------------------------------------------
  # 1.1 Get the subset of coords matching get_lga, then select lat and lon
  data <- subset(data, lga == get_lga)
  loc_data <- dplyr::select(data, latitude, longitude)
  # 1.2 Normalize the columns
  data <- normalize(loc_data)
  # 1.3 Calculate the pairwise distances between the set, returning the 
  # lower triangle of the matrix. Flatten the data to a 1D vector and assign
  # the 50% quantile to ℇ. Finally fit the model, join the cluster column 
  # with the gps data and fix the index.
  epsilon <- quantile(as.vector(dist(data)), .5)[[1]]
  DBSCAN <- fpc::dbscan(data, eps=epsilon, MinPts = 3)
  data$cluster <- DBSCAN$cluster
  rownames(data) <- rownames(loc_data)
  # 1.4 The subset of data belonging to cluster 0 are outliers,
  # however if the set of data is sparse and the outlier set is inclusive 
  # of the sample space then no points are filtered and the function returns NULL.
  outliers <- subset(data, cluster == 0)
  if (identical(data, outliers)){
    valid <- outliers
    outliers <- NULL
#     print(ggplot(valid, aes(x=longitude, y=latitude)) +
#             geom_point(size=3, colour= 'sky blue') + 
#             ggtitle(get_lga))
    
    return(outliers)
  }
  
  else{
  # 1.5 The absoulte complement of the outlier set in the sample space 
  # are then determined to be valid points. The set of valid data
  # is then enveloped using convex hull, any outliers that exist on this plane 
  # are then included as valid points. The function returns the index of outliers
    
    valid <- subset(data, cluster != 0)
    cvx_hull <- chull(dplyr::select(valid, longitude, latitude))
    cvx_hull <- c(cvx_hull, cvx_hull[1])
    poly_hull <- data.frame(longitude=valid$longitude[cvx_hull], latitude=valid$latitude[cvx_hull])
    in_hull <- mapply(function(x, y) point.in.polygon(x, y, poly_hull$longitude, poly_hull$latitude), 
                      outliers$longitude, outliers$latitude)
    outliers$cluster <- in_hull
    data <- rbind(valid, outliers)
    valid <- subset(data, cluster != 0)
    outliers <- subset(data, cluster == 0)
#     print(ggplot(valid, aes(x=longitude, y=latitude)) + 
#             geom_polygon(data=poly_hull, alpha=0.1, colour='sky blue') +
#             geom_point(size=3, colour= 'sky blue') + 
#             geom_point(data=outliers, aes(x=longitude, y=latitude), size=3) +
#             ggtitle(get_lga))
  }
  
  return (rownames(outliers))
}

# Get a list of unique_lga's
lgas <- unique(gps$lga)
# Strip out the NA
lgas <- lgas[!is.na(lgas)]
# Generate an index of all outlier data
index <- unlist(lapply(lgas, cluster_lga))
# Using the above index, pull out the outlier rows
output_outliers <- df_facilities[index,]
#Split the valid records to their cooresponding files
valid <- df_facilities[!(rownames(df_facilities) %in% index), ]
csv_output <- lapply(unique(valid$csv), function(x) subset(valid, csv == x))
csv_output <- lapply(csv_output, function(df) df[,unlist(lapply(df, function(x) !all(is.na(x))))])

# Write out the files
writter <- function(x){
    x <- data.frame(x)
    csv <- unlist(strsplit(x$csv[1], split='/'))
    csv <- csv[length(csv)]
    print <- paste('writing:', csv)
    csv <- paste('data/output_data/', csv, sep='')
    x$csv <- NULL 
    write.csv(x, file=csv, row.names=F)
}

lapply(csv_output, writter)
sprintf('writing: Geospatial_Outliers.csv')
write.csv(output_outliers, file='data/output_data/Geospatial_Outliers.csv', row.names=F)
