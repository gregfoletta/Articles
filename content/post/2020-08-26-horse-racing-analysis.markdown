---
title: Horse Racing Analysis (Draft)
author: ~
date: '2020-08-25'
slug: horse-racing-analysis
categories: [R]
images: []
---

This is a draft article looking at horse racing results, trying to determine with what kind of accuracy we can pick the winner of a race. We'll be focusing on the Moonee Valley track in Melbourne (with a small digression at the end), trying a few different approaches:

- Picking a random horse
- Picking the favourite
- Looking at barrier position and track conditionkkk






```r
library(tidyverse)
library(modelr)
library(tidymodels)
library(yardstick)
library(vctrs)
```


# Our Dataset 

We have a dataset that contains race results for all race tracks in Australia over the last ten years.

Here's an example with some of the key variables selected:


```r
full_results %>% 
    slice(1:10) %>% 
    select(
        track, date, race_number, 
        position, horse.name, barrier, 
        margin, rail_position, race_duration, 
        length, condition
    )
```

```
## # A tibble: 10 x 11
##    track date       race_number position horse.name barrier margin rail_position
##    <fct> <date>           <int> <fct>    <chr>        <int>  <dbl> <chr>        
##  1 Ascot 2011-01-01           1 1        KEMILEE          4     NA <NA>         
##  2 Ascot 2011-01-01           1 2        Final Cut        9     NA <NA>         
##  3 Ascot 2011-01-01           1 3        Bim Bom B…       2     NA <NA>         
##  4 Ascot 2011-01-01           1 4        Theatron         8     NA <NA>         
##  5 Ascot 2011-01-01           1 5        Make Me B…       3     NA <NA>         
##  6 Ascot 2011-01-01           1 6        Secret Sa…       1     NA <NA>         
##  7 Ascot 2011-01-01           1 7        Dual City       10     NA <NA>         
##  8 Ascot 2011-01-01           1 8        Rose Of P…       7     NA <NA>         
##  9 Ascot 2011-01-01           1 9        Buffalo M…      11     NA <NA>         
## 10 Ascot 2011-01-01           1 10       The Pilla…       5     NA <NA>         
## # … with 3 more variables: race_duration <chr>, length <int>, condition <fct>
```

The more pertinent variables are:

- track: the name of the track.
- date: the date of the race meet.
- race_number: the number of the race within the meet.
- position: the finishing position of the horse..
- horse.name: the name of the horse.
- barrier: the number of the barrier the horse started from.
- margin: the margin of the horse away from the winniner
- rail_position: the position of the rail on the track
- race_duration: how long the race took.
- length: the length of the race.
- condition: the condition of the track.

# The Key Questions

In the first instance we're going to be focusing on races at the Moonee Valley track over the past 5 years. We're going to be trying different methods and models and observing how accurate these are in picking the winner of each race.

# Monee Valley

We extract out race results from Moonee Valley over the last five years.


```r
mv_results <-
    full_results %>%
    filter(track == 'Moonee Valley' & year(date) > 2015)
```

This dataset has 904 races in it.

## Approach 1: Picking a Random Horse

In this approach, we look at the last five years of races at Moonee Valley. We pick a random horse from each race and "place" a dollar bet. If it wins, we get the starting price odds back, and if it loses we of course lose our dollar.



```r
# Function that picks a random horse from each race (based on race_id)
mdl_hr_random <- function(data) {
    data %>%
    group_by(race_id) %>% 
    mutate( 
        .pred = as_factor( sample(1:n()) ),
        .pred.result = factor(
            ifelse(.pred == 1, 'Win', 'Loss'),
            levels = c('Win', 'Loss')
        )
    ) %>% 
    ungroup()
}

# Extract out our 'winning' predictions
mv_random <-
    mv_results %>%
    mdl_hr_random() %>% 
    filter(.pred.result == 'Win')
    
# How accurate is the model:
mv_random %>% accuracy(result, .pred.result)
```

```
## # A tibble: 1 x 3
##   .metric  .estimator .estimate
##   <chr>    <chr>          <dbl>
## 1 accuracy binary         0.114
```

So when we pick a random horse, we are 11.4% accurate. This makes sense, as on average there are 9.647 horses in each race.

Let's place a dollar bet on a random horse in each race over the past five years.


