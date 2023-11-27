# Make figures for final report

library(tidyverse)
library(sf)
library(stars)

#### Load and format data

### Owl data
owl_data <- read_stars("./output/owl_habitat_quality_near_Rim.tif")

### Fire data
fires <- st_read("./data/CA_fire_perimeters/California_Fire_Perimeters__all_.shp") 
rim <-  fires %>%
    filter(FIRE_NAME == "RIM", YEAR_ == 2013) %>%
    st_transform(3310) # Convert to lat/long

#### Plot figures

### Figure 2

### Figure 3

p1 <- ggplot() +
    geom_stars(data = st_crop(owl_data, st_bbox(rim), epsilon = 1.1)) +
    geom_sf(aes(color = ""), data = rim, fill = NA, linewidth = 1.1) +
    theme_bw() +
    scale_fill_viridis_c(option = "mako", begin = 0.1) +
    scale_color_manual(values = "red") +
    labs(
        fill = "Spotted owl\nhabitat quality",
        color = "Rim Fire perimeter",
        x = "Longitude",
        y = "Latitude"
    )

ggsave("figures/habitat_and_Rim.svg", p1)

### Figure 4
