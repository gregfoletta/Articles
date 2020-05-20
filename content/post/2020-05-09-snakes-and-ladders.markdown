---
title: Simulating Snakes and Ladders
author: Greg Foletta
date: '2020-05-05'
slug: snakes-and-ladders
categories: [R]
description: 'Simulating Snakes and Ladders with R'
---

For the past 8 weeks I, like most people, have been in isolation thanks to the coronavirus. My eldest son is 5 years old and is really into games and puzzles at moment, so I've been spending a lot of time doing this with him,

The board game he's must enamoured with is snakes and ladders. While sitting on the floor and playing for the umpteenth time, I wondered *"what is the average number of turns it takes to finish our games of snakes and ladders?"*.

In this article I'll be looking at snakes and ladders from different perspectives:

1. Using R to simulate the specific to answer the question for our snakes and ladders board.
1. Using R to simulate the general to answer for generic snakes and ladders boards.
1. Deriving general formulas for snakes and ladders.


# The Board

We can represent a snakes and ladders board with as vector, with one element per 'spot'. The value of each spot is how many spaces you should be shifted if you land on the sport. For a ladder, this is a positive value, for a snake its negative. If the spot has neither a snake nor a ladder, it has a value of 0.

The board my son and I use is represented below. To make it easier I've let R do the calculations for me, entering values as *destination - source* for ladders, and *source - destinaton* for snakes.


```r
my_board = c(
    38-1, 0, 0, 14-4, 0, 0, 0, 0, 31-9, 0,
    0, 0, 0, 0, 0, 6-16, 0, 0, 0, 0,
    42-21, 0, 0, 0, 0, 0, 0, 84-28, 0, 0,
    0, 0, 0, 0, 0, 44-36, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 26-47, 0, 11-49, 0,
    67-51, 0, 0, 0, 0, 53-56, 0, 0, 0, 0,
    0, 19-62, 0, 60-64, 0, 0, 0, 0, 0, 0,
    91-71, 0, 0, 0, 0, 0, 0, 0, 0, 100-80,
    0, 0, 0, 0, 0, 0, 24-87, 0, 0, 0,
    0, 0, 73-93, 0, 75-95, 0, 0, 78-98, 0, 0
)
```

# The Game

We have a data structure that represents the board, now we need an algorithm that represents the game.

The `snl_game()` function takes a vector defining a board, and a finish type, and runs through a single player game until the game is complete, returning the number of rolls it took to finish the game.

A game can be finished in one of two ways: with an exact roll that takes you to off the board, or with any roll. For example: you're on spot 98 on a 100 spot board. With an 'exact' game type, you would need to roll a 3 to take you to 101 to win. If you rolled [4,5,6], you wouldn't move your piece. With an 'over' game type, you can roll [3,4,5,6] to win.
    

```r
snl_game <- function(board, finish = 'exact') {
    if (!finish %in% c('exact', 'over')) {
        stop("Argument 'finish' must be either 'exact' or 'over")
    }
    # We sart on 0, which is off the board. First space is 1
    pos <- 0
    # We finish one past the end of the board
    fin_pos <- length(board) + 1
    # Our roll counter
    n <- 0
    
    while (n <- n + 1) {
        # Roll the dice
        roll <- sample(1:6, 1)
        # Update the position
        next_pos <- pos + roll
        
        # Two types of finish:
        # a) We need an exact roll to win
        # b) We need any roll to win
        if (next_pos > fin_pos) { 
            if (finish == 'exact') {
                next
            } else {
                return(n)
            }
        }
        
        # Did we win?
        if (next_pos == fin_pos) {
            return(n)
        }
        
        # Take into account any snakes/ladders  
        pos <- next_pos + board[next_pos]
    }
}
```


# Answering the Specific Question

Now that we have our board and a game, let's answer my specific question. Using my new favourite function `crossing()`, we simulate a snakes and ladders game 200,000 times for each of the finish types and calculate the mean number of rolls.

The number of rolls is then visualised as a histogram, with the red line showing the calculated mean.


```r
library(tidyverse)
library(magrittr)
```


