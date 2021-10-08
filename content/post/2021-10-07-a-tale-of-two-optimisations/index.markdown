---
title: 'A Tale Of Two Optimisations'
author: 'Greg Foletta'
date: '2021-09-20'
slug: 'a-tale-of-two-optimisations'
categories: [R, C]
---

A couple of month’s ago I wrote a toy program called ‘whitespacer.’ It takes bytes and encodes/decodes them from/to whitespace.

Ever since I wrote it, it’s been gnawing at me that it could have been written in a more performant manner. In this article we’re going to look at a couple of different ways of encoding and decoding the data. We’ll profile and visualise their different performances, then take a bit of a deep dive into their differences at the CPU level. Along the way we’ll become gain a better understanding about the `perf` performance analysis tool and how branch prediction affects performance.

# A Quick Recap

In [this previous article](/post/2021-06-21-whitespacer/) I took you through the *whitespcer* program. Here’s a quick recap of what it does:

-   Works in an ‘encoding’ and ‘decoding’ mode’.
-   Reads from stdin and writes to stdout.
-   In encoding mode, takes each of the four dibits (2 bits) of a byte and turns it into one of four whitespace characters.
    -   Characters are tab, newline, carraige return and space.
-   Decoding mode does the reverse, taking groups of four whitespace characters and reconstituting the original byte.

Here’s the encoding function that we’ll be looking to improve upon in this article.

``` c
//Dibit to whitesapce lookup table
char encode_lookup_tbl[] = { '\t', '\n', '\r', ' ' };

//Given a dibit, returns the whitespace encoding
unsigned char lookup_encode(const unsigned char dibit) {
    return encode_lookup_tbl[ dibit ];
}
```

The decoding function is the same but uses a different inverse table.

# Attempt 1: A Mathematical Function

What bothered me about the original implementation was the lookup table. Even though I knew they’d be cached, I thoguht the memory accesses to the lookup tables might have a detrimental affect on performance.

I thought if I could find a mathematical function to perform this mapping, rather than a lookup table, I might be able to save some time on memory accesses in the hot encoding and decoding loop.

From somewhere in the recesses of my brain I recalled that if we have a set of `\(k + 1\)` data points \\(x\_0, y\_0), , (x\_k, y\_k)\\) where no two \\(x\_i\\) are the same, we can fit a curve using a linear regression with a polynomial of degree \\(k\\). Here’s our table of data points:

<div id="atspdsoolc" style="overflow-x:auto;overflow-y:auto;width:30%;height:auto;">
<style>html {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Helvetica Neue', 'Fira Sans', 'Droid Sans', Arial, sans-serif;
}

#atspdsoolc .gt_table {
  display: table;
  border-collapse: collapse;
  margin-left: auto;
  margin-right: auto;
  color: #333333;
  font-size: 16px;
  font-weight: normal;
  font-style: normal;
  background-color: #FFFFFF;
  width: auto;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #A8A8A8;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #A8A8A8;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
}

#atspdsoolc .gt_heading {
  background-color: #FFFFFF;
  text-align: center;
  border-bottom-color: #FFFFFF;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}

#atspdsoolc .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#atspdsoolc .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 0;
  padding-bottom: 6px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#atspdsoolc .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#atspdsoolc .gt_col_headings {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}

#atspdsoolc .gt_col_heading {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 6px;
  padding-left: 5px;
  padding-right: 5px;
  overflow-x: hidden;
}

#atspdsoolc .gt_column_spanner_outer {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  padding-top: 0;
  padding-bottom: 0;
  padding-left: 4px;
  padding-right: 4px;
}

#atspdsoolc .gt_column_spanner_outer:first-child {
  padding-left: 0;
}

#atspdsoolc .gt_column_spanner_outer:last-child {
  padding-right: 0;
}

#atspdsoolc .gt_column_spanner {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 5px;
  overflow-x: hidden;
  display: inline-block;
  width: 100%;
}

#atspdsoolc .gt_group_heading {
  padding: 8px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
}

