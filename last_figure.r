# Make the last figures (separated for faster runtimes)
#   - Maps of general treatment/burn areas and burn severity as requested by Mike and Rich
#   - Boxplots of burn intensity in treated/burned areas vs. rest of map


library(tidyverse)
library(sf)
library(raster)

# I'm not sure whether this script needs these
library(foreign)
library(ggnewscale)

sf_use_s2(FALSE)

### Load treatment and fire data

# Load fire data and project to WGS 84
all_fires <- st_read("./data/CA_fire_perimeters/California_Fire_Perimeters__all_.shp") %>%
    st_transform(4326)

# Isolate Rim Fire
rim_fire <- filter(all_fires, FIRE_NAME == "RIM", YEAR_ == 2013)

# Create a bbox object with extent for figures
figure_bbox <- bb_shrink(st_bbox(rim_fire), e = -0.1)

# Find fires near Rim Fire
nearby_fires <- st_crop(all_fires, figure_bbox) %>%
    filter(FIRE_NAME != "RIM", YEAR_ %in% 1993:2013) %>%
    arrange(desc(SHAPE_Area))

# Load treatment data and rpoject to WGS 84
treatments <- read_sf("./data/treatment_data/Rim_Rire_Old_Proj.shp") %>%
    st_transform(4326) %>%
    arrange(desc(SHAPE_AREA))