```r
# Simulate 200,000 games of each finish type 
# using my board
my_board_sim <- 
    crossing(finish_type = c('exact', 'over'), n = 1:200000) %>% 
    mutate(rolls = map_dbl(finish_type, ~snl_game(my_board, finish = .x)))

# Summarise the results
my_board_summary <-
    my_board_sim %>% 
    group_by(finish_type) %>% 
    summarise(
        min = min(rolls),
        max = max(rolls),
        mean = mean(rolls),
        quantile_95 = quantile(rolls, .95),
        quantile_5 = quantile(rolls, .05)
    )

# Plot the histograms
my_board_sim %>% 
    ggplot() +
    geom_histogram(aes(rolls), binwidth = 1) +
    geom_vline(
        aes(xintercept = mean), 
        linetype = 'dashed', 
        colour = 'red', 
        my_board_summary
    ) +
    geom_label(aes(label = mean, x = mean, y = 0), my_board_summary) +
    facet_wrap(~finish_type, scales = 'free') +
    labs(
        x = 'Number of Dice Rolls',
        y = 'Number of Games',
        title = 'Snakes and Ladders - Dice Roll Histogram'
    )
```

<img src="/post/2020-05-09-snakes-and-ladders_files/figure-html/my_board_simulation-1.png" width="672" />

So we can see that it takes on average 7 rolls to finish an 'exact' game type, and 7 rolls to finish an 'over' game type.

For simplicity, my son and I play the 'over' finish type, and I estimate a dice roll and move to take around 10 seconds. Our games should on average take around 12 minutes, with 95% of games finishing in less than 28 minutes.


```r
print(my_board_summary)
```

```
## # A tibble: 2 x 6
##   finish_type   min   max  mean quantile_95 quantile_5
##   <chr>       <dbl> <dbl> <dbl>       <dbl>      <dbl>
## 1 exact           7   337  41.7          90         15
## 2 over            7   362  36.5          82         12
```

# Answering the General Question

We've answered the specific question of how many rolls the games between my son and I have given our board, but now let's generalise this futher. We now ask how many rolls it take for a general snakes and ladders board.

To do this, we need to generate snakes and ladders boards based on a statistic. The statistic I've chosen is what I'm calling the 'shift mean': summing the number of snake shifts backwards and ladder shifts forwards, and divding by the total number of snakes and ladders.

The first step is to define the the shift - either forwards or backwards - of a single spot. This is done with the `spot_alloc()` function. The shift is taken from a normal distribution (truncated to an integer) and `min()`/`max()` clamped so that we don't shift ourselves off the bottom or the top of the board.


```r
spot_alloc <- function(spot, board_size, mean) {
    # Integer portion of a random normal variable
    r <- trunc(rnorm(1, mean, board_size / 3))
   
    # Bound the snake or ladder by the bottom
    # and top of the board
    max(-(spot -1), min(board_size - spot, r))
}
```

The `snl_board()` generates a board, taking a board size, a proportion of the board that will be snakes and ladders, and a desired mean.


```r
snl_board <- function(board_size, proportion, mean) {
    # Allocate the board
    board <- rep(0, board_size)
   
    # Which spots will on the board will be snakes or ladders?
    spots <- trunc(runif(proportion * board_size, 1, board_size))
        
    # Assign to these spots either a snake or a ladder
    board[spots] <- map_dbl(spots, ~spot_alloc(.x, board_size, mean))
    
    return(board)
}
```

Due to the clamping, the mean we speciify in our argument to `snl_board()` doesn't have a purely linear relationship to the evential mean of the entire board. We can see below that it actually resembles a logistic function.


```r
crossing(n = 1:10, mean = seq(-200, 200, 3)) %>%
    mutate(board_mean = map_dbl(mean, ~mean(snl_board(100, .2, .x)))) %>% 
    ggplot() +
    geom_point(aes(mean, board_mean)) +
    labs(
        x = 'Specified Mean',
        y = 'Actual Mean',
        title = 'Specified Mean versus Actual Board Mean'
    )
```

<img src="/post/2020-05-09-snakes-and-ladders_files/figure-html/unnamed-chunk-7-1.png" width="672" />

