---
title: Honest Insurance Company
author: Greg Foletta
date: '2023-09-28'
slug: []
categories: []
tags: []
images: []
---





# Data Aquisition




```sh
docker run -d -p 4444:4444 --name rsel selenium/standalone-firefox:latest
```


```r
rs <- remoteDriver(remoteServerAddr = '172.17.0.2', port = 4444L)
rs$extraCapabilities$pageLoadStrategy <- "eager"
rs$open()
```


```r
kluger_source <-
    tibble(
        offset = 12 * c(0:100)
    ) |> 
    mutate(
        source = map(offset, ~{ 
                print(glue("Reqesting {.x}"))
                rs$navigate(glue("https://www.carsales.com.au/cars/used/toyota/kluger/?offset={.x}"))
                rs$getPageSource() |> pluck(1) |> read_html()
        } )
    )
```



```r
xpath_text <- function(html, xpath) { html_elements(html, xpath = xpath) |> html_text() }
```


```r
kluger_data <-
    kluger_source |> 
    mutate(
        # Get entires that have odometer
        cards = map(source, ~html_elements(.x, xpath = "//li[@data-type = 'Odometer']/ancestor::div[@class = 'card-body']")),
        # Extract specific properties 
        price = map(cards, ~xpath_text(.x, xpath = ".//a[@data-webm-clickvalue = 'sv-price']")),
        title = map(cards, ~xpath_text(.x, xpath = ".//a[@data-webm-clickvalue = 'sv-title']")),
        odometer = map(cards, ~xpath_text(.x, xpath = ".//li[@data-type = 'Odometer']")),
        body = map(cards, ~xpath_text(.x, xpath = ".//li[@data-type = 'Body Style']")),
        transmission = map(cards, ~xpath_text(.x, xpath = ".//li[@data-type = 'Transmission']")),
        engine = map(cards, ~xpath_text(.x, xpath = ".//li[@data-type = 'Engine']"))
    ) |>
    select(-c(source, cards)) |>
    unnest(everything())
```





```r
kluger_data <-
kluger_data |>
    mutate(
        odometer = parse_number(odometer),
        odometer_Mm = odometer / 1000,
        price = parse_number(price),
        year = as.integer( str_extract(title, "^(\\d{4})", group = TRUE) ),
        drivetrain = str_extract(title, "\\w+$"),
        model = str_extract(title, "Toyota Kluger ([-\\w]+)", group = TRUE)
    )

str(kluger_data)
```

```
tibble [1,013 × 11] (S3: tbl_df/tbl/data.frame)
 $ offset      : num [1:1013] 0 0 0 0 0 0 0 0 0 0 ...
 $ price       : num [1:1013] 59980 53990 37990 18500 66990 ...
 $ title       : chr [1:1013] "2021 Toyota Kluger GX Auto eFour" "2021 Toyota Kluger GX Auto eFour" "2019 Toyota Kluger GX Auto 2WD" "2011 Toyota Kluger Grande Auto 2WD MY11" ...
 $ odometer    : num [1:1013] 28071 72631 82713 203500 196 ...
 $ body        : chr [1:1013] "SUV" "SUV" "SUV" "SUV" ...
 $ transmission: chr [1:1013] "Automatic" "Automatic" "Automatic" "Automatic" ...
 $ engine      : chr [1:1013] "2.5i/184kW Hybrid" "2.5i/184kW Hybrid" "6cyl 3.5L Petrol" "6cyl 3.5L Petrol" ...
 $ odometer_Mm : num [1:1013] 28.071 72.631 82.713 203.5 0.196 ...
 $ year        : int [1:1013] 2021 2021 2019 2011 2021 2022 2015 2021 2022 2023 ...
 $ drivetrain  : chr [1:1013] "eFour" "eFour" "2WD" "MY11" ...
 $ model       : chr [1:1013] "GX" "GX" "GX" "Grande" ...
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-10-1.png" width="672" />

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-11-1.png" width="672" />

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-12-1.png" width="672" />

# Modelling



```r
kluger_model <- cmdstan_model(model_file_path)
kluger_model$print()
```

```
data {
    int<lower=0> n;
    vector[n] odometer_Mm;
    vector[n] price;
}
parameters {
    real a;
    real b;
    real<lower=0> sigma;
}
model {
    log(price) ~ normal(a + b * odometer_Mm, sigma);
}    
generated quantities {
    array[n] real y_s = normal_rng(a + b * odometer_Mm, sigma);
}
```

```r
kluger_fit <- kluger_model$sample(
    data = compose_data(kluger_data),
    seed = 123,
    chains = 4,
    parallel_chains = 4,
    refresh = 500,
)
```

```
Running MCMC with 4 parallel chains...

