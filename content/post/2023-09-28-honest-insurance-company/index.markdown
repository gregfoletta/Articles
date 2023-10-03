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

```
## Reqesting 0
## Reqesting 12
## Reqesting 24
## Reqesting 36
## Reqesting 48
## Reqesting 60
## Reqesting 72
## Reqesting 84
## Reqesting 96
## Reqesting 108
## Reqesting 120
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
 1      0 78888 2021 …    11400 SUV   Automatic    2.5i/…  2021 eFour      Gran…
 2      0 39990 2019 …    37463 SUV   Automatic    6cyl …  2019 2WD        GX   
 3      0 63777 2022 …    15344 SUV   Automatic    6cyl …  2022 2WD        GXL  
 4      0 17000 2010 …   191500 SUV   Automatic    6cyl …  2010 2WD        KX-R 
 5      0 33900 2018 …   138700 SUV   Automatic    6cyl …  2018 AWD        GXL  
 6      0 29480 2017 …   111792 SUV   Automatic    6cyl …  2017 2WD        GX   
 7      0 22500 2013 …   110000 SUV   Automatic    6cyl …  2013 AWD        KX-R 
 8      0 81477 2022 …    13936 SUV   Automatic    2.5i/…  2022 eFour      Gran…
 9      0 67990 2021 …    20034 SUV   Automatic    2.5i/…  2021 eFour      GXL  
10      0 37999 2017 …    62050 SUV   Automatic    6cyl …  2017 2WD        GX   
# ℹ 128 more rows
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-10-1.png" width="672" />

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-11-1.png" width="672" />


# Modelling


```r
model_file <- here('content', 'post', '2023-09-28-honest-insurance-company', 'linear.stan')
kluger_model <- cmdstan_model(model_file)
kluger_model$print()
```

```
data {
    int<lower=0> n;
    vector[n] odometer;
    vector[n] price;
}
parameters {
    real alpha;
    real beta;
    real<lower=0> sigma;
}
model {
    log(price) ~ normal(alpha + beta * odometer, sigma);
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
## Warning: 783 of 4000 (20.0%) transitions hit the maximum treedepth limit of 12.
## See https://mc-stan.org/misc/warnings for details.
```
    

```r
kluger_fit <- kluger_fit |> recover_types(kluger_data_filtered)
kluger_fit$summary()
```

```
# A tibble: 4 × 10
  variable        mean   median      sd     mad       q5      q95  rhat ess_bulk
  <chr>          <num>    <num>   <num>   <num>    <num>    <num> <num>    <num>
1 lp__         1.29e+2  1.29e+2 1.24e+0 1.02e+0  1.26e+2  1.30e+2  1.02     252.
2 alpha        1.05e+1  1.05e+1 1.95e-2 1.94e-2  1.05e+1  1.05e+1  1.01     355.
3 beta        -6.76e-6 -6.76e-6 2.97e-7 2.95e-7 -7.24e-6 -6.27e-6  1.00    4135.
4 sigma        2.39e-1  2.38e-1 1.51e-2 1.45e-2  2.14e-1  2.65e-1  1.03     122.
# ℹ 1 more variable: ess_tail <num>
```

```r
kluger_fit |> 
    spread_draws(alpha, beta) |> 
    ggplot() +
    geom_histogram(aes(beta, fill = as.factor(.chain)), binwidth = .000001)
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-15-1.png" width="672" />

```r
kluger_fit |>
    spread_draws(alpha, beta) |>
    ggplot() +
    geom_abline(aes(intercept = alpha, slope = beta), alpha = .01) +
    geom_point(data = kluger_data_filtered, aes(odometer, log(price)))
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-16-1.png" width="672" />




