---
title: Getting Free Wi-Fi
author: 'Greg Foletta'
date: '2022-10-02'
slug: getting-free-wifi
categories: []
tags: []
images: []
---


There's a funny picture that's been making its way around social media showing a complicated definite integral, and asking guests to evalutate it to get the password for free WiFi. Here's an example:

![WiFi Integral](wifi_integral.jpg) 

I loved calculus back at uni, but uni was a fair while ago now and I'm more than a little dusty. I did start to have a go at integrating the equation, looking up some terms I could just remember (integration by parts? product rule?). But I thought: if I'm sitting in a cafe trying to get WiFi, I'm going to want a quick and dirty numerical solution, not some beautiful mathematical 'proof'.

So in this article I'm going to show you that quick and dirty solution. We're going to take - you guessed it - a statistical approach to finding the definite integral and getting ourselves that sweet free WiFi.

# The Function

Let's first define the function that is to be integrated in R, calling it \\(f()\\):

```r
f <- function(x) {
    (x^3 * cos(x/2) + 1/2) * sqrt(4 - x^2)
}
```

We'll than calculate \\(f(x)\\) for values of x between \\([-2,2]\)), using a small increments beween each \\(x\\) value to ensure we're got reasonable accuracy for our subsequent calculations.


```r
coords <- 
    tibble(
        x = seq(from = -2, to = 2, by = 0.000001)
    ) |> 
    mutate(y = f(x)) 
```
Let's take a look at what the function looks like (I've taken a sample as there's no reason to render every single point):
<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-4-1.png" width="672" />
There's two areas we'll need to take into consideration when integrating: from -2 to around -1.2, and from -1.2 to 2. We need to remember that when integrating, regions above the x-axis evaluate to positive numbers, but regions below evaluate to negative numbers. When calculating the total, we'll have to subtract that left region awat from the right region.

We're going to need the minimum and maximum values of \\(f(x)\\) in our calculate, so let's pull them out:

```r
min_max <-
    coords |> 
    summarise(
        min_y = min(y),
        max_y = max(y)
    ) 

min_max
```

```
## # A tibble: 1 × 2
##   min_y max_y
##   <dbl> <dbl>
## 1 -2.89  4.03
```
We can now move on to integrating this function.

# Statistical Integration

How are we going calculate a numerical answer to this integral? We'll take a stastical approach:

- Draw a number of random x and y values from a uniform distribution.
- Calculate \\(f(x)\\) for each of the random values.
- Determine whether the result is inside our outside of our integral areas.
- Find the ratio of points inside the areas versus points outside.
- Multiply this ratio by the size the total areas to find the definite integral area.




```r
total_area <- (2 - -2) * (min_max[['max_y']] - min_max[['min_y']])
total_area
```

```
## [1] 27.66986
```

    As mentioned before, we'll have to be wary of the area under the x-axis. We'll use an encoding shceme where points outside are encoded as 0, points inside the positive area are encoded as 1, and points inside the negative area are encoded as -1. When can then simply take the `mean()` of these encodings to derermine the ratio of the area. 

Here's a first pass with 50,000 points to show how it works. I've omitted the graph rendering code:


```r
ratio <-
    tibble(
        x = runif(50000, -2, 2),
        y = runif(50000, min_max[['min_y']], min_max[['max_y']]),
        fx = f(x)
    ) |> 
    mutate(
        integral_encoding = case_when(
            # Above the x-axis, below the curve
            fx > 0 & y < fx & y > 0 ~ 1,
            # Below the x-axis, above the curve
            fx < 0 & y > fx & y < 0 ~ -1,
            # Everything else
            TRUE ~ 0
        )
    )
```
<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-8-1.png" width="672" />

We can see all of our random points, and their associated encodings whether they're in the integral area or now. We'll do another run now but this time we'll use 100,000,000 points to increase our precision. We then summarise the mea



And the calculated ratio is (*drumroll*):


```r
integral_ratio
```

```
## [1] 0.1134008
```

Just above 11%. Multiplying this by the total area gives us the answer we need:


```r
total_area * integral_ratio
```

```
## [1] 3.137783
```
Immediately we something interesting about that number: it's very close to Pi. Remember we're here for a quick and dirty way to get the WiFi password, so my first guess would be the first 10 digits of Pi. 

Why didn't we get the value? Setting aside any mistakes I may have made in my calculations above, I'd guess that the number of random points isn't enough to get good enough precision. The reason I've not gone larger is I run out of memory trying to generate anything more than 100,000,000.

I have been a little deceptive, as there's actually a quick and easy way to approximate the definite integral in base R. It doesn't make for a very exciting article on its own:


```r
integrate(f, -2, 2)
```

```
## 3.141593 with absolute error < 2e-09
```

# Summary

In this post we looked at a numerical approach to calculating a definite integral. We generated random points and encoded them as to whether they were inside or outside of the integral area. We then used the ratio of this encoding and multiplied it by the total area of the region in question to get the answer.

If you're out and about in need of free WiFi and you see this question (or a question like it) posed to get access, don't be intimidated: go for the quick and dirty numerical approach. Either that, or get the first 10 digits of Pi from your phone and give that a crack.
