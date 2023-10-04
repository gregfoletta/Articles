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
        offset = 12 * c(0:10)
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
        price = parse_number(price),
        year = as.integer( str_extract(title, "^(\\d{4})", group = TRUE) ),
        drivetrain = str_extract(title, "\\w+$"),
        model = str_extract(title, "Toyota Kluger ([-\\w]+)", group = TRUE)
    )

print(kluger_data)
```

```
# A tibble: 138 × 10
   offset price title  odometer body  transmission engine  year drivetrain model
    <dbl> <dbl> <chr>     <dbl> <chr> <chr>        <chr>  <int> <chr>      <chr>
 1      0 42990 2018 …    83336 SUV   Automatic    6cyl …  2018 2WD        Gran…
 2      0 52350 2022 …    30709 SUV   Automatic    6cyl …  2022 2WD        GX   
 3      0 55990 2022 …     6602 SUV   Automatic    4cyl …  2022 2WD        GX   
 4      0 62400 2021 …    19134 SUV   Automatic    2.5i/…  2021 eFour      GX   
 5      0 29480 2017 …   111792 SUV   Automatic    6cyl …  2017 2WD        GX   
 6      0 67961 2021 …    49762 SUV   Automatic    6cyl …  2021 2WD        Gran…
 7      0 57490 2021 …    32500 SUV   Automatic    2.5i/…  2021 eFour      GX   
 8      0 73250 2023 …     2608 SUV   Automatic    2.5i/…  2023 eFour      GXL  
 9      0 47990 2021 …    26948 SUV   Automatic    6cyl …  2021 2WD        GX   
10      0 81477 2022 …    13936 SUV   Automatic    2.5i/…  2022 eFour      Gran…
# ℹ 128 more rows
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
    vector[n] odometer;
    vector[n] price;
}
parameters {
    real a;
    real b;
    real<lower=0> sigma;
}
model {
    log(price) ~ normal(a + b * odometer, sigma);
}
```

```r
kluger_fit <- kluger_model$sample(
    data = compose_data(kluger_data_filtered),
    seed = 123,
    max_treedepth = 12,
    chains = 4,
    parallel_chains = 4,
    refresh = 500,
)
```

```
## Running MCMC with 4 parallel chains...
## 
## Chain 1 Iteration:    1 / 2000 [  0%]  (Warmup) 
## Chain 2 Iteration:    1 / 2000 [  0%]  (Warmup) 
## Chain 3 Iteration:    1 / 2000 [  0%]  (Warmup) 
## Chain 4 Iteration:    1 / 2000 [  0%]  (Warmup) 
## Chain 3 Iteration:  500 / 2000 [ 25%]  (Warmup) 
## Chain 4 Iteration:  500 / 2000 [ 25%]  (Warmup) 
## Chain 2 Iteration:  500 / 2000 [ 25%]  (Warmup) 
## Chain 1 Iteration:  500 / 2000 [ 25%]  (Warmup) 
## Chain 3 Iteration: 1000 / 2000 [ 50%]  (Warmup) 
## Chain 3 Iteration: 1001 / 2000 [ 50%]  (Sampling) 
## Chain 3 Iteration: 1500 / 2000 [ 75%]  (Sampling) 
## Chain 3 Iteration: 2000 / 2000 [100%]  (Sampling) 
## Chain 3 finished in 3.1 seconds.
## Chain 2 Iteration: 1000 / 2000 [ 50%]  (Warmup) 
## Chain 2 Iteration: 1001 / 2000 [ 50%]  (Sampling) 
## Chain 4 Iteration: 1000 / 2000 [ 50%]  (Warmup) 
## Chain 4 Iteration: 1001 / 2000 [ 50%]  (Sampling) 
## Chain 1 Iteration: 1000 / 2000 [ 50%]  (Warmup) 
## Chain 1 Iteration: 1001 / 2000 [ 50%]  (Sampling) 
## Chain 4 Iteration: 1500 / 2000 [ 75%]  (Sampling) 
## Chain 1 Iteration: 1500 / 2000 [ 75%]  (Sampling) 
## Chain 4 Iteration: 2000 / 2000 [100%]  (Sampling) 
## Chain 4 finished in 6.1 seconds.
## Chain 1 Iteration: 2000 / 2000 [100%]  (Sampling) 
## Chain 1 finished in 7.1 seconds.
## Chain 2 Iteration: 1500 / 2000 [ 75%]  (Sampling) 
## Chain 2 Iteration: 2000 / 2000 [100%]  (Sampling) 
## Chain 2 finished in 13.6 seconds.
## 
## All 4 chains finished successfully.
## Mean chain execution time: 7.5 seconds.
## Total execution time: 13.7 seconds.
```
    

```r
kluger_fit <- kluger_fit |> recover_types(kluger_data_filtered)
kluger_fit$summary()
```

```
# A tibble: 4 × 10
  variable        mean   median      sd     mad       q5      q95  rhat ess_bulk
  <chr>          <num>    <num>   <num>   <num>    <num>    <num> <num>    <num>
1 lp__     86.2         1.32e+2 7.92e+1 1.76e+0 -5.13e+1  1.33e+2  1.54     7.20
2 a        10.5         1.06e+1 6.79e-2 3.08e-2  1.04e+1  1.06e+1  1.61     6.73
3 b        -0.00000666 -6.66e-6 8.76e-7 3.88e-7 -8.07e-6 -5.20e-6  1.28  1844.  
4 sigma     0.529       2.38e-1 5.14e-1 2.34e-2  2.12e-1  1.42e+0  1.56     7.03
# ℹ 1 more variable: ess_tail <num>
```

```r
kluger_fit |> 
    gather_draws(a, b) |> 
    ggplot() +
    geom_histogram(aes(.value, fill = as.factor(.chain)), bins = 100) +
    facet_wrap(vars(.variable), scales = 'free') +
    labs(
        title = "Toyota Kluger Market Linear Model",
        subtitle = "Histogram of Posterior Draws of Alpha & Beta Coefficients",
        x = "Coefficient Value",
        y = "Frequency"
    )
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-18-1.png" width="672" />

```r
kluger_fit |>
    spread_draws(a, b) |>
    ggplot() +
    geom_abline(aes(intercept = a, slope = b, group = .draw), alpha = 0.1) +
    transition_reveal(.draw) +
    geom_point(data = kluger_data_filtered, aes(odometer, log(price))) +
    #geom_point(data = kluger_data_filtered, mapping = aes(odometer, log(price))) +
    labs(
        title = "MCMC Draw {frame_along}"
    ) -> kluger_fit_animation

animate(kluger_fit_animation, renderer = gifski_renderer())
```

![](index_files/figure-html/unnamed-chunk-19-1.gif)<!-- -->




