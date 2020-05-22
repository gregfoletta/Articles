---
title: Simulating Snakes and Ladders
author: Greg Foletta
date: '2020-05-05'
slug: snakes-and-ladders
categories: [R]
description: 'Simulating Snakes and Ladders with R'
allow_html: yes
---

For the past 8 weeks I, like most people, have been in isolation thanks to the coronavirus. My eldest son is 5 years old and is really into games and puzzles at moment, so I've been spending a lot of time doing this with him,

The board game he's must enamoured with is snakes and ladders. While sitting on the floor and playing for the umpteenth time, I wondered *"what is the average number of turns it takes to finish our games of snakes and ladders?"*.

In this article I'll be looking at snakes and ladders from different perspectives:

1. Using R to simulate the specific to answer the question for our snakes and ladders board.
1. Using R to simulate the general to answer for generic snakes and ladders boards.
1. Deriving general formulas for snakes and ladders.


# The Board

This is the board we play on:

![Our Snakes and Ladders Board](/post/snakes_and_ladders/board.jpg)

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
library(tidyverse)
library(magrittr)
library(glue)
library(knitr)
```


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
        
        # Somehow did we move off the board in the negative direction?
        # Warn and reset to 0
        if (next_pos < 1) {
            warning(glue("Went into negative board position: {next_pos}"))
            return(NA_integer_)
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
## 1 exact           7   381  41.7          90         15
## 2 over            7   268  36.4          83         12
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
        n = 1:1000,
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

general_models %>% 
    tidy(model) %>% 
    kable()
```



|finish_type |term        |  estimate| std.error| statistic| p.value|
|:-----------|:-----------|---------:|---------:|---------:|-------:|
|exact       |(Intercept) | 32.813937| 0.1063747|  308.4751|       0|
|exact       |board_mean  | -3.372416| 0.0284432| -118.5668|       0|
|over        |(Intercept) | 28.015160| 0.0947942|  295.5367|       0|
|over        |board_mean  | -3.356716| 0.0253134| -132.6061|       0|

```r
general_models %>% 
    glance(model) %>% 
    kable()
```



|finish_type | r.squared| adj.r.squared|    sigma| statistic| p.value| df|    logLik|      AIC|      BIC| deviance| df.residual|
|:-----------|---------:|-------------:|--------:|---------:|-------:|--:|---------:|--------:|--------:|--------:|-----------:|
|exact       | 0.2160918|     0.2160764| 13.22837|  14058.09|       0|  2| -204065.4| 408136.8| 408163.3|  8924126|       50998|
|over        | 0.2563978|     0.2563832| 11.78823|  17584.37|       0|  2| -198187.1| 396380.1| 396406.6|  7086806|       50998|

```r
general_models_aug <-
    general_models %>% 
    augment(model)

general_snl_sim %>%
    ggplot() +
    geom_point(aes(board_mean, rolls, colour = finish_type), size = .01) +
    geom_smooth(aes(board_mean, rolls), method = 'lm', formula = 'y ~ x', ) +
    facet_wrap(~finish_type) +
    theme(legend.position = 'none')
```

```
## Warning in grid.Call.graphics(C_polygon, x$x, x$y, index): semi-
## transparency is not supported on this device: reported only once per page
```

<img src="/post/2020-05-09-snakes-and-ladders_files/figure-html/unnamed-chunk-9-1.png" width="672" />

## Analysis/



```r
# Fitted vs Residual
general_models_aug %>% 
    ggplot() +
    geom_point(aes(.fitted, .resid)) +
    facet_wrap(~finish_type)
```

<img src="/post/2020-05-09-snakes-and-ladders_files/figure-html/unnamed-chunk-10-1.png" width="672" />


