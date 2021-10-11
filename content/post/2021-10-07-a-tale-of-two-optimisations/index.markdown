---
title: 'A Tale Of Two Optimisations'
author: 'Greg Foletta'
date: '2021-09-20'
slug: 'a-tale-of-two-optimisations'
categories: [R, C]
---

A couple of months ago I wrote a toy program called [whitespacer](github.com/gregfoletta/whitespacer). Ever since, I’ve had this gnawing feeling that I could have done it better; that it could have been written in a more performant manner. In this article I’ll take you through a couple of different ideas I came up with. We’ll profile and visualise their different performances and stumble upon some surprising behaviour. We’ll use this as an excuse to take a deeper dive into their behaviour at the CPU level and gain a better understanding about the `perf` performance analysis tool and branch prediction.

# A Quick Recap

In [a previous article](/post/2021-06-21-whitespacer/) I took you through the *whitespacer* program. Here’s a quick recap of what it does:

-   Reads from standard in and writes to standard out.
-   Works in an ‘encoding’ and ‘decoding’ mode’.
-   In encoding mode it takes each of the four dibits (2 bits) of each byte and turns it into one of four whitespace characters (tab, new line, carriage return and space).
-   Decoding mode does the reverse, taking groups of four whitespace characters and reconstituting the original byte.

Here’s the encoding function:

``` c
//Dibit to whitesapce lookup table (global variable)
char encode_lookup_tbl[] = { '\t', '\n', '\r', ' ' };

//Given a dibit, returns the whitespace encoding
unsigned char lookup_encode(const unsigned char dibit) {
    return encode_lookup_tbl[ dibit ];
}
```

I’ve omitted the decoding function for brevity, but it’s the same with a different lookup table.

# Attempt 1: A Mathematical Function

What bothered me about the original implementation was the lookup table. Even though I knew they’d be cached, I still thought the memory accesses might have a detrimental affect on performance.

I had an idea about using mathematical functions (rather than the lookup table) to perform the encoding/decoding. This would remove the memory accesses and perhaps improve performance.

From somewhere I recalled that if we have a set of \\(k + 1\\) data points \\((x\_0, y\_0),…, (x\_k, y\_k)\\) where no two \\(x\_i\\) are the same, we can fit a curve using a linear regression with a polynomial of degree \\(k\\). Here’s our table of data points:

<div id="hrzskzpmfx" style="overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>html {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Helvetica Neue', 'Fira Sans', 'Droid Sans', Arial, sans-serif;
}

#hrzskzpmfx .gt_table {
  display: table;
  border-collapse: collapse;
  margin-left: auto;
  margin-right: auto;
  color: #333333;
  font-size: 16px;
  font-weight: normal;
  font-style: normal;
  background-color: #FFFFFF;
  width: 30%;
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

#hrzskzpmfx .gt_heading {
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

#hrzskzpmfx .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#hrzskzpmfx .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 0;
  padding-bottom: 6px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#hrzskzpmfx .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#hrzskzpmfx .gt_col_headings {
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

#hrzskzpmfx .gt_col_heading {
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

#hrzskzpmfx .gt_column_spanner_outer {
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

#hrzskzpmfx .gt_column_spanner_outer:first-child {
  padding-left: 0;
}

#hrzskzpmfx .gt_column_spanner_outer:last-child {
  padding-right: 0;
}

#hrzskzpmfx .gt_column_spanner {
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

#hrzskzpmfx .gt_group_heading {
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

#hrzskzpmfx .gt_empty_group_heading {
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

#hrzskzpmfx .gt_from_md > :first-child {
  margin-top: 0;
}

#hrzskzpmfx .gt_from_md > :last-child {
  margin-bottom: 0;
}

#hrzskzpmfx .gt_row {
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

#hrzskzpmfx .gt_stub {
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

#hrzskzpmfx .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#hrzskzpmfx .gt_first_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
}

#hrzskzpmfx .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#hrzskzpmfx .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}

#hrzskzpmfx .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}

#hrzskzpmfx .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#hrzskzpmfx .gt_footnotes {
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

#hrzskzpmfx .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding: 4px;
}

#hrzskzpmfx .gt_sourcenotes {
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

#hrzskzpmfx .gt_sourcenote {
  font-size: 90%;
  padding: 4px;
}

#hrzskzpmfx .gt_left {
  text-align: left;
}

