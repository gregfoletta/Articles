---
title: Telling a Spatial Story 
author: 'Greg Foletta'
date: '2022-12-18'
slug: spatial_story 
categories: [R Geospatial Animation]
---

My friend Jen is currently writing a thesis and reached out to me for some help. She had a presentation coming up wanted to add a visualisation to it. I jumped at the opportunity as it gently pushed me into learning a topic I'd wanted to learn for ages: spatial data analysis. 

In this short article I'll take you through how I created an animation for based on spatial data for Jen. What I hope I'll show is how easy it is to create a visualisation that tells a compelling story.

# What's the Story?

Jen's thesis is on post-war migration into the innter-northern suburbs of Melbourne, Australia. Using census data from the 50s, 60s, and 70, she wanted to communicate this migration, specifically the increase in concentrations on a per suburb basis and how how the migrations geographically changed over this time period.

I thought the best way to tell this story would be to take the data Jen had and overlay this on to the geography of Melbourne. It would be animated, transitioning between the years in the census. This would help to tell a visual story of the movement of these immigrant populations.



# Step 1: The Data

Jen was able to provide me the migration data in *.xlsx* format in a human readable format, to which I manually changed into a tidy format. My preference would have been to script this tidying as well for reproducibility, but due to time constraints the manual method was chosen.

We can see the data below, showing the year of the census, the suburb, and the total number and percentage of the population born overseas. 

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

We can render the full context of this geospatial data:


```r
vic_localities <- read_sf('data/VIC_LOC_POLYGON_shp GDA2020/vic_localities.shp')

vic_localities %>% 
    ggplot() +
    geom_sf(size = .1)
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-2-1.png" width="672" />

This data shows local government areas for the entire state of Victoria, Australia. We're only interested in the inner-Melbourne area, so we crop this to the relevant latitudes and longitudes:


```r
inner_melb_localities <-
    vic_localities %>% 
    st_crop(xmin=144.7, xmax=145.1, ymin=-37.95, ymax=-37.6)
```
<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-4-1.png" width="672" />

With our two key pieces of data in place, we can start to put them together.

# Step 2 - Data Wrangling

Next step is to merge our migration data with our geospatial data, using suburb as our key. However it's a little more complex that a simple join as we want to ensure, for every year, we have all of the geospatial information so we can render the full map.

The way to tackle this is to `group()` by each year and `nest()` the data, performing a join on this nested data with the spatial data. In this way we ensure that for each year the spatial data for each suburb is present and the map is complete. The suburbs that aren't in the data will have `NA` values for the **Percetnage** and **Total** columns. Jen made a decision to present this missing data as zero, but we make sure to put a note in the visualisation highlighting this fact.


```r
migrant_data_geo <-
    migrant_data %>% 
    group_by(Year) %>% 
    nest() |> 
    # On a per census year basis, join each year's data with the spatial data
    mutate(
        geo = map(data, ~{ right_join(.x, inner_melb_localities, by = c('Suburb' = 'LOC_NAME')) })
    ) %>% 
    unnest(geo) |> 
    arrange(Suburb) %>% 
    # Replace the NAs due to missing data with zero
    mutate(
        Percentage = replace_na(Percentage, 0),
        Total = replace_na(Total, 0),
    ) %>%
    select(-data) %>%
    ungroup() %>% 
    # Convert back to a 'simple features' (geosptatial) object
    st_as_sf() 
```

Here's the resulting SF object:


```r
migrant_data_geo |> head()
```

```
## Simple feature collection with 6 features and 9 fields
## Geometry type: POLYGON
## Dimension:     XY
## Bounding box:  xmin: 144.8885 ymin: -37.81213 xmax: 145.0158 ymax: -37.75392
## Geodetic CRS:  GDA2020
## # A tibble: 6 × 10
##    Year Suburb     Total Percentage LC_PLY_PID  LOC_PID DT_CREATE  LOC_C…¹ STATE
##   <dbl> <chr>      <dbl>      <dbl> <chr>       <chr>   <date>     <chr>   <chr>
## 1  1954 Abbotsford     0          0 lcp386f2bc… locb98… 2021-06-24 Gazett… VIC  
## 2  1961 Abbotsford     0          0 lcp386f2bc… locb98… 2021-06-24 Gazett… VIC  
## 3  1966 Abbotsford     0          0 lcp386f2bc… locb98… 2021-06-24 Gazett… VIC  
## 4  1971 Abbotsford     0          0 lcp386f2bc… locb98… 2021-06-24 Gazett… VIC  
## 5  1954 Aberfeldie     0          0 lcp122c942… loc812… 2021-06-24 Gazett… VIC  
## 6  1961 Aberfeldie     0          0 lcp122c942… loc812… 2021-06-24 Gazett… VIC  
## # … with 1 more variable: geometry <POLYGON [°]>, and abbreviated variable name
## #   ¹​LOC_CLASS
```


# Step 3 - Rendering



```r
migrant_data_geo_animation <- 
    migrant_data_geo %>%
    ggplot() +
    geom_sf(aes(fill = Percentage)) +
    labs(
        title = "Melbourne - Percentage Residents Born Overseas",
        subtitle = "Census Year: {closest_state}"
    ) +
    theme(
        plot.title = element_text(size = 10),
        plot.subtitle = element_text(size = 8),
        legend.title = element_text(size = 6),
        legend.text= element_text(size = 4)
    ) +
    scale_fill_distiller(name = "Percent", trans = 'reverse', labels = percent) +
    transition_states(Year, transition_length = 3, state_length = 5)
```

# The Result

So what do we get in the end? We get this:

![](index_files/figure-html/unnamed-chunk-8-1.gif)<!-- -->

Now I don't for one second think this is perfect, there's a lot of room for improvement. But if you compare the sheer *lack* of code required to generate it versus the story it's able to tell, I'd say it's a very good start.