Chain 1 Iteration:    1 / 2000 [  0%]  (Warmup) 
Chain 2 Iteration:    1 / 2000 [  0%]  (Warmup) 
Chain 3 Iteration:    1 / 2000 [  0%]  (Warmup) 
Chain 4 Iteration:    1 / 2000 [  0%]  (Warmup) 
Chain 2 Iteration:  500 / 2000 [ 25%]  (Warmup) 
Chain 3 Iteration:  500 / 2000 [ 25%]  (Warmup) 
Chain 1 Iteration:  500 / 2000 [ 25%]  (Warmup) 
Chain 4 Iteration:  500 / 2000 [ 25%]  (Warmup) 
Chain 2 Iteration: 1000 / 2000 [ 50%]  (Warmup) 
Chain 2 Iteration: 1001 / 2000 [ 50%]  (Sampling) 
Chain 3 Iteration: 1000 / 2000 [ 50%]  (Warmup) 
Chain 3 Iteration: 1001 / 2000 [ 50%]  (Sampling) 
Chain 4 Iteration: 1000 / 2000 [ 50%]  (Warmup) 
Chain 4 Iteration: 1001 / 2000 [ 50%]  (Sampling) 
Chain 1 Iteration: 1000 / 2000 [ 50%]  (Warmup) 
Chain 1 Iteration: 1001 / 2000 [ 50%]  (Sampling) 
Chain 2 Iteration: 1500 / 2000 [ 75%]  (Sampling) 
Chain 3 Iteration: 1500 / 2000 [ 75%]  (Sampling) 
Chain 4 Iteration: 1500 / 2000 [ 75%]  (Sampling) 
Chain 1 Iteration: 1500 / 2000 [ 75%]  (Sampling) 
Chain 2 Iteration: 2000 / 2000 [100%]  (Sampling) 
Chain 2 finished in 3.8 seconds.
Chain 3 Iteration: 2000 / 2000 [100%]  (Sampling) 
Chain 3 finished in 3.9 seconds.
Chain 4 Iteration: 2000 / 2000 [100%]  (Sampling) 
Chain 4 finished in 4.4 seconds.
Chain 1 Iteration: 2000 / 2000 [100%]  (Sampling) 
Chain 1 finished in 5.0 seconds.

All 4 chains finished successfully.
Mean chain execution time: 4.3 seconds.
Total execution time: 5.1 seconds.
```
    
<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-16-1.png" width="672" />
<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-17-1.png" width="672" />


![](index_files/figure-html/unnamed-chunk-18-1.gif)<!-- -->
<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-19-1.png" width="672" />



```r
kluger_fit |>
    spread_draws(a,b) |>
    ggplot() +
    geom_point(data = kluger_data, aes(odometer_Mm, price)) +
    geom_function(fun = ~exp(11.14 - 0.00626 * .x), linewidth = 2, colour = 'lightblue') +
    labs(
        title = "Toyota Kluger Market Model",
        subtitle = "Odometer vs Price",
        x = "Odometer (Megametres)",
        y = "Log(Price) ($)"
    )
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-20-1.png" width="672" />



```r
kluger_fit$summary()
```

```
# A tibble: 1,017 × 10
   variable       mean   median      sd     mad       q5      q95  rhat ess_bulk
   <chr>         <num>    <num>   <num>   <num>    <num>    <num> <num>    <num>
 1 lp__     1097.       1.10e+3 1.15e+0 9.79e-1  1.09e+3  1.10e+3 1.00     1239.
 2 a          11.1      1.11e+1 1.08e-2 1.08e-2  1.11e+1  1.12e+1 1.01     1570.
 3 b          -0.00626 -6.26e-3 8.92e-5 9.12e-5 -6.40e-3 -6.11e-3 1.00     2056.
 4 sigma       0.205    2.05e-1 4.51e-3 4.51e-3  1.98e-1  2.13e-1 1.00     1646.
 5 y_s[1]     11.0      1.10e+1 2.09e-1 2.10e-1  1.06e+1  1.13e+1 1.00     3861.
 6 y_s[2]     10.7      1.07e+1 2.09e-1 2.08e-1  1.03e+1  1.10e+1 1.00     3876.
 7 y_s[3]     10.6      1.06e+1 2.07e-1 1.99e-1  1.03e+1  1.10e+1 0.999    4127.
 8 y_s[4]      9.86     9.86e+0 2.03e-1 2.05e-1  9.53e+0  1.02e+1 0.999    3758.
 9 y_s[5]     11.1      1.11e+1 2.06e-1 2.06e-1  1.08e+1  1.15e+1 1.00     3806.
10 y_s[6]     11.1      1.11e+1 2.07e-1 2.09e-1  1.08e+1  1.14e+1 1.00     4024.
# ℹ 1,007 more rows
# ℹ 1 more variable: ess_tail <num>
```



