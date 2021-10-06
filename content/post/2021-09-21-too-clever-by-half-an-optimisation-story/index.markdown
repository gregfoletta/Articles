---
title: 'A Tale Of Two Optimisations'
author: 'Greg Foletta'
date: '2021-09-20'
slug: 'tale-of-two-optimisations'
categories: [R, C]
---

A couple of month’s ago I wrote a toy program called ‘whitespacer.’ It takes bytes and encodes/decodes them from/to whitespace.

Ever since I wrote it, it had been gnawing at me as to whether I could have written it in a more performant manner. I had an idea about trying to define a mathematical function that could perform the encoding, rather than relying on a lookup table.

This article has somewhat of a multiple personality. In the first half I’ll work through attempting to optimise the program and benchmarking it. But the benchmarking revealed something interesting about branch prediction that I felt needed to be investigated as well, so in the second half we’ll take a diversion into that.

I’m hoping that the two sections aren’t too disjointed.

# Attempt 1: A Mathematical Function

In the first iteration of the whitespacer program I used lookup tables to encode/decode the bytes. One lookup table took a dibit (two bits) of value 0 - 3 and mapped this to a whitespace character. Another lookup table did the inverse. Here’s the lookup table encoder function, which I’ve factored out:

``` c
//Dibit to whitesapce lookup table
char encode_lookup_tbl[] = { '\t', '\n', '\r', ' ' };

//Given a dibit, returns the whitespace encoding
unsigned char lookup_encode(const unsigned char dibit) {
    return encode_lookup_tbl[ dibit ];
}
```

I thought if I could find a mathematical function to perform this mapping, rather than a lookup table, I might be able to save some time on memory accesses in the hot encoding and decoding loop.

From somewhere in the recesses of my brain I recalled Lagrange polynomials: if we have a set of `\(k + 1\)` data points `\((x_0, y_0), \ldots, (x_k, y_k)\)` where no two `\(x_i\)` are the same, a polynomial of degree `\(k\)` or less can be defined that passes through all the points. For us that means I can define a function:

$$ f(x) = \beta_0 + \beta_1 x + \beta_2 x^2 + \beta_3 x^3 $$

which takes a dibit of 0, 1, 2 or 3 and returns the appropriate whitespace character. I can also define the inverse function (with differing `\(\beta\)` coefficients) which does the inverse. Outside of the `\([0, 3]\)` range the function won’t make much sense, but that fine for our use case.

<div id="qfaplaeuft" style="overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>html {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Helvetica Neue', 'Fira Sans', 'Droid Sans', Arial, sans-serif;
}

#qfaplaeuft .gt_table {
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

#qfaplaeuft .gt_heading {
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

#qfaplaeuft .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#qfaplaeuft .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 0;
  padding-bottom: 6px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#qfaplaeuft .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#qfaplaeuft .gt_col_headings {
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

#qfaplaeuft .gt_col_heading {
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

#qfaplaeuft .gt_column_spanner_outer {
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

#qfaplaeuft .gt_column_spanner_outer:first-child {
  padding-left: 0;
}

#qfaplaeuft .gt_column_spanner_outer:last-child {
  padding-right: 0;
}

#qfaplaeuft .gt_column_spanner {
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

#qfaplaeuft .gt_group_heading {
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

#qfaplaeuft .gt_empty_group_heading {
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

#qfaplaeuft .gt_from_md > :first-child {
  margin-top: 0;
}

#qfaplaeuft .gt_from_md > :last-child {
  margin-bottom: 0;
}

#qfaplaeuft .gt_row {
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

#qfaplaeuft .gt_stub {
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

#qfaplaeuft .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#qfaplaeuft .gt_first_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
}

#qfaplaeuft .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#qfaplaeuft .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}

#qfaplaeuft .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}

#qfaplaeuft .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#qfaplaeuft .gt_footnotes {
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

#qfaplaeuft .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding: 4px;
}

#qfaplaeuft .gt_sourcenotes {
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

