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
