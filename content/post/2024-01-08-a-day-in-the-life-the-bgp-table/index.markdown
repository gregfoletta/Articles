---
title: 'A Day in the Life: The BGP Table'
author: Greg Foletta
date: '2024-01-08'
slug: []
categories: []
tags: []
images: []
---

# Let the Yak SHaving Begin

# Updates, Not Routes

``` json
{
  "recv_time": 1704483075,
  "id": 12349,
  "type": "UPDATE",
  "nlri": [ "38.43.124.0/23" ],
  "withdrawn_routes": [],
  "path_attributes": [
    {
      "type": "ORIGIN", "type_code": 1,
      "flags": [ well-known", "transitive", "complete", "standard" ],
      "origin": "IGP"
    },
    {
      "type": "AS_PATH", "type_code": 2,
      "flags": ["well-known", "transitive", "complete", "standard"],
      "n_as_segments": 1,
      "path_segments": [
        {
          "type": "AS_SEQUENCE",
          "n_as": 6,
          "asns": [ 45270, 4764, 2914, 12956, 27951, 23456 ]
        }
      ]
    },
    {
      "type": "NEXT_HOP", "type_code": 3,
      "flags": ["well-known", "transitive", "complete", "standard"],
      "next_hop": "61.245.147.114"
    },
    {
      "type": "AS4_PATH", "type_code": 17,
      "flags": ["optional", "non-transitive","partial","extended" ],
      "n_as_segments": 1,
      "path_segments": [
        {
          "type": "AS_SEQUENCE",
          "n_as": 6,
          "asns": [ 45270,4764, 2914, 12956, 27951, 273013 ]
        }
      ]
    }
  ]
}
```

    ## Load and Cleaning: 37.953 sec elapsed

    ## AS_PATH Variables: 32.611 sec elapsed

# Initial Graph

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-4-1.png" width="672" />

# Initial Send, Number of v4 and v6 Paths

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-5-1.png" width="672" />
\# Updated Over Time

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-6-1.png" width="672" />

# Longest AS_PATHS

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-7-1.png" width="672" />

    ## [1] 45270
    ## [1] "f1c37f3d65"
    ## [1] 4764
    ## [1] "b70c1c82bf"
    ## [1] 2914
    ## [1] "f0d380bf4a"
    ## [1] 29632
    ## [1] "cb673d60f1"
    ## [1] 8772
    ## [1] "8c6bd10f76"
    ## [1] 200579
    ## [1] "10d93b91d1"
    ## [1] 203868
    ## [1] "10d93b91d1"

<div id="rilvmqtwne" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#rilvmqtwne table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#rilvmqtwne thead, #rilvmqtwne tbody, #rilvmqtwne tfoot, #rilvmqtwne tr, #rilvmqtwne td, #rilvmqtwne th {
  border-style: none;
}
&#10;#rilvmqtwne p {
  margin: 0;
  padding: 0;
}
&#10;#rilvmqtwne .gt_table {
  display: table;
  border-collapse: collapse;
  line-height: normal;
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
&#10;#rilvmqtwne .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#rilvmqtwne .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}
&#10;#rilvmqtwne .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 3px;
  padding-bottom: 5px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}
