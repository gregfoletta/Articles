---
title: 'Too Clever By Half: An Optimisation Story'
author: 'Greg Foletta'
date: '2021-09-20'
slug: 'too-clever-by-half'
categories: [R, C]
---

A couple of month’s ago I wrote a toy program called ‘whitespacer.’ It takes bytes and encodes/decodes them from/to whitespace.

Ever since I wrote it, it had been gnawing at me as to whether I could have written it in a more performant manner. I had an idea about trying to define a mathematical function that could perform the encoding, rather than relying on a lookup table.

This article has somewhat of a multiple personality. In the first half I’ll work through attempting to optimise the program and benchmarking it. But the benchmarking revealed something interesting about branch prediction that I felt needed to be investigated as well, so in the second half we’ll take a diversion into that.

I’m hoping that the two sections aren’t too disjointed.

# Translation Function

In the first iteration of the whitespacer program I used lookup tables to encode/decode the bytes. One lookup table took a dibit (two bits) of value 0 - 3 and mapped this to a whitespace character. Another lookup table did the inverse.

I thought if I could find a mathematical function to perform this mapping, rather than a lookup table, I might be able to save some time on memory accesses in the hot encoding and decoding loop.

From somewhere in the recesses of my brain I recalled Lagrange polynomials: if we have a set of `\(k + 1\)` data points `\((x_0, y_0), \ldots, (x_k, y_k)\)` where no two `\(x_i\)` are the same, a polynomial of degree `\(k\)` or less can be defined that passes through all the points. For us that means I can define a function:

$$ f(x) = \beta_0 + \beta_1 x + \beta_2 x^2 + \beta_3 x^3 $$

which takes a dibit of 0, 1, 2 or 3 and returns the appropriate whitespace character. I can also define the inverse function (with differing `\(\beta\)` coefficients) which does the inverse. Outside of the `\([0, 3]\)` range the function won’t make much sense, but that fine for our use case.

<div id="xgywowsntd" style="overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>html {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Helvetica Neue', 'Fira Sans', 'Droid Sans', Arial, sans-serif;
}

#xgywowsntd .gt_table {
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

#xgywowsntd .gt_heading {
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

#xgywowsntd .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#xgywowsntd .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 0;
  padding-bottom: 6px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#xgywowsntd .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#xgywowsntd .gt_col_headings {
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

#xgywowsntd .gt_col_heading {
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

#xgywowsntd .gt_column_spanner_outer {
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

#xgywowsntd .gt_column_spanner_outer:first-child {
  padding-left: 0;
}

#xgywowsntd .gt_column_spanner_outer:last-child {
  padding-right: 0;
}

#xgywowsntd .gt_column_spanner {
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

#xgywowsntd .gt_group_heading {
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

#xgywowsntd .gt_empty_group_heading {
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

#xgywowsntd .gt_from_md > :first-child {
  margin-top: 0;
}

#xgywowsntd .gt_from_md > :last-child {
  margin-bottom: 0;
}

#xgywowsntd .gt_row {
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

#xgywowsntd .gt_stub {
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

#xgywowsntd .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#xgywowsntd .gt_first_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
}

#xgywowsntd .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#xgywowsntd .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}

#xgywowsntd .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}

#xgywowsntd .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#xgywowsntd .gt_footnotes {
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

#xgywowsntd .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding: 4px;
}

#xgywowsntd .gt_sourcenotes {
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

#xgywowsntd .gt_sourcenote {
  font-size: 90%;
  padding: 4px;
}

#xgywowsntd .gt_left {
  text-align: left;
}

#xgywowsntd .gt_center {
  text-align: center;
}

#xgywowsntd .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#xgywowsntd .gt_font_normal {
  font-weight: normal;
}

#xgywowsntd .gt_font_bold {
  font-weight: bold;
}

#xgywowsntd .gt_font_italic {
  font-style: italic;
}

#xgywowsntd .gt_super {
  font-size: 65%;
}

#xgywowsntd .gt_footnote_marks {
  font-style: italic;
  font-weight: normal;
  font-size: 65%;
}
</style>
<table class="gt_table">
  
  <thead class="gt_col_headings">
    <tr>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">Dibit</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">ASCII Decimal Value</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr><td class="gt_row gt_right">0</td>
<td class="gt_row gt_right">9</td></tr>
    <tr><td class="gt_row gt_right">1</td>
<td class="gt_row gt_right">10</td></tr>
    <tr><td class="gt_row gt_right">2</td>
<td class="gt_row gt_right">13</td></tr>
    <tr><td class="gt_row gt_right">3</td>