#atspdsoolc .gt_empty_group_heading {
  padding: 0.5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: middle;
}

#atspdsoolc .gt_from_md > :first-child {
  margin-top: 0;
}

#atspdsoolc .gt_from_md > :last-child {
  margin-bottom: 0;
}

#atspdsoolc .gt_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  margin: 10px;
  border-top-style: solid;
  border-top-width: 1px;
  border-top-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  overflow-x: hidden;
}

#atspdsoolc .gt_stub {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 12px;
}

#atspdsoolc .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#atspdsoolc .gt_first_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
}

#atspdsoolc .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#atspdsoolc .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}

#atspdsoolc .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}

#atspdsoolc .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#atspdsoolc .gt_footnotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}

#atspdsoolc .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding: 4px;
}

#atspdsoolc .gt_sourcenotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}

#atspdsoolc .gt_sourcenote {
  font-size: 90%;
  padding: 4px;
}

#atspdsoolc .gt_left {
  text-align: left;
}

#atspdsoolc .gt_center {
  text-align: center;
}

#atspdsoolc .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#atspdsoolc .gt_font_normal {
  font-weight: normal;
}

#atspdsoolc .gt_font_bold {
  font-weight: bold;
}

#atspdsoolc .gt_font_italic {
  font-style: italic;
}

#atspdsoolc .gt_super {
  font-size: 65%;
}

#atspdsoolc .gt_footnote_marks {
  font-style: italic;
  font-weight: normal;
  font-size: 65%;
}
</style>
<table class="gt_table">
  
  <thead class="gt_col_headings">
    <tr>
      <th class="gt_col_heading gt_columns_bottom_border gt_center" rowspan="1" colspan="1">Dibit</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_center" rowspan="1" colspan="1">ASCII Decimal Value</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr><td class="gt_row gt_center">0</td>
<td class="gt_row gt_center">9</td></tr>
    <tr><td class="gt_row gt_center">1</td>
<td class="gt_row gt_center">10</td></tr>
    <tr><td class="gt_row gt_center">2</td>
<td class="gt_row gt_center">13</td></tr>
    <tr><td class="gt_row gt_center">3</td>
<td class="gt_row gt_center">32</td></tr>
  </tbody>
  
  
</table>
</div>

This means we can find \\(\\) coefficients for the function
$$ f(x) = \beta_0 + \beta_1 x + \beta_2 x^2 + \beta_3 x^3 $$
such that when passed a dibit value it returns the appropriate whitespace character. We can also find the inverse polynomial \\f^{-1}(x)\\) which takes a whitespace character and returns a dibit to be our decoding function. Let’s create these models in R, where `whitespace` is a tibble holding our dibit and whitespace values.

``` r
encode_model <-
    whitespace %>% 
    lm(ascii_dec ~ dibit + I(dibit^2) + I(dibit^3), data = .)

decode_model <-
    whitespace %>% 
    lm(dibit ~ ascii_dec + I(ascii_dec^2) + I(ascii_dec^3), data = .)
```

Visualising these models will help us see what’s going on. On the left is out encoding function, which takes out dibit values and maps them to our ASCII whitespace characters. On the right is the inverse function, which takes the ASCII whitespace characters’ decimal value and maps it back to a dibit. These show that outside of these data points the functions make little sense.

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-4-1.png" width="672" />

Let’s take a look at the \\(\\) coefficients:

``` r
tibble(
    parameter = c('beta_0', 'beta_1', 'beta_2', 'beta_3'),
    encode = encode_model %>% coef(),
    decode = decode_model %>% coef()
) %>% 
    gt() %>% 
    cols_label(
        parameter = 'Parameter',
        encode = 'Encoding',
        decode = 'Decoding'
    ) %>% 
    cols_align('center') %>% 
    tab_options(container.width = '50%')
```

<div id="lnknvxcsag" style="overflow-x:auto;overflow-y:auto;width:50%;height:auto;">
<style>html {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Helvetica Neue', 'Fira Sans', 'Droid Sans', Arial, sans-serif;
}

