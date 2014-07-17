require(fpc)
require(plyr)
require(dplyr)
require(sp)
require(ggplot2)

# This function normalizes data column-wise to the closed interval [0, 1]
normalize <- plyr::colwise(function(x) (x - min(x)) / (max(x) - min(x)))

cluster_lga <- function(lat, lon, plot_lga=F){  
  # combine gps columns into a dataframe
  gps_coords <- data.frame(latitude=lat, longitude=lon)
  # This function normalizes data column-wise to the closed interval [0, 1]
  gps_coords <- as.data.frame(normalize(gps_coords))
  
  # if there is only one datapoint clustering wont work, so assume point to be valid
  if (length(rownames(gps_coords)) <= 1){
    return(F)
  }
  # computes the pairwise distances (euclidean) between all points in the lga, 
  # selects a triangle, ravels to a vector and computes the 50% quantile
  epsilon <- as.numeric(quantile(as.vector(dist(gps_coords)), .5, na.rm=T))
  # fits the DBSCAN model with the normalized coords and epsilon from above 
  DBSCAN <- fpc::dbscan(gps_coords, eps=epsilon, MinPts = 3)
  gps_coords$cluster <- DBSCAN$cluster
  
  # Everything is an outlier therefore nothing is 
  if (identical(gps_coords, subset(gps_coords, cluster==0))){
    return(Map(function(x) F, gps$cluster))
  }
  
  # noise points are set to 0, thus the complement set are valid clusters
  valid <- subset(gps_coords, cluster!=0)
  # uses convex hull to infer a psuedo-shapefile around valid clusters
  cvx_hull <- chull(dplyr::select(valid, longitude, latitude))
  cvx_hull <- c(cvx_hull, cvx_hull[1])
  # data.frame containing the cartesian coordinates for the convex hull polygon 
  poly_hull <- data.frame(longitude=valid$longitude[cvx_hull], latitude=valid$latitude[cvx_hull])
  #finally tests all the gps points to see if the fit in the pseudo-shapefile
  in_hull <- mapply(function(x, y) point.in.polygon(x, y, poly_hull$longitude, poly_hull$latitude), 
                    gps_coords$longitude, gps_coords$latitude)
  # adds a column identifying spatial outliers
  gps_coords <- gps_coords %.% dplyr::mutate(spatial_outlier = (in_hull < 1))
  
  #if set to true plot the facilities, colored by group [spatial_outlier, !spatial_outlier]
  if (plot_lga == T){
    print(ggplot(gps_coords, aes(x=longitude, y=latitude, colour=spatial_outlier)) +
            geom_point(size=3))
  }
  
  return(in_hull < 1)
}

flag_spatial_outliers <- function(facility.data, output_dir, keep_outliers=F){
  #This function takes a facility.data data.frame and tests for spatial outliers
  #output_dir is where you want the spatial_outlier csv to be saved
  #if keep_outliers is set to True, then no data is dropped the input frame is returned 
  # with a column of T or F appended describing whether it is an outlier
  
  #Takes the input frame, groups by unique_lga and then adds an outlier column
  facility.data <- facility.data %.%
    dplyr::group_by(unique_lga) %.%
    dplyr::mutate(spatial_outlier=cluster_lga(latitude, longitude))
  
  #filters the above dataframe for spatial_outliers
  spatial_outliers <- dplyr::filter(facility.data, spatial_outlier==T)
  #persists those spatial outliers to disk as csv
  write.csv(spatial_outliers, row.names=F,
            file=sprintf('%s/Spatial_Outliers_Mopup_and_Baseline_NMIS_Facility.csv', output_dir))
  
  # if keep outliers is True, dont drop the outliers, just add the outlier column and return
  if (keep_outliers == F){  
    spatial_outliers <- dplyr::select(spatial_outliers, -spatial_outlier)
    facility.data <- dplyr::filter(facility.data, spatial_outlier==F) %.%
      dplyr::select(-spatial_outlier)
    
  }
  return (facility.data)
}