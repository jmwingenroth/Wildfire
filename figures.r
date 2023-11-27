# Make figures for final report

library(tidyverse)
library(sf)
library(stars)

#### Load and format data

### Owl data

# Load data keying values to point IDs
owl_vat <- st_read("./data/owl_raster/ds2185.gdb", layer = "VAT_ds2185")

# Load shapefile with point IDs, join attribute table, and reformat
owl_tidy <- st_read("./data/owl_raster/owl_raster_key.shp") %>%
    left_join(tibble(owl_vat), by = c("VALUE" = "Value")) %>%
    filter(NAME == "SPOTTED OWL") %>%
    select(quality = MEAN, geometry) %>%
    st_transform(4326) # Convert to lat/long

# Rasterize owl data
owl_raster <- st_rasterize(owl_tidy)
owl_raster[is.na(owl_raster[])] <- 0 

# Fire data

fires <- st_read("./data/CA_fire_perimeters/California_Fire_Perimeters__all_.shp") %>%
    st_transform(4326)

rim <- fires %>%
    filter(FIRE_NAME == "RIM", YEAR_ == 2013)

p1 <- ggplot() +
    geom_stars(data = st_crop(owl_raster, st_bbox(rim))) +
    geom_sf(data = rim, fill = NA, color = "white", linewidth = 1) +
    theme_bw()

ggsave("figures/habitat_and_Rim.svg", p1)

#### Figure 2

#### Figure 3

ggplot() +
    geom_stars(data = owl_raster)

#### Figure 4
