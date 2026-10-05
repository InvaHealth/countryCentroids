## calculate lat/lon centroids for regions (specified using geoJSON)

library(terra)

source("countryCentroids.R")

create_region_geojson <- function(region_name, coordinates, output_path) {
  coordinates <- as.matrix(coordinates)

  if (ncol(coordinates) != 2 || nrow(coordinates) < 3) {
    stop("'coordinates' must contain at least three longitude/latitude pairs.", call. = FALSE)
  }
  if (!identical(coordinates[1, ], coordinates[nrow(coordinates), ])) {
    coordinates <- rbind(coordinates, coordinates[1, ])
  }

  region <- vect(coordinates, type = "polygons", crs = "EPSG:4326")
  values(region) <- data.frame(region.name = region_name)
  writeVector(region, output_path, filetype = "GeoJSON", overwrite = TRUE)

  region
}

if (sys.nframe() == 0) {
  example_region_coordinates <- rbind(
    c(151.10, -33.95),
    c(151.30, -33.95),
    c(151.30, -33.75),
    c(151.10, -33.75)
  )

  output_path <- "example-region.geojson"
  create_region_geojson(
    region_name = "Example region",
    coordinates = example_region_coordinates,
    output_path = output_path
  )

  region_centroids <- calculate_polygon_centroids(vect(output_path))
  print(region_centroids)
}