#lnknvxcsag .gt_table {
  display: table;
  border-collapse: collapse;
  margin-left: auto;
  margin-right: auto;
  color: #333333;
  font-size: 16px;
  font-weight: normal;
  font-style: normal;
  background-color: #FFFFFF;
  width: auto;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #A8A8A8;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #A8A8A8;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
}

#lnknvxcsag .gt_heading {
  background-color: #FFFFFF;
  text-align: center;
  border-bottom-color: #FFFFFF;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}

#lnknvxcsag .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#lnknvxcsag .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 0;
  padding-bottom: 6px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#lnknvxcsag .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#lnknvxcsag .gt_col_headings {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}

#lnknvxcsag .gt_col_heading {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 6px;
  padding-left: 5px;
  padding-right: 5px;
  overflow-x: hidden;
}

#lnknvxcsag .gt_column_spanner_outer {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  padding-top: 0;
  padding-bottom: 0;
  padding-left: 4px;
  padding-right: 4px;
}

#lnknvxcsag .gt_column_spanner_outer:first-child {
  padding-left: 0;
}

#lnknvxcsag .gt_column_spanner_outer:last-child {
  padding-right: 0;
}

#lnknvxcsag .gt_column_spanner {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 5px;
  overflow-x: hidden;
  display: inline-block;
  width: 100%;
}

#lnknvxcsag .gt_group_heading {
  padding: 8px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
}

#lnknvxcsag .gt_empty_group_heading {
  padding: 0.5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: middle;
}

#lnknvxcsag .gt_from_md > :first-child {
  margin-top: 0;
}

#lnknvxcsag .gt_from_md > :last-child {
  margin-bottom: 0;
}

#lnknvxcsag .gt_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  margin: 10px;
  border-top-style: solid;
  border-top-width: 1px;
  border-top-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  overflow-x: hidden;
}

#lnknvxcsag .gt_stub {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 12px;
}

#lnknvxcsag .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#lnknvxcsag .gt_first_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
}

#lnknvxcsag .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#lnknvxcsag .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}

#lnknvxcsag .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}

#lnknvxcsag .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#lnknvxcsag .gt_footnotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}

#lnknvxcsag .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding: 4px;
}

#lnknvxcsag .gt_sourcenotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}

#lnknvxcsag .gt_sourcenote {
  font-size: 90%;
  padding: 4px;
}

#lnknvxcsag .gt_left {
  text-align: left;
}

#lnknvxcsag .gt_center {
  text-align: center;
}

#lnknvxcsag .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#lnknvxcsag .gt_font_normal {
  font-weight: normal;
}

#lnknvxcsag .gt_font_bold {
  font-weight: bold;
}

#lnknvxcsag .gt_font_italic {
  font-style: italic;
}

#lnknvxcsag .gt_super {
  font-size: 65%;
}

#lnknvxcsag .gt_footnote_marks {
  font-style: italic;
  font-weight: normal;
  font-size: 65%;
}
</style>
<table class="gt_table">
  
  <thead class="gt_col_headings">
    <tr>
      <th class="gt_col_heading gt_columns_bottom_border gt_center" rowspan="1" colspan="1">Parameter</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_center" rowspan="1" colspan="1">Encoding</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_center" rowspan="1" colspan="1">Decoding</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr><td class="gt_row gt_center">beta_0</td>
<td class="gt_row gt_center">9.000000</td>
<td class="gt_row gt_center">-31.82920741</td></tr>
    <tr><td class="gt_row gt_center">beta_1</td>
<td class="gt_row gt_center">4.666667</td>
<td class="gt_row gt_center">6.42174606</td></tr>
    <tr><td class="gt_row gt_center">beta_2</td>
<td class="gt_row gt_center">-6.000000</td>
<td class="gt_row gt_center">-0.38079884</td></tr>
    <tr><td class="gt_row gt_center">beta_3</td>
