# Copilot instructions

## Running the project

This repository has no build system, automated test suite, or lint configuration. Run the complete workflow with:

```sh
Rscript countryCentroids.R
```

Generate the documented example sub-country GeoJSON and calculate its centroid with:

```sh
Rscript region_centroids.R
```

The script requires the R packages `rworldmap` and `terra`. Install missing packages in R with:

```r
install.packages(c("rworldmap", "terra"))
```

There is no single-test command because the repository contains no tests.

## Architecture

`countryCentroids.R` defines reusable helpers and is also the executable country workflow. `calculate_polygon_centroids()` accepts a polygon `SpatVector`, retains its attributes, and appends `lat`/`lon` coordinates derived from `terra::centroids()`. `calculate_point_centroid()` accepts a longitude/latitude point `SpatVector` and returns one spherical-mean coordinate pair. When run directly, the script obtains the high-resolution world map from `rworldmap::getMap()`, converts it to a `terra` vector, and writes the country results to `centroids.out`.

`region_centroids.R` sources these helpers, converts manually supplied WGS 84 boundary coordinates into a polygon `SpatVector`, writes it as GeoJSON, and calculates its centroid. It is the reference for creating editable sub-country-region GeoJSON files.

The README documents this as a utility for finding country centroid coordinates in decimal degrees; keep the script runnable directly from the repository root.

## Repository conventions

- Use `terra` vector operations after obtaining the map: retain the `vect(getMap(resolution = "high"))` conversion before calculating centroids.
- Preserve the `centroids.out` column names and order: `cntry.code`, `country.name`, `lat`, and `lon`. The dotted field names are part of the existing output schema.
- Source country identifiers and names from the map attributes (`ne_10m_adm` and `ADMIN`) rather than introducing a separate country lookup.
- Keep polygon-centroid inputs as polygon `SpatVector` objects and point-centroid inputs as longitude/latitude point `SpatVector` objects. Point centroids use a spherical mean so longitude wrapping at the antimeridian is handled correctly.
- GeoJSON boundaries use WGS 84 (`EPSG:4326`) longitude/latitude coordinate pairs in boundary order. `create_region_geojson()` automatically closes an unclosed polygon ring.
