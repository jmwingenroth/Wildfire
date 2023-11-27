# Make figures for final report

library(tidyverse)
library(sf)
library(stars)

#### Load and format data

### Owl data

# Used a .tif I produced earlier because processing original data was slow
owl_data <- read_stars("./output/owl_habitat_quality_near_Rim.tif")

### Fire data

# Load fire data
all_fires <- st_read("./data/CA_fire_perimeters/California_Fire_Perimeters__all_.shp") 

# Isolate Rim Fire
rim_fire <- filter(all_fires, FIRE_NAME == "RIM", YEAR_ == 2013)

# Find fires near Rim Fire
nearby_fires <- st_crop(all_fires, st_bbox(rim_fire), epsilon = 1.1)

# Match to owl data projection (https://epsg.io/3310)
rim_proj <- st_transform(rim_fire, 3310)
nearby_proj <- st_transform(nearby_fires, 3310)

### Vegetation data

# Load, transform, and crop vegetation data
veg_proj <- read_stars("./data/vegetation/US_130_EVT/us_130evt.tif") %>% 
    st_warp(crs = 3310) %>%
    st_crop(st_bbox(rim_proj), epsilon = 1.1)

#### Plot figures

### Figure 2

p2 <- ggplot() +
    geom_stars(data = veg_proj) +
    geom_sf(aes(color = ""), data = rim_proj, fill = NA, linewidth = 1.1) +
    theme_bw() +
    scale_fill_viridis_c(option = "mako", begin = 0.1) +
    scale_color_manual(values = "red") +
    labs(
        fill = "Vegetation\ncategory",
        color = "Rim Fire perimeter",
        x = "Longitude",
        y = "Latitude"
    )

ggsave("figures/Figure_2.svg", p2)

### Figure 3

p3 <- ggplot() +
    geom_stars(data = st_crop(owl_data, st_bbox(rim_proj), epsilon = 1.1)) +
    geom_sf(aes(color = ""), data = rim_proj, fill = NA, linewidth = 1.1) +
    theme_bw() +
    scale_fill_viridis_c(option = "mako", begin = 0.1) +
    scale_color_manual(values = "red") +
    labs(
        fill = "Spotted owl\nhabitat quality",
        color = "Rim Fire perimeter",
        x = "Longitude",
        y = "Latitude"
    )

ggsave("figures/Figure_3.svg", p3)

### Figure 4
