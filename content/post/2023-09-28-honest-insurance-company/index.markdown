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
        price = parse_number(price),
        year = as.integer( str_extract(title, "^(\\d{4})", group = TRUE) ),
        drivetrain = str_extract(title, "\\w+$"),
        model = str_extract(title, "Toyota Kluger ([-\\w]+)", group = TRUE)
    )

str(kluger_data)
```

```
tibble [1,013 × 10] (S3: tbl_df/tbl/data.frame)
 $ offset      : num [1:1013] 0 0 0 0 0 0 0 0 0 0 ...
 $ price       : num [1:1013] 59980 53990 37990 18500 66990 ...
 $ title       : chr [1:1013] "2021 Toyota Kluger GX Auto eFour" "2021 Toyota Kluger GX Auto eFour" "2019 Toyota Kluger GX Auto 2WD" "2011 Toyota Kluger Grande Auto 2WD MY11" ...
 $ odometer    : num [1:1013] 28071 72631 82713 203500 196 ...
 $ body        : chr [1:1013] "SUV" "SUV" "SUV" "SUV" ...
 $ transmission: chr [1:1013] "Automatic" "Automatic" "Automatic" "Automatic" ...
 $ engine      : chr [1:1013] "2.5i/184kW Hybrid" "2.5i/184kW Hybrid" "6cyl 3.5L Petrol" "6cyl 3.5L Petrol" ...
 $ year        : int [1:1013] 2021 2021 2019 2011 2021 2022 2015 2021 2022 2023 ...
 $ drivetrain  : chr [1:1013] "eFour" "eFour" "2WD" "MY11" ...
 $ model       : chr [1:1013] "GX" "GX" "GX" "Grande" ...
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-11-1.png" width="672" />

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-12-1.png" width="672" />

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-13-1.png" width="672" />


```r
kluger_data_filtered <-
    kluger_data |>
    # Centre the odometer variable
    mutate(
        odometer = (odometer - mean(odometer)) / sd(odometer)
    ) |>
    select(odometer, price)
```


```r
kluger_data_filtered |>
    ggplot() +
    geom_point(aes(odometer, log(price))) +
    labs(
        title = 'Toyota Kluger Market',
        subtitle = 'Standardised and Cenetered Odometer Values',
        x = 'Odometer (centered/standardised)',
        y = 'Log(price) ($)'
    )
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-15-1.png" width="672" />

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
    chains = 4,
    parallel_chains = 4,
    refresh = 500,
)
```

```
Running MCMC with 4 parallel chains...

Chain 1 Iteration:    1 / 2000 [  0%]  (Warmup) 
Chain 1 Iteration:  500 / 2000 [ 25%]  (Warmup) 
Chain 1 Iteration: 1000 / 2000 [ 50%]  (Warmup) 
Chain 1 Iteration: 1001 / 2000 [ 50%]  (Sampling) 
Chain 2 Iteration:    1 / 2000 [  0%]  (Warmup) 
Chain 2 Iteration:  500 / 2000 [ 25%]  (Warmup) 
Chain 2 Iteration: 1000 / 2000 [ 50%]  (Warmup) 
Chain 2 Iteration: 1001 / 2000 [ 50%]  (Sampling) 
Chain 3 Iteration:    1 / 2000 [  0%]  (Warmup) 
Chain 3 Iteration:  500 / 2000 [ 25%]  (Warmup) 
Chain 3 Iteration: 1000 / 2000 [ 50%]  (Warmup) 
Chain 3 Iteration: 1001 / 2000 [ 50%]  (Sampling) 
Chain 4 Iteration:    1 / 2000 [  0%]  (Warmup) 
Chain 4 Iteration:  500 / 2000 [ 25%]  (Warmup) 
Chain 4 Iteration: 1000 / 2000 [ 50%]  (Warmup) 
Chain 4 Iteration: 1001 / 2000 [ 50%]  (Sampling) 
Chain 1 Iteration: 1500 / 2000 [ 75%]  (Sampling) 
Chain 1 Iteration: 2000 / 2000 [100%]  (Sampling) 
Chain 2 Iteration: 1500 / 2000 [ 75%]  (Sampling) 
Chain 2 Iteration: 2000 / 2000 [100%]  (Sampling) 
Chain 3 Iteration: 1500 / 2000 [ 75%]  (Sampling) 
Chain 3 Iteration: 2000 / 2000 [100%]  (Sampling) 
Chain 4 Iteration: 1500 / 2000 [ 75%]  (Sampling) 
Chain 4 Iteration: 2000 / 2000 [100%]  (Sampling) 
Chain 1 finished in 0.2 seconds.
Chain 2 finished in 0.3 seconds.
Chain 3 finished in 0.3 seconds.
Chain 4 finished in 0.3 seconds.

All 4 chains finished successfully.
Mean chain execution time: 0.3 seconds.
Total execution time: 0.3 seconds.
```
    
<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-19-1.png" width="672" />
<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-20-1.png" width="672" />


![](index_files/figure-html/unnamed-chunk-21-1.gif)<!-- -->


```r
kluger_fit$summary()
```

```
# A tibble: 4 × 10
  variable     mean   median      sd     mad       q5      q95  rhat ess_bulk
  <chr>       <num>    <num>   <num>   <num>    <num>    <num> <num>    <num>
1 lp__     1097.    1097.    1.21    0.993   1094.    1098.     1.00    1921.
2 a          10.5     10.5   0.00649 0.00630   10.5     10.5    1.00    4512.
3 b          -0.450   -0.450 0.00635 0.00628   -0.461   -0.440  1.00    5408.
4 sigma       0.205    0.205 0.00454 0.00458    0.198    0.213  1.00    3489.
# ℹ 1 more variable: ess_tail <num>
```



