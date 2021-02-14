---
title: 'A Bit on the Nose (Draft)'
author: Greg Foletta
date: '2021-02-04'
slug: a-bit-on-the-nose
categories: [R]
---

I've never been particularly interested in horse racing, but I married into a family that loves it. Each in-law has their own ideas and combinations of factors that lead them to bet on a particular horse, be it form, barrier position, track condition, trainer, or jockey.

After being drawn into conversations about their preferred selection methods, I wanted come at the problem from a data driven perspective. I must admit I had an initial feeling of arrogance, thinking "of course I can do this better". In fact I've seen this in many places where 'data scientists' stroll into fields of enquiry armed with data and a swag of models, but lacking an understanding of the problem space. Poor assumptions abound, and incorrect conclusions are almost certainly reached.

I was determined not to fall into the same traps, and after quashing my misplaced sense of superiority, I started to think about how to approach the problem at hand. Rather than diving straight into prediction - models akimbo - the best place to start is to create naive baseline models of the data. This gives us something to compare the performance of any complicated models. 

The first naive model we will create is simply to pick a random horse in each race. This is the lower bound for model predictive accuracy. The second naive model is to pick the favourite in each race. The favourite has many of the factors that we would be using in the model already built in: form, barrier position, trainer, jockey, etc. Any model we create needs to do better than this, otherwise we're no better than consensus.

To put it simply, we want to answer the following question:

> What is the mean and distribution of returns, and the predictive accuracy, of betting on a random and the favourite respectively in a horse race?





# Data Information & Aquisition



The data was acquired by using [rvest](https://rvest.tidyverse.org/) to scrape a website that contained the information I needed. I was able to iterate across each each , pulling out specific variables using CSS selectors and XPaths. The dataset is for my own personal use, and I have encrypted the data that us used in this article.

The dataset contains information on around 180,000 horse races over the period of 2011 to 2020. The data is in a tidy format, with each row containing information on each horse in each race. This information includes the name and state that the track, the date of the race, the name of the horse, jockey and trainer, the weight the horse is carrying, race length, duration, barrier position, etc.

Most of this information won't be used, instead we'll be focusing on the following key variables:

- *race_id* - a unique identifier for each race. There are multiple rows with the same *race_id*, each representing a horse that ran in that race.
- *odds.sp* - the 'starting price', which is are the "odds prevailing on a particular horse in the on-course fixed-odds betting market at the time a race begins.".
- *position* - the finishing position of the horse.

For readability I won't show all of the code used, however as always the full source of this page (and the entire website) is available on [github](https://github.com/gregfoletta/articles.foletta.org). The dataset is downloaded, decrypted, unzipped, the loaded into the variable `hr_results`:


```r
hr_results %>% 
    select(race_id, state, track, horse.name, jockey, odds.sp, position, barrier, weight) %>% 
    slice_sample(n = 10) %>% 
    gt()
```

<style>html {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Helvetica Neue', 'Fira Sans', 'Droid Sans', Arial, sans-serif;
}

#pejjdcxvrr .gt_table {
  display: table;
  border-collapse: collapse;
  margin-left: auto;
  margin-right: auto;
  color: #333333;
  font-size: 16px;
  font-weight: normal;
  font-style: normal;
  background-color: #FFFFFF;
  width: auto;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #A8A8A8;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #A8A8A8;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
}

#pejjdcxvrr .gt_heading {
  background-color: #FFFFFF;
  text-align: center;
  border-bottom-color: #FFFFFF;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}

#pejjdcxvrr .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#pejjdcxvrr .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 0;
  padding-bottom: 4px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#pejjdcxvrr .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#pejjdcxvrr .gt_col_headings {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}

#pejjdcxvrr .gt_col_heading {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 6px;
  padding-left: 5px;
  padding-right: 5px;
  overflow-x: hidden;
}

