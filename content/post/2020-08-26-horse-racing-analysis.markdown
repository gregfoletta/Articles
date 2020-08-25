---
title: Horse Racing Analysis
author: ~
date: '2020-08-25'
slug: horse-racing-analysis
categories: [R]
images: []
---





```r
library(tidyverse)
library(modelr)
```




```r
# Extract out Moonee Valley over the past five years from our
# full dataset of races
mv_results <-
    full_results %>%
    filter(track == 'Moonee Valley' & year(date) > 2015) %>%
    arrange(date) %>% 
    mutate(mv_race_id = group_indices(., date, race_number)) %>% 
    mutate(odds.sp.win = ifelse(position != 1 | is.na(odds.sp), -1, odds.sp))
```

# Approach: Picking a Random Horse

In this approach, we look at the last five years of races at Moonee Valley. We pick a random horse from each race and "place" a dollar bet. If it wins, we get the starting price odds back, and if it loses we of course lose our dollar.


```r
set.seed(1)
mv_results %>%
    group_by(race_id) %>% 
    mutate(random_guess = sample(1:n())) %>% 
    ungroup() %>% 
    filter(random_guess == 1) %>%
    mutate(dollar_bet = cumsum(odds.sp.win)) %>% 
    ggplot() +
    geom_line(
        aes(mv_race_id, dollar_bet, colour = as_factor(year(date))),
        size = .5
    ) +
    labs(
        title = 'Moonee Valley - Last Five Years - Cumulative Winnings',
        subtitle = 'Dollar Bet Placed on a Random Horse in Every Race',
        x = 'Date',
        y = 'Cumulative Winnings (Dollars)',
        colour = 'Year'
    )
```

<img src="/post/2020-08-26-horse-racing-analysis_files/figure-html/unnamed-chunk-4-1.png" width="672" />
# Approach: Betting on the Favourite

In this approach, we simply bet on the favourite in each race based on their starting price.


```r
mv_results %>% 
    group_by(race_id, n = 1, ties = FALSE) %>% 
    slice_min(odds.sp) %>% 
    ungroup() %>%
    arrange(mv_race_id) %>% 
    mutate(dollar_bet = cumsum(odds.sp.win)) %>% 
    ggplot() +
    geom_line(aes(mv_race_id, dollar_bet, colour = as_factor(year(date)))) +
    labs(
        title = 'Moonee Valley - Last Five Years - Cumulative Winnings',
        subtitle = 'Dollar Bet Placed the Favourite (Starting Price)',
        x = 'Moonee Valley Race',
        y = 'Cumulative Winnings (Dollars)',
        colour = 'Year'
    )
```

<img src="/post/2020-08-26-horse-racing-analysis_files/figure-html/unnamed-chunk-5-1.png" width="672" />




 