We've got a board and a game, let's play some snakes and ladders. We'll simulate 50 games of each finish type for mean values between 0 and 50, generating a unique board for each simulation.
    

```r
set.seed(1)
general_snl_sim <-
    crossing(
        n = 1:200,
        mean = 0:50,
        finish_type = c('exact', 'over')
    ) %>% 
    mutate(
        board = map(mean, ~snl_board(100, .2, .x)),
        board_mean = map_dbl(board, ~mean(.x)),
        rolls = map2_dbl(board, finish_type, ~snl_game(.x, .y))
    )



general_snl_sim %>%
    ggplot() +
    geom_point(aes(board_mean, rolls, colour = finish_type)) +
    facet_wrap(~finish_type) +
    theme(legend.position = 'none') +
    labs(
        x = 'Board Mean',
        y = 'Number of Dice Rolls',
        title = 'Simulated Snakes and Ladders',
        subtitle = 'Mean of the Board vs. Number of Dice Rolls'
    )
```

<img src="/post/2020-05-09-snakes-and-ladders_files/figure-html/unnamed-chunk-8-1.png" width="672" />


```r
library(broom)

general_models <-
general_snl_sim %>% 
    group_by(finish_type) %>% 
    do(model = lm(rolls ~ board_mean, data = .) )

general_models %>% tidy(model)
```

```
## # A tibble: 4 x 6
## # Groups:   finish_type [2]
##   finish_type term        estimate std.error statistic p.value
##   <chr>       <chr>          <dbl>     <dbl>     <dbl>   <dbl>
## 1 exact       (Intercept)    32.5     0.233      139.        0
## 2 exact       board_mean     -3.29    0.0624     -52.8       0
## 3 over        (Intercept)    28.0     0.215      131.        0
## 4 over        board_mean     -3.37    0.0572     -58.8       0
```

```r
general_models %>% glance(model)
```

```
## # A tibble: 2 x 12
## # Groups:   finish_type [2]
##   finish_type r.squared adj.r.squared sigma statistic p.value    df  logLik
##   <chr>           <dbl>         <dbl> <dbl>     <dbl>   <dbl> <int>   <dbl>
## 1 exact           0.215         0.214  13.0     2785.       0     2 -40660.
## 2 over            0.253         0.253  11.9     3461.       0     2 -39760.
## # … with 4 more variables: AIC <dbl>, BIC <dbl>, deviance <dbl>,
## #   df.residual <int>
```

```r
general_snl_sim %>%
    ggplot() +
    geom_point(aes(board_mean, rolls, colour = finish_type)) +
    geom_smooth(aes(board_mean, rolls), method = 'lm', formula = 'y ~ x') +
    facet_wrap(~finish_type) +
    theme(legend.position = 'none')
```

```
## Warning in grid.Call.graphics(C_polygon, x$x, x$y, index): semi-
## transparency is not supported on this device: reported only once per page
```

<img src="/post/2020-05-09-snakes-and-ladders_files/figure-html/unnamed-chunk-9-1.png" width="672" />

# Mean Rolls Formulation

Case with no 


```r
zero_board_sim <-
    crossing(finish_type = c('exact', 'over'), n = 1:1000) %>% 
    mutate(rolls = map_dbl(finish_type, ~snl_game(rep(0, 100), .x)))

zero_board_means <-
    zero_board_sim %>% 
    group_by(finish_type) %>%  
    summarise(
        mean = mean(rolls)
    )

zero_board_sim %>%
    group_by(finish_type) %>% 
    mutate(cum_average = cumsum(rolls) / n) %>% 
    ggplot() +
    geom_line(aes(n, cum_average, colour = finish_type)) +
    geom_hline(
        aes(yintercept = mean, colour = finish_type),
        zero_board_means,
        linetype = 'dotted'
    ) +
    geom_label(
        aes(label = mean, x = 50, y = mean),
        zero_board_means,
    ) +
    labs(
        x = 'Game Number',
        y = 'Cumulative Average Number of Rolls',
        title = 'Cumulative Average Rolls - All Zero Board',
        colour = 'Game Type'
    )
```

<img src="/post/2020-05-09-snakes-and-ladders_files/figure-html/unnamed-chunk-10-1.png" width="672" />