<td class="gt_row gt_center">2.333333</td>
<td class="gt_row gt_center">0.00669163</td></tr>
  </tbody>
  
  
</table>
</div>

Immediately we see a bit of a problem. I’ll be honest in that I was hoping - somewhat optimistically - that I would get some nice, clean integer coefficients, but instead we’ve got floating point values. My gut feel is that having to use floating point instructions is not going to improve upon our original lookup table. But we won’t know until we profile, so let’s persist. Here’s the new encoding function:

``` c
unsigned char poly_encode(const unsigned char dibit) {
    return (unsigned char) (9.0 + 
    4.666667 * dibit - 
    6.0 * (dibit * dibit) + 
    2.333333333333 * (dibit * dibit * dibit));
}
```

We don’t need to hit the mark exactly, we just need to get close enough so that the whole part is correct. The cast to `usigned char` will give us this whole part, throwing away any values after the decimal point.

# Attempt 2: A Switch

While working on the polynomial function, it struck me that we could also simply use a switch statement. It looks at the value of the dibit and returns the whitespace character. Here’s the implementation of the encoding function:

``` c
unsigned char switch_encode(const unsigned char dibit) {
    switch (dibit) {
        case 0:
            return '\t';
        case 1:
            return '\n';
        case 2:
            return '\r';
        case 3:
            return ' ';
    }
}
```

We also need need a way to select the algorithm the program uses at runtime. A command line option *-a <algorithm>* has been added, where <algorithm> is either ‘lookup,’ ‘poly’ or ‘switch.’ If none is specified it defaults to the original lookup table.

# Profiling

Rather than supposition, let’s test how the different alogrithms perform. I’ve created a sm. I’ve created a small R function which takes a vector of shell commands and returns how long they took to run. There’s a small amount of overhead in spawning a shell, but this is constant across and as we’re looking at he *differences* between the runtimes, it gets cancelled out.

``` r
system_profile <- function(commands) {
    map_dbl(commands, ~{
        start <- proc.time()["elapsed"] 
        system(.x, ignore.stdout = TRUE)
        finish <- proc.time()["elapsed"]
        finish - start
    })
}
```

We run 200 iterations of an encode / decode pipeline for each algorithm, piping in a 32Mb file of random bytes generated from */dev/urandom*. The output is dumped to */dev/null*.

``` r
profiling_results <-
    tibble(
        n = 1:600,
        algo = rep(c('lookup', 'poly', 'switch'), max(n) / 3)
    ) %>% 
    mutate(
            command = glue('cat urandom_32M | ./ws_debug -a { algo } {n} | ./ws_debug -d -a { algo } > /dev/null'),
            time = system_profile(command)
    ) %>% 
    select(-command)
```

Rather than simply looking at the means or medians for each of the algorithms, we take a look at the distribution of runtimes for each with the mean highlighted.

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-8-1.png" width="672" />

As expected, the polynomial encoding/decoding is slower than the lookup table. But what is really surprising is that the switch statement: its slower than both! On average it’s taking over one second more to encode and decode the 32M file. I love a good surprise, so let’s dive in and find out what happening.

# What’s With The Switch?

I took a bottom-up approach to trying to solve this mystery. This made sense because:

1.  I was the one that wrote it.
2.  The cod is simple and
3.  This is a learning experience.

In most other scenarios I think a top-down approach would be the more efficient.

The approach taken was to first take a look at the instructions that were being executed on the CPU as the program was running. We can use `perf record` execute the program take samples of it’s state, which on my machine will use the *Precise Event Based Sampling (PEBS)* Intel feature. At a certain frequency (default 4000Hz, based on an overflowing counter) the PEBS will write processor state (CPU ID, instruction pointer, register values, etc) to a buffer, issue an interrupt, and perf will read these values.