&#10;#rilvmqtwne .gt_heading {
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
&#10;#rilvmqtwne .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#rilvmqtwne .gt_col_headings {
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
&#10;#rilvmqtwne .gt_col_heading {
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
&#10;#rilvmqtwne .gt_column_spanner_outer {
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
&#10;#rilvmqtwne .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#rilvmqtwne .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#rilvmqtwne .gt_column_spanner {
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
&#10;#rilvmqtwne .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#rilvmqtwne .gt_group_heading {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
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
  text-align: left;
}
&#10;#rilvmqtwne .gt_empty_group_heading {
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
&#10;#rilvmqtwne .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#rilvmqtwne .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#rilvmqtwne .gt_row {
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
&#10;#rilvmqtwne .gt_stub {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#rilvmqtwne .gt_stub_row_group {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
  vertical-align: top;
}
&#10;#rilvmqtwne .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#rilvmqtwne .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#rilvmqtwne .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#rilvmqtwne .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#rilvmqtwne .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#rilvmqtwne .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#rilvmqtwne .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#rilvmqtwne .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#rilvmqtwne .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#rilvmqtwne .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#rilvmqtwne .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#rilvmqtwne .gt_footnotes {
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
&#10;#rilvmqtwne .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#rilvmqtwne .gt_sourcenotes {
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
&#10;#rilvmqtwne .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#rilvmqtwne .gt_left {
  text-align: left;
}
&#10;#rilvmqtwne .gt_center {
  text-align: center;
}
&#10;#rilvmqtwne .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#rilvmqtwne .gt_font_normal {
  font-weight: normal;
}
&#10;#rilvmqtwne .gt_font_bold {
  font-weight: bold;
}
&#10;#rilvmqtwne .gt_font_italic {
  font-style: italic;
}
&#10;#rilvmqtwne .gt_super {
  font-size: 65%;
}
&#10;#rilvmqtwne .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#rilvmqtwne .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#rilvmqtwne .gt_indent_1 {
  text-indent: 5px;
}
&#10;#rilvmqtwne .gt_indent_2 {
  text-indent: 10px;
}
&#10;#rilvmqtwne .gt_indent_3 {
  text-indent: 15px;
}
&#10;#rilvmqtwne .gt_indent_4 {
  text-indent: 20px;
}
&#10;#rilvmqtwne .gt_indent_5 {
  text-indent: 25px;
}
</style>
<table class="gt_table" data-quarto-disable-processing="false" data-quarto-bootstrap="false">
  <thead>
    &#10;    <tr class="gt_col_headings">
      <th class="gt_col_heading gt_columns_bottom_border gt_center" rowspan="1" colspan="1" scope="col" id="&lt;strong&gt;AS Number&lt;/strong&gt;"><strong>AS Number</strong></th>
      <th class="gt_col_heading gt_columns_bottom_border gt_center" rowspan="1" colspan="1" scope="col" id="&lt;strong&gt;No. of Prepends&lt;/strong&gt;"><strong>No. of Prepends</strong></th>
      <th class="gt_col_heading gt_columns_bottom_border gt_center" rowspan="1" colspan="1" scope="col" id="&lt;strong&gt;Organisation Name&lt;/strong&gt;"><strong>Organisation Name</strong></th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr><td headers="as_path" class="gt_row gt_center">45270</td>
<td headers="n" class="gt_row gt_center">1</td>
<td headers="organisation" class="gt_row gt_center">Ossini Pty Ltd</td></tr>
    <tr><td headers="as_path" class="gt_row gt_center">4764</td>
<td headers="n" class="gt_row gt_center">1</td>
<td headers="organisation" class="gt_row gt_center">Wideband Networks Pty Ltd</td></tr>
    <tr><td headers="as_path" class="gt_row gt_center">2914</td>
<td headers="n" class="gt_row gt_center">1</td>
<td headers="organisation" class="gt_row gt_center">NTT America, Inc.</td></tr>
    <tr><td headers="as_path" class="gt_row gt_center">29632</td>
<td headers="n" class="gt_row gt_center">1</td>
<td headers="organisation" class="gt_row gt_center">Netassist Limited</td></tr>
    <tr><td headers="as_path" class="gt_row gt_center">8772</td>
<td headers="n" class="gt_row gt_center">592</td>
<td headers="organisation" class="gt_row gt_center">NetAssist LLC</td></tr>
    <tr><td headers="as_path" class="gt_row gt_center">200579</td>
<td headers="n" class="gt_row gt_center">2</td>
<td headers="organisation" class="gt_row gt_center">Rifqi Arief Pamungkas</td></tr>
    <tr><td headers="as_path" class="gt_row gt_center">203868</td>
<td headers="n" class="gt_row gt_center">1</td>
<td headers="organisation" class="gt_row gt_center">Rifqi Arief Pamungkas</td></tr>
  </tbody>
  &#10;  
</table>
</div>

# IP Address Space

## Prefix Length Distribution

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-11-1.png" width="672" />

# Path Attributes

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-14-1.png" width="672" />

    ## [1] 714
    ## [1] "e7117ce3ab"
    ## [1] 7014
    ## [1] "5934dab83b"
    ## [1] 14706
    ## [1] "e6c07b0cef"
    ## [1] 11720
    ## [1] "2a645adc62"
    ## [1] 15205
    ## [1] "0db32e9699"

    ## # A tibble: 5 × 2
    ##   originating_asn organisation                            
    ##             <int> <chr>                                   
    ## 1             714 Apple Inc.                              
    ## 2            7014 Verizon Business                        
    ## 3           14706 Monterey Bay Aquarium Research Institute
    ## 4           11720 Independent Bank Corporation            
    ## 5           15205 Nassau County Police Department
