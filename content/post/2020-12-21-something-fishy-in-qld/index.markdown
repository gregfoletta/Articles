---
title: Something Fishy in QLD
author: Greg Foletta
date: '2020-12-19'
slug: something-fishy-in-qld 
categories: [R]
---


This is a draft article looking at horse racing results, trying to determine with what kind of accuracy we can pick the winner of a race. We'll be focusing on the Moonee Valley track in Melbourne (with a small digression at the end), trying a few different approaches:

- Picking a random horse
- Picking the favourite
- Looking at barrier position and track condition

# Adding some additional variables



```r
library(tidyverse)
library(tidymodels)
library(encryptr)
```


```r
decrypted_filename <- 'hr_results.csv'
decrypt_file('hr_results.csv.encryptr.bin', file_name = decrypted_filename)
```

```
## Decrypted file written with name 'hr_results.csv'
```

```r
hr_results <- read_csv(
    decrypted_filename,
    col_types = cols(
        race_id = col_double(),
        track = col_character(),
        state = col_character(),
        results_link = col_character(),
        date = col_date(format = ""),
        raceday_link = col_character(),
        race_number = col_double(),
        position = col_character(),
        horse.name = col_character(),
        horse.number = col_double(),
        barrier = col_double(),
        margin = col_double(),
        weight = col_double(),
        horse.age = col_double(),
        horse.type = col_character(),
        trainer = col_character(),
        jockey = col_character(),
        horse.ancestry = col_character(),
        odds.sp = col_double(),
        odds.stab = col_double(),
        odds.nsw = col_double(),
        odds.ubet = col_double(),
        odds.sb = col_double(),
        race_duration = col_character(),
        race_datetime = col_datetime(),
        rail_position = col_character(),
        race_name = col_character(),
        length = col_double(),
        class = col_character(),
        condition = col_character(),
        error = col_character(),
        track_race_id = col_double(),
        result = col_character(),
        condition.num = col_double(),
        odds.sp.win = col_double()
    )
)

if (file.exists(decrypted_filename)) {
    file.remove(decrypted_filename)
}
```

```
## [1] TRUE
```


# Our Dataset 

We have a dataset that contains race results for all race tracks in Australia over the last ten years.

Here's an example with some of the key variables selected:


```r
hr_results %>% 
    slice(1:10) %>% 
    select(
        track, date, race_id, race_number, 
        position, horse.name, barrier, 
        margin, rail_position, race_duration, 
        length, condition
    )
```

```
## # A tibble: 10 x 12
##    track date       race_id race_number position horse.name barrier margin
##    <chr> <date>       <dbl>       <dbl> <chr>    <chr>        <dbl>  <dbl>
##  1 Canb… 2011-04-01   25488           1 1        Pale             1     NA
##  2 Canb… 2011-04-01   25488           1 2        Nineveh's…       2     NA
##  3 Canb… 2011-04-01   25488           1 3        LE COMMAN…       5     NA
##  4 Canb… 2011-04-01   25488           1 4        Colourist        3     NA
##  5 Canb… 2011-04-01   25488           1 5        Zarweep          6     NA
##  6 Canb… 2011-04-01   25488           1 6        HE'S ALERT       4     NA
##  7 Canb… 2011-04-01   25489           2 1        Pray To G…       1     NA
##  8 Canb… 2011-04-01   25489           2 2        Tonk             3     NA
##  9 Canb… 2011-04-01   25489           2 3        THEREHEIZ        4     NA
## 10 Canb… 2011-04-01   25489           2 4        JOLLY JOK…       2     NA
## # … with 4 more variables: rail_position <chr>, race_duration <chr>,
## #   length <dbl>, condition <chr>
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

## Approach 1: Picking a Random Horse

In this approach, we look at the last five years of races at Moonee Valley. We pick a random horse from each race and "place" a dollar bet. If it wins, we get the starting price odds back, and if it loses we of course lose our dollar.




So when we pick a random horse, we are `mv_random %>% accuracy(result, .pred.result) %>% pull(.estimate) %>% round(3) *100`% accurate. This makes sense, as on average there are ` mv_results %>% group_by(race_id) %>% slice_max(barrier) %>% ungroup() %>% summarise(m = mean(barrier)) %>% pull(m) %>% round(3)` horses in each race.

Let's place a dollar bet on a random horse in each race over the past five years.


```r
full_results_random %>%
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



# Approach 2: Betting on the Favourite

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

full_results_favourite <-
    full_results %>% 
    mdl_hr_favourite() %>% 
    filter(.pred.result == 'Win')

full_results_favourite %>% accuracy(result, .pred.result)
```

By picking the favourite, we've increased our accuracy to ` mv_favourite %>% accuracy(result, .pred.result) %>% pull(.estimate) %>% round(3) * 100`%. This is the consensus view, and we can consider it a distillation of a whole bunch of factors: track conditions, weather, form, make-up of the race. This is our baseline that we would like to beat, and with this level of accuracy it's going to be difficult. Of course if it wasn't difficult, everyone would be making money!

Again, let's place a dollar bet on each race and see what our returns are.


```r
full_results_favourite %>% 
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