#qfaplaeuft .gt_sourcenote {
  font-size: 90%;
  padding: 4px;
}

#qfaplaeuft .gt_left {
  text-align: left;
}

#qfaplaeuft .gt_center {
  text-align: center;
}

#qfaplaeuft .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#qfaplaeuft .gt_font_normal {
  font-weight: normal;
}

#qfaplaeuft .gt_font_bold {
  font-weight: bold;
}

#qfaplaeuft .gt_font_italic {
  font-style: italic;
}

#qfaplaeuft .gt_super {
  font-size: 65%;
}

#qfaplaeuft .gt_footnote_marks {
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

I now create two models: one for encoding, and one for decoding. I’m using a linear regression rather than the Lagrange polynomial formula, but the `\(\beta\)` coefficients end up the same.

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

<div id="nynybfbrwg" style="overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>html {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Helvetica Neue', 'Fira Sans', 'Droid Sans', Arial, sans-serif;
}

#nynybfbrwg .gt_table {
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

#nynybfbrwg .gt_heading {
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

#nynybfbrwg .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#nynybfbrwg .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 0;
  padding-bottom: 6px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#nynybfbrwg .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#nynybfbrwg .gt_col_headings {
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

#nynybfbrwg .gt_col_heading {
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

#nynybfbrwg .gt_column_spanner_outer {
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

#nynybfbrwg .gt_column_spanner_outer:first-child {
  padding-left: 0;
}

#nynybfbrwg .gt_column_spanner_outer:last-child {
  padding-right: 0;
}

#nynybfbrwg .gt_column_spanner {
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

#nynybfbrwg .gt_group_heading {
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

#nynybfbrwg .gt_empty_group_heading {
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

#nynybfbrwg .gt_from_md > :first-child {
  margin-top: 0;
}

#nynybfbrwg .gt_from_md > :last-child {
  margin-bottom: 0;
}

#nynybfbrwg .gt_row {
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

#nynybfbrwg .gt_stub {
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

#nynybfbrwg .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#nynybfbrwg .gt_first_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
}

#nynybfbrwg .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#nynybfbrwg .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}

#nynybfbrwg .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}

#nynybfbrwg .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#nynybfbrwg .gt_footnotes {
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

#nynybfbrwg .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding: 4px;
}

#nynybfbrwg .gt_sourcenotes {
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

#nynybfbrwg .gt_sourcenote {
  font-size: 90%;
  padding: 4px;
}

#nynybfbrwg .gt_left {
  text-align: left;
}

#nynybfbrwg .gt_center {
  text-align: center;
}

#nynybfbrwg .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#nynybfbrwg .gt_font_normal {
  font-weight: normal;
}

#nynybfbrwg .gt_font_bold {
  font-weight: bold;
}

#nynybfbrwg .gt_font_italic {
  font-style: italic;
}

#nynybfbrwg .gt_super {
  font-size: 65%;
}

#nynybfbrwg .gt_footnote_marks {
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

We’ve got a bit of a problem. I’ll be honest, I was hoping - somewhat optimistically - that I would get some nice, clean integer coefficients to work work.

Let’s persist and create encoding and decoding functions based on polynomial functions.

``` c
unsigned char poly_encode(const unsigned char dibit) {
    return 9.0 + 
    4.666667 * dibit - 
    6.0 * (dibit * dibit) + 
    2.333333333333 * (dibit * dibit * dibit);
}
```

The cast from floating point to unsigned char gi

# Attempt 2: A Switch

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
            command = glue('cat urandom_32M | ./ws_debug -a { algo } | ./ws_debug -d -a { algo } > /dev/null'),
            time = system_profile(command)
    ) %>% 
    select(-command)
