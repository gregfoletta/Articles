---
title: 'A Bit on the Nose (Draft)'
author: Greg Foletta
date: '2021-02-15'
slug: a-bit-on-the-nose
categories: [R]
---

I've never been particularly interested in horse racing, but I married into a family that loves it. Each in-law has their own ideas and combinations of factors that lead them to bet on a particular horse. It could be it form, barrier position, track condition, trainer, jockey, and many others.

After being drawn into conversations about their preferred selection methods, I wanted come at the problem backed with data. I must admit I had an initial feeling of arrogance, thinking "of course I can do this better". In fact I've seen this in many places where 'data scientists' stroll into fields of enquiry armed with data and a swag of models, but lacking an understanding of the problem space. Poor assumptions abound, and incorrect conclusions are almost certainly reached.

I was determined not to fall into the same traps, and after quashing my misplaced sense of superiority, I started to think about how to approach the problem at hand. Rather than diving straight into prediction - models akimbo - I thought the best place to start would be to create naive baselines. This would give me something to compare the performance of any subsequent models against.

In this article I will look at two baselines. The first is to pick a random horse in each race, which will provide us with a lower bound for model predictive accuracy. The second is to pick the favourite in each race. The favourite has many of the factors that we would be using in the model already built in via the consensus of the bettors: form, barrier position, trainer, jockey, etc. Any model we create needs to approach the accuracy of this method.

Simply put, we want to answer the following questions: 

> How accurate are our 'random' and 'favourite' methods at picking the winning horse?

> What are our long term returns using the 'random' and 'favourite' methods?





# Data Information & Aquisition



The data was acquired by using [rvest](https://rvest.tidyverse.org/) to scrape a website that contained historical information on horse races. I was able to iterate across each race, pulling out specific variables using CSS selectors and XPaths. The dataset is for my own personal use, and I have encrypted the data that us used in this article.

The dataset contains information on around 180,000 horse races over the period from 2011 to 2020. Its in a tidy format, with each row containing information on each horse in each race. It includes, but isn't limited to, the name and state that the track, the date of the race, the name of the horse, jockey and trainer, the weight the horse is carrying, race length, duration, barrier position. Here's an random sample from the dataset with some of the key variables selected:


```r
hr_results %>% 
    select(
        race_id, state, track, 
        horse.name, jockey, odds.sp, 
        position, barrier, weight
    ) %>% 
    slice_sample(n = 10) %>% 
    gt()
```

<style>html {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Helvetica Neue', 'Fira Sans', 'Droid Sans', Arial, sans-serif;
}

#cqcapjkiqq .gt_table {
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

#cqcapjkiqq .gt_heading {
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

#cqcapjkiqq .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#cqcapjkiqq .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 0;
  padding-bottom: 4px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#cqcapjkiqq .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#cqcapjkiqq .gt_col_headings {
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

#cqcapjkiqq .gt_col_heading {
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

#cqcapjkiqq .gt_column_spanner_outer {
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

#cqcapjkiqq .gt_column_spanner_outer:first-child {
  padding-left: 0;
}

#cqcapjkiqq .gt_column_spanner_outer:last-child {
  padding-right: 0;
}

#cqcapjkiqq .gt_column_spanner {
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

#cqcapjkiqq .gt_group_heading {
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

#cqcapjkiqq .gt_empty_group_heading {
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

#cqcapjkiqq .gt_from_md > :first-child {
  margin-top: 0;
}

#cqcapjkiqq .gt_from_md > :last-child {
  margin-bottom: 0;
}

#cqcapjkiqq .gt_row {
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

#cqcapjkiqq .gt_stub {
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

#cqcapjkiqq .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#cqcapjkiqq .gt_first_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
}

#cqcapjkiqq .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#cqcapjkiqq .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}

#cqcapjkiqq .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}

#cqcapjkiqq .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#cqcapjkiqq .gt_footnotes {
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

#cqcapjkiqq .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding: 4px;
}

#cqcapjkiqq .gt_sourcenotes {
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

#cqcapjkiqq .gt_sourcenote {
  font-size: 90%;
  padding: 4px;
}

#cqcapjkiqq .gt_left {
  text-align: left;
}

