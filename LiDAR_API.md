LiDAR API
================

## Goal

We seek to find areas where LiDAR data has been collected on two
occasions. Eventually we will use fire perimeter data to find areas
where LiDAR was collected before and after a fire.

## Approach

I plan to use the R packages in the
[tidyverse](https://www.tidyverse.org) to process data taken from the
[web API](https://apps.nationalmap.gov/tnmaccess/#/) provided by [The
National Map](https://apps.nationalmap.gov/lidar-explorer/#/).
Ultimately, interacting with URLs is performed using a package that
ports [curl](https://curl.se/) over to R.

``` r
# Load R packages
library(tidyverse)
```

    ## -- Attaching packages --------------------------------------- tidyverse 1.3.1 --

    ## v ggplot2 3.3.6     v purrr   0.3.4
    ## v tibble  3.1.6     v dplyr   1.0.8
    ## v tidyr   1.2.0     v stringr 1.4.0
    ## v readr   2.1.2     v forcats 0.5.1

    ## Warning: package 'ggplot2' was built under R version 4.1.3

    ## Warning: package 'tidyr' was built under R version 4.1.3

    ## Warning: package 'readr' was built under R version 4.1.3

    ## Warning: package 'dplyr' was built under R version 4.1.3

    ## -- Conflicts ------------------------------------------ tidyverse_conflicts() --
    ## x dplyr::filter() masks stats::filter()
    ## x dplyr::lag()    masks stats::lag()

``` r
library(jsonlite)
```

    ## Warning: package 'jsonlite' was built under R version 4.1.3

    ## 
    ## Attaching package: 'jsonlite'

    ## The following object is masked from 'package:purrr':
    ## 
    ##     flatten

``` r
library(curl)
```

    ## Using libcurl 7.64.1 with Schannel

    ## 
    ## Attaching package: 'curl'

    ## The following object is masked from 'package:readr':
    ## 
    ##     parse_date

## Finding a dataset

We’ll need to look at LiDAR products eventually, but to illustrate the
general principle, let’s be thorough and use the Datasets API to track
down the LiDAR data:

``` r
# Get datasets from the API and convert to a tidy table (tibble)
datasets <- stream_in(url("https://tnmaccess.nationalmap.gov/api/v1/datasets")) %>%
    tibble()
```

    ## opening url input connection.

    ## Warning in readLines(con, n = pagesize, encoding = "UTF-8"): incomplete final
    ## line found on 'https://tnmaccess.nationalmap.gov/api/v1/datasets'

    ##  Found 1 records... Imported 1 records. Simplifying...

    ## closing url input connection.

``` r
colnames(datasets)
```

    ##  [1] "title"                      "sbDatasetTag"              
    ##  [3] "parentCategory"             "id"                        
    ##  [5] "description"                "refreshCycle"              
    ##  [7] "lastPublishedDate"          "lastUpdatedDate"           
    ##  [9] "dataGovUrl"                 "infoUrl"                   
    ## [11] "thumbnailUrl"               "mapServerLayerIdsForLegend"
    ## [13] "mapServerUrl"               "showMapServerLink"         
    ## [15] "mapServerLinkShowTitle"     "mapServerLinkHideTitle"    
    ## [17] "formats"                    "defaultExtent"             
    ## [19] "tags"                       "extents"                   
    ## [21] "mapServerLayerNames"        "descriptionLink"           
    ## [23] "layerOpacity"               "wmsLayers"                 
    ## [25] "zipLink"

So, the Datasets API has provided us with quite a bit of information.
Let’s examine some variables that look promising.

``` r
datasets %>%
    select(title, id, lastPublishedDate, lastUpdatedDate, formats)
```

    ## # A tibble: 15 x 5
    ##    title                                           id    lastP~1 lastU~2 formats
    ##    <chr>                                           <chr> <chr>   <chr>   <list> 
    ##  1 US Topo                                         us-t~ "Sep 4~ "Sep 7~ <df>   
    ##  2 Historical Topographic Maps                     hist~ "Jan 1~ "Jul 2~ <df>   
    ##  3 Boundaries - National Boundary Dataset          nati~ "Aug 1~ "Aug 3~ <df>   
    ##  4 Elevation Products (3DEP)                       elev~ "Sep 9~ "Sep 1~ <df>   
    ##  5 Elevation Source Data (3DEP) - Lidar, IfSAR     elev~ "Sep 9~ "Sep 1~ <df>   
    ##  6 Hydrography (NHDPlus HR, NHD, WBD)              hydr~ "Sep 1~ "Sep 1~ <df>   
    ##  7 Imagery - NAIP Plus (1 meter to 1 foot)         imag~ "Nov 2~ "Sep 7~ <df>   
    ##  8 Map Indices                                     map-~ "Aug 1~ "Aug 2~ <df>   
    ##  9 Names - Geographic Names Information System (G~ name~ "Jan 1~ "Aug 9~ <df>   
    ## 10 Small-scale Datasets                            smal~ "Dec 6~ "Jun 2~ <df>   
    ## 11 Structures - National Structures Dataset        stru~ "Aug 1~ "Aug 3~ <df>   
    ## 12 Topo Map Data and Topo Stylesheet               topo~ "Aug 3~ "Sep 3~ <df>   
    ## 13 Topobathy - Elevation                           elev~ ""      ""      <df>   
    ## 14 Transportation                                  tran~ "Jul 1~ "Jul 1~ <df>   
    ## 15 Woodland Tint                                   wood~ "Aug 2~ "Sep 1~ <df>   
    ## # ... with abbreviated variable names 1: lastPublishedDate, 2: lastUpdatedDate

The fifth item appears to be what we’re looking for. Let’s take a closer
look.

``` r
datasets %>%
    filter(str_detect(title, "Lidar")) %>%
    select_if(is.character) %>% # Can't combine different types of variables in the same column
    pivot_longer(title:zipLink)
```

    ## # A tibble: 18 x 2
    ##    name                   value                                                 
    ##    <chr>                  <chr>                                                 
    ##  1 title                  "Elevation Source Data (3DEP) - Lidar, IfSAR"         
    ##  2 sbDatasetTag           "National Elevation Dataset (NED)"                    
    ##  3 parentCategory         "Data"                                                
    ##  4 id                     "elevation-source-data-lidar-isfar"                   
    ##  5 description            ""                                                    
    ##  6 refreshCycle           "Continuous"                                          
    ##  7 lastPublishedDate      "Sep 9, 2019"                                         
    ##  8 lastUpdatedDate        "Sep 11, 2019"                                        
    ##  9 dataGovUrl             ""                                                    
    ## 10 infoUrl                "https://www.usgs.gov/core-science-systems/ngp/3dep/a~
    ## 11 thumbnailUrl           "https://apps.nationalmap.gov/datasets/img/lpc_thumb.~
    ## 12 mapServerUrl           "https://index.nationalmap.gov/arcgis/rest/services/3~
    ## 13 mapServerLinkShowTitle  <NA>                                                 
    ## 14 mapServerLinkHideTitle  <NA>                                                 
    ## 15 defaultExtent          "Varies"                                              
    ## 16 descriptionLink         <NA>                                                 
    ## 17 layerOpacity            <NA>                                                 
    ## 18 zipLink                 <NA>

Not especially helpful. Well, anyways, I’ve been playing around on the
user-friendly [API for data
products](https://apps.nationalmap.gov/tnmaccess/#/product) and have
learned how to structure URL queries that way, so let’s move on to that.

## Finding LiDAR data
