require(fpc)
require(plyr)
require(dplyr)
require(sp)
require(ggplot2)

#This function normalizes data column-wise to the closed interval [0, 1]
normalize <- plyr::colwise(function(x) (x - min(x)) / (max(x) - min(x)))
to_numeric <- plyr::colwise(function(x) as.numeric(x))

parse_gps <- function(gps){
  gps <- do.call(rbind, strsplit(gps, ' '))
  gps <- to_numeric(data.frame(gps,stringsAsFactors = F))
  colnames(gps) <- c('latitude', 'longitude', 'elevation', 'precision')
  return(gps)
}

cluster_lga <- function(lat, lon, plot_lga=F){  
  gps_coords <- data.frame(latitude=lat, longitude=lon)
  gps_coords <- as.data.frame(normalize(gps_coords))

  epsilon <- as.numeric(quantile(as.vector(dist(gps_coords)), .5, na.rm=T))
  DBSCAN <- fpc::dbscan(gps_coords, eps=epsilon, MinPts = 3)
  if (length(rownames(gps_coords)) <= 1){
    return(F)
  }
  gps_coords$cluster <- DBSCAN$cluster
  
  # Everything is an outlier therefore nothing is
  if (identical(gps_coords, subset(gps_coords, cluster==0))){
    return(Map(function(x) F, gps$cluster))
  }
  
  valid <- subset(gps_coords, cluster!=0)
  cvx_hull <- chull(dplyr::select(valid, longitude, latitude))
  cvx_hull <- c(cvx_hull, cvx_hull[1])
  poly_hull <- data.frame(longitude=valid$longitude[cvx_hull], latitude=valid$latitude[cvx_hull])
  
  in_hull <- mapply(function(x, y) point.in.polygon(x, y, poly_hull$longitude, poly_hull$latitude), 
                    gps_coords$longitude, gps_coords$latitude)
  
  gps_coords <- gps_coords %.% dplyr::mutate(spatial_outlier = (in_hull < 1))
  
  if (plot_lga == T){
    print(ggplot(gps_coords, aes(x=longitude, y=latitude, colour=spatial_outlier)) +
            geom_point(size=3))
  }
  
  return(in_hull < 1)
}
