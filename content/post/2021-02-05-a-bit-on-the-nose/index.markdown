---
title: 'A Bit on the Nose (Draft)'
author: Greg Foletta
date: '2021-02-04'
slug: a-bit-on-the-nose
categories: [R]
---

I've never been particularly interested in horse racing, however I've married into a family that's mad for it. Each of them has their own ideas and combinations of factors that lead them to bet on a particular horse; it could be form, barrier position, track condition, and many others.

I was interested at coming at the problem from a data driven perspective. I must admit that there was an initial arrogance that overcame me; an assumption that "of course I can do this better". In fact I've seen this in many places where 'data scientists' stroll into areas with the tools and data, but a lack of understanding of the problem space. Poor assumptions surely abound, and incorrect conclusions are almost certainly reached.

After I quashed this misplaced sense of superiority, I started to think about how I could compute naive baselines that any models I may create could be compared against. The first naive model is to pick a random horse in each race. This is the lower bound for model predictive accuracy. The second naive model is to pick the favourite in each race. The favourite has many of the factors that we would be using in the model already built in: form, barrier position, trainer, jockey, etc. Any model we create needs to do better than this, otherwise we're no better than consensus.

In this article I will answer the following question:

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

#ciceooiggb .gt_table {
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

#ciceooiggb .gt_heading {
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

#ciceooiggb .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#ciceooiggb .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 0;
  padding-bottom: 4px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#ciceooiggb .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#ciceooiggb .gt_col_headings {
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

#ciceooiggb .gt_col_heading {
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

#ciceooiggb .gt_column_spanner_outer {
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

#ciceooiggb .gt_column_spanner_outer:first-child {
  padding-left: 0;
}

#ciceooiggb .gt_column_spanner_outer:last-child {
  padding-right: 0;
}

#ciceooiggb .gt_column_spanner {
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

#ciceooiggb .gt_group_heading {
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

#ciceooiggb .gt_empty_group_heading {
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

#ciceooiggb .gt_from_md > :first-child {
  margin-top: 0;
}

#ciceooiggb .gt_from_md > :last-child {
  margin-bottom: 0;
}

#ciceooiggb .gt_row {
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

#ciceooiggb .gt_stub {
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

#ciceooiggb .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#ciceooiggb .gt_first_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
}

#ciceooiggb .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#ciceooiggb .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}

#ciceooiggb .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}

#ciceooiggb .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#ciceooiggb .gt_footnotes {
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

#ciceooiggb .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding: 4px;
}

#ciceooiggb .gt_sourcenotes {
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

#ciceooiggb .gt_sourcenote {
  font-size: 90%;
  padding: 4px;
}

#ciceooiggb .gt_left {
  text-align: left;
}

#ciceooiggb .gt_center {
  text-align: center;
}

#ciceooiggb .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#ciceooiggb .gt_font_normal {
  font-weight: normal;
}

#ciceooiggb .gt_font_bold {
  font-weight: bold;
}

#ciceooiggb .gt_font_italic {
  font-style: italic;
}

#ciceooiggb .gt_super {
  font-size: 65%;
}

