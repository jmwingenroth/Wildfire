# Check out the data from Tony

library(tidyverse)
library(sf)

treatments <- st_read("data/Rim_Rire_Old_Proj/Rim_Rire_Old_Proj.shp")

fires <- st_read("./data/CA_fire_perimeters/California_Fire_Perimeters__all_.shp")

rim <- fires %>%
    filter(FIRE_NAME == "RIM", YEAR_ == 2013)

rim %>%
    ggplot() +
    geom_sf() +
    geom_sf(data = treatments, fill = "light green")