<td class="gt_row gt_right">32</td></tr>
  </tbody>
  
  
</table>
</div>

I now create two models: one for encoding, and one for decoding. I’m using a linear regression rather than the Lagrange polynomial formula, but the results are the same.

``` r
encode_model <-
    whitespace %>% 
    lm(ascii_dec ~ dibit + I(dibit^2) + I(dibit^3), data = .)

decode_model <-
    whitespace %>% 
    lm(dibit ~ ascii_dec + I(ascii_dec^2) + I(ascii_dec^3), data = .)
```

Visualising these models will help us see what’s going on. On the left is out encoding function, which takes out dibit values and maps them to our ASCII whitespace characters. On the right is the inverse function, which takes the ASCII whitespace characters’ decimal value and maps it back to a dibit. This function shows how the function makes little sense outside of our four defined values.

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-4-1.png" width="672" />

Let’s take a look at the `\(\beta\)` coefficients.

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
    )
```

<div id="xpitxqzhnd" style="overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>html {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Helvetica Neue', 'Fira Sans', 'Droid Sans', Arial, sans-serif;
}

#xpitxqzhnd .gt_table {
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

#xpitxqzhnd .gt_heading {
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

#xpitxqzhnd .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#xpitxqzhnd .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 0;
  padding-bottom: 6px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#xpitxqzhnd .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#xpitxqzhnd .gt_col_headings {
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

#xpitxqzhnd .gt_col_heading {
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

#xpitxqzhnd .gt_column_spanner_outer {
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

#xpitxqzhnd .gt_column_spanner_outer:first-child {
  padding-left: 0;
}

#xpitxqzhnd .gt_column_spanner_outer:last-child {
  padding-right: 0;
}

#xpitxqzhnd .gt_column_spanner {
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

#xpitxqzhnd .gt_group_heading {
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

#xpitxqzhnd .gt_empty_group_heading {
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

#xpitxqzhnd .gt_from_md > :first-child {
  margin-top: 0;
}

#xpitxqzhnd .gt_from_md > :last-child {
  margin-bottom: 0;
}

#xpitxqzhnd .gt_row {
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

#xpitxqzhnd .gt_stub {
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

#xpitxqzhnd .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#xpitxqzhnd .gt_first_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
}

#xpitxqzhnd .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#xpitxqzhnd .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}

#xpitxqzhnd .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}

#xpitxqzhnd .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#xpitxqzhnd .gt_footnotes {
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

#xpitxqzhnd .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding: 4px;
}

#xpitxqzhnd .gt_sourcenotes {
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

#xpitxqzhnd .gt_sourcenote {
  font-size: 90%;
  padding: 4px;
}

#xpitxqzhnd .gt_left {
  text-align: left;
}

#xpitxqzhnd .gt_center {
  text-align: center;
}

#xpitxqzhnd .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#xpitxqzhnd .gt_font_normal {
  font-weight: normal;
}

#xpitxqzhnd .gt_font_bold {
  font-weight: bold;
}

#xpitxqzhnd .gt_font_italic {
  font-style: italic;
}

#xpitxqzhnd .gt_super {
  font-size: 65%;
}

#xpitxqzhnd .gt_footnote_marks {
  font-style: italic;
  font-weight: normal;
  font-size: 65%;
}
</style>
<table class="gt_table">
  
  <thead class="gt_col_headings">
    <tr>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1">Parameter</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">Encoding</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1">Decoding</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr><td class="gt_row gt_left">beta_0</td>
<td class="gt_row gt_right">9.000000</td>
<td class="gt_row gt_right">-31.82920741</td></tr>
    <tr><td class="gt_row gt_left">beta_1</td>
<td class="gt_row gt_right">4.666667</td>
<td class="gt_row gt_right">6.42174606</td></tr>
    <tr><td class="gt_row gt_left">beta_2</td>
<td class="gt_row gt_right">-6.000000</td>
<td class="gt_row gt_right">-0.38079884</td></tr>
    <tr><td class="gt_row gt_left">beta_3</td>
<td class="gt_row gt_right">2.333333</td>
<td class="gt_row gt_right">0.00669163</td></tr>
  </tbody>
  
  
</table>
</div>

We have a bit of a problem. I’ll be honest, I was hoping - somewhat optimistically - that I would get some nice, clean integer coefficients to work work.

``` c
unsigned char poly_encode(const unsigned char dibit) {
    return 9.0 + 4.666667 * dibit - 6.0 * (dibit * dibit) + 2.333333333333 * (dibit * dibit * dibit);
}
```

# What About a Switch?

While working on the polynomial functions, I the thought that, rather than using a lookup table or a mathematical function, I simply use a switch statement. It looks at the value of the dibit and simply returns the whitespace character. Here’s the implementation of the encoding function:

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

Finally, we need a way to select the algorithm the program uses at runtime. I added the ‘-a <algorithm>’ command line argument to allow this selection, where <algorithm> is either ‘lookup,’ ‘poly’ or ‘switch’ to select the algorithm to use. If none is specified it defaults to the original lookup table.

# Profiling

Rather than supposition, let’s test our assumptions and see where they land. I’ve created a small R function which takes a vector of shell commands and returns how long they took to run. There’s a small amount of overhead in spawning a shell, but this is constant across and as we’re looking at he *differences* between the runtimes, it gets cancelled out.

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

I run 500 iterations of an encode / decode pipeline for each algorithm. I pipe in a 32Mb file of random bytes generated from */dev/urandom*, and piping the output to */dev/null*. We end up with a table of 1500 rows with the time it took to run this pipeline.

``` r
profiling_results <-
    tibble(
        n = 1:30,
        algo = rep(c('lookup', 'poly', 'switch'), max(n) / 3)
    ) %>% 
    mutate(
            command = glue('cat urandom_32M | ./ws -a { algo } | ./ws -d -a { algo } > /dev/null'),
            time = system_profile(command)
    ) %>% 
    select(-command)