#hrzskzpmfx .gt_center {
  text-align: center;
}

#hrzskzpmfx .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#hrzskzpmfx .gt_font_normal {
  font-weight: normal;
}

#hrzskzpmfx .gt_font_bold {
  font-weight: bold;
}

#hrzskzpmfx .gt_font_italic {
  font-style: italic;
}

#hrzskzpmfx .gt_super {
  font-size: 65%;
}

#hrzskzpmfx .gt_footnote_marks {
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
such that when passed a dibit value it returns the appropriate whitespace character. We can also find the inverse polynomial \\(f^{-1}(x)\\) which takes a whitespace character and returns a dibit to be our decoding function. Let’s create linear regression models in R where `whitespace` is the table holding our dibit and whitespace values:

``` r
encode_model <-
    whitespace %>% 
    lm(ascii_dec ~ dibit + I(dibit^2) + I(dibit^3), data = .)

decode_model <-
    whitespace %>% 
    lm(dibit ~ ascii_dec + I(ascii_dec^2) + I(ascii_dec^3), data = .)
```

Visualising these models will help us see what’s going on. On the left is our encoding model, which takes out dibit values and maps them to our ASCII whitespace characters. On the right our decoding model, which takes the ASCII whitespace characters’ decimal value and maps it back to a dibit. What becomes obvious by visualising these is how they make no sense for any values outside of our four points:

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-4-1.png" width="672" />

Let’s take a look at the \\(\\) coefficients:

<div id="fzeonzdcyg" style="overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>html {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Helvetica Neue', 'Fira Sans', 'Droid Sans', Arial, sans-serif;
}

#fzeonzdcyg .gt_table {
  display: table;
  border-collapse: collapse;
  margin-left: auto;
  margin-right: auto;
  color: #333333;
  font-size: 16px;
  font-weight: normal;
  font-style: normal;
  background-color: #FFFFFF;
  width: 30%;
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

#fzeonzdcyg .gt_heading {
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

#fzeonzdcyg .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#fzeonzdcyg .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 0;
  padding-bottom: 6px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#fzeonzdcyg .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#fzeonzdcyg .gt_col_headings {
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

#fzeonzdcyg .gt_col_heading {
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

#fzeonzdcyg .gt_column_spanner_outer {
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

#fzeonzdcyg .gt_column_spanner_outer:first-child {
  padding-left: 0;
}

#fzeonzdcyg .gt_column_spanner_outer:last-child {
  padding-right: 0;
}

#fzeonzdcyg .gt_column_spanner {
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

#fzeonzdcyg .gt_group_heading {
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

#fzeonzdcyg .gt_empty_group_heading {
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

#fzeonzdcyg .gt_from_md > :first-child {
  margin-top: 0;
}

#fzeonzdcyg .gt_from_md > :last-child {
  margin-bottom: 0;
}

#fzeonzdcyg .gt_row {
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

#fzeonzdcyg .gt_stub {
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

#fzeonzdcyg .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#fzeonzdcyg .gt_first_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
}

#fzeonzdcyg .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#fzeonzdcyg .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}

#fzeonzdcyg .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}

#fzeonzdcyg .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#fzeonzdcyg .gt_footnotes {
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

#fzeonzdcyg .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding: 4px;
}

#fzeonzdcyg .gt_sourcenotes {
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

#fzeonzdcyg .gt_sourcenote {
  font-size: 90%;
  padding: 4px;
}

#fzeonzdcyg .gt_left {
  text-align: left;
}

#fzeonzdcyg .gt_center {
  text-align: center;
}

#fzeonzdcyg .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#fzeonzdcyg .gt_font_normal {
  font-weight: normal;
}

#fzeonzdcyg .gt_font_bold {
  font-weight: bold;
}

#fzeonzdcyg .gt_font_italic {
  font-style: italic;
}

#fzeonzdcyg .gt_super {
  font-size: 65%;
}

#fzeonzdcyg .gt_footnote_marks {
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

Immediately we see a bit of a problem. I’ll be honest that I was hoping - somewhat optimistically - for some nice, clean integer coefficients. Instead we’ve got floating point values. My gut feel is that having to use floating point instructions is not going to improve upon our original lookup table. But we won’t know until we profile, so let’s persist. Here’s the new polynomial encoding function, with the decoding function omitted for brevity:

