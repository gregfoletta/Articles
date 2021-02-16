---
title: 'A Bit on the Nose (Draft)'
author: Greg Foletta
date: '2021-02-15'
slug: a-bit-on-the-nose
categories: [R]
---

I've never been particularly interested in horse racing, but I married into a family that loves it. Each in-law has their own ideas and combinations of factors that lead them to bet on a particular horse; be it form, barrier position, track condition, trainer, jockey, or or more.

After being drawn into conversations about their preferred selection methods, I wanted come at the problem backed with data. I must admit I had an initial feeling of arrogance, thinking "of course I can do this better". In fact I've seen this in many places where 'data scientists' stroll into fields of enquiry armed with data and a swag of models, but lacking an understanding of the problem space. Poor assumptions abound, and incorrect conclusions are almost certainly reached.

I was determined not to fall into the same traps, and after quashing my misplaced sense of superiority, I started to think about how to approach the problem at hand. Rather than diving straight into prediction - models akimbo - I thought the best place to start would be to create naive baseline models of the data. This would give me something to compare the performance of any subsequent models created.

In this article I will look at two naive 'models'. The first is to simply to pick a random horse in each race. This is the lower bound for model predictive accuracy. The second is to pick the favourite in each race. The favourite has many of the factors that we would be using in the model already built in via the consensus of all of the bettors: form, barrier position, trainer, jockey, etc. Any model we create needs to approach the accuracy of this method.

Simply put, we want to answer the following questions for both of these two methods:

> What is the mean and middle ninety-five percentile accuracy?

> What is the mean and middle ninety-five percentile profit per race?





# Data Information & Aquisition



The data was acquired by using [rvest](https://rvest.tidyverse.org/) to scrape a website that contained historical information on horse races. I was able to iterate across each race, pulling out specific variables using CSS selectors and XPaths. The dataset is for my own personal use, and I have encrypted the data that us used in this article.

The dataset contains information on around 180,000 horse races over the period from 2011 to 2020. The data is in a tidy format, with each row containing information on each horse in each race. This information includes the name and state that the track, the date of the race, the name of the horse, jockey and trainer, the weight the horse is carrying, race length, duration, barrier position. Here's an random sample from the dataset:


```r
hr_results %>% 
    select(race_id, state, track, horse.name, jockey, odds.sp, position, barrier, weight) %>% 
    slice_sample(n = 10) %>% 
    gt()
```

<style>html {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Helvetica Neue', 'Fira Sans', 'Droid Sans', Arial, sans-serif;
}

#olydekjihq .gt_table {
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

#olydekjihq .gt_heading {
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

#olydekjihq .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#olydekjihq .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 0;
  padding-bottom: 4px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#olydekjihq .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#olydekjihq .gt_col_headings {
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

#olydekjihq .gt_col_heading {
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

#olydekjihq .gt_column_spanner_outer {
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

#olydekjihq .gt_column_spanner_outer:first-child {
  padding-left: 0;
}

#olydekjihq .gt_column_spanner_outer:last-child {
  padding-right: 0;
}

#olydekjihq .gt_column_spanner {
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

#olydekjihq .gt_group_heading {
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

#olydekjihq .gt_empty_group_heading {
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

#olydekjihq .gt_from_md > :first-child {
  margin-top: 0;
}

#olydekjihq .gt_from_md > :last-child {
  margin-bottom: 0;
}

#olydekjihq .gt_row {
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

#olydekjihq .gt_stub {
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

#olydekjihq .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#olydekjihq .gt_first_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
}

#olydekjihq .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#olydekjihq .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}

#olydekjihq .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}

#olydekjihq .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#olydekjihq .gt_footnotes {
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

#olydekjihq .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding: 4px;
}

#olydekjihq .gt_sourcenotes {
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

#olydekjihq .gt_sourcenote {
  font-size: 90%;
  padding: 4px;
}

#olydekjihq .gt_left {
  text-align: left;
}

#olydekjihq .gt_center {
  text-align: center;
}

