---
title: Telling a Spatial Story 
author: 'Greg Foletta'
date: '2023-03-09'
slug: spatial_story 
categories: [R Geospatial Animation]
---

My friend Jen is writing a thesis and recently reached out to me to see if I could help. She had an upcoming presentation up wanted to add some visualisation to it to better tell the story. I jumped at the opportunity as it was the an opportunity to familiarise myself with a area I'd explored: spatial data. 

In this short article I'll take you through the creation of the visualisation. It's not very complex, but what I hope to show is that the transition from data to something that tells a story can be done elegantly and with a relatively small amount of R code.

# What's the Story?

Jen's thesis is on post-war migration into the inner-northern suburbs of Melbourne, Australia. Using census data from the 50s, 60s, and 70, she wanted to communicate this migration, specifically the increase in concentrations on a per suburb basis and how how the migrations geographically changed over this time period.

Jen had provided me with the data, and I thought the best way to communicate this was to highlight the data on to the geography of Melbourne, and animate the changes throughout the each census year.



# Step 1: The Data

Jen sent me the migration data in an Excel spreadsheet, an I manually changed it into a tidy format. Were I doing this on an ongoing basis I would have scripted this tidying for reproducibility, but due to time constraints the manual was quicker and easier.

We see a sample of the data below, showing the year of the census, the suburb, and the total number and percentage of the population born overseas. 

```r
migrant_data <- 
    read.xlsx('data/migrant_population_growth.xlsx', sheet = 'Tidied') %>%
    as_tibble()

migrant_data |> sample_n(10)
```

```
## # A tibble: 10 × 4
##     Year Suburb          Total Percentage
##    <dbl> <chr>           <dbl>      <dbl>
##  1  1966 Fitzroy         12314      0.452
##  2  1971 Fitzroy         11857      0.461
##  3  1971 Essendon        12697      0.22 
##  4  1971 South Melbourne  6520      0.242
##  5  1961 Collingwood      7037      0.277
##  6  1971 Springvale      11779      0.202
##  7  1954 Melbourne       17252      0.185
##  8  1971 Coburg          17246      0.263
##  9  1971 Caulfield       16696      0.204
## 10  1966 Altona           7186      0.287
```

The next step was to get the geospatial data for these Melbourne suburbs. Thankfully the Australian government has [shapefile data](https://data.gov.au/dataset/ds-dga-af33dd8c-0534-4e18-9245-fc64440f742e/distribution/dist-dga-4d6ec8bb-1039-4fef-aa58-6a14438f29b1/details?q=) available for suburbs and locality within Victoria. 

Here's a render of the full content of the geospatial data:


```r
vic_localities <- read_sf('data/VIC_LOC_POLYGON_shp GDA2020/vic_localities.shp')

vic_localities %>% 
    ggplot() +
    geom_sf(size = .1)
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-2-1.png" width="672" />

These borders are local government areas for the entire state of Victoria, Australia. The borders of these localities aren't going to be *exactly* the same now as they were when the censuses were performed, but it'll be good enough for our purposes. We're only interested in the inner-Melbourne area, so we crop this to the relevant latitudes and longitudes:


```r
inner_melb_localities <-
    vic_localities %>% 
    st_crop(xmin=144.7, xmax=145.1, ymin=-37.95, ymax=-37.6)
```
<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-4-1.png" width="672" />

With our two key pieces of data in place, we can start to put them together.

# Step 2 - Data Wrangling

Next step is to merge our migration data with our geospatial data, using suburb as our key, however it's a little more complex that a simple join. As we want to ensure for every year we have all of the geospatial information so we can render the full map, we need to do a bit of `group()`ing and `nest()`ing.

The way I've tackled this is as such:

- First group by each year.
- Nest the data based on these groups.
- Performing a join on this nested data with the spatial data.
 - In this way we ensure that for each year, the spatial data for each suburb is present and the map is complete.
- Unnest the data
- Suburbs that aren't in the data will have `NA` values for the **Percetnage** and **Total** columns. 
  - I talked to Jen about this, and she made a decision in the short term to replace these with 0.
  - Were more rigor required for the visualisation other options may need to be considered around this missing data.
- Convert to a geospatial object.

Below is the full pipeline interspersed with comments to help understand what's happening in each stage:


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

The final step is the easiest: the rendering. The map is rendered with the fill of each polygon representing the percentage of population born overseas. We then animate the map, transitioning between the data within each *Year*


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

What we have in the end is what I handed over to Jen for her presentation: an animation showing the change in overseas-born population in inner-city Melbourne from 1954 to 1971. All done with relative ease in 40 or so lines of R. 

![](index_files/figure-html/unnamed-chunk-8-1.gif)<!-- -->

# Is That It?

Is this visualisation perfect? Far from it. There's probably two areas where it could be improved. The first (and least important) is the aestheitcs of it; I think it could simply look better. Better fonts, better arrangement, different colours. 

But more importantly I think there that there are choices to be made about how the information is presented. The suburbs with no information have been zeroed out, is that the right choice? Does the colour scale accurately convey the change, or does it need to have multiple colours in it? Do the suburbs need to be labelled? What exactly is the definition of "inner-north Melbourne"?

All of those are decisions best made by someone with domain-specific knowledge, not necessarily by the person who's generating the visualisation. Regardless, if we're looking at this through an 80/20 lens, I contiue to be amazed about the 80 that can be generated with only a few lines of R code. 
