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
Let’s choose some variables that look promising.