```r
mv_random %>%
    mutate(
        cumulative_return = cumsum(odds.sp.win),
        index = 1:n()
    ) %>% 
    ggplot() +
    geom_line(aes(index, cumulative_return, colour = as_factor(year(date)))) +
    geom_hline(yintercept = 0) +
    labs(
        x = 'Race Index',
        y = 'Cumulative Return (Dollars)',
        title = 'Moonee Valley - Last Five Years',
        subtitle = 'Cumulative Return - Pick: Random Horse',
        colour = 'Year'
    )
```

<img src="/post/2020-08-26-horse-racing-analysis_files/figure-html/unnamed-chunk-7-1.png" width="672" />



# Approach 1: Betting on the Favourite

In this approach, we simply bet on the favourite in each race based on their starting price.


```r
# Function that picks the horse with the lowest odds. 
mdl_hr_favourite <- function(data) {
    data %>% 
    group_by(race_id) %>% 
    mutate(
        .pred = order(odds.sp),
        .pred.result = factor(
            ifelse(.pred == 1, 'Win', 'Loss'),
            levels = c('Win', 'Loss')
        )
    ) %>% 
    ungroup()
}

mv_favourite <-
    mv_results %>% 
    mdl_hr_favourite() %>% 
    filter(.pred.result == 'Win')

mv_favourite %>% accuracy(result, .pred.result)
```

```
## # A tibble: 1 x 3
##   .metric  .estimator .estimate
##   <chr>    <chr>          <dbl>
## 1 accuracy binary         0.341
```

By picking the favourite, we've increased our accuracy to 34.1%. This is the consensus view, and we can consider it a distillation of a whole bunch of factors: track conditions, weather, form, make-up of the race. This is our baseline that we would like to beat, and with this level of accuracy it's going to be difficult. Of course if it wasn't difficult, everyone would be making money!

Again, let's place a dollar bet on each race and see what our returns are.


```r
mv_favourite %>% 
    mutate(
        cumulative_return = cumsum(odds.sp.win),
        index = 1:n()
    ) %>% 
    ggplot() +
    geom_line(aes(index, cumulative_return, colour = factor(year(date)))
    ) +
    geom_hline(yintercept = 0) +
    labs(
        title = 'Moonee Valley - Last Five Years',
        subtitle = 'Cumulative Return - Pick: Favourite',
        x = 'Race Index',
        y = 'Cumulative Winnings (Dollars)',
        colour = 'Year'
    )
```

<img src="/post/2020-08-26-horse-racing-analysis_files/figure-html/unnamed-chunk-9-1.png" width="672" />

Now this is if we bet on every single race over the past 5 years, which might not be realistic for some punters. Instead, let's put a dollar bet on 100 random races over the five years, but do it 20 times so see the how varied the return is.



```r
mv_favourite %>% 
    rep_sample_n(size = 100, reps = 20) %>%
    group_by(replicate) %>% 
    arrange(date) %>% 
    mutate(
        cumulative_return = cumsum(odds.sp.win),
        index = 1:n()
    ) %>% 
    ggplot() +
    geom_line(
        aes(
            index, cumulative_return,
            group = replicate, colour = as_factor(year(date))
        )
    ) +
    geom_hline(yintercept = 0) +
    labs(
        title = 'Moonee Valley - Last Five Years - 100 Random Races',
        subtitle = 'Cumulative Return - Pick: Favourite',
        x = 'Race Index',
        y = 'Cumulative Winnings (Dollars)',
        colour = 'Year'
    )
```

<img src="/post/2020-08-26-horse-racing-analysis_files/figure-html/unnamed-chunk-10-1.png" width="672" />


## Approach 3: Barrier Position

In this approach, we're going to look at how the barrier, rail position, and group conditions affect the result.



```r
# Filter out races lengths and entire circuit rail positions.
# Extract out the rail position in metres and add a win/loss
# categorical variable
mv_results_1100 <-
    full_results %>% 
    filter(track == 'Moonee Valley' & !is.na(barrier)) %>% 
    filter(str_detect(rail_position, 'Entire Circuit')) %>% 
    mutate(
        condition.num = as.integer(str_extract(condition, '\\d')),
        rail_metres = str_match(rail_position, '\\d'),
        rail_metres = ifelse(is.na(rail_metres), 0, rail_metres),
        win = ifelse(position == 1, TRUE, FALSE)
    )
```

This gives us a total of 1058 races. We first take a look at the win to run ratios for each barrier. If the barrier position has no impact, then we would expect to see these ratios around .1, just like our random pick previously.


