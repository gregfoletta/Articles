---
title: Honest Insurance Company
author: Greg Foletta
date: '2023-09-28'
slug: []
categories: [R Bayesian]
tags: []
---



Last month my car - a Toyota Kluger - was run into while parked in front of my house. Luckily no one was injured and while annoying, the person had insurance (coincidently with the same company as my). The insurance company came back and determined that the car had been written off and I would be paid out the market value of the car. But what is the market value? How could I keep the insurance company honest and make sure I wasn't getting stiffed?

In this post I'll go through the process I used to keep the insurance company honest. There's data acquisition and visiualisation of the current market, then modelling of the market price. 

# Data Aquisition

The first step was to acquire some data on the current market for Toyota Klugers. I used [carsales.com.au](https://www.carsales.com.au/cars/used/toyota/kluger/) as my source. The Carsales site requires Javascript to render, so simply requesting the pages wasn't going to work. Instead we need to render the page in a browser. To do this I used a docker instance of the webdriver [Selenium](https://www.selenium.dev/), interfacing into this with the R package [RSelenium](https://github.com/ropensci/RSelenium). This allows us to browse to the site from a 'remotely controller' browser, Javascript and all, and retrieve the information we need.

First up, we connect to the docker instance, setting the page load strategy to eager so that it will return when the initial HTML is loaded and not wait for stylesheets, images, etc.






```r
rs <- remoteDriver(remoteServerAddr = '172.17.0.2', port = 4444L)
rs$extraCapabilities$pageLoadStrategy <- "eager"
rs$open()
```

Each page of Klugers for sale is determined by an offset of 12. We generate the offsets (12, 24, 36 etc) and the URIs based on these offsets. We then navigate to each page, reading the source, and parsing into a structuered XML document.


```r
kluger_source <-
    tibble(
        # Generate offsets
        offset = 12 * c(0:100),
        # Create URIs based on offsets
        uri = glue("https://www.carsales.com.au/cars/used/toyota/kluger/?offset={offset}")
    ) |> 
    mutate(
        # Naviate to each URI, read and parse the source
        source = map(uri, ~{ 
            rs$navigate(uri)
            rs$getPageSource() |> pluck(1) |> read_html()
        } )
    )
```

With the raw source in our hands, we can move on to extracting the pieces of data we need from each of them.

# Data Extractiion

First up, we define a small helper function which finds an element based on its XPath, and pulls out the text of that element.


```r
# XPath helper function, xpt short for xpath_text
xpt <- function(html, xpath) {
    html_elements(html, xpath = xpath) |> 
    html_text()
}
```

Each 'card' has the details of a car for sale. The issue we ran into is that not all of them have the odometer reading, which is the critical variable we're going to use in our modelling later. To get around this, we use a some convoluted XPath. We find all the <li> tags that have the odometer reading, then go back up the tree to find the ancestor <div> tags that define the entire card. This ensures that all the cards we've pulled out have odometer readings. 

From there, it's trivial to extract specific properties from the car sale.


```r
kluger_data <-
    kluger_source |> 
    mutate(
        # Get entires that have odometer
        cards = map(source, ~html_elements(.x, xpath = "//li[@data-type = 'Odometer']/ancestor::div[@class = 'card-body']")),
        # Extract specific values of each car sale
        price = map(cards, ~xpt(.x, xpath = ".//a[@data-webm-clickvalue = 'sv-price']")),
        title = map(cards, ~xpt(.x, xpath = ".//a[@data-webm-clickvalue = 'sv-title']")),
        odometer = map(cards, ~xpt(.x, xpath = ".//li[@data-type = 'Odometer']")),
        body = map(cards, ~xpt(.x, xpath = ".//li[@data-type = 'Body Style']")),
        transmission = map(cards, ~xpt(.x, xpath = ".//li[@data-type = 'Transmission']")),
        engine = map(cards, ~xpt(.x, xpath = ".//li[@data-type = 'Engine']"))
    ) |>
    select(-c(source, cards, offset)) |>
    unnest(everything())
```



At this stage, the data is a bit raw: the odometer and price are character strings with dollar signs and commas, and other important pieces of info are in the title:


```
# A tibble: 1,013 × 6
   price    title                             odometer body  transmission engine
   <chr>    <chr>                             <chr>    <chr> <chr>        <chr> 
 1 $59,980* 2021 Toyota Kluger GX Auto eFour  28,071 … SUV   Automatic    2.5i/…
 2 $53,990* 2021 Toyota Kluger GX Auto eFour  72,631 … SUV   Automatic    2.5i/…
 3 $37,990  2019 Toyota Kluger GX Auto 2WD    82,713 … SUV   Automatic    6cyl …
 4 $18,500* 2011 Toyota Kluger Grande Auto 2… 203,500… SUV   Automatic    6cyl …
 5 $66,990* 2021 Toyota Kluger GXL Auto 2WD   196 km   SUV   Automatic    6cyl …
 6 $55,990* 2022 Toyota Kluger GX Auto 2WD    6,602 km SUV   Automatic    4cyl …
 7 $27,000* 2015 Toyota Kluger GX Auto 2WD    134,000… SUV   Automatic    6cyl …
 8 $67,961  2021 Toyota Kluger Grande Auto 2… 49,762 … SUV   Automatic    6cyl …
 9 $52,350* 2022 Toyota Kluger GX Auto 2WD    30,709 … SUV   Automatic    6cyl …
10 $73,250* 2023 Toyota Kluger GXL Auto eFour 2,608 km SUV   Automatic    2.5i/…
# ℹ 1,003 more rows
```

There's a small amount of housekeeping to be done. The price and odometer are in a textual format, so these are converted to integers. we also create a new *megametre* variable (i.e. thousands of kilometers). The year, model, and drivetrain are pulled out of the title of the advert using regex.


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

print(kluger_data)
```

```
# A tibble: 1,013 × 10
   price title   odometer body  transmission engine odometer_Mm  year drivetrain
   <dbl> <chr>      <dbl> <chr> <chr>        <chr>        <dbl> <int> <chr>     
 1 59980 2021 T…    28071 SUV   Automatic    2.5i/…      28.1    2021 eFour     
 2 53990 2021 T…    72631 SUV   Automatic    2.5i/…      72.6    2021 eFour     
 3 37990 2019 T…    82713 SUV   Automatic    6cyl …      82.7    2019 2WD       
 4 18500 2011 T…   203500 SUV   Automatic    6cyl …     204.     2011 MY11      
 5 66990 2021 T…      196 SUV   Automatic    6cyl …       0.196  2021 2WD       
 6 55990 2022 T…     6602 SUV   Automatic    4cyl …       6.60   2022 2WD       
 7 27000 2015 T…   134000 SUV   Automatic    6cyl …     134      2015 2WD       
 8 67961 2021 T…    49762 SUV   Automatic    6cyl …      49.8    2021 2WD       
 9 52350 2022 T…    30709 SUV   Automatic    6cyl …      30.7    2022 2WD       
10 73250 2023 T…     2608 SUV   Automatic    2.5i/…       2.61   2023 eFour     
# ℹ 1,003 more rows
# ℹ 1 more variable: model <chr>
```

# Taking a Quick Look

Let's visualise key features of the data. First up we'll, how does the market price for a Kluger change as the odometers (in megametres):

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-11-1.png" width="672" />
The thing I notice is that looks suspiciously like there's some sort of negative exponential relationship between the the odometer and price. What if we take a look at the odometer versus the log of the price?

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-12-1.png" width="672" />
This is great; with the log transform we've now got a linear relationship between the number odometer of the car and the price. We're going to end up trying to fit a line to this data, and the log transform provides a nice interpretation for the slope of this line. You might recall that in general when you fit a line to x and y, the slope (\\(beta\\)) of that line is "the change in the y variable given a change of one unit of the x variable". When you fit a line to to x and log(y) (called log-linear), for small \\(\beta\\), \\(e^\beta\\) is the percentage change in y for a one unit change of x. 

Here's the same view, but we split it out by model:

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-13-1.png" width="672" />

# Modelling

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-14-1.png" width="672" />
With our data in hand, what we want to do is create a model that helps us predict the sell price of a Toyota Kluger. In the interests of starting with a very simple model, we're only going use the odometer reading as a single predictor variable. This means there's likely a log of 




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
    
    real price_pred = exp( normal_rng(a + b * 60, sigma) );
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
Chain 2 finished in 3.7 seconds.
Chain 3 Iteration: 2000 / 2000 [100%]  (Sampling) 
Chain 3 finished in 4.1 seconds.
Chain 4 Iteration: 2000 / 2000 [100%]  (Sampling) 
Chain 4 finished in 4.6 seconds.
Chain 1 Iteration: 2000 / 2000 [100%]  (Sampling) 
Chain 1 finished in 5.1 seconds.

All 4 chains finished successfully.
Mean chain execution time: 4.4 seconds.
Total execution time: 5.3 seconds.
```

# Assessing the Model

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-18-1.png" width="672" />
<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-19-1.png" width="672" />


![](index_files/figure-html/unnamed-chunk-20-1.gif)<!-- -->


<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-21-1.png" width="672" />

# Model Outcomes


```
## # A tibble: 3 × 4
##   variable     mean   median        sd
##   <chr>       <num>    <num>     <num>
## 1 a        11.1     11.1     0.0107   
## 2 b        -0.00626 -0.00626 0.0000888
## 3 sigma     0.205    0.205   0.00470
```


```r
kluger_quantile <-
    kluger_fit |>
    spread_draws(price_pred) |>
    reframe(
        interval = c(.11, .89),
        value = quantile(price_pred, interval)
    ) |>
    spread(interval, value)

kluger_fit |>
    recover_types() |>
    spread_draws(price_pred) |>
    ggplot() +
    geom_histogram(aes(price_pred), bins = 200) +
    geom_vline(xintercept = kluger_quantile[['0.11']], color = 'blue', linewidth = 1, linetype = 'dotted') +
    geom_vline(xintercept = kluger_quantile[['0.89']], color = 'blue', linewidth = 1, linetype = 'dotted') +
    scale_x_continuous(labels = scales::comma) +
    scale_y_continuous(labels = scales::comma) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) 
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-23-1.png" width="672" />



<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-24-1.png" width="672" />




```r
kluger_fit$summary()
```

```
# A tibble: 1,018 × 10
   variable       mean   median      sd     mad       q5      q95  rhat ess_bulk
   <chr>         <num>    <num>   <num>   <num>    <num>    <num> <num>    <num>
 1 lp__     1097.       1.10e+3 1.20e+0 1.01e+0  1.09e+3  1.10e+3  1.00    1186.
 2 a          11.1      1.11e+1 1.07e-2 1.08e-2  1.11e+1  1.12e+1  1.00    1564.
 3 b          -0.00626 -6.26e-3 8.88e-5 8.73e-5 -6.41e-3 -6.12e-3  1.00    2056.
 4 sigma       0.205    2.05e-1 4.70e-3 4.84e-3  1.98e-1  2.13e-1  1.01    1548.
 5 y_s[1]     11.0      1.10e+1 2.03e-1 1.99e-1  1.06e+1  1.13e+1  1.00    3962.
 6 y_s[2]     10.7      1.07e+1 2.06e-1 2.03e-1  1.03e+1  1.10e+1  1.00    3913.
 7 y_s[3]     10.6      1.06e+1 2.04e-1 2.08e-1  1.03e+1  1.10e+1  1.00    4068.
 8 y_s[4]      9.86     9.86e+0 2.10e-1 2.15e-1  9.52e+0  1.02e+1  1.00    3967.
 9 y_s[5]     11.1      1.11e+1 2.06e-1 2.04e-1  1.08e+1  1.15e+1  1.00    3480.
10 y_s[6]     11.1      1.11e+1 2.06e-1 2.05e-1  1.08e+1  1.14e+1  1.00    3747.
# ℹ 1,008 more rows
# ℹ 1 more variable: ess_tail <num>
```



