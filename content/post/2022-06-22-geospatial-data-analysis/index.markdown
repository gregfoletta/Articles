---
title: Geospatial Data Analysis
author: ''
date: '2022-06-20'
slug: geospatial_data_analysis
categories: []
tags: []
images: []
---






```r
vic_localities <- read_sf('data/VIC_LOC_POLYGON_shp GDA2020/vic_localities.shp')

migrant_data <- 
    read.xlsx('data/migrant_population_growth.xlsx', sheet = 'Tidied') %>%
    as_tibble()
```


```r
vic_localities %>% 
    ggplot() +
    geom_sf()
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-2-1.png" width="672" />


```r
vic_localities %>% 
    left_join(migrant_data, by = c('LOC_NAME' = 'Suburb')) %>% 
    st_crop(xmin=144.5, xmax=145.2, ymin=-38, ymax=-37.4) %>%
    ggplot() +
    geom_sf()
```

```
## Warning: attribute variables are assumed to be spatially constant throughout all
## geometries
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-3-1.png" width="672" />


```r
migrant_data_geo <-
    migrant_data %>% 
    group_by(Year) %>% 
    nest() %>% 
    mutate(geo = map(data, ~{ right_join(.x, vic_localities, by = c('Suburb' = 'LOC_NAME')) })) %>% 
    unnest(geo) %>%
    arrange(Suburb) %>% 
    mutate(Percentage = replace_na(Percentage, 0)) %>%
    select(-data) %>%
    ungroup() %>% 
    st_as_sf() %>% 
    st_crop(xmin=144.7, xmax=145.1, ymin=-37.95, ymax=-37.6) 
```

```
## Warning: attribute variables are assumed to be spatially constant throughout all
## geometries
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

![](index_files/figure-html/unnamed-chunk-5-1.gif)<!-- -->
