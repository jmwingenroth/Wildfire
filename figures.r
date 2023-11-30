# Make figures for final report

library(tidyverse)
library(sf)
library(raster)
library(foreign)
library(ggnewscale)

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
nearby_fires <- st_crop(all_fires, figure_bbox) %>%
    filter(FIRE_NAME != "RIM", YEAR_ %in% 1993:2013) %>%
    arrange(desc(SHAPE_Area))

### Owl data

# Load owl data and project to WGS 84
owl_data <- raster("./output/owl_habitat_quality_near_Rim.tif") %>% 
    projectRaster(crs = 4326, method = "ngb")

# Get coordinates from owl data
owl_coords <- xyFromCell(owl_data, seq_len(ncell(owl_data)))

# Convert owl data and coordinates to a tibble
owl_tidy <- as_tibble(bind_cols(as.data.frame(owl_data), owl_coords))

### Vegetation data

## 2012

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
        `Developed/Agricultural` = c(
            "Developed",
            "Developed-Roads",
            "Developed-Low Intensity",
            "Developed-Medium Intensity",
            "Quarries-Strip Mines-Gravel Pits",
            "Developed-High Intensity",
            "Agricultural",
            "Exotic Herbaceous"
        ),
        `Sparse or No Vegetation` = c(
            "Barren",
            "Sparsely Vegetated",
            "Snow-Ice"
        ),
        Conifer = c("Conifer", "Conifer-Hardwood")
    ))

## 2016

# Load vegetation data and project to WGS 84
veg_data_16 <- raster("./data/vegetation/LF2016_EVT_200_CONUS/LC16_EVT_200.tif") %>% 
    projectRaster(crs = 4326, method = "ngb")
veg_attributes_16 <- as_tibble(read.dbf("./data/vegetation/LF2016_EVT_200_CONUS/LC16_EVT_200.tif.vat.dbf"))

# Get coordinates from vegetation data
veg_coords_16 <- xyFromCell(veg_data_16, seq_len(ncell(veg_data_16)))

# Convert vegetation data and coordinates to a tibble, join attributes, and refactor
veg_tidy_16 <- as_tibble(bind_cols(as.data.frame(veg_data_16), veg_coords_16)) %>%
    left_join(veg_attributes_16, by = c("EVT_NAME" = "VALUE")) %>%
    filter(!is.na(EVT_PHYS)) %>%
    mutate(veg_cats = fct_collapse(
        EVT_PHYS,
        `Developed/Agricultural` = c(
            "Developed",
            "Developed-Roads",
            "Developed-Low Intensity",
            "Developed-Medium Intensity",
            "Quarries-Strip Mines-Gravel Pits-Well and Wind Pads",
            "Developed-High Intensity",
            "Agricultural",
            "Exotic Herbaceous",
            "Exotic Tree-Shrub"
        ),
        `Sparse or No Vegetation` = c(
            "Sparsely Vegetated"
        ),
        Conifer = c("Conifer", "Conifer-Hardwood")
    )) %>%
    mutate(veg_cats = fct_relevel(veg_cats, "Sparse or No Vegetation", after = 1))

burn_16 <- filter(veg_tidy_16, str_detect(EVT_NAME.y, "Burned"))

### Treatment data

treatments <- read_sf("./data/treatment_data/Rim_Rire_Old_Proj.shp") %>%
    st_transform(4326) %>%
    arrange(desc(SHAPE_AREA))

#### Plot figures

### Figure 2

p2 <- ggplot() +
    geom_raster(data = veg_tidy, aes(x = x, y = y, fill = veg_cats)) +
    geom_sf(data = rim_fire, fill = NA, color = "red", linewidth = 0.8) +
    theme_bw() +
    scale_fill_manual(
        values = c(
            "pink",
            "#f5dc6e",
            "dark green",
            "#c2aa42",
            "green",
            "dark blue",
            "light blue",
            "#3ea1b3"
        )
    ) +
    scale_x_continuous(expand = c(0,0), limits = figure_bbox[c("xmin","xmax")]) +
    scale_y_continuous(expand = c(0,0), limits = figure_bbox[c("ymin","ymax")]) +
    labs(
        title = "Pre-Fire (2012) Vegetation Categories",
        fill = "",
        x = "",
        y = ""
    ) +
    theme(legend.position = "bottom") +
    guides(fill = guide_legend(nrow = 4, byrow = TRUE))

ggsave("figures/Figure_2.svg", p2, height = 7, width = 7)

### Figure 3

p3 <- ggplot() +
    geom_raster(data = owl_tidy, aes(x = x, y = y, fill = owl_habitat_quality_near_Rim)) +
    geom_sf(data = rim_fire, fill = NA, color = "red", linewidth = 0.8) +
    theme_bw() +
    scale_fill_viridis_c(option = "mako", begin = 0.1) +
    scale_x_continuous(expand = c(0,0), limits = figure_bbox[c("xmin","xmax")]) +
    scale_y_continuous(expand = c(0,0), limits = figure_bbox[c("ymin","ymax")]) +
    coord_sf() +
    labs(
        title = "Spotted Owl Habitat Quality (0 = Low, 1 = High)",
        fill = "",
        x = "",
        y = ""
    ) +
    theme(legend.position = "bottom")

ggsave("figures/Figure_3.svg", p3, height = 7, width = 7)

### Figure 4

p4 <- p2 +
    scale_fill_manual(
        values = c(
            "#e3d8e0",
            "#e6e2ca",
            "#415443",
            "#8c8774",
            "#97ad93",
            "#1d1f2e",
            "#c8d7de",
            "#7d8c96"
        )
    ) +
    new_scale_fill() +
    geom_sf(aes(fill = "Previous Fires"), data = nearby_fires, alpha = .7, color = alpha("black", .7)) +
    geom_sf(aes(fill = "Treatment Areas"), data = treatments, color = NA) +
    labs(fill = "", title = "Previous Fires (1993 Onwards) and Treatment Areas (2003 Onwards)") +
    scale_fill_manual(values = c("orange", "cyan"))

ggsave("figures/Figure_4.svg", p4, height = 7, width = 7)

### Figure 5

p5 <- ggplot() +
    geom_raster(data = veg_tidy_16, aes(x = x, y = y, fill = veg_cats)) +
    geom_sf(data = rim_fire, fill = NA, color = "red", linewidth = 0.8) +
    theme_bw() +
    scale_fill_manual(
        values = c(
            "pink",
            "#f5dc6e",
            "dark green",
            "#c2aa42",
            "green",
            "dark blue",
            "light blue",
            "#3ea1b3"
        )
    ) +
    scale_x_continuous(expand = c(0,0), limits = figure_bbox[c("xmin","xmax")]) +
    scale_y_continuous(expand = c(0,0), limits = figure_bbox[c("ymin","ymax")]) +
    labs(
        title = "Post-Fire (2016) Vegetation Categories",
        fill = "",
        x = "",
        y = ""
    ) +
    theme(legend.position = "bottom") +
    guides(fill = guide_legend(nrow = 4, byrow = TRUE))

ggsave("figures/Figure_5.svg", p5, height = 7, width = 7)

### Figure 6

