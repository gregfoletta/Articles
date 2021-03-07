---
title: 'A Bit on the Nose'
author: Greg Foletta
date: '2021-03-07'
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

The dataset contains information on around 180,000 horse races over the period from 2011 to 2020. It's in a tidy format, with each row containing information on each horse in each race. It includes, but isn't limited to, the name and state that the track, the date of the race, the name of the horse, jockey and trainer, the weight the horse is carrying, race length, duration, barrier position. Here's an random sample from the dataset with some of the key variables selected:


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

#hfjgovmpcs .gt_table {
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

#hfjgovmpcs .gt_heading {
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

#hfjgovmpcs .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#hfjgovmpcs .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 0;
  padding-bottom: 4px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#hfjgovmpcs .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#hfjgovmpcs .gt_col_headings {
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

#hfjgovmpcs .gt_col_heading {
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

#hfjgovmpcs .gt_column_spanner_outer {
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

#hfjgovmpcs .gt_column_spanner_outer:first-child {
  padding-left: 0;
}

#hfjgovmpcs .gt_column_spanner_outer:last-child {
  padding-right: 0;
}

#hfjgovmpcs .gt_column_spanner {
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

#hfjgovmpcs .gt_group_heading {
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

#hfjgovmpcs .gt_empty_group_heading {
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

#hfjgovmpcs .gt_from_md > :first-child {
  margin-top: 0;
}

#hfjgovmpcs .gt_from_md > :last-child {
  margin-bottom: 0;
}

#hfjgovmpcs .gt_row {
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

#hfjgovmpcs .gt_stub {
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

#hfjgovmpcs .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#hfjgovmpcs .gt_first_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
}

#hfjgovmpcs .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#hfjgovmpcs .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}

#hfjgovmpcs .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}

#hfjgovmpcs .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#hfjgovmpcs .gt_footnotes {
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

#hfjgovmpcs .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding: 4px;
}

#hfjgovmpcs .gt_sourcenotes {
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

#hfjgovmpcs .gt_sourcenote {
  font-size: 90%;
  padding: 4px;
}

#hfjgovmpcs .gt_left {
  text-align: left;
}

#hfjgovmpcs .gt_center {
  text-align: center;
}

#hfjgovmpcs .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#hfjgovmpcs .gt_font_normal {
  font-weight: normal;
}

#hfjgovmpcs .gt_font_bold {
  font-weight: bold;
}

#hfjgovmpcs .gt_font_italic {
  font-style: italic;
}

#hfjgovmpcs .gt_super {
  font-size: 65%;
}