#pejjdcxvrr .gt_column_spanner_outer {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  padding-top: 0;
  padding-bottom: 0;
  padding-left: 4px;
  padding-right: 4px;
}

#pejjdcxvrr .gt_column_spanner_outer:first-child {
  padding-left: 0;
}

#pejjdcxvrr .gt_column_spanner_outer:last-child {
  padding-right: 0;
}

#pejjdcxvrr .gt_column_spanner {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 6px;
  overflow-x: hidden;
  display: inline-block;
  width: 100%;
}

#pejjdcxvrr .gt_group_heading {
  padding: 8px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
}

#pejjdcxvrr .gt_empty_group_heading {
  padding: 0.5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: middle;
}

#pejjdcxvrr .gt_from_md > :first-child {
  margin-top: 0;
}

#pejjdcxvrr .gt_from_md > :last-child {
  margin-bottom: 0;
}

#pejjdcxvrr .gt_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  margin: 10px;
  border-top-style: solid;
  border-top-width: 1px;
  border-top-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  overflow-x: hidden;
}

#pejjdcxvrr .gt_stub {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 12px;
}

#pejjdcxvrr .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#pejjdcxvrr .gt_first_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
}

#pejjdcxvrr .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#pejjdcxvrr .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}

#pejjdcxvrr .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}

#pejjdcxvrr .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#pejjdcxvrr .gt_footnotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}

#pejjdcxvrr .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding: 4px;
}

#pejjdcxvrr .gt_sourcenotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}

#pejjdcxvrr .gt_sourcenote {
  font-size: 90%;
  padding: 4px;
}

#pejjdcxvrr .gt_left {
  text-align: left;
}

#pejjdcxvrr .gt_center {
  text-align: center;
}

#pejjdcxvrr .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#pejjdcxvrr .gt_font_normal {
  font-weight: normal;
}

#pejjdcxvrr .gt_font_bold {
  font-weight: bold;
}

#pejjdcxvrr .gt_font_italic {
  font-style: italic;
}

#pejjdcxvrr .gt_super {
  font-size: 65%;
}