#ciceooiggb .gt_footnote_marks {
  font-style: italic;
  font-size: 65%;
}
</style>
<div id="ciceooiggb" style="overflow-x:auto;overflow-y:auto;width:auto;height:auto;"><table class="gt_table">
  
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
      <td class="gt_row gt_right">92477</td>
      <td class="gt_row gt_left">NSW</td>
      <td class="gt_row gt_left">Kembla</td>
      <td class="gt_row gt_left">All My Loving</td>
      <td class="gt_row gt_left">Andrew Gibbons</td>
      <td class="gt_row gt_right">6.5</td>
      <td class="gt_row gt_left">4</td>
      <td class="gt_row gt_right">2</td>
      <td class="gt_row gt_right">59.5</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">129544</td>
      <td class="gt_row gt_left">WA</td>
      <td class="gt_row gt_left">Northam</td>
      <td class="gt_row gt_left">Devilish Dane</td>
      <td class="gt_row gt_left">Aaron Mitchell</td>
      <td class="gt_row gt_right">101.0</td>
      <td class="gt_row gt_left">14</td>
      <td class="gt_row gt_right">3</td>
      <td class="gt_row gt_right">53.0</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">15681</td>
      <td class="gt_row gt_left">WA</td>
      <td class="gt_row gt_left">Belmont Park</td>
      <td class="gt_row gt_left">Keepers Court</td>
      <td class="gt_row gt_left">Patrick Carbery</td>
      <td class="gt_row gt_right">3.5</td>
      <td class="gt_row gt_left">2</td>
      <td class="gt_row gt_right">6</td>
      <td class="gt_row gt_right">54.0</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">97687</td>
      <td class="gt_row gt_left">VIC</td>
      <td class="gt_row gt_left">Kyneton</td>
      <td class="gt_row gt_left">First Class Manner</td>
      <td class="gt_row gt_left">Daniel Stackhouse</td>
      <td class="gt_row gt_right">31.0</td>
      <td class="gt_row gt_left">7</td>
      <td class="gt_row gt_right">3</td>
      <td class="gt_row gt_right">58.0</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">55616</td>
      <td class="gt_row gt_left">VIC</td>
      <td class="gt_row gt_left">Echuca</td>
      <td class="gt_row gt_left">Woogie</td>
      <td class="gt_row gt_left">Ryan Maloney</td>
      <td class="gt_row gt_right">7.5</td>
      <td class="gt_row gt_left">1</td>
      <td class="gt_row gt_right">5</td>
      <td class="gt_row gt_right">56.0</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">80492</td>
      <td class="gt_row gt_left">VIC</td>
      <td class="gt_row gt_left">Hamilton</td>
      <td class="gt_row gt_left">Mickiem</td>
      <td class="gt_row gt_left">Caitlin Jones</td>
      <td class="gt_row gt_right">11.0</td>
      <td class="gt_row gt_left">1</td>
      <td class="gt_row gt_right">8</td>
      <td class="gt_row gt_right">59.5</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">151058</td>
      <td class="gt_row gt_left">QLD</td>
      <td class="gt_row gt_left">Rockhampton</td>
      <td class="gt_row gt_left">Maid Of Sevens</td>
      <td class="gt_row gt_left">Carly-Mae Pye</td>
      <td class="gt_row gt_right">21.0</td>
      <td class="gt_row gt_left">7</td>
      <td class="gt_row gt_right">11</td>
      <td class="gt_row gt_right">54.0</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">134795</td>
      <td class="gt_row gt_left">VIC</td>
      <td class="gt_row gt_left">Pakenham</td>
      <td class="gt_row gt_left">Shanghai Rooster</td>
      <td class="gt_row gt_left">Jacques Luxe</td>
      <td class="gt_row gt_right">31.0</td>
      <td class="gt_row gt_left">9</td>
      <td class="gt_row gt_right">3</td>
      <td class="gt_row gt_right">54.0</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">170203</td>
      <td class="gt_row gt_left">VIC</td>
      <td class="gt_row gt_left">Swan Hill</td>
      <td class="gt_row gt_left">Capecain</td>
      <td class="gt_row gt_left">Chelsea MacFarlane</td>
      <td class="gt_row gt_right">21.0</td>
      <td class="gt_row gt_left">10</td>
      <td class="gt_row gt_right">4</td>
      <td class="gt_row gt_right">56.5</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">142313</td>
      <td class="gt_row gt_left">SA</td>
      <td class="gt_row gt_left">Port Lincoln</td>
      <td class="gt_row gt_left">Hardashian</td>
      <td class="gt_row gt_left">B Sweeney</td>
      <td class="gt_row gt_right">13.0</td>
      <td class="gt_row gt_left">2</td>
      <td class="gt_row gt_right">3</td>
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
    geom_line(aes(month, n, colour = state)) +
    labs(
        title = 'Number of Race Days per Month per State',
        x = 'Month',
        y = 'Race Days'
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

Finally, which tracks have run the most races over this period?


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

# Data Sampling

With a high level handle on the data we're working with, let's move on to answering the questions. The process is reasonably simple: we simulate placing a dollar bet on a horse, and either collect our return (the starting price odds) in the event that in won, or lose the dollar in the event that it lost.

We'll do this in a manner that tries to be realistic, so we're not going to bet on every race. We also want to determine the variability, so there will need to be a random element in there are well. The process is:
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

The `mc_cv()` (Monte-Carlo cross validation) function is used to create our sampled data sets. Technically I'm not performing the cross-validation part, as I'm only using the 'analysis' or 'training' set of sampled data. I'm using it as a way to take repeated samples from the data set.

We create a worker function so we can pass it to `future_map()`, which allows us to spread the workload across multiple cores on the system, speeding up the process.

The returned results are then unnested, returning us back to our original tidy format, with each sample identified by the *sample_id* variable.


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

A `dollar_bets()` function is created which takes our horses (one per race) that we've 'bet' on, determines the return for each horse, and then on a per sample basis indexes the races and calculates the cumulative return. This index is used as our x-axis in some of the graphs, as we can't use date due to the sampled nature of the data.


```r
dollar_bets <- function(data) {
    data %>% 
        mutate(bet.return = if_else(position == 1, odds.sp, -1)) %>% 
        group_by(sample_id) %>% 
        mutate(
            sample_race_index = 1:n(),
            cumulative.return = cumsum(bet.return)
        ) %>% 
        ungroup()
}
```

# Approach 1: Random Selection

The first approach to take is to bet on a random horse per race.


```r
# Random horse from each race
hr_random <- hr_mccv %>% 
    drop_na(odds.sp) %>%
    group_by(sample_id, race_id) %>% 
    slice_sample(n = 1) %>% 
    ungroup()

# Place our bets
hr_random <- dollar_bets(hr_random)
```

Looking at the cumulative return over time and the distribution of returns.


```r
hr_random %>% 
    filter(sample_id %in% 1:40) %>% 
    ggplot() +
    geom_line(aes(sample_race_index, cumulative.return, group = sample_id), alpha = .5) +
    labs(
        title = "Dollar Bets - Random",
        x = 'Race Index',
        y = 'Dollars'
    )
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-11-1.png" width="672" />

```r
hr_random %>% 
    group_by(sample_id) %>% 
    summarise(return = sum(bet.return)) %>%
    ggplot() +
    geom_histogram(aes(return), binwidth = 5) +
    geom_vline(aes(xintercept = mean(return))) +
    labs(
        title = 'Dollar Bet - Random Horse - Returns Over Time',
        x = 'Sample Race Index',
        y = 'Dollars'
    )
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-11-2.png" width="672" />



The mean return on this bet is -155.2948625 with the 95% of returns in the range of -329.568-54.80025 

# Approach 2 - Favourite

The second approach to take is to bet on the favourite in each race.


```r
# Favourite horse from each race
hr_favourite <- hr_mccv %>% 
    drop_na(odds.sp) %>% 
    group_by(sample_id, race_id) %>% 
    mutate(odds.rank = order(odds.sp)) %>% 
    slice_min(odds.rank, with_ties = FALSE, n = 1) %>% 
    ungroup()
    
hr_favourite <- hr_favourite %>% 
    mutate(bet.return = if_else(position == 1, odds.sp, -1)) %>% 
    group_by(sample_id) %>% 
    mutate(
        sample_race_index = 1:n(),
        cumulative.return = cumsum(bet.return)
    ) %>% 
    ungroup()
```

Again we look at the cumulative return over time, and the distribution of returns.


```r
hr_favourite %>%
    filter(sample_id %in% 1:40) %>% 
    ggplot() +
    geom_line(aes(sample_race_index, cumulative.return, group = sample_id), alpha = .5) +
    labs(
        title = "Dollar Bets - Favourites",
        x = 'Race'
    )
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-14-1.png" width="672" />

```r
hr_favourite %>% 
    group_by(sample_id) %>% 
    summarise(return = sum(bet.return)) %>%
    ggplot() +
    geom_histogram(aes(return), binwidth = 5) +
    geom_vline(aes(xintercept = mean(return))) +
    labs(
        title = 'Dollar Bet - Favourite - Returns',
        x = 'Sample Race Index',
        y = 'Dollars'
    )
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-14-2.png" width="672" />




The mean return on this bet is 246.68865 with the 95% of returns in the range of 146.93925-343.9135 

# Summary

Favourite looks good.
