## find the latitude/longitude coordinates (decimal degrees)

library(rworldmap)
library(terra)

calculate_polygon_centroids <- function(regions) {
  if (!inherits(regions, "SpatVector") || !all(geomtype(regions) == "polygons")) {
    stop("'regions' must be a polygon SpatVector.", call. = FALSE)
  }

  region_attributes <- as.data.frame(regions)
  centroid_coordinates <- crds(centroids(regions), df = TRUE)

  if (ncol(region_attributes) == 0) {
    return(data.frame(
      lat = centroid_coordinates$y,
      lon = centroid_coordinates$x
    ))
  }

  data.frame(
    region_attributes,
    lat = centroid_coordinates$y,
    lon = centroid_coordinates$x
  )
}

calculate_point_centroid <- function(points) {
  if (!inherits(points, "SpatVector") || !all(geomtype(points) == "points")) {
    stop("'points' must be a point SpatVector.", call. = FALSE)
  }
  if (!is.lonlat(points)) {
    stop("'points' must use a longitude/latitude coordinate reference system.", call. = FALSE)
  }

  point_coordinates <- crds(points, df = TRUE)
  if (nrow(point_coordinates) == 0) {
    stop("'points' must contain at least one point.", call. = FALSE)
  }

  longitude_radians <- point_coordinates$x * pi / 180
  latitude_radians <- point_coordinates$y * pi / 180
  mean_x <- mean(cos(latitude_radians) * cos(longitude_radians))
  mean_y <- mean(cos(latitude_radians) * sin(longitude_radians))
  mean_z <- mean(sin(latitude_radians))

  data.frame(
    lat = atan2(mean_z, sqrt(mean_x^2 + mean_y^2)) * 180 / pi,
    lon = atan2(mean_y, mean_x) * 180 / pi
  )
}

if (sys.nframe() == 0) {
  wmap <- vect(getMap(resolution = "high"))
  country_centroids <- calculate_polygon_centroids(wmap)
  centroids.out <- data.frame(
    'cntry.code' = country_centroids$ne_10m_adm,
    'country.name' = country_centroids$ADMIN,
    'lat' = country_centroids$lat,
    'lon' = country_centroids$lon
  )
  head(centroids.out)
}
