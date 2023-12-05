# Make the last figures (separated for faster runtimes)
#   - Maps of general treatment/burn areas and burn severity as requested by Mike and Rich
#   - Boxplots of burn intensity in treated/burned areas vs. rest of map


library(tidyverse)
library(sf)
library(raster)

sf_use_s2(FALSE)

### Load fire, treatment, and NP data

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

# Clip to Rim Fire area and get large areas of overlap
large_fires_within <- st_intersection(nearby_fires, rim_fire) %>%
    transmute(area = as.numeric(st_area(geometry))) %>%
    filter(area > 4e6) %>%
    st_union()

# Load treatment data and project to WGS 84
treatments <- read_sf("./data/treatment_data/Rim_Rire_Old_Proj.shp") %>%
    st_transform(4326) %>%
    arrange(desc(SHAPE_AREA))

# Load park data and project to WGS 84
all_parks <- st_read("./data/National_parks/nps_boundary.shp") %>%
    st_transform(4326)

# Isolate Yosemite
yosemite <- all_parks %>%
    filter(str_detect(UNIT_NAME, "Yosemite"))

# Clip to Rim Fire area
yosemite_within <- st_intersection(st_cast(yosemite, "MULTILINESTRING"),rim_fire)

### Load burn severity data

# Load burn data and project to WGS 84
burn_data <- raster("./data/burn_severity/ca3785712008620130817_20130714_20140701_dnbr.tif") %>% 
    projectRaster(crs = 4326, method = "ngb")

burn_data[burn_data < 0] <- 0
burn_data <- mask(burn_data, rim_fire)

# Get coordinates from burn data
burn_coords <- xyFromCell(burn_data, seq_len(ncell(burn_data)))

# Convert owl data and coordinates to a tibble
burn_tidy <- as_tibble(bind_cols(as.data.frame(burn_data), burn_coords)) %>%
    filter(!is.na(Layer_1))

burn_overlay <- ggplot() +
    geom_raster(data = burn_tidy, aes(x = x, y = y, fill = Layer_1)) +
    geom_sf(data = rim_fire, fill = NA, color = "black", linewidth = 0.8) +
    geom_sf(data = yosemite_within, fill = NA, color = "black", linewidth = 0.8, lty = "31") +
    geom_sf(aes(color = " "), data = large_fires_within, fill = NA, linewidth = 1.3) +
    theme_bw() +
    scale_fill_viridis_c(option = "turbo", begin = .5,) +
    scale_color_manual(values = "blue") +
    labs(fill = "Burn Severity (dNBR)", color = "Largest Subregions\nBurned Since 1993", x = "", y = "")

ggsave("figures/Figure_4b_overlay.svg", burn_overlay, height = 7, width = 7)
ggsave("figures/Figure_4b_overlay.png", burn_overlay, height = 7, width = 7, dpi = 600)