#olydekjihq .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#olydekjihq .gt_font_normal {
  font-weight: normal;
}

#olydekjihq .gt_font_bold {
  font-weight: bold;
}

#olydekjihq .gt_font_italic {
  font-style: italic;
}

#olydekjihq .gt_super {
  font-size: 65%;
}

#olydekjihq .gt_footnote_marks {
  font-style: italic;
  font-size: 65%;
}
</style>
<div id="olydekjihq" style="overflow-x:auto;overflow-y:auto;width:auto;height:auto;"><table class="gt_table">
  
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
      <td class="gt_row gt_right">162336</td>
      <td class="gt_row gt_left">VIC</td>
      <td class="gt_row gt_left">Seymour</td>
      <td class="gt_row gt_left">Everywhere Mann</td>
      <td class="gt_row gt_left">Jarrod Fry</td>
      <td class="gt_row gt_right">3.1</td>
      <td class="gt_row gt_left">1</td>
      <td class="gt_row gt_right">9</td>
      <td class="gt_row gt_right">58.5</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">155488</td>
      <td class="gt_row gt_left">VIC</td>
      <td class="gt_row gt_left">Sale</td>
      <td class="gt_row gt_left">Neil's Party</td>
      <td class="gt_row gt_left">Kane Bradley</td>
      <td class="gt_row gt_right">21.0</td>
      <td class="gt_row gt_left">3</td>
      <td class="gt_row gt_right">2</td>
      <td class="gt_row gt_right">58.5</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">43762</td>
      <td class="gt_row gt_left">QLD</td>
      <td class="gt_row gt_left">Deagon</td>
      <td class="gt_row gt_left">Monashee Ridge</td>
      <td class="gt_row gt_left">Vishan Venkaya</td>
      <td class="gt_row gt_right">NA</td>
      <td class="gt_row gt_left">7</td>
      <td class="gt_row gt_right">1</td>
      <td class="gt_row gt_right">0.0</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">34461</td>
      <td class="gt_row gt_left">QLD</td>
      <td class="gt_row gt_left">Chinchilla</td>
      <td class="gt_row gt_left">Fields Of Oxley</td>
      <td class="gt_row gt_left">Ian Coombes</td>
      <td class="gt_row gt_right">15.0</td>
      <td class="gt_row gt_left">7</td>
      <td class="gt_row gt_right">9</td>
      <td class="gt_row gt_right">55.0</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">48236</td>
      <td class="gt_row gt_left">QLD</td>
      <td class="gt_row gt_left">Doomben</td>
      <td class="gt_row gt_left">Sea Red</td>
      <td class="gt_row gt_left">Matthew McGillivray</td>
      <td class="gt_row gt_right">10.0</td>
      <td class="gt_row gt_left">4</td>
      <td class="gt_row gt_right">6</td>
      <td class="gt_row gt_right">52.0</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">171554</td>
      <td class="gt_row gt_left">NSW</td>
      <td class="gt_row gt_left">Tamworth</td>
      <td class="gt_row gt_left">Rachels Own</td>
      <td class="gt_row gt_left">Clare Pettigrew</td>
      <td class="gt_row gt_right">7.0</td>
      <td class="gt_row gt_left">9</td>
      <td class="gt_row gt_right">12</td>
      <td class="gt_row gt_right">54.0</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">90018</td>
      <td class="gt_row gt_left">QLD</td>
      <td class="gt_row gt_left">Julia Creek</td>
      <td class="gt_row gt_left">Hi Mackay</td>
      <td class="gt_row gt_left">Rachel Shred</td>
      <td class="gt_row gt_right">5.0</td>
      <td class="gt_row gt_left">6</td>
      <td class="gt_row gt_right">7</td>
      <td class="gt_row gt_right">53.0</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">143954</td>
      <td class="gt_row gt_left">NSW</td>
      <td class="gt_row gt_left">Queanbeyan</td>
      <td class="gt_row gt_left">Lovespeed Girl</td>
      <td class="gt_row gt_left">Jon Grisedale</td>
      <td class="gt_row gt_right">7.0</td>
      <td class="gt_row gt_left">5</td>
      <td class="gt_row gt_right">2</td>
      <td class="gt_row gt_right">55.0</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">41261</td>
      <td class="gt_row gt_left">QLD</td>
      <td class="gt_row gt_left">Dalby</td>
      <td class="gt_row gt_left">Alucard</td>
      <td class="gt_row gt_left">Matthew McGillivray</td>
      <td class="gt_row gt_right">9.0</td>
      <td class="gt_row gt_left">5</td>
      <td class="gt_row gt_right">11</td>
      <td class="gt_row gt_right">53.0</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">150978</td>
      <td class="gt_row gt_left">QLD</td>
      <td class="gt_row gt_left">Rockhampton</td>
      <td class="gt_row gt_left">Real French Saga</td>
      <td class="gt_row gt_left">Micheal Hellyer</td>
      <td class="gt_row gt_right">21.0</td>
      <td class="gt_row gt_left">10</td>
      <td class="gt_row gt_right">3</td>
      <td class="gt_row gt_right">55.5</td>
    </tr>
  </tbody>
  
  
