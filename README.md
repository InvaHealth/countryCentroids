# Centroids

Find latitude/longitude centroid coordinates for countries, polygonal regions, gazetted administrative levels, or groups of points using `countryCentroids.R`.

## countries

Run the complete country workflow:

```sh
Rscript countryCentroids.R
```

Prints first rows of `centroids.out`, which contains the Natural Earth country code, country name, and centroid latitude/longitude in decimal degrees.

To calculate centroids for selected ISO 3166-1 alpha-3 codes, source the script and
call `calculate_country_centroids()`. The result preserves the requested code order
and returns `cntry.code`, `country.name`, `lat`, and `lon`.

```r
source("countryCentroids.R")

country_centroids <- calculate_country_centroids(c("AUS", "NZL", "FJI"))
print(country_centroids)
```

## sub-country regions

Source the script, load polygonal regions into a `terra` `SpatVector`, and call `calculate_polygon_centroids()`. Returned data frame preserve region attributes and add `lat` and `lon`.

```r
source("countryCentroids.R")

regions <- vect("regions.geojson")
region_centroids <- calculate_polygon_centroids(regions)
```

## gazetted sub-country locations

For provinces, states, regions, municipalities, and other gazetted locations, use the
authoritative boundary file where one is available. `calculate_gazetted_centroids()`
calculates a WGS 84 polygon centroid while retaining the source information needed to
trace the result later.

```r
source("countryCentroids.R")

official_regions <- vect("official-regions.gpkg")
centroids <- calculate_gazetted_centroids(
  official_regions,
  source = "State mapping authority",
  source_id = "2026-boundary-release",
  source_url = "https://example.gov.example/boundaries",
  source_version = "2026"
)
```

The returned attributes include `centroid.source`, `centroid.source.id`,
`centroid.source.url`, `centroid.source.version`, and `centroid.method`, in addition
to the input attributes, `lat`, and `lon`. Inputs with a known projected CRS are
reprojected to WGS 84 before coordinates are returned.

### geoBoundaries

`gazetted_centroids.R` automates the global fallback workflow using the
[geoBoundaries](https://www.geoboundaries.org/) `gbOpen` collection. It downloads an
administrative boundary layer, optionally selects locations by an exact `shapeName`,
and records geoBoundaries source metadata with every centroid.

```sh
Rscript gazetted_centroids.R
```

Examples:

```r
source("gazetted_centroids.R")

australia_state_centroids <- calculate_geoboundaries_centroids(
    country_iso = "AUS",
    admin_level = "ADM1",
    location_names = c("New South Wales", "Victoria","South Australia","Western Australia",
                       "Queensland","Northern Territory","Tasmania")
)
print(australia_state_centroids)

australia_city_centroids <- calculate_geoboundaries_centroids(
    country_iso = "AUS",
    admin_level = "ADM2",
    location_names = c("Sydney","Melbourne","Brisbane","Adelaide","Perth","Darwin")
  )
print(australia_city_centroids)

```

Note: ADM1—5 levels can be queried using <code>geobounds</code>

```r
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
```


`get_geoboundaries_regions()` supports `gbOpen`, `gbHumanitarian`, and
`gbAuthoritative` collections. Inspect the returned metadata and verify the supplied
licence, source, vintage, and administrative definition before publishing results.
The downloader requires the `jsonlite` package:

```r
install.packages("jsonlite")
```

### creating a region GeoJSON

`region_centroids.R` demonstrates how to create a GeoJSON polygon for a sub-country region. Replace the example longitude/latitude boundary coordinates with the region's boundary, then run:

```sh
Rscript region_centroids.R
```

Creates `example-region.geojson` and prints its centroid. The coordinates use WGS 84 (`EPSG:4326`), are specified as longitude then latitude, and form the region boundary in order. Script closes the polygon automatically.

```r
example_region_coordinates <- rbind(
  c(151.10, -33.95),
  c(151.30, -33.95),
  c(151.30, -33.75),
  c(151.10, -33.75)
)

create_region_geojson(
  region_name = "Example region",
  coordinates = example_region_coordinates,
  output_path = "example-region.geojson"
)
```

## groups of points

Pass a longitude/latitude `SpatVector` of point geometries to `calculate_point_centroid()`. It returns one latitude/longitude pair using a spherical mean, including for groups that cross the antimeridian.

```r
source("countryCentroids.R")

points <- vect(
  data.frame(lon = c(151.21, 144.96, 153.03), lat = c(-33.87, -37.81, -27.47)),
  geom = c("lon", "lat"),
  crs = "EPSG:4326"
)
point_centroid <- calculate_point_centroid(points)
```