By using the `-b` switch, perf also captures the *Last Branch Record (LBR) stack*. With the LBR processor feature, the CPU logs a set of *from* and *to* address of branches taken (predicted and mispredicted) to a set of special purpose registers in a ring buffer (my CPU has 32 entries in the ruing buffer). With this information perf can reconstitute the history of instructions executed on the CPU, rather than only having a single point - the instruction pointer - to use from the sample.

Perf runs the whitespacer encoding half of the pipeline, and is fed 32Mb of random bytes.

``` sh
perf record -b -o switch.data -e cycles:pp ./ws_debug -a switch < urandom_32M > /dev/null
[ perf record: Woken up 22 times to write data ]
[ perf record: Captured and wrote 5.345 MB switch.data (6833 samples) ]
```

Looking at the trace data (saved in *switch.data*), the *brstackins* field allows us to see the assembly instructions executed along the branches of the branch stack. Perf has captures around 43,000 executions of our `switch_encode()` function. Here’s the output from one of them:

``` sh
perf script -F +brstackinsn -i switch.data
```

``` asm
switch_encode:
0000560dd2bffddd        insn: 55 
0000560dd2bffdde        insn: 48 89 e5 
0000560dd2bffde1        insn: 89 f8 
0000560dd2bffde3        insn: 88 45 fc 
0000560dd2bffde6        insn: 0f b6 45 fc 
0000560dd2bffdea        insn: 83 f8 01 
0000560dd2bffded        insn: 74 1e                     # MISPRED 4 cycles 1.50 IPC
0000560dd2bffe0d        insn: b8 0a 00 00 00 
0000560dd2bffe12        insn: eb 0e                     # PRED 22 cycles 0.05 IPC
0000560dd2bffe22        insn: 5d 
0000560dd2bffe23        insn: c3                        # PRED 5 cycles 0.20 IPC
```

The thing that stands out immediately is the misprediction, and the wopping 22 cycles in the other predicted branch. Let’s take a step back and run the `perf stat` command to pull out to pull out some summaries:

``` sh
# Perf stat with 32Mb urandom bytes
perf stat ./ws_debug -a switch < urandom_32M > /dev/null       
```

    ## 
    ##  Performance counter stats for './ws_debug -a switch':
    ## 
    ##        1658.055170      task-clock (msec)         #    0.999 CPUs utilized          
    ##                  4      context-switches          #    0.002 K/sec                  
    ##                  0      cpu-migrations            #    0.000 K/sec                  
    ##             12,852      page-faults               #    0.008 M/sec                  
    ##      6,317,437,770      cycles                    #    3.810 GHz                    
    ##      5,772,191,219      instructions              #    0.91  insn per cycle         
    ##        967,643,280      branches                  #  583.601 M/sec                  
    ##        121,900,789      branch-misses             #   12.60% of all branches        
    ## 
    ##        1.659130589 seconds time elapsed

The first statistic that should conern us is the instructions per cycle, which is just under one. The second is the numbner of branch misses, which is up at 12.56%. Put simply, we’re not getting much bang for our buck when it comes to predicting branches.

The hypothesis at this point is that given our data is random and uniformly distributed, combined with the branching (the C switch statement) used to encode the data, the branch predictor is performing poorly, and so is our performance.

To confirm this hypothesis, let’s create an input file of all zeros and see how it performs.

``` zsh
# Perf stat with 32Mb of zero bytes
perf stat ./ws_debug -a switch < zero_32M > /dev/null
```

    ## 
    ##  Performance counter stats for './ws_debug -a switch':
    ## 
    ##         462.646730      task-clock (msec)         #    0.999 CPUs utilized          
    ##                  1      context-switches          #    0.002 K/sec                  
    ##                  0      cpu-migrations            #    0.000 K/sec                  
    ##             12,852      page-faults               #    0.028 M/sec                  
    ##      1,785,116,443      cycles                    #    3.858 GHz                    
    ##      5,835,314,253      instructions              #    3.27  insn per cycle         
    ##        999,506,500      branches                  # 2160.410 M/sec                  
    ##            171,532      branch-misses             #    0.02% of all branches        
    ## 
    ##        0.463012748 seconds time elapsed