```r
mv_results_1100 %>% 
    group_by(barrier) %>% 
    summarise(win_ratio = sum(win) / n(), .groups = 'drop') %>% 
    ggplot() +
    geom_col(aes(as_factor(barrier), win_ratio)) +
    labs(
        title = 'Moonee Valley - Last 5 Years',
        subtitle = 'Races <= 1100m - Barrier Win Ratios',
        x = 'Barrier',
        y = 'Win/Run Ratio'
    )
```

<img src="/post/2020-08-26-horse-racing-analysis_files/figure-html/unnamed-chunk-12-1.png" width="672" />

What about if we also take into account the condition of the track?


```r
mv_results_1100 %>% 
    group_by(race_id) %>%
    slice_head() %>% 
    ungroup() %>% 
    count(condition, condition.num) %>% 
    mutate(condition = fct_reorder(condition, condition.num)) %>% 
    ggplot() +
    geom_col(aes(condition, n)) +
    geom_label(aes(condition, n, label = n)) +
    labs(
        title = 'Moonee Valley',
        subtitle = 'Number of Races per Track Condition',
        x = 'Track Condition',
        y = '# of Races'
    )
```

<img src="/post/2020-08-26-horse-racing-analysis_files/figure-html/unnamed-chunk-13-1.png" width="672" />




```r
mv_results_1100 %>% 
    group_by(barrier, condition) %>% 
    summarise(win_ratio = sum(win)/n(), .groups = 'drop') %>% 
    ggplot() +
    geom_col(aes(as_factor(barrier), win_ratio)) +
    facet_wrap(~condition) +
    labs(
        title = 'Moonee Valley - Last 5 Years',
        subtitle = 'Races <= 1100m - Barrier Win Ratios',
        x = 'Barrier',
        y = 'Win/Run Ratio'
    )
```

<img src="/post/2020-08-26-horse-racing-analysis_files/figure-html/unnamed-chunk-14-1.png" width="672" />

# All Tracks

## Approach: Betting on the Favourite

Let's take a look at all tracks where there have been at least than 100 races over the past five years and see how betting on the favourite would have worked out.

Note that there can be times when there is more than one horse as the favourite. In these instances, we place a bet on each horse.


```r
full_dollar_bets <-
    full_results %>%
    add_count(track) %>% 
    filter(n > 100) %>% 
    filter(year(date) > 2015) %>% 
    group_by(race_id) %>% 
    slice_min(odds.sp, with_ties = TRUE) %>%
    ungroup() %>% 
    group_by(track, state) %>% 
    summarise(dollar_bet = sum(odds.sp.win)) %>% 
    ungroup()
```

```
## `summarise()` regrouping output by 'track' (override with `.groups` argument)
```

```r
full_dollar_bets %>% 
    ggplot() + 
    geom_col(aes(reorder(track, dollar_bet), dollar_bet, fill = state)) +
    theme(
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank()) +
    labs(
        title = 'Betting on Favourite - Cumulative Winnings - Last 5 Years',
        subtitle = 'Tracks with more than 120 races',
        x = '',
        y = 'Cumulative Winnings ($)',
        fill = 'State'
    )
```

<img src="/post/2020-08-26-horse-racing-analysis_files/figure-html/unnamed-chunk-15-1.png" width="672" />
What are the top and bottom 20 tracks?


```r
# Top 30
full_dollar_bets %>%
    slice_max(dollar_bet, n = 30) %>% 
    ggplot() + 
    geom_col(aes(reorder(track, dollar_bet), dollar_bet, fill = state)) +
    theme(
        axis.text.x = element_text(angle = 45, hjust = 1)
    ) +
    labs(
        title = 'Betting on Favourite - Cumulative Winnings - Last 5 Years',
        subtitle = 'Tracks with more than 120 races',
        x = 'Track Name',
        y = 'Cumulative Winnings ($)',
        fill = 'State'
    )
```

<img src="/post/2020-08-26-horse-racing-analysis_files/figure-html/unnamed-chunk-16-1.png" width="672" />

```r
# Bottom 30
full_dollar_bets %>% 
    slice_min(dollar_bet, n = 30) %>% 
    ggplot() + 
    geom_col(aes(reorder(track, dollar_bet), dollar_bet, fill = state)) +
    theme(
        axis.text.x = element_text(angle = 45, hjust = 1)
    ) +
    labs(
        title = 'Betting on Favourite - Cumulative Winnings - Last 5 Years',
        subtitle = 'Tracks with more than 120 races',
        x = 'Track Name',
        y = 'Cumulative Winnings ($)',
        fill = 'State'
    )
```

<img src="/post/2020-08-26-horse-racing-analysis_files/figure-html/unnamed-chunk-16-2.png" width="672" />



 