#cqcapjkiqq .gt_center {
  text-align: center;
}

#cqcapjkiqq .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#cqcapjkiqq .gt_font_normal {
  font-weight: normal;
}

#cqcapjkiqq .gt_font_bold {
  font-weight: bold;
}

#cqcapjkiqq .gt_font_italic {
  font-style: italic;
}

#cqcapjkiqq .gt_super {
  font-size: 65%;
}

#cqcapjkiqq .gt_footnote_marks {
  font-style: italic;
  font-size: 65%;
}
</style>
<div id="cqcapjkiqq" style="overflow-x:auto;overflow-y:auto;width:auto;height:auto;"><table class="gt_table">
  
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
      <td class="gt_row gt_right">101853</td>
      <td class="gt_row gt_left">NSW</td>
      <td class="gt_row gt_left">Leeton</td>
      <td class="gt_row gt_left">Magic Cranach</td>
      <td class="gt_row gt_left">Nick Souquet</td>
      <td class="gt_row gt_right">8.00</td>
      <td class="gt_row gt_left">6</td>
      <td class="gt_row gt_right">9</td>
      <td class="gt_row gt_right">56.5</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">46746</td>
      <td class="gt_row gt_left">VIC</td>
      <td class="gt_row gt_left">Donald</td>
      <td class="gt_row gt_left">Audacity</td>
      <td class="gt_row gt_left">Jason Maskiell</td>
      <td class="gt_row gt_right">4.00</td>
      <td class="gt_row gt_left">4</td>
      <td class="gt_row gt_right">2</td>
      <td class="gt_row gt_right">59.5</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">140993</td>
      <td class="gt_row gt_left">SA</td>
      <td class="gt_row gt_left">Port Augusta</td>
      <td class="gt_row gt_left">DIATISTIC</td>
      <td class="gt_row gt_left">Tamara Zanker</td>
      <td class="gt_row gt_right">31.00</td>
      <td class="gt_row gt_left">9</td>
      <td class="gt_row gt_right">9</td>
      <td class="gt_row gt_right">55.0</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">94</td>
      <td class="gt_row gt_left">NT</td>
      <td class="gt_row gt_left">Adelaide River</td>
      <td class="gt_row gt_left">Bomber</td>
      <td class="gt_row gt_left">Barry Huppatz</td>
      <td class="gt_row gt_right">1.73</td>
      <td class="gt_row gt_left">3</td>
      <td class="gt_row gt_right">4</td>
      <td class="gt_row gt_right">59.5</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">146574</td>
      <td class="gt_row gt_left">NSW</td>
      <td class="gt_row gt_left">Randwick</td>
      <td class="gt_row gt_left">Orcein</td>
      <td class="gt_row gt_left">Brenton Avdulla</td>
      <td class="gt_row gt_right">9.00</td>
      <td class="gt_row gt_left">5</td>
      <td class="gt_row gt_right">8</td>
      <td class="gt_row gt_right">55.5</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">57008</td>
      <td class="gt_row gt_left">WA</td>
      <td class="gt_row gt_left">Esperance Bay</td>
      <td class="gt_row gt_left">Dance Mindy Dance</td>
      <td class="gt_row gt_left">Natasha Faithfull</td>
      <td class="gt_row gt_right">6.00</td>
      <td class="gt_row gt_left">2</td>
      <td class="gt_row gt_right">8</td>
      <td class="gt_row gt_right">55.5</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">118960</td>
      <td class="gt_row gt_left">QLD</td>
      <td class="gt_row gt_left">Mount Garnet</td>
      <td class="gt_row gt_left">XAARTRIK</td>
      <td class="gt_row gt_left">M Elliott</td>
      <td class="gt_row gt_right">10.00</td>
      <td class="gt_row gt_left">9</td>
      <td class="gt_row gt_right">5</td>
      <td class="gt_row gt_right">58.5</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">67813</td>
      <td class="gt_row gt_left">QLD</td>
      <td class="gt_row gt_left">Gold Coast</td>
      <td class="gt_row gt_left">Nivo</td>
      <td class="gt_row gt_left">Skye Bogenhuber</td>
      <td class="gt_row gt_right">2.75</td>
      <td class="gt_row gt_left">1</td>
      <td class="gt_row gt_right">2</td>
      <td class="gt_row gt_right">57.0</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">131366</td>
      <td class="gt_row gt_left">NSW</td>
      <td class="gt_row gt_left">Nowra</td>
      <td class="gt_row gt_left">Steel Fixer</td>
      <td class="gt_row gt_left">Grant Buckley</td>
      <td class="gt_row gt_right">6.50</td>
      <td class="gt_row gt_left">4</td>
      <td class="gt_row gt_right">7</td>
      <td class="gt_row gt_right">58.5</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">16478</td>
      <td class="gt_row gt_left">WA</td>
      <td class="gt_row gt_left">Belmont Park</td>
      <td class="gt_row gt_left">Young Gina</td>
      <td class="gt_row gt_left">William Pike</td>
      <td class="gt_row gt_right">3.40</td>
      <td class="gt_row gt_left">5</td>
      <td class="gt_row gt_right">8</td>
      <td class="gt_row gt_right">57.5</td>
    </tr>
  </tbody>
  
  