#pejjdcxvrr .gt_footnote_marks {
  font-style: italic;
  font-size: 65%;
}
</style>
<div id="pejjdcxvrr" style="overflow-x:auto;overflow-y:auto;width:auto;height:auto;"><table class="gt_table">
  
  <thead class="gt_col_headings">
    <tr>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">race_id</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1">state</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1">track</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1">horse.name</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1">jockey</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">odds.sp</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1">position</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">barrier</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">weight</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr>
      <td class="gt_row gt_right">145004</td>
      <td class="gt_row gt_left">NSW</td>
      <td class="gt_row gt_left">Quirindi</td>
      <td class="gt_row gt_left">Zerchois</td>
      <td class="gt_row gt_left">Andrew Gibbons</td>
      <td class="gt_row gt_right">10.0</td>
      <td class="gt_row gt_left">4</td>
      <td class="gt_row gt_right">1</td>
      <td class="gt_row gt_right">56.0</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">121475</td>
      <td class="gt_row gt_left">SA</td>
      <td class="gt_row gt_left">Murray Bridge</td>
      <td class="gt_row gt_left">Perfect Yank</td>
      <td class="gt_row gt_left">Jake Toeroek</td>
      <td class="gt_row gt_right">2.0</td>
      <td class="gt_row gt_left">6</td>
      <td class="gt_row gt_right">2</td>
      <td class="gt_row gt_right">53.5</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">105534</td>
      <td class="gt_row gt_left">QLD</td>
      <td class="gt_row gt_left">Mackay</td>
      <td class="gt_row gt_left">Kachada</td>
      <td class="gt_row gt_left">Tasha Chambers</td>
      <td class="gt_row gt_right">15.0</td>
      <td class="gt_row gt_left">6</td>
      <td class="gt_row gt_right">6</td>
      <td class="gt_row gt_right">57.5</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">16887</td>
      <td class="gt_row gt_left">WA</td>
      <td class="gt_row gt_left">Belmont Park</td>
      <td class="gt_row gt_left">Melody Lady</td>
      <td class="gt_row gt_left">Ben Paterson</td>
      <td class="gt_row gt_right">11.0</td>
      <td class="gt_row gt_left">9</td>
      <td class="gt_row gt_right">11</td>
      <td class="gt_row gt_right">52.0</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">137347</td>
      <td class="gt_row gt_left">WA</td>
      <td class="gt_row gt_left">Pinjarra</td>
      <td class="gt_row gt_left">Sulphur Crested</td>
      <td class="gt_row gt_left">Clint Johnston-Porter</td>
      <td class="gt_row gt_right">9.0</td>
      <td class="gt_row gt_left">4</td>
      <td class="gt_row gt_right">8</td>
      <td class="gt_row gt_right">56.5</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">9412</td>
      <td class="gt_row gt_left">SA</td>
      <td class="gt_row gt_left">Balaklava</td>
      <td class="gt_row gt_left">Wise And Happy</td>
      <td class="gt_row gt_left">Jason Holder</td>
      <td class="gt_row gt_right">10.0</td>
      <td class="gt_row gt_left">6</td>
      <td class="gt_row gt_right">8</td>
      <td class="gt_row gt_right">58.0</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">176251</td>
      <td class="gt_row gt_left">NSW</td>
      <td class="gt_row gt_left">Tomingley</td>
      <td class="gt_row gt_left">Gorgeous Boy</td>
      <td class="gt_row gt_left">Katelyn Jenkinson</td>
      <td class="gt_row gt_right">6.0</td>
      <td class="gt_row gt_left">6</td>
      <td class="gt_row gt_right">5</td>
      <td class="gt_row gt_right">63.0</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">87895</td>
      <td class="gt_row gt_left">QLD</td>
      <td class="gt_row gt_left">Ipswich</td>
      <td class="gt_row gt_left">Sequoia Miss</td>
      <td class="gt_row gt_left">James Orman</td>
      <td class="gt_row gt_right">8.0</td>
      <td class="gt_row gt_left">5</td>
      <td class="gt_row gt_right">5</td>
      <td class="gt_row gt_right">56.0</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">163399</td>
      <td class="gt_row gt_left">VIC</td>
      <td class="gt_row gt_left">Stony Creek</td>
      <td class="gt_row gt_left">O'Tauto</td>
      <td class="gt_row gt_left">Nikita Beriman</td>
      <td class="gt_row gt_right">NA</td>
      <td class="gt_row gt_left">3</td>
      <td class="gt_row gt_right">3</td>
      <td class="gt_row gt_right">NA</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">155259</td>
      <td class="gt_row gt_left">NSW</td>
      <td class="gt_row gt_left">Rosehill</td>
      <td class="gt_row gt_left">Rarer Than Rubies</td>
      <td class="gt_row gt_left">Kayla Nisbet</td>
      <td class="gt_row gt_right">6.5</td>
      <td class="gt_row gt_left">5</td>
      <td class="gt_row gt_right">5</td>
      <td class="gt_row gt_right">58.0</td>
    </tr>
  </tbody>
  
  
</table></div>


# An Explore

Let's take a look at the dataset from a few different perspectives to give us some context. First up we take a look at the number of races per month per state. We can clearly see the yearly cyclic nature, with the rise into the spring racing carnivals and a drop off over winter.


