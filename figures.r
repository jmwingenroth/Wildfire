library(tidyverse)
library(sf)
library(stars)

#### Load and format data

# Owl data
owl_vat <- st_read("./data/owl_raster/ds2185.gdb", layer = "VAT_ds2185")

owl_tidy <- st_read("./data/owl_raster/owl_raster_key.shp") %>%
    left_join(tibble(owl_vat), by = c("VALUE" = "Value")) %>%
    filter(NAME == "SPOTTED OWL") %>%
    select(quality = MEAN, geometry)

owl_small <- owl_tidy %>%
    st_transform(4326) # Convert to lat/long

owl_raster <- st_rasterize(owl_tidy)

ggplot() +
    geom_stars(data = owl_raster)

#### Figure 2

#### Figure 3

#### Figure 4
