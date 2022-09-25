---
title: Lebesgue Curves
author: Greg Foletta
date: '2022-10-19'
slug: lebesgue-curves
categories: [R, C]
---



First up a note: this post is a sidebar for another article I'm currently writing. There aren't any grand conclusions or deep insights, it's more exploratory.

I needed a way to map a one-dimensional number on to two-dimensional space. This mapping could then be used visualise an process that returned a one-dimensional numbner.

I was going to reach for the space-filling Hilbert curve à la the [XKCD "Map of the Internet"](https://xkcd.com/195/), but whist researching I discovered the [Lebesgue Curve](https://en.wikipedia.org/wiki/Z-order_curve), also known as the *Z-order* or *Morton* curve. It looked to have reasonable locality, and its inherent binary nature implied it was simple to implement. 

In this article I'll implement the Lebesgue curve and explore some of its properties.

# Lebesgue Curve 

The Lebesgue curve maps an integer \\(Z\\) into two or more integers we'll call \\(x\\) and \\(y\\). In can also be used in reverse to map two or more integers back into a single integer.

The algorithm is relatively simple:

- Take an \\(n\\) bit integer \\(Z\\)
- Mask the even bits \\([0, 2, \ldots, n - 2]\\) into \\(x\\)
- Mask the odd bits \\([1, 2, \ldots, n - 1]\\) into \\(y\\)
- Collapse/shift the masked bits down so that they are "next" to each other
    - This results in an \\(\frac{n}{2}\\) bit integer

The `lebesgue_coords()` "C inside Rcpp" function below implements the algorithm. I've then vectorised it in the `lebesgue()` function that returns a list of \\(x\\) and \\(y\\) coordinates for each \\(z\\) integer, exported using Rcpp. It's not the most optimal algorithm, but I've (hopefully) traded off time for clarity.


```cpp
#include <Rcpp.h>
using namespace Rcpp;

//The x,y vertice generated from the single z value
struct vert { unsigned long x; unsigned long y; };

//Lebesgue calculation for a single z value
struct vert lebesgue_coords(unsigned long z) {
    struct vert coords;
    unsigned long shift_mask;
    
    //Mask out even bits
    coords.x = z & 0x55555555;
    //Mask out odd bits, then shift back
    coords.y = (z & 0xaaaaaaaa) >> 1;
    
    shift_mask = 0xfffffffc;
    //Compress the bits together
    do {
        //Extract the top bits, then shift them down one
        long int x_upper = (coords.x & shift_mask) >> 1;
        //Clear out the top bits from x and re-introduce
        //the shift top bits, thereby compressing them together
        coords.x = x_upper | (coords.x & ~shift_mask) ;

        //Same as above for y
        long int y_upper = (coords.y & shift_mask) >> 1;
        coords.y = y_upper | (coords.y & ~shift_mask);
    } while (shift_mask <<= 1);
    
    return coords;
}

// [[Rcpp::export]]
List lebesgue(IntegerVector z) {
    int i;
    struct vert v;
    IntegerVector x,y;
    
    for (i = 0; i < z.size(); i++) {
        v = lebesgue_coords(z[i]);
        x.push_back(v.x);
        y.push_back(v.y);
    }
    return List::create(Named("x") = x, Named("y") = y);
}
```

With this function, let's calculate the two-dimensional coordinates for the integers from 0 to 1023:


```r
lebesgue_points <-
tibble(z = 0:102) |> 
    mutate(l = as_tibble(lebesgue(z))) |> 
    unnest(l)

print(lebesgue_points)
```

```
# A tibble: 103 × 3
       z     x     y
   <int> <int> <int>
 1     0     0     0
 2     1     1     0
 3     2     0     1
 4     3     1     1
 5     4     2     0
 6     5     3     0
 7     6     2     1
 8     7     3     1
 9     8     0     2
10     9     1     2
# … with 93 more rows
```

An animation of these shows the fractal like behaviour of the curve, with groups of 4, 16, and 64 having a similar two-dimensional structure.


```
geom_path: Each group consists of only one observation. Do you need to adjust
the group aesthetic?
geom_path: Each group consists of only one observation. Do you need to adjust
the group aesthetic?
```

![](index_files/figure-html/unnamed-chunk-4-1.gif)<!-- -->

# Locality

I mentioned at the start that the Lebesgue has good locality: points that are close in one-dimension should be close in two-dimensions. Let's see how it fares.

We take the points we generated previously and see how far each \\((x_{z},y_{z})\\) pair is away from \\((x_{z-1}, y_{z-1})\\) using the good old Pythagoras:

$$ d = \sqrt{(x_2 - x_1)^2 + (y_2 - y_1)^2} $$


```r
lebesgue_locality <-
    lebesgue_points |>
    mutate(
        coord_distance = sqrt(
            (x - lag(x,1))^2 +
            (y - lag(y,1))^2
        )
    ) |> 
    filter(!is.na(coord_distance))

lebesgue_locality |> 
    summarise(mean_distance = mean(coord_distance))
```

```
# A tibble: 1 × 1
  mean_distance
          <dbl>
1          1.53
```
On average, each point is 1.55 times further away in the two dimensional representation that in the one-dimensional representation. But as we all (should) know, an average is a summary and hides specifics. Taking a look at \\(z\)) versus the distance paints a more accurate picture of the underlying process:

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-6-1.png" width="672" />
Locality is good, except every so often we get a spike of distance between points. This spike is where we're moving between our different power-of-two regions: \\(2^4, 2^6, 2^8, \ldots\\). For a different perspective, we map our two-dimensional points with colour and size conveying the distance:

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-7-1.png" width="672" />

I don't have a quantitative metric on hand that defines what "good" locality would be. So at this point I'll hand wave over this and saay "it looks good enough".

# Additive Properties

Finally, we'll look at some additive properties that yielded an interesting result. As part of the article I am using the Lebesgue curve in, a really useful property would have been this:

$$ l(a + b) = l(a) + l(b) $$


```r
equality <-
    crossing(a = 0:127, b = 0:127) |> 
    mutate(
        x = (lebesgue(a + b))$x == (lebesgue(a)$x + lebesgue(b)$x),
        y = (lebesgue(a + b))$y == (lebesgue(a)$y + lebesgue(b)$y)
    ) |>
    pivot_longer(cols = c(x, y), names_to = 'coord', values_to = 'equality')

print(equality)
```

```
# A tibble: 32,768 × 4
       a     b coord equality
   <int> <int> <chr> <lgl>   
 1     0     0 x     TRUE    
 2     0     0 y     TRUE    
 3     0     1 x     TRUE    
 4     0     1 y     TRUE    
 5     0     2 x     TRUE    
 6     0     2 y     TRUE    
 7     0     3 x     TRUE    
 8     0     3 y     TRUE    
 9     0     4 x     TRUE    
10     0     4 y     TRUE    
# … with 32,758 more rows
```
<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-9-1.png" width="672" />


# Summary