``` r
profiling_results <-
    tibble(
        n = 1:30,
        algo = rep(c('lookup', 'poly', 'switch'), max(n) / 3)
    ) %>% 
    mutate(
            command = glue('cat zero_32M | ./ws_debug -a { algo } {n} | ./ws_debug -d -a { algo } > /dev/null'),
            time = system_profile(command)
    ) %>% 
    select(-command)
    
profiling_means <-
    profiling_results %>% 
    group_by(algo) %>% 
    summarise(mean = mean(time))

profiling_results %>% 
    ggplot() +
    geom_density(aes(time, fill = algo), alpha = .4) +
    geom_vline(data = profiling_means, aes(xintercept = mean, colour = algo)) +
    geom_label(data = profiling_means, aes(x = mean, y = 0, label = round(mean, 2))) +
    labs(
        x = 'Seconds',
        y = 'Density',
        title = 'Whitespacer Algorithms - Performance',
        subtitle = 'Encode/Decode 32Mb of zero bytes',
        fill = 'Algorithm',
        colour = 'Algorithm'
    )
```

<img src="{{< blogdown/postref >}}index_files/figure-html/zero_profiling-1.png" width="672" />

There we go - the number of instructions has remained almost the same, but we’re getting 3.2 instructions per cycle. This appears to be due to the number of branch misses approaching 0.

I’ll be honest and say that at this point I’m butting up against the limits of my CPU architecture knowledge. I thought that branch predictions were a zero-cost optimisation, and that mispredicted branches didn’t have any side effects. If anyone has any more information or theories on this please [reach out](mailto:greg@foletta.org).

# Lookup versus Polynomial

Now let’s take a look at the unsurprising result: our original lookup algorithm versus the polynomial. We’ll go straight to using `perf stat` to see high-level statistics:

``` zsh
# Lookup table 
perf stat ./ws_debug -a lookup < urandom_32M > /dev/null
```

    ## 
    ##  Performance counter stats for './ws_debug -a lookup':
    ## 
    ##         462.481227      task-clock (msec)         #    0.999 CPUs utilized          
    ##                  0      context-switches          #    0.000 K/sec                  
    ##                  0      cpu-migrations            #    0.000 K/sec                  
    ##             12,852      page-faults               #    0.028 M/sec                  
    ##      1,687,558,028      cycles                    #    3.649 GHz                    
    ##      5,195,104,985      instructions              #    3.08  insn per cycle         
    ##        487,489,417      branches                  # 1054.074 M/sec                  
    ##             97,701      branch-misses             #    0.02% of all branches        
    ## 
    ##        0.463036330 seconds time elapsed

``` zsh
# Polynomial
perf stat ./ws_debug -a poly < urandom_32M > /dev/null
```

    ## 
    ##  Performance counter stats for './ws_debug -a poly':
    ## 
    ##         968.111096      task-clock (msec)         #    0.999 CPUs utilized          
    ##                  7      context-switches          #    0.007 K/sec                  
    ##                  0      cpu-migrations            #    0.000 K/sec                  
    ##             12,852      page-faults               #    0.013 M/sec                  
    ##      3,746,605,851      cycles                    #    3.870 GHz                    
    ##      7,755,261,498      instructions              #    2.07  insn per cycle         
    ##        487,451,809      branches                  #  503.508 M/sec                  
    ##            104,295      branch-misses             #    0.02% of all branches        
    ## 
    ##        0.968726968 seconds time elapsed

We see two main reasons as to why the polynomial is slower. First off it simply takes for instructions to calculate the polynomial, as compared to simply looking up the value in a lookup table. Secondly, this increase in instructions is compounded by that fact that we’re getting less instructions per seconds.

# Summary

In this article we looked at two different alternatives to a lookup table for encoding and decoding bytes in the *whitespacer* program. The fist was to try and use a polynomial function, and the seconds was to use a switch statement rather than a lookup table.
