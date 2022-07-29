---
title: Geospatial Data Analysis
author: 'Greg Foletta'
date: '2022-06-20'
slug: geospatial_data_analysis
categories: [R Geospatial Animation]
---

Over the past couple of years I've been focused on writing long form, detailed analyses of "things": packets, betting, bandwidth forecasting. This article bucks the trend and is more of a short form, fun article.

My friend Jen is currently writing a thesis on migration in Melbourne, Australia during the 1950s, 60s, and 70s. Specifically she is looking at their movement within the northern suburbs of Melbourne.

Jen had census data on percentage of non-English speaking within each suburb during different years, and with a conference coming up wanted to be able to tell a visual story of the movement over the years. She reached out to me and I grabbed on to the opportunity to learn to R tools I'd never used before: geospatial data and animations.

This article is a "making of", documenting the process to get from data to a nice animtation that tells a story. There's nothing crazy or even very hard. If there's anything I want to show it's just how easy it is - in a few lines of R - to go from raw data to a visualisation that tells a story no table or bar graph could ever tell.




# Step 1: The Data

The fist step was to ingest the data. Jen provided me Excel files in a human readable format, to which I tidied up manually. The *Year* column is the census year, the *Suburb* is the suburb in Melbourne, and the *Percentage* is the percentage of non-English speaking people within that suburb. 


```r
migrant_data <- 
    read.xlsx('data/migrant_population_growth.xlsx', sheet = 'Tidied') %>%
    as_tibble() %>% 
    print()
```

```
## # A tibble: 57 × 4
##     Year Suburb      Total Percentage
##    <dbl> <chr>       <dbl>      <dbl>
##  1  1954 Keilor       3113      0.291
##  2  1954 Fitzroy      7321      0.242
##  3  1954 Melbourne   17252      0.185
##  4  1954 Sunshine     7026      0.17 
##  5  1954 St Kilda     8598      0.161
##  6  1954 Caulfield   12727      0.153
##  7  1954 Werribee      935      0.14 
##  8  1954 Collingwood  3499      0.129
##  9  1954 Brunswick    6603      0.123
## 10  1954 Richmond     4091      0.116
## # … with 47 more rows
```
The next step was to get geospatial data for these suburbs. Thankfully the Australian government has [shapefile data](https://data.gov.au/dataset/ds-dga-af33dd8c-0534-4e18-9245-fc64440f742e/distribution/dist-dga-4d6ec8bb-1039-4fef-aa58-6a14438f29b1/details?q=) available for suburbs and locality within Victoria.


```r
vic_localities <- read_sf('data/VIC_LOC_POLYGON_shp GDA2020/vic_localities.shp')

vic_localities %>% 
    ggplot() +
    geom_sf(size = .1)
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-2-1.png" width="672" />

As Jen is only interested in inner-Melbourne, I can crop this down:


```r
inner_melb_localities <-
    vic_localities %>% 
    st_crop(xmin=144.7, xmax=145.1, ymin=-37.95, ymax=-37.6)
```

```
## Warning: attribute variables are assumed to be spatially constant throughout all
## geometries
```


<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-4-1.png" width="672" />


```r
migrant_data_geo <-
    migrant_data %>% 
    group_by(Year) %>% 
    nest() %>% 
    mutate(geo = map(data, ~{ right_join(.x, inner_melb_localities, by = c('Suburb' = 'LOC_NAME')) })) %>% 
    unnest(geo) %>%
    arrange(Suburb) %>% 
    mutate(Percentage = replace_na(Percentage, 0)) %>%
    select(-data) %>%
    ungroup() %>% 
    st_as_sf() 
```


```r
migrant_data_geo %>%
    ggplot() +
    geom_sf(aes(fill = Percentage)) +
    labs(
        title = "Melbourne Local Government Areas with the largest percentage\nof local residents born overseas*",
        subtitle = "Year: {closest_state}"
    ) +
    theme(
        plot.title = element_text(size = 20),
        plot.subtitle = element_text(size = 17),
        legend.title = element_text(size = 17),
        legend.text= element_text(size = 17)
    ) +
    scale_fill_distiller(name = "Percent", trans = 'reverse', labels = percent) +
    transition_states(Year, transition_length = 3, state_length = 5) 
```

![](index_files/figure-html/unnamed-chunk-6-1.gif)<!-- -->