```r
hr_results %>% 
    count(state, month = floor_date(date, '1 month')) %>% 
    ggplot() +
    geom_line(aes(month, n, colour = fct_reorder(state, n, .desc = TRUE))) +
    labs(
        title = 'Number of Race Days per Month per State',
        x = 'Month',
        y = 'Race Days',
        colour = 'State'
    )
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-4-1.png" width="672" />

Next we take a look at the top 10 winning horses and trainers over this period:


```r
hr_results %>%
    filter(position == 1) %>%  
    pivot_longer(c(horse.name, trainer)) %>% 
    count(name, value, name = 'wins') %>% 
    group_by(name) %>%
    slice_max(wins, n = 10) %>% 
    ggplot() +
    geom_col(aes(fct_reorder(value, wins), wins), fill = 'darkgreen') +
    facet_wrap(vars(name), scales = 'free') +
    coord_flip() +
    labs(
        title = 'Top 10 Wins by Horse and by Trainer (2011 - 2020)',
        x = 'Name',
        y = 'Wins'
    )
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-5-1.png" width="672" />

Which tracks have run the most races over this period?


```r
hr_results %>% 
    distinct(race_id, .keep_all = TRUE) %>% 
    count(track, name = 'races') %>% 
    slice_max(races, n = 10) %>% 
    ggplot() +
    geom_col(aes(fct_reorder(track, races), races), fill = 'lightblue') +
    coord_flip() +
    labs(
        title = 'Tracks - Total Race Days (2011 - 2020)',
        x = 'Tack Name',
        y = 'Race Days'
    )
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-6-1.png" width="672" />

Finally, what is the distribution of the starting price odds? THere's a very long tail for this variable going up to around 500:1, so I've removed odds below 100:1 to provide a better view of the most common values. What's interesting to note there is the large increases in horses with odds on nice round numbers after the 20:1 mark.


```r
hr_results %>%
    drop_na(odds.sp) %>%
    ggplot() +
    geom_histogram(aes(odds.sp), binwidth = 1) +
    scale_x_continuous(limits = c(0, 100), breaks = seq(0, 100, 5)) +
    labs(
        title = 'Starting Price Odds (2011 - 2021)',
        subtitle = 'Histogram',
        x = 'Odds',
        y = 'Count'
    )
```

```
## Warning: Removed 58409 rows containing non-finite values (stat_bin).
```

```
## Warning: Removed 2 rows containing missing values (geom_bar).
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-7-1.png" width="672" />


# Data Sampling

With a high level handle on the data we're working with, let's move on to answering the questions. The process is reasonably simple: we simulate placing a dollar bet on a horse, and either collect our return (the starting price odds) in the event that in won, or lose the dollar in the event that it lost. But we want to do this a number of times on different races so we can gauge the variance of our returns.

The process we will use is:
- A sample of races across the time period is taken.
    - I'll be using 0.5% of all races, which works out to be ~800 races, or about 1.5 races bet on per week.
- A dollar 'bet' is placed (based on the two criteria) on a horse in each race.
- The return is determined.
- The cumulative return is calculated.
- This process is repeated a number of times. 

This in effect allows us to live a number of 'lives' over the period, with each life varying in the races that were bet on.

The first step is to nest the data for each race together, allowing us to easily sample on a per race basis, rather than on a per horse basis.


```r
# Nest per race
hr_results <- hr_results %>%
    group_by(race_id) %>% 
    nest()

head(hr_results)
```

```
## # A tibble: 6 x 2
## # Groups:   race_id [6]
##   race_id data              
##     <dbl> <list>            
## 1   25488 <tibble [6 × 34]> 
## 2   25489 <tibble [5 × 34]> 
## 3   25490 <tibble [6 × 34]> 
## 4   25491 <tibble [12 × 34]>
## 5   25492 <tibble [14 × 34]>
## 6   25493 <tibble [9 × 34]>
```


We then use the `mc_cv()` (Monte-Carlo cross validation) function to create our sampled data sets. Technically we're not performing the cross-validation part, only using the 'analysis' or 'training' set that comes back from the cross-validation function. 

We create a worker function `mc_sample()` that we can pass it to `future_map()`. This which allows us to spread the workload across multiple cores on the system, speeding up the process.

We generate 20 samples (to be increased in the final version of this artucle) of .5% of the total races (~800). The returned results are then unnested, returning us back to our original tidy format, with each sample identified by the *sample_id* variable.


