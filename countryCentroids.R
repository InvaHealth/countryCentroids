## find the latitude/longitude coordinates (decimal degrees)

library(rworldmap)
library(terra)

calculate_polygon_centroids <- function(regions) {
  if (!inherits(regions, "SpatVector") || !all(geomtype(regions) == "polygons")) {
    stop("'regions' must be a polygon SpatVector.", call. = FALSE)
  }
  if (!is.lonlat(regions)) {
    if (is.na(crs(regions))) {
      stop("'regions' must have a coordinate reference system.", call. = FALSE)
    }
    regions <- project(regions, "EPSG:4326")
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

calculate_country_centroids <- function(country_iso3) {
  if (
    !is.character(country_iso3) ||
    length(country_iso3) == 0 ||
    any(is.na(country_iso3)) ||
    any(!grepl("^[A-Za-z]{3}$", country_iso3))
  ) {
    stop(
      "'country_iso3' must contain one or more three-letter ISO 3166-1 alpha-3 codes.",
      call. = FALSE
    )
  }

  country_iso3 <- toupper(country_iso3)
  world_map <- vect(getMap(resolution = "high"))
  country_indices <- match(country_iso3, world_map$ne_10m_adm)
  if (any(is.na(country_indices))) {
    stop(
      sprintf(
        "No country boundary is available for: %s.",
        paste(shQuote(country_iso3[is.na(country_indices)]), collapse = ", ")
      ),
      call. = FALSE
    )
  }

  country_centroids <- calculate_polygon_centroids(world_map[country_indices, ])
  data.frame(
    'cntry.code' = as.character(country_centroids$ne_10m_adm),
    'country.name' = as.character(country_centroids$ADMIN),
    'lat' = country_centroids$lat,
    'lon' = country_centroids$lon
  )
}

calculate_continent_centroids <- function(continents = NULL) {
  if (
    !is.null(continents) &&
    (
      !is.character(continents) ||
      length(continents) == 0 ||
      any(is.na(continents)) ||
      any(!nzchar(continents))
    )
  ) {
    stop(
      "'continents' must be NULL or contain one or more non-empty continent names.",
      call. = FALSE
    )
  }

  world_map <- vect(getMap(resolution = "high"))
  available_continents <- unique(stats::na.omit(as.character(world_map$continent)))
  if (is.null(continents)) {
    continents <- available_continents
  }

  continent_indices <- match(tolower(continents), tolower(available_continents))
  if (any(is.na(continent_indices))) {
    stop(
      sprintf(
        "No continent boundary is available for: %s.",
        paste(shQuote(continents[is.na(continent_indices)]), collapse = ", ")
      ),
      call. = FALSE
    )
  }

  continents <- available_continents[continent_indices]
  continent_regions <- world_map[
    !is.na(world_map$continent) & world_map$continent %in% continents,
    "continent"
  ]
  continent_boundaries <- aggregate(
    makeValid(continent_regions),
    by = "continent",
    dissolve = TRUE
  )
  continent_centroids <- calculate_polygon_centroids(continent_boundaries)
  continent_centroids <- continent_centroids[
    match(continents, as.character(continent_centroids$continent)),
    ]

  data.frame(
    continent = as.character(continent_centroids$continent),
    lat = continent_centroids$lat,
    lon = continent_centroids$lon
  )
}

get_geoboundaries_regions <- function(country_iso, admin_level, collection = "gbOpen") {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop(
      "Package 'jsonlite' is required to retrieve geoBoundaries metadata. Install it with install.packages('jsonlite').",
      call. = FALSE
    )
  }
  if (!is.character(country_iso) || length(country_iso) != 1 || !grepl("^[A-Za-z]{3}$", country_iso)) {
    stop("'country_iso' must be a three-letter ISO 3166-1 alpha-3 code.", call. = FALSE)
  }
  if (!is.character(admin_level) || length(admin_level) != 1 || !grepl("^ADM[0-5]$", admin_level)) {
    stop("'admin_level' must be an administrative level from 'ADM0' to 'ADM5'.", call. = FALSE)
  }
  if (!is.character(collection) || length(collection) != 1 || !collection %in% c("gbOpen", "gbHumanitarian", "gbAuthoritative")) {
    stop("'collection' must be 'gbOpen', 'gbHumanitarian', or 'gbAuthoritative'.", call. = FALSE)
  }

  metadata_url <- sprintf(
    "https://www.geoboundaries.org/api/current/%s/%s/%s/",
    collection,
    toupper(country_iso),
    admin_level
  )
  metadata <- jsonlite::fromJSON(metadata_url)
  if (is.null(metadata$gjDownloadURL) || !nzchar(metadata$gjDownloadURL)) {
    stop("geoBoundaries did not provide a GeoJSON download URL for the requested boundary.", call. = FALSE)
  }

  geometry_path <- tempfile(fileext = ".geojson")
  on.exit(unlink(geometry_path), add = TRUE)
  tryCatch(
    utils::download.file(metadata$gjDownloadURL, geometry_path, mode = "wb", quiet = TRUE),
    error = function(error) {
      stop(
        sprintf("Unable to download the geoBoundaries geometry: %s", conditionMessage(error)),
        call. = FALSE
      )
    }
  )

  list(
    regions = vect(geometry_path),
    metadata = metadata,
    metadata_url = metadata_url
  )
}

select_gazetted_locations <- function(regions, names, name_field) {
  if (!inherits(regions, "SpatVector")) {
    stop("'regions' must be a SpatVector.", call. = FALSE)
  }
  if (!is.character(names) || length(names) == 0 || any(!nzchar(names))) {
    stop("'names' must contain one or more non-empty location names.", call. = FALSE)
  }
  if (!is.character(name_field) || length(name_field) != 1 || !name_field %in% names(regions)) {
    stop("'name_field' must name an attribute in 'regions'.", call. = FALSE)
  }

  matches <- as.character(values(regions)[[name_field]]) %in% names
  missing_names <- setdiff(names, as.character(values(regions)[[name_field]]))
  if (length(missing_names) > 0) {
    stop(
      sprintf(
        "No exact match in '%s' for: %s.",
        name_field,
        paste(shQuote(missing_names), collapse = ", ")
      ),
      call. = FALSE
    )
  }

  regions[matches, ]
}

calculate_gazetted_centroids <- function(
  regions,
  source,
  source_id = NA_character_,
  source_url = NA_character_,
  source_version = NA_character_
) {
  if (!is.character(source) || length(source) != 1 || !nzchar(source)) {
    stop("'source' must be a non-empty character string.", call. = FALSE)
  }

  centroids <- calculate_polygon_centroids(regions)
  data.frame(
    centroids,
    centroid.source = source,
    centroid.source.id = source_id,
    centroid.source.url = source_url,
    centroid.source.version = source_version,
    centroid.method = "polygon",
    check.names = FALSE
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

calculate_coordinate_centroid <- function(coordinates) {
  coordinates <- as.data.frame(coordinates)
  if (ncol(coordinates) != 2 || nrow(coordinates) < 3) {
    stop(
      "'coordinates' must contain at least three latitude/longitude pairs.",
      call. = FALSE
    )
  }

  latitude <- suppressWarnings(as.numeric(coordinates[[1]]))
  longitude <- suppressWarnings(as.numeric(coordinates[[2]]))
  if (
    anyNA(latitude) ||
    anyNA(longitude) ||
    any(!is.finite(latitude)) ||
    any(!is.finite(longitude)) ||
    any(latitude < -90 | latitude > 90) ||
    any(longitude < -180 | longitude > 180)
  ) {
    stop(
      "'coordinates' must contain finite latitude values from -90 to 90 and longitude values from -180 to 180.",
      call. = FALSE
    )
  }

  points <- vect(
    data.frame(lon = longitude, lat = latitude),
    geom = c("lon", "lat"),
    crs = "EPSG:4326"
  )
  calculate_point_centroid(points)
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
