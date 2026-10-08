## calculate centroids for named, gazetted sub-country locations

source("countryCentroids.R")

calculate_geoboundaries_centroids <- function(country_iso, admin_level, location_names = NULL) {
  boundary_data <- get_geoboundaries_regions(country_iso, admin_level)
  regions <- boundary_data$regions

  if (!is.null(location_names)) {
    regions <- select_gazetted_locations(regions, location_names, name_field = "shapeName")
  }

  calculate_gazetted_centroids(
    regions,
    source = "geoBoundaries",
    source_id = boundary_data$metadata$boundaryID,
    source_url = boundary_data$metadata$boundarySourceURL,
    source_version = boundary_data$metadata$boundaryYearRepresented
  )
}

## examples
if (sys.nframe() == 0) {
  australia_state_centroids <- calculate_geoboundaries_centroids(
    country_iso = "AUS",
    admin_level = "ADM1",
    location_names = c("New South Wales", "Victoria","South Australia","Western Australia",
                       "Queensland","Northern Territory","Tasmania")
  )
  print(australia_state_centroids)
}

if (sys.nframe() == 0) {
  australia_city_centroids <- calculate_geoboundaries_centroids(
    country_iso = "AUS",
    admin_level = "ADM2",
    location_names = c("Sydney","Melbourne","Brisbane","Adelaide","Perth","Darwin")
  )
  print(australia_city_centroids)
}

## find ADM regions using geobounds
install.packages("geobounds")
library(geobounds)
sri_lanka_adm3 <- gb_get_adm3("Sri Lanka")
print(sri_lanka_adm3)

aus_adm2 <- gb_get_adm2("Australia")
print(aus_adm2)

fra_adm1 <- gb_get_adm1("France")
print(fra_adm1)

fra_adm2 <- gb_get_adm2("France")
print(fra_adm2)

gb_get_adm2("Brazil")



## working
calculate_country_centroids("REU")

points <- vect(
  data.frame(lon = c(-2.610702, -4.298582782), lat = c(11.28484, 11.17086128)),
  geom = c("lon", "lat"),
  crs = "EPSG:4326"
)
point_centroid <- calculate_point_centroid(points)
point_centroid

Sys.setenv(OGR_GEOJSON_MAX_OBJ_SIZE = "10000")
library(sf)

centr_out <- calculate_geoboundaries_centroids(
  country_iso = "COL",
  admin_level = "ADM2"
)
print(centr_out$shapeName)
centr_out[which(centr_out$shapeName == "Tapon del Darién"),]

# 57°43'S
-(57 + (43/60))
# 5°17'W
-(5+(17/60))