``` c
unsigned char poly_encode(const unsigned char dibit) {
    return (unsigned char) (9.0 + 
    4.666667 * dibit - 
    6.0 * (dibit * dibit) + 
    2.333333333333 * (dibit * dibit * dibit));
}
```

We don’t need to (and are probably unlikely to) hit the mark exactly, we just need to get close enough so that the whole part of the floating point value is correct. The cast to `usigned char` will give us this whole part, throwing away any values after the decimal point.

# Attempt 2: A Switch

While working on the polynomial function, it struck me that we could also use a conditional statement to make decisions on how to encode (and decode) individual dibits. Here’s an implementation which uses a switch statement:

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

We also need need a way to select the algorithm the program uses at runtime. A command line option *-a <algorithm>* has been added, where <algorithm> is either ‘lookup,’ ‘poly’ or ‘switch.’ If none is specified it defaults to the original lookup table. You can find the full code for the new, multi-algorithm whitespacer [here](https://github.com/gregfoletta/whitespacer/tree/algorithms).

# Profiling

Rather than supposition, let’s test how the different algorithms perform. I’ve created an R function which takes a vector of shell commands and returns how long they took to run. There will be a small amount of overhead in spawning a shell, but as this is constant across all executions and as we’re looking at he *differences* between the runtimes, it gets cancelled out.

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

We now run 200 iterations of an encode / decode pipeline for each algorithm and look at the time each takes to run, piping in a 32Mb file of random bytes generated from */dev/urandom*. The output is dumped to */dev/null*. The executables have been compiled with all optimisations disabled.

``` r
profiling_results <-
    tibble(
        n = 1:9,
        algo = rep(c('lookup', 'poly', 'switch'), max(n) / 3)
    ) %>% 
    mutate(
            command = glue(
                '< urandom_32M ./ws_debug -a { algo } | ./ws_debug -d -a { algo } > /dev/null'
            ),
            time = system_profile(command)
    ) %>% 
    select(-command)
```

Rather than simply looking at the means or medians for each of the algorithms, we take a look at the distribution of runtimes for each with the mean highlighted.

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-8-1.png" width="672" />

As expected, the polynomial encoding/decoding is slower than the lookup table. But what is really surprising is the switch statement: its slower than both! On average it’s 2.3 seconds slower than the lookup table! I love a good surprise, so let’s dive in and try to work out what’s happening.

# What’s With The Switch?

We’ll take a bottom up approach and look at the instructions that were being executed on the CPU as the process was running. Using `perf record` we take samples of the process’s state, most importantly the instruction pointer. By using the `-b` switch, perf also captures the *Last Branch Record (LBR) stack*. With the LBR processor feature, the CPU logs the *from* and *to* addresses of predicted and mispredicted branches taken to a set of special purpose registers. With this information, *perf* can reconstitute the a history of the instructions executed, rather than only having a single point in time to use from the sample.

Let’s run the encoding half of the pipeline and feed it 32Mb of random bytes:

``` sh
perf record -b -o switch.data -e cycles:pp ./ws_debug -a switch < urandom_32M > /dev/null
[ perf record: Woken up 22 times to write data ]
[ perf record: Captured and wrote 5.345 MB switch.data (6833 samples) ]
```

Looking at the trace data (saved in *switch.data*), the *brstackins* field allows us to see the instructions executed and approximate CPU cycles for different branches. Perf has captured around 43,000 executions of our `switch_encode()` function, with just one of these displayed below:

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

Even without decoding the machine code, what immediately stands stand out is the 22 cycles taken following the branch misprediction. Let’s now zoom out and run `perf stat` to pull out some summary statistics:

``` sh
# Perf stat with 32Mb urandom bytes
perf stat ./ws_debug -a switch < urandom_32M > /dev/null       
```


     Performance counter stats for './ws_debug -a switch':

           1641.089879      task-clock (msec)         #    1.000 CPUs utilized          
                     7      context-switches          #    0.004 K/sec                  
                     0      cpu-migrations            #    0.000 K/sec                  
                12,853      page-faults               #    0.008 M/sec                  
         6,316,880,424      cycles                    #    3.849 GHz                    
         5,772,375,503      instructions              #    0.91  insn per cycle         
           967,706,194      branches                  #  589.673 M/sec                  
           121,878,281      branch-misses             #   12.59% of all branches        

           1.641870438 seconds time elapsed

The first statistic that stands out are the instructions per cycle, which is just under one. The likely cause of this is the number is the number of branch misses, which is up at \~12%. These branch prediction misses are destroying any benefit of pipelining in the CPU.

I’ve got an sneaking suspicion that the cause of these missed branch predictions is our input data, so let’s test the hypothesis. We create a 32Mb file of all zeros from */dev/zero* instead of random bytes, then re-profile with this data as input instead of the random bytes. I’ll omit the code and go straight to the results:

<img src="{{< blogdown/postref >}}index_files/figure-html/zero_profiling-1.png" width="672" />

The switch algorithm now outperforms the others! Here’s the *perf stat*:

``` zsh
# Perf stat with 32Mb of zero bytes
perf stat ./ws_debug -a switch < zero_32M > /dev/null
```


     Performance counter stats for './ws_debug -a switch':

            524.998367      task-clock (msec)         #    0.998 CPUs utilized          
                    33      context-switches          #    0.063 K/sec                  
                     0      cpu-migrations            #    0.000 K/sec                  
                12,853      page-faults               #    0.024 M/sec                  
         1,827,951,688      cycles                    #    3.482 GHz                    
         5,834,871,616      instructions              #    3.19  insn per cycle         
           999,396,597      branches                  # 1903.618 M/sec                  
               185,046      branch-misses             #    0.02% of all branches        

           0.526126660 seconds time elapsed

In the grand scheme of things, almost no branch prediction misses, and a huge speed increase as compared to the random bytes.

Now this is where I start to butt up against the limits of my CPU architecture knowledge (feel free to [contact me](mailto:greg@foletta.org) with any corrections), but what I assume is happening is that the branch predictor on my CPU is using historical branching information to try and make good guesses. But when the input is random bytes, history provides no additional information, and the branch predictor adds no benefit. In fact it may be a hindrance due to the penalty of a missed branches.

# Lookup versus Polynomial

Now let’s take a look at the unsurprising result: our original lookup algorithm versus the polynomial. We’ll go straight to using `perf stat` to see high-level statistics. First up is the lookup algorithm:

``` zsh
# Lookup table 
perf stat ./ws_debug -a lookup < urandom_32M > /dev/null
```


     Performance counter stats for './ws_debug -a lookup':

            448.711935      task-clock (msec)         #    0.996 CPUs utilized          
                     9      context-switches          #    0.020 K/sec                  
                     0      cpu-migrations            #    0.000 K/sec                  
                12,851      page-faults               #    0.029 M/sec                  
         1,694,238,421      cycles                    #    3.776 GHz                    
         5,194,807,323      instructions              #    3.07  insn per cycle         
           487,407,742      branches                  # 1086.238 M/sec                  
                92,316      branch-misses             #    0.02% of all branches        

           0.450334167 seconds time elapsed

Now the polynomial:

``` zsh
# Polynomial
perf stat ./ws_debug -a poly < urandom_32M > /dev/null
```


     Performance counter stats for './ws_debug -a poly':

            970.773548      task-clock (msec)         #    1.000 CPUs utilized          
                     1      context-switches          #    0.001 K/sec                  
                     0      cpu-migrations            #    0.000 K/sec                  
                12,853      page-faults               #    0.013 M/sec                  
         3,762,791,989      cycles                    #    3.876 GHz                    
         7,755,359,156      instructions              #    2.06  insn per cycle         
           487,501,085      branches                  #  502.178 M/sec                  
                94,286      branch-misses             #    0.02% of all branches        

           0.970993316 seconds time elapsed

We see two main reasons as to why the polynomial is slower. First off it simply takes more instructions to calculate the polynomial as opposed to looking up the value in a lookup table. Second, even with the (likely cached) memory accesses, we’re able to execute more instructions per cycle with the lookup table as opposed to the polynomial algorithm.

# Summary

In this article we looked at two different alternatives to a lookup table for encoding and decoding bytes in the *whitespacer* program. The fist was to try and use a polynomial function, and the second was to use a conditional switch statement.

We found a surprising result with the switch statement, and were able to determine using the *perf* tool that we were paying a penalty for missed branch predictions due to the randomness of the input data.

When you run into a problem or a surprising result, you’re often gifted an opportunity to learn something new. I’ve certainly learned a lot about *perf*, LBR stacks and branch prediction in putting this article together.
