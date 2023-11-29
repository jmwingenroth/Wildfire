# Make figures for final report

library(tidyverse)
library(sf)
library(raster)
library(foreign)

sf_use_s2(FALSE)

# Shrink/grow bounding box
bb_shrink <- function (bb, e) {
    dx = diff(bb[c("xmin", "xmax")])
    dy = diff(bb[c("ymin", "ymax")])
    st_bbox(setNames(c(bb["xmin"] + e * dx, bb["ymin"] + e * 
        dy, bb["xmax"] - e * dx, bb["ymax"] - e * dy), c("xmin", 
        "ymin", "xmax", "ymax")))
}

#### Load and format data

### Fire data

# Load fire data and project to WGS 84
all_fires <- st_read("./data/CA_fire_perimeters/California_Fire_Perimeters__all_.shp") %>%
    st_transform(4326)

# Isolate Rim Fire
rim_fire <- filter(all_fires, FIRE_NAME == "RIM", YEAR_ == 2013)

# Create a bbox object with extent for figures
figure_bbox <- bb_shrink(st_bbox(rim_fire), e = -0.1)

# Find fires near Rim Fire
nearby_fires <- st_crop(all_fires, figure_bbox)

### Owl data

# Load owl data and project to WGS 84
owl_data <- raster("./output/owl_habitat_quality_near_Rim.tif") %>% 
    projectRaster(crs = 4326, method = "ngb")

# Get coordinates from owl data
owl_coords <- xyFromCell(owl_data, seq_len(ncell(owl_data)))

# Convert owl data and coordinates to a tibble
owl_tidy <- as_tibble(bind_cols(as.data.frame(owl_data), owl_coords))

### Vegetation data

# Load vegetation data and project to WGS 84
veg_data <- raster("./data/vegetation/US_130_EVT/us_130evt.tif") %>% 
    projectRaster(crs = 4326, method = "ngb")
veg_attributes <- as_tibble(read.dbf("./data/vegetation/US_130_EVT/us_130evt.tif.vat.dbf"))

# Get coordinates from vegetation data
veg_coords <- xyFromCell(veg_data, seq_len(ncell(veg_data)))

# Convert vegetation data and coordinates to a tibble, join attributes, and refactor
veg_tidy <- as_tibble(bind_cols(as.data.frame(veg_data), veg_coords)) %>%
    left_join(veg_attributes, by = c("OID_" = "VALUE")) %>%
    filter(!is.na(EVT_PHYS)) %>%
    mutate(veg_cats = fct_collapse(
        EVT_PHYS,
        `Developed and Agricultural` = c(
            "Developed",
            "Developed-Roads",
            "Developed-Low Intensity",
            "Developed-Medium Intensity",
            "Quarries-Strip Mines-Gravel Pits",
            "Developed-High Intensity",
            "Agricultural",
            "Exotic Herbaceous"
        ),
        `Sparsely Vegetated and Barren` = c(
            "Barren",
            "Sparsely Vegetated",
            "Snow-Ice"
        ),
        Conifer = c("Conifer", "Conifer-Hardwood")
    ))

#### Plot figures

### Figure 2

p2 <- ggplot() +
    geom_raster(data = veg_tidy, aes(x = x, y = y, fill = veg_cats)) +
    geom_sf(aes(color = ""), data = rim_fire, fill = NA, linewidth = 0.8) +
    theme_bw() +
    scale_fill_manual(
        values = c(
            "pink",
            "#f5dc6e",
            "dark green",
            "cyan",
            "green",
            "dark blue",
            "light blue",
            "#3ea1b3"
        )
    ) +
    scale_color_manual(values = "red") +
    scale_x_continuous(expand = c(0,0), limits = figure_bbox[c("xmin","xmax")]) +
    scale_y_continuous(expand = c(0,0), limits = figure_bbox[c("ymin","ymax")]) +
    labs(
        fill = "Vegetation\ncategory",
        color = "Rim Fire perimeter",
        x = "Longitude",
        y = "Latitude"
    )

ggsave("figures/Figure_2.svg", p2)

### Figure 3

p3 <- ggplot() +
    geom_raster(data = owl_tidy, aes(x = x, y = y, fill = owl_habitat_quality_near_Rim)) +
    geom_sf(aes(color = ""), data = rim_fire, fill = NA, linewidth = 0.8) +
    theme_bw() +
    scale_fill_viridis_c(option = "mako", begin = 0.1) +
    scale_color_manual(values = "red") +
    scale_x_continuous(expand = c(0,0), limits = figure_bbox[c("xmin","xmax")]) +
    scale_y_continuous(expand = c(0,0), limits = figure_bbox[c("ymin","ymax")]) +
    coord_sf() +
    labs(
        fill = "Spotted owl\nhabitat quality",
        color = "Rim Fire perimeter",
        x = "Longitude",
        y = "Latitude"
    )

ggsave("figures/Figure_3.svg", p3)

### Figure 4
