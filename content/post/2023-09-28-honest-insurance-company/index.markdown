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
## # A tibble: 520 × 10
##    offset price title  odometer body  transmission engine  year drivetrain model
##     <dbl> <dbl> <chr>     <dbl> <chr> <chr>        <chr>  <int> <chr>      <chr>
##  1      0 28990 2015 …   136417 SUV   Automatic    6cyl …  2015 AWD        GX   
##  2      0 12990 2007 …   260296 SUV   Automatic    6cyl …  2007 2WD        KX-S 
##  3      0 67990 2023 …       35 SUV   Automatic    2.5i/…  2023 eFour      GX   
##  4      0 27000 2015 …   128613 SUV   Automatic    6cyl …  2015 2WD        GXL  
##  5      0 49705 2021 …    38878 SUV   Automatic    6cyl …  2021 2WD        GX   
##  6      0 66990 2021 …      196 SUV   Automatic    6cyl …  2021 2WD        GXL  
##  7      0 16400 2011 …   212000 SUV   Automatic    6cyl …  2011 MY11       Gran…
##  8      0 39950 2019 …    31978 SUV   Automatic    6cyl …  2019 2WD        GX   
##  9      0 34490 2015 …   100346 SUV   Automatic    6cyl …  2015 AWD        Gran…
## 10      0 73990 2022 …     2012 SUV   Automatic    2.5i/…  2022 eFour      GXL  
## # ℹ 510 more rows
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-10-1.png" width="672" />

```r
kluger_data <- kluger_data |> mutate( log_price = log10(price) )
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-12-1.png" width="672" />
<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-13-1.png" width="672" />

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-14-1.png" width="672" />
# Modelling