#hfjgovmpcs .gt_footnote_marks {
  font-style: italic;
  font-size: 65%;
}
</style>
<div id="hfjgovmpcs" style="overflow-x:auto;overflow-y:auto;width:auto;height:auto;"><table class="gt_table">
  
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
      <td class="gt_row gt_right">51226</td>
      <td class="gt_row gt_left">QLD</td>
      <td class="gt_row gt_left">Doomben</td>
      <td class="gt_row gt_left">Daisy Duke</td>
      <td class="gt_row gt_left">Robbie Fradd</td>
      <td class="gt_row gt_right">6.00</td>
      <td class="gt_row gt_left">1</td>
      <td class="gt_row gt_right">3</td>
      <td class="gt_row gt_right">58.0</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">134689</td>
      <td class="gt_row gt_left">VIC</td>
      <td class="gt_row gt_left">Pakenham</td>
      <td class="gt_row gt_left">Nautilus</td>
      <td class="gt_row gt_left">James Winks</td>
      <td class="gt_row gt_right">6.00</td>
      <td class="gt_row gt_left">4</td>
      <td class="gt_row gt_right">1</td>
      <td class="gt_row gt_right">54.5</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">24981</td>
      <td class="gt_row gt_left">WA</td>
      <td class="gt_row gt_left">Bunbury</td>
      <td class="gt_row gt_left">RABBIT NAGINA</td>
      <td class="gt_row gt_left">Alan Kennedy</td>
      <td class="gt_row gt_right">31.00</td>
      <td class="gt_row gt_left">6</td>
      <td class="gt_row gt_right">10</td>
      <td class="gt_row gt_right">56.5</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">78601</td>
      <td class="gt_row gt_left">NSW</td>
      <td class="gt_row gt_left">Grenfell</td>
      <td class="gt_row gt_left">Gaze Beyond</td>
      <td class="gt_row gt_left">Ms Ashleigh Stanley</td>
      <td class="gt_row gt_right">6.00</td>
      <td class="gt_row gt_left">4</td>
      <td class="gt_row gt_right">9</td>
      <td class="gt_row gt_right">53.0</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">44267</td>
      <td class="gt_row gt_left">NSW</td>
      <td class="gt_row gt_left">Deniliquin</td>
      <td class="gt_row gt_left">Sunpoint</td>
      <td class="gt_row gt_left">Ms A Beer</td>
      <td class="gt_row gt_right">8.00</td>
      <td class="gt_row gt_left">6</td>
      <td class="gt_row gt_right">4</td>
      <td class="gt_row gt_right">57.0</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">129895</td>
      <td class="gt_row gt_left">WA</td>
      <td class="gt_row gt_left">Northam</td>
      <td class="gt_row gt_left">Ram Jam</td>
      <td class="gt_row gt_left">Ben Kennedy</td>
      <td class="gt_row gt_right">2.25</td>
      <td class="gt_row gt_left">1</td>
      <td class="gt_row gt_right">4</td>
      <td class="gt_row gt_right">58.5</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">101574</td>
      <td class="gt_row gt_left">TAS</td>
      <td class="gt_row gt_left">Launceston</td>
      <td class="gt_row gt_left">Gee Gee Double Hot</td>
      <td class="gt_row gt_left">Scarlet So</td>
      <td class="gt_row gt_right">5.00</td>
      <td class="gt_row gt_left">1</td>
      <td class="gt_row gt_right">1</td>
      <td class="gt_row gt_right">52.0</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">134173</td>
      <td class="gt_row gt_left">VIC</td>
      <td class="gt_row gt_left">Pakenham</td>
      <td class="gt_row gt_left">Miss Mo</td>
      <td class="gt_row gt_left">Ben E Thompson</td>
      <td class="gt_row gt_right">8.50</td>
      <td class="gt_row gt_left">7</td>
      <td class="gt_row gt_right">3</td>
      <td class="gt_row gt_right">58.0</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">69517</td>
      <td class="gt_row gt_left">QLD</td>
      <td class="gt_row gt_left">Gold Coast</td>
      <td class="gt_row gt_left">Liberty Island</td>
      <td class="gt_row gt_left">Jag Guthmann-Chester</td>
      <td class="gt_row gt_right">8.00</td>
      <td class="gt_row gt_left">5</td>
      <td class="gt_row gt_right">12</td>
      <td class="gt_row gt_right">57.0</td>
    </tr>
    <tr>
      <td class="gt_row gt_right">140862</td>
      <td class="gt_row gt_left">SA</td>
      <td class="gt_row gt_left">Port Augusta</td>
      <td class="gt_row gt_left">Gold Maestro</td>
      <td class="gt_row gt_left">Jeffrey Maund</td>
      <td class="gt_row gt_right">31.00</td>
      <td class="gt_row gt_left">1</td>
      <td class="gt_row gt_right">5</td>
      <td class="gt_row gt_right">54.0</td>
    </tr>
  </tbody>
  
  
</table></div>

We won't use most of the variables in the data set, only a select few:

- *race_id* - a unique identifier for each race. There are multiple rows with the same *race_id*, each representing a horse that ran in that race.
- *odds.sp* - the 'starting price', which is are the "odds prevailing on a particular horse in the on-course fixed-odds betting market at the time a race begins.".
- *position* - the finishing position of the horse.

I've omitted the code to load the data, however the full source of this article (and the entire website) is available on [github](https://github.com/gregfoletta/articles.foletta.org). The data is contained in the variable `hr_results`.


# Exploration

Let's take a look at the dataset from a few different perspectives to give us some context. First up we take a look at the number of races per month per state. We can clearly see the yearly cyclic nature, with the rise into the spring racing carnivals and a drop off over winter.

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-4-1.png" width="672" />

Next we take a look at the top 10 winning horses and trainers over this period:

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-5-1.png" width="672" />

Which tracks have run the most races over this period?

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-6-1.png" width="672" />

Finally, what is the distribution of the starting price odds? This distribution has a very long tail, so I've removed the long odds above 100 to provide a better view of the most common values. What's interesting is the bias towards odds with round numbers after the 20 mark.

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-7-1.png" width="672" />

# Data Sampling

With a high level handle on the data we're working with, let's move on to answering the questions.  The process is:

1. Take a sample of races across the time period.
    - We will use 0.5% or ~800 races.
1. Place a dollar 'bet' on a horse in each race, determined by one of our methods.
1. Calculate our return (payout - stake).
1. Calculate our cumulative return.
1. Calculate our accuracy across all the races.
1. Calculate our return per race.
1. Return to 1. and repeat.

After the process is complete, we can look at the mean and distributions for the return per race and accuracy metrics. This process is similar to a bootstrap except within the sample we're performing it *without* replacement instead of *with* replacement.

We select only the variables that we need, so we're not moving huge amounts of unused data between to our worker processes. (Before I realised I should be pruning the data, I was spinning up large AWS instances with 128Gb of memory to perform the sampling. After the pruning I could run it on my laptop with 16GB of memory!) The data is nested based on its race ID, allowing us to sample per race rather than per horse.


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


