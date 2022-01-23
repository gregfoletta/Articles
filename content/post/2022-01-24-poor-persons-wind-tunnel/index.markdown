---
title: Poor Man's Wind Tunnel
author: ''
date: '2021-12-24'
slug: 
categories: []
tags: []
images: []
---



I raced bikes as a junior, then came back to it in my mid thirties. One of the big contrasts has been the low barrier to entry for technology. When I was young everyone had bike computer that showed you your speed, but that was it. Now you've got speed, location via GPS, cadence, heart rate, and power. Looking and graphs and visualising the data is interesting, but I've been wanting to try and do more with it.

This article is split into two sections:

1. In the first section we will take cycling data that I've generated in a controlled manner, extract it from XML and transform it into a tidy, rectangular data frame. The goal is to show how elegance of R and how easy it performs manipulations like this.
1. In the second section we will use the data to create a "poor person's wind tunnel", determining how efficient different positions on the bike are in terms of watts saved. 


# Data Acquisition

Let's first talk about how the experimental set up and how the data was generated. At a high level I needed to 

The data was gathered from two sources: Powertap P1 power meter pedals attached to the cranks of a track bike, and a Wahoo speed sensor attached to the hub of the rear wheel. The track bike was ridden around the the [Coburg velodrome](https://www.google.com/maps/place/Coburg+Velodrome/@-37.7296415,144.9550159,224m/data=!3m1!1e3!4m5!3m4!1s0x6ad65b31556ddfe1:0x781y b87247b213bce!8m2!3d-37.7298532!4d144.9553354!5m1!1e4).

For each position on the handlebars, the pace was slowly increasing from around 20km/h to to 50km/h, in around 8-10km/h increments. For each increment level, the pace was held as close as possible to constant for two laps, increasing to three laps for the higher speeds in order to get enough samples.


# Transforming the Data

The data is downloaded in TCX (Training Center XML) format. While good for us that it's in a standard structured format, it's not quite in the rectangular tidy data structure that we need for our analysis. Our first step is to extract and transform it into this format. The XML is structured as a single *activity* with one or more *laps*. Each *lap* has *trackpoints* which contain a timestamp and all of the other data (speed, power, heartrate, etc) that we've collected. A trackpoint is taken every one second.

Here's an example of the XML from the root to the a trackpoint. Only one lap and one trackpoint is shown.

```xml
<TrainingCenterDatabase>
 <Activities>
  <Activity>
   <Lap>
    <Track>
     <Trackpoint>
      <Time>2022-01-16T00:00:41Z</Time>
      <DistanceMeters>1.48</DistanceMeters>
      <HeartRateBpm>
       <Value>105</Value>
      </HearthRateBpm>
      <Cadence>32</Cadence>
      <Extensions>
       <TPX>
        <Speed>3.19</Speed>
        <Watts>56</Watts>
       </TPX>
      </Extensions>
      </Trackpoint>
      ...
    </Track>
   </Lap>
   ...
  </Activity>
 </Activities>
</TrainingCenterDatabase>
```

In what I think is a great example of the elegance and power of R, the following code takes our TCX file and uses XPath to extract out the fields we need, turning it into a tidy data frame.



```r
cycle_data <-
    read_xml('cycle_data.tcx') %>%
    xml_ns_strip() %>%
    xml_find_all('.//Trackpoint[Extensions]') %>%
    {
        tibble(
            time = xml_find_first(., './Time') %>% xml_text(),
            speed = xml_find_first(., './Extensions/TPX/Speed') %>% xml_text(),
            power = xml_find_first(., './Extensions/TPX/Watts') %>% xml_text(),
            bpm = xml_find_first(., './HeartRateBpm/Value') %>% xml_text(),
            cadence = xml_find_first(., './Cadence') %>% xml_text(),
            lap = xml_find_num(
                .,
                'count(./parent::Track/parent::Lap/preceding-sibling::Lap)'
            ),
        )
    }

print(cycle_data)
```

```
## # A tibble: 1,985 × 6
##    time                 speed power bpm   cadence   lap
##    <chr>                <chr> <chr> <chr> <chr>   <dbl>
##  1 2022-01-16T00:00:42Z 3.19  56    105   32          0
##  2 2022-01-16T00:00:43Z 3.28  100   104   34          0
##  3 2022-01-16T00:00:44Z 3.50  75    104   36          0
##  4 2022-01-16T00:00:45Z 3.58  84    105   38          0
##  5 2022-01-16T00:00:46Z 3.78  79    106   40          0
##  6 2022-01-16T00:00:47Z 4.08  83    107   43          0
##  7 2022-01-16T00:00:48Z 4.39  172   108   46          0
##  8 2022-01-16T00:00:49Z 4.58  197   109   47          0
##  9 2022-01-16T00:00:50Z 4.78  213   111   49          0
## 10 2022-01-16T00:00:51Z 5.00  288   113   51          0
## # … with 1,975 more rows
```

I think it's worth going through each line:

- The TCX file is read in as as an *xml_document*
- The TCX is namespaced, but as we're only working with this file we strip the namespace to make our XPath shorter.
- We find all <Trackpoint> nodes that have a child <Extensions> node. We can't just find all of the trackpoints as there seems to be a quirk where the first trackpoint has a timestamp but nothing else.
- We then construct a data frame (a tibble) by finding and extracting the text from our data nodes (speed, power, etc) from each of the trackpoints. The pipe to tibble is enclosed in braces to stop the left-hand side from automatically being placed asa the first argument. 
- We also want to find out which *lap* the trackpoint is a member of. This is done by finding the parent lap node for each of the trackpoints, counting how many preceeding lap siblings each node has.

Everything is extraxted out as a character type, so we do some type conversion.


```r
cycle_data <-
    cycle_data %>% 
    mutate(
        lap = as.integer(lap),
        time = ymd_hms(time),
        across(c(bpm, cadence, speed, power), as.double),
    )

print(cycle_data)
```

```
## # A tibble: 1,985 × 6
##    time                speed power   bpm cadence   lap
##    <dttm>              <dbl> <dbl> <dbl>   <dbl> <int>
##  1 2022-01-16 00:00:42  3.19    56   105      32     0
##  2 2022-01-16 00:00:43  3.28   100   104      34     0
##  3 2022-01-16 00:00:44  3.5     75   104      36     0
##  4 2022-01-16 00:00:45  3.58    84   105      38     0
##  5 2022-01-16 00:00:46  3.78    79   106      40     0
##  6 2022-01-16 00:00:47  4.08    83   107      43     0
##  7 2022-01-16 00:00:48  4.39   172   108      46     0
##  8 2022-01-16 00:00:49  4.58   197   109      47     0
##  9 2022-01-16 00:00:50  4.78   213   111      49     0
## 10 2022-01-16 00:00:51  5      288   113      51     0
## # … with 1,975 more rows
```

And that's it: with less than 20 lines of code we've been able to tranform our XML into a tidy, retangular data format.

Let's visualise a couple of aspects of the data to give a general feel for it. First off is the power output over time, with each lap coloured separately. Laps two and four contain the data that we will be using in our model.

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-4-1.png" width="672" />

The data was generated on a track bike, which has only a single gear. This the speed and cadence should have a perfect linear relationship.

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-5-1.png" width="672" />

We see this linear relationship, but note that there is a distribution of speeds across each cadence value. This is likley due to the cadence being measured as an integer, whereas the speed has a decimal point. We can also see that the slower we move, the noiser the data gets.

Finally, let's take  look at the data we'll be modelling and its relationship. We first extract out the second and fourth laps from the data, then create a new *position* factor variable with appropriately names levels.


```r
cycle_data_cleaned <-
    cycle_data %>% 
    filter(
        lap %in% c(1,3),
        between(power - lag(power), -20, 20)
    ) %>%
    mutate(position = fct_recode(as_factor(lap), "Tops" = "1", "Drops" = "3"))
```

We then take a look at the relationsip between speed and power, which we will be modelling in the second section.

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-7-1.png" width="672" />

We see some sort of exponential relationship between speed and power (we'll discuss that in the next section). We can also see the "blobs" of data where I have tried to keep a constant speed, and how keeping that constant speed become more difficult as I went faster.


# Building a Model

Before we define a model in R, we first have to define what the model is going to be. I'm going to be using the drag equation:
y
$$ F_D = \frac{1}{2}\rho C_D A v^2$$
where \\(\rho\\) is the density of the fluid (in our case air), \\(C_D\\) is the drag coefficient of my bike/body, \\(A\\) is front on cross-sectional area, and \\(v\\) is my velocity. I'm going to bundle up all coefficients into a single coefficient \\(\beta\\).

$$ 
\text{Let } \beta = \frac{1}{2} \rho C_D A \\
F_D = \beta v^2
$$
We've got force on our left-hand side, but we need power. Energy is force x distance, and power is energy over time, so we have:

$$ F_D \frac{x}{t} = \beta v^2 \frac{x}{t} \\
P_D = \beta v^2 \frac{x}{t} $$

As distance over time is simply velocity, we are left with:

$$ P_D = \beta v^3 $$ 
We're going to use this model in conjuntion with our data. The model will give us an estimate (with some uncertainty) of the \\(\beta\\) value when I was on the tops of the handvars, and a \\(\beta\\) value when I was in the drops.

As we know the generative process for this data, we have some prior information that we should definitely include in the model: it takes zero watts to go zero metres per second. This implies that our model should go through the origin \\((0,0)\\) and we should not include an intercept. 


```r
cycle_data_mdl <-
    cycle_data_cleaned %>% 
    lm(power ~ position + I(speed^3) - 1, data = .) 

tidy(cycle_data_mdl)
```

```
## # A tibble: 3 × 5
##   term          estimate std.error statistic  p.value
##   <chr>            <dbl>     <dbl>     <dbl>    <dbl>
## 1 positionTops    33.4     2.27        14.7  2.25e-43
## 2 positionDrops   16.4     2.09         7.83 1.71e-14
## 3 I(speed^3)       0.217   0.00239     91.0  0
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-9-1.png" width="672" />


<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-10-1.png" width="672" />

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-11-1.png" width="672" />


<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-12-1.png" width="672" />

