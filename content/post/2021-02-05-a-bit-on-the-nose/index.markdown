---
title: 'A Bit on the Nose'
author: Greg Foletta
date: '2021-02-04'
slug: a-bit-on-the-nose
categories: [R]
---

I've never really been interested in horse racing


```r
library(tidyverse)
library(rsample)
library(encryptr)
library(gt)
library(zip)
library(glue)
library(furrr)
library(lubridate)
```



# Data Information & Aquisition

The data was acquired by using [rvest](https://rvest.tidyverse.org/) to scrape website that contained this information. I was lucky enough to find an index with links to each track's races, and was able to slowly iterate across each of these, pulling out specific variables using CSS selectors and XPaths. The dataset is for my own personal use, and to avoid any legal issues I have encrypted the file that us used in this article.

The data set that we'll be working with contains information on around 180,000 horse races over the period of 2011 to 2020. The data is in a tidy format, with each row containing information on each horse in each race. This information includes the name and state that the track, the date of the race, the name of the horse, jockey and trainer, the weight the horse is carrying, race length, duration, barrier position, and more.

However we won't be using most of this information in this article. Instead we'll be focusing on the following key variables:

- *race_id* - a unique identifier for each race. There are multiple rows with the same *race_id*, each representing a horse that ran in that race.
- *odds.sp* - the 'starting price', which is are the "odds prevailing on a particular horse in the on-course fixed-odds betting market at the time a race begins.".
- *position* - the finishing position of the horse.


We download the dataset, decrypt, unzip, and load it into the variable `hr_results`.



# An Explore

Before we move on, let's take a look at the dataset from a few different perspectives to give us some context. First up we take a look at the number of races per month per state. We can clearly see the yearly cyclic nature, with the rise into the spring racing carnivals and a drop off over winter.


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

WHich horses and trainers have won the most over this time period?


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

# Monte-Carlo Cross Validation

Now that we've got a good hold on the data we're using, let's move on to the question at hand. To answer the question, we will simulate placing a dollar bet on a horse, determining whether it won, and then collecting our return, which is either the loss of the dollar, or the gain of the starting price odds of the horse.

We want to do this in a realistic way, but we also want to have enough data to reach a conclusion. At a high level our process will be:

- Take a sample of races across the time period; we'll be using 1% of all races.
- Place a bet on a horse in each race, and calculate the return.
- Calculate the cumulative return across the races
- Repeat this a number of times.

This in effect allows us to live a number of 'lives' over the period, each varying in the races that they bet on.

We take our data frame and nest it together on a race by race basis.


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

The `mc_cv()` is used to create our sampled data sets to perform Monte Carlo cross validation on. Technically I'm not performing the cross-validation part, as I'm only using the 'analysis' or 'training' set of sampled data.

We create a worker function so we can pass it to `future_map()`, which allows us to spread the workload across multiple cores on the system and speeding up the process.

The returned results are then unnested returning us back to our original tidy format, with each sample identified by the *sample_id* variable.


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
library(tictoc)
tic()
number_samples <- 10 
hr_mccv <- future_map(
    1:number_samples,
    ~{ mc_sample(hr_results, times = 1, prop = .005) },
    .options = furrr_options(seed = TRUE)
)
toc()
```

```
## 123.05 sec elapsed
```

```r
# Switch plans to close workers and release memory
plan(sequential)

# Bind samples together and unnest
hr_mccv <- hr_mccv %>% 
    bind_rows() %>% 
    mutate(sample_id = 1:n()) %>% 
    unnest(cols = analysis) %>% 
    unnest(cols = data)
```


From this sampled data set, we take to subsets:

- `hr_random` takes a random horse from each race.
- `hr_favourite` takes the favourite from each race.


The `dollar_bets()` function takes our data, determines the return for each horse, and then on a per sample basis indexes the races and calculates the cumulative return.


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

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-13-1.png" width="672" />

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

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-13-2.png" width="672" />
# Summary