```

Rather than simply looking at the means or medians for each of the algorithms, we take a look at the distribution of runtimes for each with the mean highlighted.

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-8-1.png" width="672" />

# What’s With The Switch?

So what is going on with this switch implementation? I took a bottom-up approach to trying to solve this mystery. This made sense because:

1.  I was the one that wrote it.
2.  It was a very simple, and
3.  I was using this as a learning experience.

I would recommend a more top-down approach in any other situation.

This bottom up appraoch was to first take a look at the instructions that were being executed on the CPU as the program was running. This can be done using `perf record`:

``` sh
perf record -b -o switch -e cycles ./ws_debug -a switch < urandom_32M > /dev/null
[ perf record: Woken up 22 times to write data ]
[ perf record: Captured and wrote 5.345 MB switch.data (6833 samples) ]
```

This is sampling the CPU 4000 times a second (the default, changed with the -F argument) and determining where the instruction pointer is, and approximately how many CPU cycles have ocurred since the last sample.

``` sh
perf script -F +brstackinsn -f -i switch.data
```

``` asm
        switch_encode:
        0000556e3cfa7ddd        insn: 55 
        0000556e3cfa7dde        insn: 48 89 e5 
        0000556e3cfa7de1        insn: 89 f8 
        0000556e3cfa7de3        insn: 88 45 fc 
        0000556e3cfa7de6        insn: 0f b6 45 fc 
        0000556e3cfa7dea        insn: 83 f8 01 
        0000556e3cfa7ded        insn: 74 1e 
        0000556e3cfa7def        insn: 83 f8 01 
        0000556e3cfa7df2        insn: 7f 06                     # PRED 6 cycles 1.33 IPC
        0000556e3cfa7dfa        insn: 83 f8 02 
        0000556e3cfa7dfd        insn: 74 15                     # MISPRED 1 cycles 1.00 IPC
        0000556e3cfa7e14        insn: b8 0d 00 00 00 
        0000556e3cfa7e19        insn: eb 07                     # PRED 18 cycles 0.06 IPC
        0000556e3cfa7e22        insn: 5d 
        0000556e3cfa7e23        insn: c3                        # PRED 5 cycles 0.20 IPC