```r
# Sampling function 
mc_sample <- function(data, times, prop) {
    data %>% 
        mc_cv(times = times, prop = prop) %>% 
        mutate(analysis = map(splits, ~analysis(.x))) %>%
        select(-c(id, splits))
}

plan(multisession, workers = availableCores() - 1)

# Parallel Monte Carlo cross-validation
number_samples <- 20 
hr_mccv <- future_map(
    1:number_samples,
    ~{ mc_sample(hr_results, times = 1, prop = .005) },
    .options = furrr_options(seed = TRUE)
)

# Switch plans to close workers and release memory
plan(sequential)

# Bind samples together and unnest
hr_mccv <- hr_mccv %>% 
    bind_rows() %>% 
    mutate(sample_id = 1:n()) %>% 
    unnest(cols = analysis) %>% 
    unnest(cols = data)
```

A `dollar_bet_profit()` function is created which places a dollar bet 'on the nose' (i.e. for the win only) on each horse, then determines the profit of our bet based on the starting price odds. The data set uses decimal (also known as continental) odds, so if we placed a \$1 bet on a horse with odds of 3.0, and the horse won, our *return* would be $3. But taking away our stake, our *profit* would be \$2. If the horse didn't win, our return is \$0 but our profit is $-1. 

As our stake is constant over time, we remove it and focus on profit to give us a clearer idea of the performance of our betting strategy.


```r
# Places a dollar bet for the win on each horse and calculates the profit.
# For each sample of races it creates an index variable, and calculates
# the cumulative profit.
dollar_bet_profit <- function(data) {
    data %>% 
        mutate(bet.profit= if_else(position == 1, odds.sp - 1, -1)) %>% 
        group_by(sample_id) %>% 
        mutate(
            sample_race_index = 1:n(),
            cumulative.profit = cumsum(bet.profit)
        ) %>% 
        ungroup()
}
```

# Approach 1: Random Selection

The first approach to take is to bet on a random horse per race.


```r
# Select a random horse from each race where there are odds available
hr_random <- hr_mccv %>% 
    drop_na(odds.sp) %>%
    group_by(sample_id, race_id) %>% 
    slice_sample(n = 1) %>% 
    ungroup()

# Place our bets
hr_random <-dollar_bet_profit(hr_random)
```

What kind of accuracy does this give us?


```r
hr_random_accuracy <- 
    hr_random %>%
    mutate(win = if_else(position == 1, 1, 0)) %>% 
    group_by(sample_id) %>% 
    summarise(accuracy = mean(win))

hr_random_accuracy %>% 
    ggplot() +
    geom_histogram(aes(accuracy), binwidth = .001) +
    geom_vline(aes(xintercept = mean(accuracy))) +
    geom_label(aes(mean(accuracy), 1, label = round(mean(accuracy), 3)))
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-12-1.png" width="672" />


So it's an mean accuracy of 11%, with 95% range of [9.7% - 13.4%]. That's about a 1 in 9 chance of picking the winning horse. At first I thought this was a little low, as the average number of horses in a race was about 6, so I naively assumed that the random method would give us a 1 in 6 chance of picking the winnow, or 17% accuracy level. But this assumption assumes a uniform probability of winning for each horse, which of course is not correct.

Accuracy is one thing, but what about our returns? Let's take a look at the at the cumulative return over time and its distribution. 


```r
hr_random %>% 
    filter(sample_id %in% 1:40) %>% 
    ggplot() +
    geom_line(aes(sample_race_index, cumulative.profit, group = sample_id), alpha = .5) +
    labs(
        title = "Dollar Bets - Random",
        x = 'Race Index',
        y = 'Dollars'
    )
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-14-1.png" width="672" />