</table></div>

We won't use most of the variables in the data set, only a select few:

- *race_id* - a unique identifier for each race. There are multiple rows with the same *race_id*, each representing a horse that ran in that race.
- *odds.sp* - the 'starting price', which is are the "odds prevailing on a particular horse in the on-course fixed-odds betting market at the time a race begins.".
- *position* - the finishing position of the horse.

I've omitted the code to load the data is not shown, however the full source of this article (and the entire website) is available at [github](https://github.com/gregfoletta/articles.foletta.org). The data is contained in the variable `hr_results`.


# Exploration

Let's take a look at the dataset from a few different perspectives to give us some context. First up we take a look at the number of races per month per state. We can clearly see the yearly cyclic nature, with the rise into the spring racing carnivals and a drop off over winter.

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-4-1.png" width="672" />

Next we take a look at the top 10 winning horses and trainers over this period:

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-5-1.png" width="672" />

Which tracks have run the most races over this period?

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-6-1.png" width="672" />

Finally, what is the distribution of the starting price odds? This distribution has a very long tail, so I've removed the long odds above 100 to provide a better view of the most common values. What's interesting is the bias towards odds with round numbers after around the the 20 mark.

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-7-1.png" width="672" />

# Data Sampling

With a high level handle on the data we're working with, let's move on to answering the questions.  The process is:

1. Take a sample of races across the time period.
    - We will use 0.5% or ~800 races.
1. Place a dollar 'bet' on a horse in each race, determined by one of our methods.
1. Calculate our return for each race (payout - stake).
1. Calculate our return per race. 
1. Calculate our accuracy across the races in the sample.
1. Return to 1. and repeat.

After the process is complete, we can then look at the mean and distributions for the return per race and accuracy metrics. This process is similar to a bootstrap except we're performing it *without* replacement instead of *with* replacement.

We nest the data for each race together, allowing us to sample on a per race basis, rather than on a per horse basis:


```r
# Nest per race
hr_results <- hr_results %>%
    select(race_id, position, odds.sp) %>% 
    group_by(race_id) %>% 
    nest()

head(hr_results)
```

```
## # A tibble: 6 x 2
## # Groups:   race_id [6]
##   race_id data             
##     <dbl> <list>           
## 1   25488 <tibble [6 × 2]> 
## 2   25489 <tibble [5 × 2]> 
## 3   25490 <tibble [6 × 2]> 
## 4   25491 <tibble [12 × 2]>
## 5   25492 <tibble [14 × 2]>
## 6   25493 <tibble [9 × 2]>
```


The the `mc_cv()` (Monte-Carlo cross validation) function is used to create our sampled data sets. We're not actually performing the cross-validation part, only using the training set that comes back from the function and throwing away the test set.

The worker function `mc_sample()` is created to be passed to `future_map()` so we can spread the sampling work across multiple cores. 

We generate 800 samples of .5% (~800) of the total races in the dataset. The returned results are unnested, returning us back to our original tidy format, with each sample identified by the *sample_id* variable:


```r
library(tictoc)
tic()
# Sampling function that creates a Monte-Carlo CV set
# and returns the analysis portion.
mc_sample <- function(data, times, prop) {
    data %>% 
        mc_cv(times = times, prop = prop) %>% 
        mutate(analysis = map(splits, ~analysis(.x))) %>%
        select(-c(id, splits))
}

# Set up out workers
plan(multisession, workers = availableCores() - 1)

# Parallel sampling
number_samples <- 200 
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
toc()
```

```
## 35.657 sec elapsed
```


A `bet_returns()` function is created which places - by default a \\$1 dollar bet -  'on the nose' (i.e. for the win only) on each horse. It then determines the return based on the starting price odds. The data set uses decimal (also known as continental) odds, so if we placed a \\$1 bet on a horse with odds of 3.0 and the horse wins, our *payout* is \\$3, but our *return* is \\$2 (payout - \\$1). If the horse doesn't win, our payout is \\$0 and our return is -\\$1. 


```r
# Places a bet for the win on each horse and calculates the return.
# For each sample of races it creates an index variable, and calculates
# the cumulative profit per race (ppr)
bet_returns <- function(data, bet = 1) {
    data %>% 
        mutate(bet_profit = if_else(
                position == 1,
                (bet * odds.sp) - bet,
                -bet
            )
        ) %>% 
        group_by(sample_id) %>% 
        mutate(
            sample_race_index = 1:n(),
            cumulative_return = cumsum(bet_profit),
            cumulative_rpr = cumulative_return / sample_race_index 
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
hr_random <- bet_returns(hr_random)
```

What kind of accuracy does this give us?

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-12-1.png" width="672" />


So it's an mean accuracy of 11%, with 95% range between 9.1% and 13.2%. That's about a 1 in 9 chance of picking the winning horse. At first I thought this was a little low, as the average number of horses in a race was about 6. I naively assumed that the random method would give us a 1 in 6 chance of picking the winnow, or 17% accuracy level. But this assumption assumes a uniform probability of winning for each horse, which of course is not correct.

Accuracy is one thing, but what about our returns? Let's take a look at the 

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-14-1.png" width="672" />

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-15-1.png" width="672" />



The result isn't great: in the long run we're definitely losing money. You can see some occasional big jumps where we've managed to pick the long shot and pull our cumualtive returns into positive terriroty, but over time we trend back down into the red. In the long run our average return per race is -\$0.30 per race, and 95% of returns per race are in the range of -\$0.48 to -\$0.10.  

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
hr_favourite <- bet_returns(hr_favourite)
```

What's our accuracy look like for this kind of bet?

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-18-1.png" width="672" />


This is looking much better - we've got a mean accuracy across all of the samples of 35% wih a 95% range of 31.8% - 38.4%. These accuracy percentages look pretty good, and gut feel is that they would be pretty difficult to even get close to with any sort of predictive model. Picking the favourite is around 300 times better than when picking a random horse.

Let's take a look at the cumulative returns over time:

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-20-1.png" width="672" />

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-21-1.png" width="672" />



This is much better than picking a random horse, but it's certainly no slam dunk. We've got longer stretches with a positive return on our investment, but again in the long run our PPR trends to negative. The mean PPR is -\$0.05, with the 95% of PPRs in the range of -\textbackslash \$0.14 to \textbackslash \$0.03.

# Conclusion 

In this article we baselined two different approaches to betting on horse races: picking a random horse, and picking the favourite. Our aim was determine the mean accuracy , and the profits per race, for each of these approaches.

We found the accuracy of picking a random horse is 11% and the mean profits per race for a dollar bet are -\$0.30.

Betting of the favourite is of course markedly better, with a mean accuracy of 35%, however the mean profits per race for a dollar bet are -\$0.05, so betting on the favourite does not guarantee us a profit. This makes sense: if this method of betting did guarantee us a profit, everyone would be doing it and the bookies would go out of business.

What we don't take into account here is the utility, or enjoyment, that is gained from the bet. If you think cost of the enjoyment you receive  betting on a random horse is worth around 30% of your stake, or betting on the favourite is worth 5% of your stake, then go for it. As long as you're not betting more than you can afford, then I say analyses be damned and simply enjoy the thrill of the punt.