```

``` sh
# Perf stat with 32Mb urandom bytes
perf stat ./ws_debug -a switch < urandom_32M > /dev/null       
```

    ## 
    ##  Performance counter stats for './ws_debug -a switch':
    ## 
    ##        1931.190343      task-clock (msec)         #    0.999 CPUs utilized          
    ##                  8      context-switches          #    0.004 K/sec                  
    ##                  0      cpu-migrations            #    0.000 K/sec                  
    ##             12,851      page-faults               #    0.007 M/sec                  
    ##      6,532,690,881      cycles                    #    3.383 GHz                    
    ##      5,775,121,648      instructions              #    0.88  insn per cycle         
    ##        968,227,349      branches                  #  501.363 M/sec                  
    ##        122,583,603      branch-misses             #   12.66% of all branches        
    ## 
    ##        1.933769770 seconds time elapsed

``` zsh
# Create a 32M file of all zero bytes
dd if=/dev/zero of=zero_32M bs=1MB count=32
```

    ## 32+0 records in
    ## 32+0 records out
    ## 32000000 bytes (32 MB, 31 MiB) copied, 0.0201193 s, 1.6 GB/s

``` zsh
# Run the perf stat
perf stat ./ws_debug -a switch < zero_32M > /dev/null 
```

    ## 
    ##  Performance counter stats for './ws_debug -a switch':
    ## 
    ##         547.240778      task-clock (msec)         #    0.999 CPUs utilized          
    ##                  2      context-switches          #    0.004 K/sec                  
    ##                  0      cpu-migrations            #    0.000 K/sec                  
    ##             12,850      page-faults               #    0.023 M/sec                  
    ##      1,819,721,576      cycles                    #    3.325 GHz                    
    ##      5,836,770,862      instructions              #    3.21  insn per cycle         
    ##        999,771,210      branches                  # 1826.931 M/sec                  
    ##            217,576      branch-misses             #    0.02% of all branches        
    ## 
    ##        0.547518297 seconds time elapsed

# Why The Lookup?

Now let’s take a look at the unsurprising result: the lookup algorithm is than the polynomial. The reason is simple: it takes more instructions to run. I’ve extracted the assembly out using *objdump* which you can see [here](https://github.com/gregfoletta/whitespacer/blob/algorithms/encoding_assembly.md).

``` zsh
perf stat ./ws -a lookup < urandom_32M > /dev/null
```

    ## 
    ##  Performance counter stats for './ws -a lookup':
    ## 
    ##         535.703442      task-clock (msec)         #    0.998 CPUs utilized          
    ##                  8      context-switches          #    0.015 K/sec                  
    ##                  0      cpu-migrations            #    0.000 K/sec                  
    ##             12,850      page-faults               #    0.024 M/sec                  
    ##      1,759,076,713      cycles                    #    3.284 GHz                    
    ##      5,200,260,035      instructions              #    2.96  insn per cycle         
    ##        488,226,193      branches                  #  911.374 M/sec                  
    ##            477,634      branch-misses             #    0.10% of all branches        
    ## 
    ##        0.536536069 seconds time elapsed

``` zsh
perf stat ./ws -a poly < urandom_32M > /dev/null
```

    ## 
    ##  Performance counter stats for './ws -a poly':
    ## 
    ##        1127.449560      task-clock (msec)         #    0.999 CPUs utilized          
    ##                  8      context-switches          #    0.007 K/sec                  
    ##                  0      cpu-migrations            #    0.000 K/sec                  
    ##             12,853      page-faults               #    0.011 M/sec                  
    ##      3,815,850,683      cycles                    #    3.384 GHz                    
    ##      7,757,764,944      instructions              #    2.03  insn per cycle         
    ##        487,993,660      branches                  #  432.830 M/sec                  
    ##            320,777      branch-misses             #    0.07% of all branches        
    ## 
    ##        1.128916265 seconds time elapsed

But what really surprised me was the switch was much slower than

# Intermission

# What About The o

``` zsh
perf stat ./ws_debug -a lookup < urandom_32M > /dev/null
```

    ## 
    ##  Performance counter stats for './ws_debug -a lookup':
    ## 
    ##         467.730584      task-clock (msec)         #    0.999 CPUs utilized          
    ##                  1      context-switches          #    0.002 K/sec                  
    ##                  0      cpu-migrations            #    0.000 K/sec                  
    ##             12,851      page-faults               #    0.027 M/sec                  
    ##      1,745,162,634      cycles                    #    3.731 GHz                    
    ##      5,196,440,141      instructions              #    2.98  insn per cycle         
    ##        487,709,448      branches                  # 1042.714 M/sec                  
    ##            111,900      branch-misses             #    0.02% of all branches        
    ## 
    ##        0.468017329 seconds time elapsed

``` zsh
perf stat ./ws_debug -a poly < urandom_32M > /dev/null
```

    ## 
    ##  Performance counter stats for './ws_debug -a poly':
    ## 
    ##        1146.243565      task-clock (msec)         #    0.999 CPUs utilized          
    ##                 14      context-switches          #    0.012 K/sec                  
    ##                  0      cpu-migrations            #    0.000 K/sec                  
    ##             12,853      page-faults               #    0.011 M/sec                  
    ##      3,846,017,269      cycles                    #    3.355 GHz                    
    ##      7,757,334,153      instructions              #    2.02  insn per cycle         
    ##        487,867,624      branches                  #  425.623 M/sec                  
    ##            546,365      branch-misses             #    0.11% of all branches        
    ## 
    ##        1.146873995 seconds time elapsed