```r
hr_random %>% 
    group_by(sample_id) %>% 
    summarise(profit = sum(bet.profit)) %>%
    ggplot() +
    geom_histogram(aes(profit), binwidth = 5) +
    geom_vline(aes(xintercept = mean(profit))) +
    labs(
        title = 'Dollar Bet - Random Horse - Total Profit Counts',
        subtitle = 'Bin Width = 5',
        x = 'Total Profit',
        y = 'Count'
    )
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-14-2.png" width="672" />
The result isn't great: in the long run we've lost a fair amount of money. You can see some occasional big jumps where we've managed to pick the long shot, but over time, bit-by-by, we're losing money.



The mean profit on the random bet is -$257.16 and 95% of profits are in the range of [-$364.17 - -$75.59].  

# Approach 2 - Favourite

The second approach to take is to bet on the favourite in each race. We rank each horse in each race using the `order()` function, and extract the horse with a rank of 1. For races where there are two equal favourites, we pick one of those horses at random.


```r
# Favourite horse from each race
hr_favourite <- hr_mccv %>% 
    drop_na(odds.sp) %>% 
    group_by(sample_id, race_id) %>% 
    mutate(odds.rank = order(odds.sp)) %>% 
    slice_min(odds.rank, with_ties = FALSE, n = 1) %>% 
    ungroup()
    
# Place out bets
hr_favourite <- dollar_bet_profit(hr_favourite)
```

What's our accuracy look like for this kind of bet?


```r
# Calculate the accuracy
hr_favourite_accuracy <- 
    hr_favourite %>%
    mutate(win = if_else(position == 1, 1, 0)) %>% 
    group_by(sample_id) %>% 
    summarise(accuracy = mean(win))

# Graph
hr_favourite_accuracy %>%  
    ggplot() +
    geom_histogram(aes(accuracy), binwidth = .001) +
    geom_vline(aes(xintercept = mean(accuracy))) +
    geom_label(aes(mean(accuracy), 1, label = round(mean(accuracy), 3)))
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-17-1.png" width="672" />

i
This is looking much better - we've got a mean accuracy across all of the samples of 35% wih a 95% range of 33.2% - 37.5%. These accuracy percentages look pretty good, and gut feel is that they would be pretty difficult to even get close to with any sort of predictive model. Picking the favourite is around 314 times better than when picking a random horse.

Let's take a look at the cumulative returns over time:


```r
hr_favourite %>%
    filter(sample_id %in% 1:40) %>% 
    ggplot() +
    geom_line(aes(sample_race_index, cumulative.profit, group = sample_id), alpha = .5) +
    labs(
        title = "Dollar Bets - Favourites",
        x = 'Race Index',
        y = 'Cumulative Profit'
    )
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-19-1.png" width="672" />

```r
hr_favourite %>% 
    group_by(sample_id) %>% 
    summarise(profit = sum(bet.profit)) %>%
    ggplot() +
    geom_histogram(aes(profit), binwidth = 5) +
    geom_vline(aes(xintercept = mean(profit))) +
    labs(
        title = 'Dollar Bet - Favourite - Total Profit Counts',
        subtitle = 'Bin Width = 5',
        x = 'Total Profit',
        y = 'Count'
    )
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-19-2.png" width="672" />



This is much better than picking a random horse, but it's certainly no slam dunk. The mean profit is $-$47.40, with the 95% of returns in the range of [-$81.76 - $1.64]. In general, even betting on the favourite is not going to get you close to generating a profit over time. 

# Conclusion 

In this article we baselined two different approaches to betting on horse races: picking a random horse, and picking the favourite. Oum was determine the mean accuracy and profits for each of these approaches.

We found the accuracy of picking a random horse is 11% and the mean profits over time for a dollar bet are -$257.16. Betting of the favourite is of course markedly better, with a mean accuracy of %35%, however the mean profits a dollar bet are -$47.40, so betting on the favourite does not guarantee us a profit.

This of course makes sense, because if this method of betting did guarantee us a profit, everyone would be doing it and the bookies would go out of business. It looks like I'm not going to be able to quit my day job just yet.
.





