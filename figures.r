# Make figures for final report

library(tidyverse)
library(sf)
library(stars)

#### Load and format data

### Owl data

# Load attribute table that keys values to point IDs
owl_vat <- st_read("./data/owl_raster/ds2185.gdb", layer = "VAT_ds2185")

# Load shapefile with point IDs, join attribute table, and reformat
owl_data <- st_read("./data/owl_raster/owl_raster_key.shp") %>%
    filter(row_number()%%9 == 0) %>% # Lower resolution to speed up code
    right_join(tibble(owl_vat), by = c("VALUE" = "Value")) %>%
    filter(NAME == "SPOTTED OWL") %>%
    select(quality = MEAN, geometry) %>%
    st_transform(4326) # Convert to lat/long

# Drop missing values
owl_clean <- owl_data[!st_is_empty(owl_data),,drop = FALSE]

# Rasterize owl data
owl_raster <- st_rasterize(owl_clean)
owl_raster[is.na(owl_raster[])] <- 0 # Set NA values to zero

### Fire data

fires <- st_read("./data/CA_fire_perimeters/California_Fire_Perimeters__all_.shp") %>%
    st_transform(4326) # Convert to lat/long

rim <- fires %>%
    filter(FIRE_NAME == "RIM", YEAR_ == 2013)


#### Figure 2

#### Figure 3

p1 <- ggplot() +
    geom_stars(data = st_crop(owl_raster, st_bbox(rim))) +
    geom_sf(data = rim, fill = NA, color = "white", linewidth = 1) +
    theme_bw() +
    scale_fill_viridis_c()

ggsave("figures/habitat_and_Rim.svg", p1)

#### Figure 4
