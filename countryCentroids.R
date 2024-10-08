library(rworldmap)
library(terra)

# get world map
wmap <- vect(getMap(resolution="high"))

# get centroids
centroids <- centroids(wmap)

# get a data.frame with centroids
centroids.df <- as.data.frame(centroids)
head(centroids.df)
centroids.out <- data.frame('cntry.code'=centroids.df$ne_10m_adm,
                            'country.name'=centroids.df$ADMIN,
                            'lat'=centroids.df$LAT,
                            'lon'=centroids.df$LON)
head(centroids.out)
