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
docker container stop rsel
docker container rm rsel
```

```
## rsel
## rsel
```


```sh
docker run -d -p 4444:4444 --name rsel selenium/standalone-firefox:latest
docker container inspect rsel | jq '.[].NetworkSettings.Networks.bridge.IPAddress'
sleep 5
```

```
## 95dfef5d11df6a0bc2c3f416c19d5fec07239fc87ea5c243ae8aca414924392f
## "172.17.0.2"
```





```r
kluger_raw <-
    tibble(
        offset = 12 * c(0:10)
    ) |> 
    mutate(
        source = map(offset, ~{ 
                rs$navigate(glue("https://www.carsales.com.au/cars/used/toyota/kluger/?offset={.x}"))
                rs$getPageSource() |> pluck(1) |> read_html()
        } )
    )
```



```r
xpath_text <- function(html, xpath) {
    html_elements(html, xpath = xpath) |> html_text()
}
```


```r
kluger_data <- 
    kluger_raw |> 
    mutate(
        price = map(source, ~xpath_text(.x, xpath = ".//a[@data-webm-clickvalue = 'sv-price']")),
        title = map(source, ~xpath_text(.x, xpath = ".//a[@data-webm-clickvalue = 'sv-title']")),
        odometer = map(source, ~xpath_text(.x, xpath = ".//li[@data-type = 'Odometer']")),
        body = map(source, ~xpath_text(.x, xpath = ".//li[@data-type = 'Body Style']")),
        transmission = map(source, ~xpath_text(.x, xpath = ".//li[@data-type = 'Transmission']")),
        engine = map(source, ~xpath_text(.x, xpath = ".//li[@data-type = 'Engine']"))
    ) |>
    mutate(
        o_len = map_int(odometer, ~length(.x)),
        t_len = map_int(title, ~length(.x))
    ) |>
    filter(o_len == t_len) |>
    select(-source, offset, o_len, t_len) |>
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
## # A tibble: 124 × 12
##    offset price title       odometer body  transmission engine o_len t_len  year
##     <dbl> <dbl> <chr>          <dbl> <chr> <chr>        <chr>  <int> <int> <int>
##  1      0 39999 2019 Toyot…    79836 SUV   Automatic    6cyl …    16    16  2019
##  2      0 75990 2021 Toyot…    18236 SUV   Automatic    2.5i/…    16    16  2021
##  3      0 39990 2019 Toyot…   110503 SUV   Automatic    6cyl …    16    16  2019
##  4      0 42500 2018 Toyot…    92000 SUV   Automatic    6cyl …    16    16  2018
##  5      0 45888 2019 Toyot…    82112 SUV   Automatic    6cyl …    16    16  2019
##  6      0 37990 2019 Toyot…    82713 SUV   Automatic    6cyl …    16    16  2019
##  7      0 32000 2014 Toyot…    79352 SUV   Automatic    6cyl …    16    16  2014
##  8      0 34900 2018 Toyot…    93903 SUV   Automatic    6cyl …    16    16  2018
##  9      0 68990 2021 Toyot…    49762 SUV   Automatic    6cyl …    16    16  2021
## 10      0 26987 2014 Toyot…   165000 SUV   Automatic    6cyl …    16    16  2014
## # ℹ 114 more rows
## # ℹ 2 more variables: drivetrain <chr>, model <chr>
```


```r
kluger_data |>
    ggplot() +
    geom_point(aes(odometer, price, colour = model))
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-9-1.png" width="672" />

```r
kluger_data <-
    kluger_data |>
    mutate(
        log_price = log10(price),
    )
```


```r
kluger_data |>
    ggplot() +
    geom_point(aes(odometer, log_price, colour = model))
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-11-1.png" width="672" />

```r
kluger_data |>
    ggplot() +
    geom_point(aes(odometer, log_price, colour = model)) +
    facet_wrap(~engine)
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-11-2.png" width="672" />



```sh
docker container stop rsel
docker container rm rsel
```

```
## rsel
## rsel
```