```

Rather than simply looking at the means or medians for each of the algorithms, we take a look at the distribution of runtimes for each with the mean highlighted.

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-8-1.png" width="672" />

As I kind-of expected, the polynomial encoding/decoding is slower than the lookup table. But what is really surprising is that the switch statement is even slower. On average it’s taking over one second more to encode and decode the 32M file. I love a good surprise, so let’s dive in and find out what happening.

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
    ##        1660.048586      task-clock (msec)         #    1.000 CPUs utilized          
    ##                  3      context-switches          #    0.002 K/sec                  
    ##                  0      cpu-migrations            #    0.000 K/sec                  
    ##             12,852      page-faults               #    0.008 M/sec                  
    ##      6,314,282,417      cycles                    #    3.804 GHz                    
    ##      5,772,420,360      instructions              #    0.91  insn per cycle         
    ##        967,717,288      branches                  #  582.945 M/sec                  
    ##        121,801,823      branch-misses             #   12.59% of all branches        
    ## 
    ##        1.660692551 seconds time elapsed

The first statistic that should conern us is the instructions per cycle, which is just under one. The second is the numbner of branch misses, which is up at 12.56%. Put simply, we’re not getting much bang for our buck when it comes to predicting branches.

The hypothesis at this point is that given our data is random and uniformly distributed, combined with the branching (the C switch statement) used to encode the data, the branch predictor is performing poorly, and so is our performance.

To confirm this hypothesis, let’s create an input file of all zeros and see how it performs.

``` zsh
# Run the perf stat
perf stat ./ws_debug -a switch < zero_32M > /dev/null 
```

    ## 
    ##  Performance counter stats for './ws_debug -a switch':
    ## 
    ##         455.616288      task-clock (msec)         #    1.000 CPUs utilized          
    ##                  0      context-switches          #    0.000 K/sec                  
    ##                  0      cpu-migrations            #    0.000 K/sec                  
    ##             12,853      page-faults               #    0.028 M/sec                  
    ##      1,770,972,691      cycles                    #    3.887 GHz                    
    ##      5,835,066,403      instructions              #    3.29  insn per cycle         
    ##        999,466,423      branches                  # 2193.658 M/sec                  
    ##            148,811      branch-misses             #    0.01% of all branches        
    ## 
    ##        0.455830290 seconds time elapsed

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
    ##         480.813345      task-clock (msec)         #    0.998 CPUs utilized          
    ##                  4      context-switches          #    0.008 K/sec                  
    ##                  0      cpu-migrations            #    0.000 K/sec                  
    ##             12,851      page-faults               #    0.027 M/sec                  
    ##      1,727,564,992      cycles                    #    3.593 GHz                    
    ##      5,195,086,496      instructions              #    3.01  insn per cycle         
    ##        487,500,554      branches                  # 1013.908 M/sec                  
    ##            129,061      branch-misses             #    0.03% of all branches        
    ## 
    ##        0.481558683 seconds time elapsed

``` zsh
# Polynomial
perf stat ./ws_debug -a poly < urandom_32M > /dev/null
```

    ## 
    ##  Performance counter stats for './ws_debug -a poly':
    ## 
    ##         969.362232      task-clock (msec)         #    1.000 CPUs utilized          
    ##                  8      context-switches          #    0.008 K/sec                  
    ##                  0      cpu-migrations            #    0.000 K/sec                  
    ##             12,854      page-faults               #    0.013 M/sec                  
    ##      3,760,745,809      cycles                    #    3.880 GHz                    
    ##      7,755,555,360      instructions              #    2.06  insn per cycle         
    ##        487,534,636      branches                  #  502.944 M/sec                  
    ##            124,997      branch-misses             #    0.03% of all branches        
    ## 
    ##        0.969693473 seconds time elapsed

We see two main reasons as to why the polynomial is slower. First off it simply takes for instructions to calculate the polynomial, as compared to simply looking up the value in a lookup table. Secondly, this increase in instructions is compounded by that fact that we’re getting less instructions per seconds.

# Summary

In this article we looked at two different alternatives to a lookup table for encoding and decoding bytes in the *whitespacer* program. The fist was to try and use a polynomial function, and the seconds was to use a switch statement rather than a lookup table.

Upon calculation of the coefficients for the polynomial, we knew we

``` zsh
rm -rf whitespacer urandom_32M zero_32M ws_debug 
```