The the `mc_cv()` (Monte-Carlo cross validation) function from the [rsample](https://rsample.tidymodels.org/) package is used to create our sampled data sets. We're not actually performing the cross-validation part, only using the training set that comes back from the function and throwing away the test set.

The worker function `mc_sample()` is created to be passed to `future_map()` so we can spread the sampling work across multiple cores. 

We generate 2000 samples of .5% of the total races in the dataset, or around 800 races per sample. The returned results are unnested, returning us back to our original tidy format, with each sample identified by the *sample_id* variable:


```r
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
number_samples <- 2000 
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


A `bet_returns()` function is created which places a bet (default \$1) for the win on each horse in the dataset it's provided. It determines the return based on the starting price odds. The data set uses decimal (also known as continental) odds, so if we placed a \$1 bet on a horse with odds of 3.0 and the horse wins, our *payout* is \$3, but our *return* is \$2 (payout - \$1). If the horse doesn't win, our payout is \$0 and our return is -\$1. 


```r
# Places a bet for the win on each horse and calculates the return,
# the cumulative return, and the cumulative return per race.
bet_returns <- function(data, bet = 1) {
    data %>% 
        mutate(
            bet_return = if_else(
                position == 1,
                (bet * odds.sp) - bet,
                -bet
            )
        ) %>% 
        group_by(sample_id) %>% 
        mutate(
            sample_race_index = 1:n(),
            cumulative_return = cumsum(bet_return),
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

Let's first calculate the accuracy per sample, and view this as a histogram. The solid line is the mean, and the dashed lines are the 2.5% and 97.5% quantiles, showing the middle 95% range of the accuracy.


```r
hr_random_accuracy <- 
    hr_random %>%
    mutate(win = if_else(position == 1, 1, 0)) %>% 
    group_by(sample_id) %>% 
    summarise(accuracy = mean(win))
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-13-1.png" width="672" />


The random method gives us a mean accuracy of 11%, with 95% range between 9.1% and 13.5%. That's about a 1 in 9 chance of picking the winning horse. At first I thought this was a little low, as the average number of horses in a race was about 6. I naively assumed that the random method would give us a 1 in 6 chance of picking the winnow, or 17% accuracy level. But this assumption assumes a uniform probability of winning for each horse, which of course is not correct.

Accuracy is one thing, but what about our returns? Let's take a look at our cumulative returns over time. It's difficult to graph the entire 2000 samples as it becomes one big blob on the graph, so we look at the first 40 samples which gives us a reasonable representation:

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-15-1.png" width="672" />

The result is a general trend downwards. We see some big jumps where our chosen horse is the long shot that came home, and some of our samples manage to pull themselves back into the black for periods of time. But they quickly regress trend back into the red. 

The number of races may vary slightly per sample, so instead of looking at the cumulative return, let's look at the returns per race, i.e. (cumulative return / number of races).

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-16-1.png" width="672" />



In the long run our average return per race is -\$0.30, and 95% of our returns are within the range of -\$0.49 to -\$0.04. As we've used a dollar bet, this translates nicely to a percentage. What we can say is that in the long run we're on average losing 30% of our stake each time we use this method of betting. 

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

Let's again take a look at the accuracy of this approach, viewed as a histogram of accuracy per sample.


```r
# Calculate the accuracy
hr_favourite_accuracy <- 
    hr_favourite %>%
    mutate(win = if_else(position == 1, 1, 0)) %>% 
    group_by(sample_id) %>% 
    summarise(accuracy = mean(win))
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-20-1.png" width="672" />


This is looking much better - we've got a mean accuracy across all of the samples of 35%,  with 95% of our accuracy in the range of 32.0% - 38.3%. These accuracy percentages look pretty good, and my gut feel is that they would be pretty difficult to approach with any sort of predictive model. Picking the favourite is around 3 times better than picking a random horse.

What do our returns over time look like? Again we take the first 40 samples and graph the cumulative return.

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-22-1.png" width="672" />

There is still a general trend downwards, however it's certainly not as pronounced as the random method. There are longer periods of time where we're trending sideways, and some of our samples even manage to eke out a profit.

Taking a look again at the distributions of our returns per race:

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-23-1.png" width="672" />



Picking the favourite is much better than picking a random horse but it's certainly no slam dunk. The long run average return per race is still negative at -\$0.05. The 95% of returns per race are in the range of -\$0.15 to \$0.04.

# Conclusion 

In this article we baselined two different approaches to betting on horse races: picking a random horse, and picking the favourite. Our aim was determine the mean accuracy  and mean returns per race for each of the approaches.

We found the accuracy of picking a random horse is 11% and the mean returns per race for a dollar bet are -\$0.30. You're losing thirty cents on the dollar per bet.

Betting of the favourite is unsurprisingly much better, with a mean accuracy of 35% and mean returns per race for a dollar bet being -\$0.05, or a loss a five cents on the dollar. I'm impressed with the bookies ability to get so close to parity. 

What we don't take into account here is the utility, or enjoyment, that is gained from the bet. If you think cost of the enjoyment you receive  betting on a random horse is worth around 30% of your stake, or betting on the favourite is worth 5% of your stake, then go for it. As long as you're not betting more than you can afford, then I say analyses be damned and simply enjoy the thrill of the punt.