</table></div>

We won't use most of the variables in the data set, only a select few:

- *race_id* - a unique identifier for each race. There are multiple rows with the same *race_id*, each representing a horse that ran in that race.
- *odds.sp* - the 'starting price', which is are the "odds prevailing on a particular horse in the on-course fixed-odds betting market at the time a race begins.".
- *position* - the finishing position of the horse.

The code to load the data is not shown, however the full source of this article (and the entire website) is available at [github](https://github.com/gregfoletta/articles.foletta.org). The data is contained in the variable `hr_results`.


# Exploration

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

With a high level handle on the data we're working with, let's move on to answering the questions.  The process used is as follows:

- A sample of races across the time period is taken.
    - We will use 0.5% of all races, which works out to be ~800 races.
- A dollar 'bet' is placed (based on the two criteria) on a horse in each race.
- The profit is determined, i.e. return - stake.
- The cumulative return per race is calculated. 
- The accuracy across the races is calculated.

This process is repeated a number of times across different samples, a la bootstrapping but without replacement. This allows us to determine not just the mean accuracy and profit per race, but also their distributions.

We first nest the data for each race together, allowing us to sample on a per race basis, rather than on a per horse basis:


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


The the `mc_cv()` (Monte-Carlo cross validation) function to create our sampled data sets. Technically we're not performing the cross-validation part, only using the training set that comes back from the function and throwing away the test set.

The worker function `mc_sample()` is created to be passed to `future_map()`. The sampling is an 'embarrassingly parallel' task, so we would remiss to not use all the compute available to us.

We generate 20 samples (to be increased in the final version of this artucle) of .5% of the total races (~800). The returned results are unnested, returning us back to our original tidy format, with each sample identified by the *sample_id* variable:


```r
# Sampling function 
mc_sample <- function(data, times, prop) {
    data %>% 
        mc_cv(times = times, prop = prop) %>% 
        mutate(analysis = map(splits, ~analysis(.x))) %>%
        select(-c(id, splits))
}

# Set up out workers
plan(multisession, workers = availableCores() - 1)

# Parallel sampling
number_samples <- 800
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


The `bet_ppr()` function places - by default a \$1 bet -  'on the nose' (i.e. for the win only) on each horse. It then determines the profit of our bet based on the starting price odds. The data set uses decimal (also known as continental) odds, so if we placed a \$1 bet on a horse with odds of 3.0 and the horse wins, our *return* is \$3, but our *profit* is \$2 (stake - \$1 be). If the horse doesn't win, our return is \$0 and our profit is -$1. 


```r
# Places a bet for the win on each horse and calculates the profit.
# For each sample of races it creates an index variable, and calculates
# the cumulative profit per race (ppr)
bet_ppr <- function(data, bet = 1) {
    data %>% 
        mutate(bet.profit = if_else(
                position == 1,
                (bet * odds.sp) - bet,
                -bet
            )
        ) %>% 
        group_by(sample_id) %>% 
        mutate(
            sample_race_index = 1:n(),
            cumulative.ppr = cumsum(bet.profit) / sample_race_index 
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
hr_random <- bet_ppr(hr_random)
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


So it's an mean accuracy of 11%, with 95% range of [9.1% - 13.5%]. That's about a 1 in 9 chance of picking the winning horse. At first I thought this was a little low, as the average number of horses in a race was about 6, so I naively assumed that the random method would give us a 1 in 6 chance of picking the winnow, or 17% accuracy level. But this assumption assumes a uniform probability of winning for each horse, which of course is not correct.

Accuracy is one thing, but what about our returns? Let's take a look at the at the cumulative return over time and its distribution. 


```r
hr_random %>% 
    filter(sample_id %in% 1:40) %>% 
    ggplot() +
    geom_line(aes(sample_race_index, cumulative.ppr, group = sample_id), alpha = .5) +
    labs(
        title = "Dollar Bet - Random Horse per Race",
        subtitle = 'Cumulative Profit per Race',
        x = 'Race Index',
        y = 'Dollars'
    )
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-14-1.png" width="672" />

```r
hr_random %>% 
    group_by(sample_id) %>% 
    summarise(total_ppr = sum(bet.profit / n())) %>%
    ggplot() +
    geom_histogram(aes(total_ppr), binwidth = .01) +
    geom_vline(aes(xintercept = mean(total_ppr))) +
    labs(
        title = 'Dollar Bet - Random Horse - Profit per Race Distribution',
        subtitle = 'Bin Width = .01',
        x = 'Total Profit',
        y = 'Count'
    )
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-14-2.png" width="672" />



The result isn't great: in the long run we're definitely losing money. You can see some occasional big jumps where we've managed to pick the long shot and pull our PPR into positive terriroty, but over time we trend back down into the red. In the long run our average profit per race -\$0.30 per race, and 95% of profits per race are in the range of [-\$0.49 - -\$0.07].  

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
hr_favourite <- bet_ppr(hr_favourite)
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
This is looking much better - we've got a mean accuracy across all of the samples of 35% wih a 95% range of 31.9% - 38.3%. These accuracy percentages look pretty good, and gut feel is that they would be pretty difficult to even get close to with any sort of predictive model. Picking the favourite is around 309 times better than when picking a random horse.

Let's take a look at the cumulative returns over time:


```r
hr_favourite %>%
    filter(sample_id %in% 1:40) %>% 
    ggplot() +
    geom_line(aes(sample_race_index, cumulative.ppr, group = sample_id), alpha  = .5) +
    labs(
        title = "Dollar Bet - Favourite - Cumulative Profits per Race",
        x = 'Race Index',
        y = 'Dollars'
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



This is much better than picking a random horse, but it's certainly no slam dunk. We've got longer stretches with a positive return on our investment, but again in the long run our PPR trends to negative. The mean PPR is -$0.06, with the 95% of PPRs in the range of [-\$0.15 - \$0.04].

# Conclusion 

In this article we baselined two different approaches to betting on horse races: picking a random horse, and picking the favourite. Our aim was determine the mean accuracy , and the profits per race, for each of these approaches.

We found the accuracy of picking a random horse is 11% and the mean profits per race for a dollar bet are -$0.30.

Betting of the favourite is of course markedly better, with a mean accuracy of %35%, however the mean profits per race for a dollar bet are -$0.06, so betting on the favourite does not guarantee us a profit. This makes sense: if this method of betting did guarantee us a profit, everyone would be doing it and the bookies would go out of business.

What we don't take into account here is the utility, or enjoyment, that is gained from the bet. If you think cost of the enjoyment you receive  betting on a random horse is worth around 30% of your stake, or betting on the favourite is worth 6% of your stake, then go for it. As long as you're not betting more than you can afford, then I say analyses be damned and simply enjoy the thrill of the punt.





