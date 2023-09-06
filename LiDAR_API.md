LiDAR API
================

## Goal

We seek to find areas where LiDAR data has been collected on two
occasions. Eventually, we will use fire perimeter data to find areas
where LiDAR was collected before and after a fire. That might allow us
some insight into the effects of fire on the properties of vegetation
and particularly underbrush, potentially using the machine-learning
approach that Tony proposed.

## Approach

I plan to use the R packages in the
[tidyverse](https://www.tidyverse.org) to process data taken from the
[web API](https://apps.nationalmap.gov/tnmaccess/#/) provided by [The
National Map](https://apps.nationalmap.gov/lidar-explorer/#/).
Ultimately, interacting with URLs is performed using a package that
ports [curl](https://curl.se/) over to R. I’ll leave in the package
messages and metadata just in case they help down the road.

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
library(curl)
```

    ## Using libcurl 7.64.1 with Schannel

    ## 
    ## Attaching package: 'curl'

    ## The following object is masked from 'package:readr':
    ## 
    ##     parse_date

## Finding a dataset

Initially, I used the dataset API but it was not especially helpful. It
only has 15 items. Well, anyways, I’ve been playing around on the
user-friendly [API for data
products](https://apps.nationalmap.gov/tnmaccess/#/product) and have
learned how to target LiDAR products using URL queries that way, so
let’s move on to that.

## Finding LiDAR data

The [guide to the TNM
API](https://apps.nationalmap.gov/help/documents/TNMAccessAPIDocumentation/TNMAccessAPIDocumentation.pdf)
says that there are almost 4 million products available. Running the
[products query with no
arguments](https://tnmaccess.nationalmap.gov/api/v1/products) suggests
that that guide is out of date and there are in fact almost 13 million
products available (upper left). Queries targeting LiDAR data
specifically show that there are almost 7 million LiDAR products
available, all but five of which are available in the common LAS or LAZ
(compressed LAS) formats. Granted, most of these are small-ish
rectangles that are components of a given project conducted by USGS or
another agency.

To begin moving towards a sensible dataset size, let’s restrict our
search to the continental US (CONUS). Not that it helps all that much,
seeing as there are still over 6 million products. A bounding box for
the CONUS spans roughly 60 degrees of longitude (125° W to 65° W) and 30
degrees of latitude (20° N to 50° N), including a little bit of cushion.

Let’s get our hands dirty. I’m going to pick a random 1°×1° box
somewhere in the Western US and query all the LiDAR data it contains.

``` r
ptm <- proc.time() # A timer will help assess the feasibility of upscaling

# Describe URL components for the query
root_url <- "https://tnmaccess.nationalmap.gov/api/v1/products?"
bbox_url <- "bbox=-100,40,-99,41"
type_url <- "datasets=Lidar%20Point%20Cloud%20(LPC)"
maxn_url <- "max=10000"
form_url <- "outputFormat=CSV"

# Open a connection to the server using the query
url <- url(paste0(root_url,bbox_url,"&",type_url,"&",maxn_url,"&",form_url))

# Download the data from the server
data <- read_csv(url)
```

    ## Rows: 1000 Columns: 25
    ## -- Column specification --------------------------------------------------------
    ## Delimiter: ","
    ## chr  (17): title, moreInfo, sourceId, sourceName, sourceOriginName, metaUrl,...
    ## dbl   (2): sizeInBytes, bestFitIndex
    ## lgl   (2): sourceOriginId, downloadURLRaster
    ## dttm  (2): lastUpdated, dateCreated
    ## date  (2): publicationDate, modificationInfo
    ## 
    ## i Use `spec()` to retrieve the full column specification for this data.
    ## i Specify the column types or set `show_col_types = FALSE` to quiet this message.

``` r
proc.time() - ptm # Calculate duration
```

    ##    user  system elapsed 
    ##    0.23    0.03    0.79

The API guide said that it was possible to get 10,000 results per page,
but it appears that the limit is actually 1,000. Oh well.

``` r
maxn_url_fixed <- "max=1000"

offset <- 100 # Start with the 101st item
offset_url <- paste0("offset=",offset)

# Update the query
url <- url(paste0(root_url,bbox_url,"&",type_url,"&",maxn_url_fixed,"&",offset_url,"&",form_url))

# Download data using the new query
data_check <- read_csv(url)
```

    ## Rows: 1000 Columns: 25
    ## -- Column specification --------------------------------------------------------
    ## Delimiter: ","
    ## chr  (17): title, moreInfo, sourceId, sourceName, sourceOriginName, metaUrl,...
    ## dbl   (2): sizeInBytes, bestFitIndex
    ## lgl   (2): sourceOriginId, downloadURLRaster
    ## dttm  (2): lastUpdated, dateCreated
    ## date  (2): publicationDate, modificationInfo
    ## 
    ## i Use `spec()` to retrieve the full column specification for this data.
    ## i Specify the column types or set `show_col_types = FALSE` to quiet this message.

``` r
# Check how many items are shared in common between the two
length(intersect(data$downloadURL, data_check$downloadURL)) # URLs are unique identifiers
```

    ## [1] 900

As we’d expect, skipping 100 entries leaves 900 entries in common. Now
let’s see if we can get all the data from our 1°×1° box into one table.

``` r
# Specify our page size explicitly
max_n <- 1000

# Also specify a break point for our loop for safety
break_n <- 2e4 # i.e., 10,000

# Reset the offset
offset <- 0
offset_url <- paste0("offset=",offset)

ptm <- proc.time() # Start the timer

# Update the query
url <- url(paste0(root_url,bbox_url,"&",type_url,"&",maxn_url_fixed,"&",offset_url,"&",form_url))

# Download the data
new_data <- read_csv(url)
```

    ## Rows: 1000 Columns: 25
    ## -- Column specification --------------------------------------------------------
    ## Delimiter: ","
    ## chr  (17): title, moreInfo, sourceId, sourceName, sourceOriginName, metaUrl,...
    ## dbl   (2): sizeInBytes, bestFitIndex
    ## lgl   (2): sourceOriginId, downloadURLRaster
    ## dttm  (2): lastUpdated, dateCreated
    ## date  (2): publicationDate, modificationInfo
    ## 
    ## i Use `spec()` to retrieve the full column specification for this data.
    ## i Specify the column types or set `show_col_types = FALSE` to quiet this message.

``` r
# Create a copy to compile data from multiple queries
data_all <- new_data

# Query the server repeatedly until either a partial page of results is returned or the break point is reached
suppressMessages({ # Remove repeated, identical messages
    while (nrow(new_data) == max_n & nrow(data_all) <= break_n) {
        offset <- offset + max_n
        offset_url <- paste0("offset=",offset)
        url <- url(paste0(root_url,bbox_url,"&",type_url,"&",maxn_url_fixed,"&",offset_url,"&",form_url))
        new_data <- read_csv(url)
        data_all <- bind_rows(data_all, new_data)
    }
})

proc.time() - ptm # This could be inaccurate because repeating a query yields results much faster
```

    ##    user  system elapsed 
    ##     0.4     0.0     4.0

``` r
nrow(data_all) == length(unique(data_all$downloadURL)) # Check whether all results are unique
```

    ## [1] TRUE

``` r
nrow(data_all) # Total number of products in the box
```

    ## [1] 10314

On the first go, getting 10,000 results took about 45 seconds. Round up
to a minute and that suggests we could populate a table with all 7
million results in less than 12 hours, assuming that the TNM API doesn’t
use DDoS-prevention technology. It sure would be nice if we could
download the metadata in this API as a whole, which would take a
fraction of the time, but you have to play the cards you’re dealt.

## Assessing overlap of LiDAR data
