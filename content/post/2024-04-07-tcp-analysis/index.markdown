---
title: TCP Analysis
author: ''
date: '2024-04-07'
slug: []
categories: []
tags: []
images: []
---

I currently work for a [network & security vendor](https://fortinet.com) whos main product is a firewall. When sizing firewalls there’s a two main things to consider: the throughput, and the conncurrent connections. Sizing based on throughput is relatively easy: what’s the aggregate bandwidth connected to the device. But concurrent connections is a little harder. Imagine a head office with 200 people, how many concurrent connections would you expect? Also, what’s our certainty about this?

In this article we’re going to try and answer this question by taking Bayesian perspective. We’ll do this by using real packet capture data from my laptop, and using this as an input to a STAN program. THe STAN program estimate the parameters for the probability distributions for the connections per second, and the connection duration. We’ll then simulate connections by pulling values from these probability distributions.

The result is an idea of the probable concurrent connections that we can use to size our firewall.

# Caveats Firsts

Let’s be up-front in where the flaws are with this. The first is that it’s predicated on everyone else’s behaviour looking like mine. For an office scenario I don’t think this is too far fetched: my data was taken during a normal work day, so it’s got Microsoft Teams, web-browsing, Outlook; the standard worker fare. But we need to be aware that not everyones traffic profile looks like this.

The second is that in real life, concurrent connections rise and fall like the tide based on people’s behaviour.

# Traffic Data

I used `tshark` to capture my wlan0 interface over the course of the day, piping this in to `jq` to filter out the fields I didn’t need to reduce the size. The commandline looked like this:

``` sh
tshark -Tjson -J 'frame eth ip tcp udp' -iwlan0 | jq --stream --from-file pcap_stream_filter.jq
```

``` json
[
    {
      "frame.time": "Apr 17, 2024 10:16:19.373894967 AEST",
      "frame.time_epoch": "1713312979.373894967",
      "frame.time_delta": "0.000000000",
      "frame.time_relative": "0.000000000",
      "frame.number": "1",
      "frame.protocols": "eth:ethertype:ip:tcp:tls",
      "eth.src": "e0:23:ff:65:52:61",
      "eth.dst": "6c:94:66:78:d4:e4",
      "ip.src": "10.50.9.66",
      "ip.dst": "10.50.3.2",
      "udp.stream": null,
      "tcp.srcport": "3389",
      "tcp.dstport": "56708",
      "tcp.stream": "0",
      "tcp.flags_tree": {
        "tcp.flags.res": "0",
        "tcp.flags.ns": "0",
        "tcp.flags.cwr": "0",
        "tcp.flags.ecn": "0",
        "tcp.flags.urg": "0",
        "tcp.flags.ack": "1",
        "tcp.flags.push": "1",
        "tcp.flags.reset": "0",
        "tcp.flags.syn": "0",
        "tcp.flags.fin": "0",
        "tcp.flags.str": "·······AP···"
      },
    },
    ...
]
```

You can take a look at the [*pcap_stream_filter.jq* here](pcap_stream_filter.jq). The data is loaded into R and we do some wrangling:

After a bit of wrangling, including filtering for just TCP and UDP, unnesting the TCP flags tree, and converting the time to a POSIXct object, the data is in a form where we can actually use it:

<div id="lpebxgbsqx" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#lpebxgbsqx table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#lpebxgbsqx thead, #lpebxgbsqx tbody, #lpebxgbsqx tfoot, #lpebxgbsqx tr, #lpebxgbsqx td, #lpebxgbsqx th {
  border-style: none;
}
&#10;#lpebxgbsqx p {
  margin: 0;
  padding: 0;
}
&#10;#lpebxgbsqx .gt_table {
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
&#10;#lpebxgbsqx .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#lpebxgbsqx .gt_title {
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
&#10;#lpebxgbsqx .gt_subtitle {
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
&#10;#lpebxgbsqx .gt_heading {
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
&#10;#lpebxgbsqx .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#lpebxgbsqx .gt_col_headings {
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
&#10;#lpebxgbsqx .gt_col_heading {
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
&#10;#lpebxgbsqx .gt_column_spanner_outer {
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
&#10;#lpebxgbsqx .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#lpebxgbsqx .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#lpebxgbsqx .gt_column_spanner {
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
&#10;#lpebxgbsqx .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#lpebxgbsqx .gt_group_heading {
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
&#10;#lpebxgbsqx .gt_empty_group_heading {
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
&#10;#lpebxgbsqx .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#lpebxgbsqx .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#lpebxgbsqx .gt_row {
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
&#10;#lpebxgbsqx .gt_stub {
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
&#10;#lpebxgbsqx .gt_stub_row_group {
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
&#10;#lpebxgbsqx .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#lpebxgbsqx .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#lpebxgbsqx .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#lpebxgbsqx .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#lpebxgbsqx .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#lpebxgbsqx .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#lpebxgbsqx .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#lpebxgbsqx .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#lpebxgbsqx .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#lpebxgbsqx .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#lpebxgbsqx .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#lpebxgbsqx .gt_footnotes {
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
&#10;#lpebxgbsqx .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#lpebxgbsqx .gt_sourcenotes {
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
&#10;#lpebxgbsqx .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#lpebxgbsqx .gt_left {
  text-align: left;
}
&#10;#lpebxgbsqx .gt_center {
  text-align: center;
}
&#10;#lpebxgbsqx .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#lpebxgbsqx .gt_font_normal {
  font-weight: normal;
}
&#10;#lpebxgbsqx .gt_font_bold {
  font-weight: bold;
}
&#10;#lpebxgbsqx .gt_font_italic {
  font-style: italic;
}
&#10;#lpebxgbsqx .gt_super {
  font-size: 65%;
}
&#10;#lpebxgbsqx .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#lpebxgbsqx .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#lpebxgbsqx .gt_indent_1 {
  text-indent: 5px;
}
&#10;#lpebxgbsqx .gt_indent_2 {
  text-indent: 10px;
}
&#10;#lpebxgbsqx .gt_indent_3 {
  text-indent: 15px;
}
&#10;#lpebxgbsqx .gt_indent_4 {
  text-indent: 20px;
}
&#10;#lpebxgbsqx .gt_indent_5 {
  text-indent: 25px;
}
</style>
<table class="gt_table" data-quarto-disable-processing="false" data-quarto-bootstrap="false">
  <thead>
    <tr class="gt_col_headings">
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="time">time</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="frame.time_relative">frame.time_relative</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="id">id</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="eth.src">eth.src</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="eth.dst">eth.dst</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="tcp.stream">tcp.stream</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="udp.stream">udp.stream</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="tcp.srcport">tcp.srcport</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="tcp.dstport">tcp.dstport</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="tcp.flags.syn">tcp.flags.syn</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="tcp.flags.ack">tcp.flags.ack</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="tcp.flags.fin">tcp.flags.fin</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="tcp.flags.reset">tcp.flags.reset</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="flags_string">flags_string</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:19.373895</td>
<td headers="frame.time_relative" class="gt_row gt_right">0.000000000</td>
<td headers="id" class="gt_row gt_right">1</td>
<td headers="eth.src" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="eth.dst" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="tcp.stream" class="gt_row gt_right">0</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">3389</td>
<td headers="tcp.dstport" class="gt_row gt_right">56708</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······AP···</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:19.373898</td>
<td headers="frame.time_relative" class="gt_row gt_right">0.000002826</td>
<td headers="id" class="gt_row gt_right">2</td>
<td headers="eth.src" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="eth.dst" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="tcp.stream" class="gt_row gt_right">1</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">22</td>
<td headers="tcp.dstport" class="gt_row gt_right">59712</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······AP···</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:19.373898</td>
<td headers="frame.time_relative" class="gt_row gt_right">0.000003028</td>
<td headers="id" class="gt_row gt_right">3</td>
<td headers="eth.src" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="eth.dst" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="tcp.stream" class="gt_row gt_right">1</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">22</td>
<td headers="tcp.dstport" class="gt_row gt_right">59712</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······AP···</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:19.373898</td>
<td headers="frame.time_relative" class="gt_row gt_right">0.000003070</td>
<td headers="id" class="gt_row gt_right">4</td>
<td headers="eth.src" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="eth.dst" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="tcp.stream" class="gt_row gt_right">1</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">22</td>
<td headers="tcp.dstport" class="gt_row gt_right">59712</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······AP···</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:19.373945</td>
<td headers="frame.time_relative" class="gt_row gt_right">0.000050391</td>
<td headers="id" class="gt_row gt_right">5</td>
<td headers="eth.src" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="eth.dst" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="tcp.stream" class="gt_row gt_right">1</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">59712</td>
<td headers="tcp.dstport" class="gt_row gt_right">22</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······A····</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:19.373969</td>
<td headers="frame.time_relative" class="gt_row gt_right">0.000074057</td>
<td headers="id" class="gt_row gt_right">6</td>
<td headers="eth.src" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="eth.dst" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="tcp.stream" class="gt_row gt_right">0</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">56708</td>
<td headers="tcp.dstport" class="gt_row gt_right">3389</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······A····</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:19.373988</td>
<td headers="frame.time_relative" class="gt_row gt_right">0.000093359</td>
<td headers="id" class="gt_row gt_right">7</td>
<td headers="eth.src" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="eth.dst" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="tcp.stream" class="gt_row gt_right">1</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">59712</td>
<td headers="tcp.dstport" class="gt_row gt_right">22</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······A····</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:19.373996</td>
<td headers="frame.time_relative" class="gt_row gt_right">0.000101149</td>
<td headers="id" class="gt_row gt_right">8</td>
<td headers="eth.src" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="eth.dst" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="tcp.stream" class="gt_row gt_right">1</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">59712</td>
<td headers="tcp.dstport" class="gt_row gt_right">22</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······A····</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:19.681155</td>
<td headers="frame.time_relative" class="gt_row gt_right">0.307260347</td>
<td headers="id" class="gt_row gt_right">9</td>
<td headers="eth.src" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="eth.dst" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="tcp.stream" class="gt_row gt_right">2</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">3478</td>
<td headers="tcp.dstport" class="gt_row gt_right">34867</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······A····</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:19.681211</td>
<td headers="frame.time_relative" class="gt_row gt_right">0.307316321</td>
<td headers="id" class="gt_row gt_right">10</td>
<td headers="eth.src" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="eth.dst" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="tcp.stream" class="gt_row gt_right">2</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">34867</td>
<td headers="tcp.dstport" class="gt_row gt_right">3478</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······A····</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:20.381941</td>
<td headers="frame.time_relative" class="gt_row gt_right">1.008045795</td>
<td headers="id" class="gt_row gt_right">11</td>
<td headers="eth.src" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="eth.dst" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="tcp.stream" class="gt_row gt_right">NA</td>
<td headers="udp.stream" class="gt_row gt_right">0</td>
<td headers="tcp.srcport" class="gt_row gt_right">NA</td>
<td headers="tcp.dstport" class="gt_row gt_right">NA</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">NA</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">NA</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">NA</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">NA</td>
<td headers="flags_string" class="gt_row gt_left">NA</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:20.386758</td>
<td headers="frame.time_relative" class="gt_row gt_right">1.012863256</td>
<td headers="id" class="gt_row gt_right">12</td>
<td headers="eth.src" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="eth.dst" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="tcp.stream" class="gt_row gt_right">NA</td>
<td headers="udp.stream" class="gt_row gt_right">0</td>
<td headers="tcp.srcport" class="gt_row gt_right">NA</td>
<td headers="tcp.dstport" class="gt_row gt_right">NA</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">NA</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">NA</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">NA</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">NA</td>
<td headers="flags_string" class="gt_row gt_left">NA</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:20.386849</td>
<td headers="frame.time_relative" class="gt_row gt_right">1.012954375</td>
<td headers="id" class="gt_row gt_right">13</td>
<td headers="eth.src" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="eth.dst" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="tcp.stream" class="gt_row gt_right">1</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">22</td>
<td headers="tcp.dstport" class="gt_row gt_right">59712</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······AP···</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:20.38685</td>
<td headers="frame.time_relative" class="gt_row gt_right">1.012954669</td>
<td headers="id" class="gt_row gt_right">14</td>
<td headers="eth.src" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="eth.dst" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="tcp.stream" class="gt_row gt_right">1</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">22</td>
<td headers="tcp.dstport" class="gt_row gt_right">59712</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······AP···</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:20.38685</td>
<td headers="frame.time_relative" class="gt_row gt_right">1.012954785</td>
<td headers="id" class="gt_row gt_right">15</td>
<td headers="eth.src" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="eth.dst" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="tcp.stream" class="gt_row gt_right">1</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">22</td>
<td headers="tcp.dstport" class="gt_row gt_right">59712</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······AP···</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:20.38685</td>
<td headers="frame.time_relative" class="gt_row gt_right">1.012954877</td>
<td headers="id" class="gt_row gt_right">16</td>
<td headers="eth.src" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="eth.dst" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="tcp.stream" class="gt_row gt_right">1</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">22</td>
<td headers="tcp.dstport" class="gt_row gt_right">59712</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······AP···</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:20.386887</td>
<td headers="frame.time_relative" class="gt_row gt_right">1.012992087</td>
<td headers="id" class="gt_row gt_right">17</td>
<td headers="eth.src" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="eth.dst" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="tcp.stream" class="gt_row gt_right">1</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">59712</td>
<td headers="tcp.dstport" class="gt_row gt_right">22</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······A····</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:20.386913</td>
<td headers="frame.time_relative" class="gt_row gt_right">1.013018078</td>
<td headers="id" class="gt_row gt_right">18</td>
<td headers="eth.src" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="eth.dst" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="tcp.stream" class="gt_row gt_right">1</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">59712</td>
<td headers="tcp.dstport" class="gt_row gt_right">22</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······A····</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:20.386919</td>
<td headers="frame.time_relative" class="gt_row gt_right">1.013023668</td>
<td headers="id" class="gt_row gt_right">19</td>
<td headers="eth.src" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="eth.dst" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="tcp.stream" class="gt_row gt_right">1</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">59712</td>
<td headers="tcp.dstport" class="gt_row gt_right">22</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······A····</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:20.386925</td>
<td headers="frame.time_relative" class="gt_row gt_right">1.013029829</td>
<td headers="id" class="gt_row gt_right">20</td>
<td headers="eth.src" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="eth.dst" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="tcp.stream" class="gt_row gt_right">1</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">59712</td>
<td headers="tcp.dstport" class="gt_row gt_right">22</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······A····</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:20.387024</td>
<td headers="frame.time_relative" class="gt_row gt_right">1.013128992</td>
<td headers="id" class="gt_row gt_right">21</td>
<td headers="eth.src" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="eth.dst" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="tcp.stream" class="gt_row gt_right">NA</td>
<td headers="udp.stream" class="gt_row gt_right">0</td>
<td headers="tcp.srcport" class="gt_row gt_right">NA</td>
<td headers="tcp.dstport" class="gt_row gt_right">NA</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">NA</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">NA</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">NA</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">NA</td>
<td headers="flags_string" class="gt_row gt_left">NA</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:20.389858</td>
<td headers="frame.time_relative" class="gt_row gt_right">1.015963063</td>
<td headers="id" class="gt_row gt_right">22</td>
<td headers="eth.src" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="eth.dst" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="tcp.stream" class="gt_row gt_right">NA</td>
<td headers="udp.stream" class="gt_row gt_right">0</td>
<td headers="tcp.srcport" class="gt_row gt_right">NA</td>
<td headers="tcp.dstport" class="gt_row gt_right">NA</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">NA</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">NA</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">NA</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">NA</td>
<td headers="flags_string" class="gt_row gt_left">NA</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:20.425969</td>
<td headers="frame.time_relative" class="gt_row gt_right">1.052074024</td>
<td headers="id" class="gt_row gt_right">23</td>
<td headers="eth.src" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="eth.dst" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="tcp.stream" class="gt_row gt_right">3</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">34838</td>
<td headers="tcp.dstport" class="gt_row gt_right">22</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······AP···</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:20.447164</td>
<td headers="frame.time_relative" class="gt_row gt_right">1.073268937</td>
<td headers="id" class="gt_row gt_right">24</td>
<td headers="eth.src" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="eth.dst" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="tcp.stream" class="gt_row gt_right">3</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">22</td>
<td headers="tcp.dstport" class="gt_row gt_right">34838</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······AP···</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:20.44795</td>
<td headers="frame.time_relative" class="gt_row gt_right">1.074054714</td>
<td headers="id" class="gt_row gt_right">25</td>
<td headers="eth.src" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="eth.dst" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="tcp.stream" class="gt_row gt_right">3</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">34838</td>
<td headers="tcp.dstport" class="gt_row gt_right">22</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······AP···</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:20.498667</td>
<td headers="frame.time_relative" class="gt_row gt_right">1.124772256</td>
<td headers="id" class="gt_row gt_right">26</td>
<td headers="eth.src" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="eth.dst" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="tcp.stream" class="gt_row gt_right">3</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">22</td>
<td headers="tcp.dstport" class="gt_row gt_right">34838</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······A····</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:20.498667</td>
<td headers="frame.time_relative" class="gt_row gt_right">1.124772542</td>
<td headers="id" class="gt_row gt_right">27</td>
<td headers="eth.src" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="eth.dst" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="tcp.stream" class="gt_row gt_right">3</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">22</td>
<td headers="tcp.dstport" class="gt_row gt_right">34838</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······AP···</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:20.498667</td>
<td headers="frame.time_relative" class="gt_row gt_right">1.124772588</td>
<td headers="id" class="gt_row gt_right">28</td>
<td headers="eth.src" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="eth.dst" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="tcp.stream" class="gt_row gt_right">3</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">22</td>
<td headers="tcp.dstport" class="gt_row gt_right">34838</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······AP···</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:20.498857</td>
<td headers="frame.time_relative" class="gt_row gt_right">1.124961796</td>
<td headers="id" class="gt_row gt_right">29</td>
<td headers="eth.src" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="eth.dst" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="tcp.stream" class="gt_row gt_right">3</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">34838</td>
<td headers="tcp.dstport" class="gt_row gt_right">22</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······A····</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:20.502722</td>
<td headers="frame.time_relative" class="gt_row gt_right">1.128827240</td>
<td headers="id" class="gt_row gt_right">30</td>
<td headers="eth.src" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="eth.dst" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="tcp.stream" class="gt_row gt_right">3</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">22</td>
<td headers="tcp.dstport" class="gt_row gt_right">34838</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······AP···</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:20.502723</td>
<td headers="frame.time_relative" class="gt_row gt_right">1.128827458</td>
<td headers="id" class="gt_row gt_right">31</td>
<td headers="eth.src" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="eth.dst" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="tcp.stream" class="gt_row gt_right">3</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">22</td>
<td headers="tcp.dstport" class="gt_row gt_right">34838</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······AP···</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:20.502866</td>
<td headers="frame.time_relative" class="gt_row gt_right">1.128970572</td>
<td headers="id" class="gt_row gt_right">32</td>
<td headers="eth.src" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="eth.dst" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="tcp.stream" class="gt_row gt_right">3</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">34838</td>
<td headers="tcp.dstport" class="gt_row gt_right">22</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······A····</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:20.504135</td>
<td headers="frame.time_relative" class="gt_row gt_right">1.130240104</td>
<td headers="id" class="gt_row gt_right">33</td>
<td headers="eth.src" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="eth.dst" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="tcp.stream" class="gt_row gt_right">3</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">22</td>
<td headers="tcp.dstport" class="gt_row gt_right">34838</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······AP···</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:20.504258</td>
<td headers="frame.time_relative" class="gt_row gt_right">1.130362876</td>
<td headers="id" class="gt_row gt_right">34</td>
<td headers="eth.src" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="eth.dst" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="tcp.stream" class="gt_row gt_right">3</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">34838</td>
<td headers="tcp.dstport" class="gt_row gt_right">22</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······A····</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:20.507027</td>
<td headers="frame.time_relative" class="gt_row gt_right">1.133131959</td>
<td headers="id" class="gt_row gt_right">35</td>
<td headers="eth.src" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="eth.dst" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="tcp.stream" class="gt_row gt_right">3</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">22</td>
<td headers="tcp.dstport" class="gt_row gt_right">34838</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······AP···</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:20.507027</td>
<td headers="frame.time_relative" class="gt_row gt_right">1.133132098</td>
<td headers="id" class="gt_row gt_right">36</td>
<td headers="eth.src" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="eth.dst" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="tcp.stream" class="gt_row gt_right">3</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">22</td>
<td headers="tcp.dstport" class="gt_row gt_right">34838</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······AP···</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:20.507027</td>
<td headers="frame.time_relative" class="gt_row gt_right">1.133132145</td>
<td headers="id" class="gt_row gt_right">37</td>
<td headers="eth.src" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="eth.dst" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="tcp.stream" class="gt_row gt_right">3</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">22</td>
<td headers="tcp.dstport" class="gt_row gt_right">34838</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······AP···</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:20.507126</td>
<td headers="frame.time_relative" class="gt_row gt_right">1.133230762</td>
<td headers="id" class="gt_row gt_right">38</td>
<td headers="eth.src" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="eth.dst" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="tcp.stream" class="gt_row gt_right">3</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">34838</td>
<td headers="tcp.dstport" class="gt_row gt_right">22</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······A····</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:20.508432</td>
<td headers="frame.time_relative" class="gt_row gt_right">1.134537452</td>
<td headers="id" class="gt_row gt_right">39</td>
<td headers="eth.src" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="eth.dst" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="tcp.stream" class="gt_row gt_right">3</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">22</td>
<td headers="tcp.dstport" class="gt_row gt_right">34838</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······AP···</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:20.508552</td>
<td headers="frame.time_relative" class="gt_row gt_right">1.134657209</td>
<td headers="id" class="gt_row gt_right">40</td>
<td headers="eth.src" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="eth.dst" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="tcp.stream" class="gt_row gt_right">3</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">34838</td>
<td headers="tcp.dstport" class="gt_row gt_right">22</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······A····</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:20.508691</td>
<td headers="frame.time_relative" class="gt_row gt_right">1.134795924</td>
<td headers="id" class="gt_row gt_right">41</td>
<td headers="eth.src" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="eth.dst" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="tcp.stream" class="gt_row gt_right">3</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">34838</td>
<td headers="tcp.dstport" class="gt_row gt_right">22</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······AP···</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:20.510818</td>
<td headers="frame.time_relative" class="gt_row gt_right">1.136923263</td>
<td headers="id" class="gt_row gt_right">42</td>
<td headers="eth.src" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="eth.dst" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="tcp.stream" class="gt_row gt_right">3</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">22</td>
<td headers="tcp.dstport" class="gt_row gt_right">34838</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······A····</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:20.909534</td>
<td headers="frame.time_relative" class="gt_row gt_right">1.535639137</td>
<td headers="id" class="gt_row gt_right">43</td>
<td headers="eth.src" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="eth.dst" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="tcp.stream" class="gt_row gt_right">4</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">3478</td>
<td headers="tcp.dstport" class="gt_row gt_right">40719</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······A····</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:20.909588</td>
<td headers="frame.time_relative" class="gt_row gt_right">1.535693325</td>
<td headers="id" class="gt_row gt_right">44</td>
<td headers="eth.src" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="eth.dst" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="tcp.stream" class="gt_row gt_right">4</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">40719</td>
<td headers="tcp.dstport" class="gt_row gt_right">3478</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······A····</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:21.421685</td>
<td headers="frame.time_relative" class="gt_row gt_right">2.047790345</td>
<td headers="id" class="gt_row gt_right">45</td>
<td headers="eth.src" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="eth.dst" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="tcp.stream" class="gt_row gt_right">0</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">3389</td>
<td headers="tcp.dstport" class="gt_row gt_right">56708</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······AP···</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:21.421689</td>
<td headers="frame.time_relative" class="gt_row gt_right">2.047793961</td>
<td headers="id" class="gt_row gt_right">46</td>
<td headers="eth.src" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="eth.dst" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="tcp.stream" class="gt_row gt_right">1</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">22</td>
<td headers="tcp.dstport" class="gt_row gt_right">59712</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······AP···</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:21.421689</td>
<td headers="frame.time_relative" class="gt_row gt_right">2.047794079</td>
<td headers="id" class="gt_row gt_right">47</td>
<td headers="eth.src" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="eth.dst" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="tcp.stream" class="gt_row gt_right">1</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">22</td>
<td headers="tcp.dstport" class="gt_row gt_right">59712</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······AP···</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:21.421689</td>
<td headers="frame.time_relative" class="gt_row gt_right">2.047794154</td>
<td headers="id" class="gt_row gt_right">48</td>
<td headers="eth.src" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="eth.dst" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="tcp.stream" class="gt_row gt_right">1</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">22</td>
<td headers="tcp.dstport" class="gt_row gt_right">59712</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······AP···</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:21.421731</td>
<td headers="frame.time_relative" class="gt_row gt_right">2.047836281</td>
<td headers="id" class="gt_row gt_right">49</td>
<td headers="eth.src" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="eth.dst" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="tcp.stream" class="gt_row gt_right">1</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">59712</td>
<td headers="tcp.dstport" class="gt_row gt_right">22</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······A····</td></tr>
    <tr><td headers="time" class="gt_row gt_right">2024-04-17 10:16:21.42175</td>
<td headers="frame.time_relative" class="gt_row gt_right">2.047855198</td>
<td headers="id" class="gt_row gt_right">50</td>
<td headers="eth.src" class="gt_row gt_left">6c:94:66:78:d4:e4</td>
<td headers="eth.dst" class="gt_row gt_left">e0:23:ff:65:52:61</td>
<td headers="tcp.stream" class="gt_row gt_right">0</td>
<td headers="udp.stream" class="gt_row gt_right">NA</td>
<td headers="tcp.srcport" class="gt_row gt_right">56708</td>
<td headers="tcp.dstport" class="gt_row gt_right">3389</td>
<td headers="tcp.flags.syn" class="gt_row gt_right">0</td>
<td headers="tcp.flags.ack" class="gt_row gt_right">1</td>
<td headers="tcp.flags.fin" class="gt_row gt_right">0</td>
<td headers="tcp.flags.reset" class="gt_row gt_right">0</td>
<td headers="flags_string" class="gt_row gt_left">·······A····</td></tr>
  </tbody>
  &#10;  
</table>
</div>

# Connections Per Second

Determining the connections per second is relatively easy. For TCP we group by each TCP stream, filter out any streams for which we haven’t seen a SYN (began before we started the packet capture) or where only see SYNs (connection never fully established). We can then count the number of SYNs that ocurred each second, then merge in the full range of time values so it’s continues across our range:

``` r
# TCP connections are based on the the first SYN seen
tcp_connections <-
    tcp_segments |>
    # Conver back from POSIXct to integer
    mutate(time = as.integer(time)) |> 
    group_by(tcp.stream) |> 
    # Filter out any where by haven't seen the initial SYN
    filter(any(tcp.flags.syn == 1 & tcp.flags.ack == 0)) |>
    # Filter out any where we've ONLY seen the initial SYN
    filter(!all(tcp.flags.syn == 1)) |> 
    ungroup() |> 
    # Group by each second and count the number of SYNs
    group_by(time) |>
    summarise(cps = sum(tcp.flags.syn)) |> 
    # Fill in any missing gaps in our time columns
    full_join(
        tibble(
            time = as.integer( first(tcp_segments$time):last(tcp_segments$time) ),
        ),
        by = 'time'
    ) |>
    arrange(time) |>
    # The merged in rows are implicitly 0 
    mutate(cps = replace_na(cps, 0))
```

UDP has no concept of a conneciton, so we group by UDP stream, filter for the first datagram in each stream that has more than one datagram:

``` r
# UDP connections based simply on first datagram per stream seen
udp_connections <-
    udp_datagrams |>
    mutate(time = as.integer(time)) |> 
    group_by(udp.stream) |>
    # Filter out the first datagram in streams with more than one datagram
    filter(row_number() == 1 & n() > 1) |>
    ungroup() |>
    count(time, name = 'cps') |> 
    full_join(
        tibble(
            time = as.integer( first(udp_datagrams$time):last(udp_datagrams$time) ),
        ),
        by = 'time'
    ) |> 
    arrange(time) |> 
    mutate(cps = replace_na(cps, 0))

# Merge TCP and UDP back together
connections_per_second <- 
    bind_rows(tcp = tcp_connections, udp = udp_connections, .id = 'protocol')
```

We merge these two dataframes together and can

    Warning: Removed 2 rows containing missing values or values outside the scale range
    (`geom_bar()`).

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-3-1.png" width="672" />

# Connection Length

We now need to calculate the session length for each TCP and UDP stream. While the initial start of the TCP stream is well defined, the end is a bit messier. They don’t all end with a nice FIN/FIN-ACK, and even if they do often you’ll see an RST come through 20 to 30 seconds later. Here’s a breakdown of the TCP flags for the last segment in each of the TCP streams:

<div id="ucvqyswtcs" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#ucvqyswtcs table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#ucvqyswtcs thead, #ucvqyswtcs tbody, #ucvqyswtcs tfoot, #ucvqyswtcs tr, #ucvqyswtcs td, #ucvqyswtcs th {
  border-style: none;
}
&#10;#ucvqyswtcs p {
  margin: 0;
  padding: 0;
}
&#10;#ucvqyswtcs .gt_table {
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
&#10;#ucvqyswtcs .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#ucvqyswtcs .gt_title {
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
&#10;#ucvqyswtcs .gt_subtitle {
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
&#10;#ucvqyswtcs .gt_heading {
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
&#10;#ucvqyswtcs .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#ucvqyswtcs .gt_col_headings {
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
&#10;#ucvqyswtcs .gt_col_heading {
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
&#10;#ucvqyswtcs .gt_column_spanner_outer {
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
&#10;#ucvqyswtcs .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#ucvqyswtcs .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#ucvqyswtcs .gt_column_spanner {
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
&#10;#ucvqyswtcs .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#ucvqyswtcs .gt_group_heading {
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
&#10;#ucvqyswtcs .gt_empty_group_heading {
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
&#10;#ucvqyswtcs .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#ucvqyswtcs .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#ucvqyswtcs .gt_row {
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
&#10;#ucvqyswtcs .gt_stub {
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
&#10;#ucvqyswtcs .gt_stub_row_group {
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
&#10;#ucvqyswtcs .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#ucvqyswtcs .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#ucvqyswtcs .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#ucvqyswtcs .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#ucvqyswtcs .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#ucvqyswtcs .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#ucvqyswtcs .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#ucvqyswtcs .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#ucvqyswtcs .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#ucvqyswtcs .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#ucvqyswtcs .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#ucvqyswtcs .gt_footnotes {
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
&#10;#ucvqyswtcs .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#ucvqyswtcs .gt_sourcenotes {
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
&#10;#ucvqyswtcs .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#ucvqyswtcs .gt_left {
  text-align: left;
}
&#10;#ucvqyswtcs .gt_center {
  text-align: center;
}
&#10;#ucvqyswtcs .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#ucvqyswtcs .gt_font_normal {
  font-weight: normal;
}
&#10;#ucvqyswtcs .gt_font_bold {
  font-weight: bold;
}
&#10;#ucvqyswtcs .gt_font_italic {
  font-style: italic;
}
&#10;#ucvqyswtcs .gt_super {
  font-size: 65%;
}
&#10;#ucvqyswtcs .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#ucvqyswtcs .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#ucvqyswtcs .gt_indent_1 {
  text-indent: 5px;
}
&#10;#ucvqyswtcs .gt_indent_2 {
  text-indent: 10px;
}
&#10;#ucvqyswtcs .gt_indent_3 {
  text-indent: 15px;
}
&#10;#ucvqyswtcs .gt_indent_4 {
  text-indent: 20px;
}
&#10;#ucvqyswtcs .gt_indent_5 {
  text-indent: 25px;
}
</style>
<table class="gt_table" data-quarto-disable-processing="false" data-quarto-bootstrap="false">
  <thead>
    <tr class="gt_col_headings">
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="TCP Flags">TCP Flags</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="Count">Count</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr><td headers="flags_string" class="gt_row gt_left">·········R··</td>
<td headers="n" class="gt_row gt_right">1824</td></tr>
    <tr><td headers="flags_string" class="gt_row gt_left">·······A····</td>
<td headers="n" class="gt_row gt_right">916</td></tr>
    <tr><td headers="flags_string" class="gt_row gt_left">·······A·R··</td>
<td headers="n" class="gt_row gt_right">652</td></tr>
    <tr><td headers="flags_string" class="gt_row gt_left">··········S·</td>
<td headers="n" class="gt_row gt_right">34</td></tr>
    <tr><td headers="flags_string" class="gt_row gt_left">·······A···F</td>
<td headers="n" class="gt_row gt_right">25</td></tr>
    <tr><td headers="flags_string" class="gt_row gt_left">·······AP··F</td>
<td headers="n" class="gt_row gt_right">13</td></tr>
    <tr><td headers="flags_string" class="gt_row gt_left">·······AP···</td>
<td headers="n" class="gt_row gt_right">3</td></tr>
  </tbody>
  &#10;  
</table>
</div>

We’ll keep it simple an take the duration to be the time between the first and last segment seen in the packet capture:

``` r
tcp_session_duration <-
    tcp_segments |>
    group_by(tcp.stream) |>
    # Filter out any where by haven't seen the initial SYN
    filter(any(tcp.flags.syn == 1 & tcp.flags.ack == 0)) |>
    # Filter out any where we've ONLY seen the initial SYN
    filter(!all(tcp.flags.syn == 1)) |>
    # Remove streams with no RST or FIN
    filter(!any(tcp.flags.fin) | !any(tcp.flags.reset)) |> 
    # Calculate the duration
    summarise(duration = last(frame.time_relative) - first(frame.time_relative)) |>
    rename(stream = tcp.stream)
```

We’ll do the same for UDP, then merge the two dataframes together:

``` r
# UDP session length
udp_session_duration <-
    udp_datagrams |>
    group_by(udp.stream) |>
    filter(n() != 1) |>
    summarise(duration = last(frame.time_relative) - first(frame.time_relative)) |>
    rename(stream = udp.stream)

session_duration <- 
    bind_rows(tcp = tcp_session_duration, udp = udp_session_duration, .id = 'protocol') 
```

``` r
session_duration |> 
    ggplot() +
    geom_histogram(aes(duration, after_stat(density), fill = protocol), bins = 256) +
    scale_x_continuous(limits = c(10, 130)) +
    labs(
        title = 'TCP and UDP - Session Duration Density',
        subtitle = 'X-Axis Range Limited (0, 130)',
        x = 'Duration (Seconds)',
        y = 'Density',
        fill = 'Protocol'
    )
```

    Warning: Removed 9370 rows containing non-finite outside the scale range
    (`stat_bin()`).

    Warning: Removed 4 rows containing missing values or values outside the scale range
    (`geom_bar()`).

<img src="{{< blogdown/postref >}}index_files/figure-html/session_histogram-1.png" width="672" />

# Modelling

    data {
      int<lower = 0> n_cps, n_duration;
      array[n_cps] int cps;
      vector[n_duration] duration;
    }
    parameters { 
        //cps neg_binomial() parameters
        real<lower = 0> nb_alpha;
        real<lower = 0> nb_beta;
        
        //duration gamma() parameteres 
        real<lower = 0> g_alpha;
        real<lower = 0> g_beta;
    }
    model {
        // negative binomial priors
        nb_alpha ~ exponential(.5);
        nb_beta ~ exponential(.5);
        
        //gamma priors
        g_alpha ~ exponential(.5);
        g_beta ~ exponential(.5);
        
        //model
        cps ~ neg_binomial(nb_alpha, nb_beta);
        duration ~ gamma(g_alpha, g_beta);
    }

    generated quantities {
        array[1000] int cps_sim;
        array[1000] real duration_sim;
        
        for (n in 1:1000) {
            cps_sim[n] = neg_binomial_rng(nb_alpha, nb_beta);
            duration_sim[n] = gamma_rng(g_alpha, g_beta);
        }
    }

``` r
tcp_fit |> 
    gather_draws(nb_alpha, nb_beta, g_alpha, g_beta) |>
    recover_types() |> 
    ggplot() +
    geom_line(aes(.iteration, .value, colour = as_factor(.chain)), alpha = .8) +
    facet_grid(vars(.variable), scales = 'free_y')
```

<img src="{{< blogdown/postref >}}index_files/figure-html/assess_chains-1.png" width="672" />

``` r
tcp_fit |> 
    gather_draws(nb_alpha, nb_beta, g_alpha, g_beta) |>
    recover_types() |> 
    ggplot() +
    geom_histogram(aes(.value, fill = as.factor(.chain)), bins = 100) +
    facet_wrap(vars(.variable), scales = 'free')
```

<img src="{{< blogdown/postref >}}index_files/figure-html/assess_chains-2.png" width="672" />
<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-5-1.png" width="672" />

``` r
tcp_fit |>
    recover_types() |>
    spread_draws(duration_sim[i]) |>
    transmute(duration = duration_sim) |> 
    bind_rows(real = _, simulated = session_duration, .id = 'set') |> 
    ggplot() +
    geom_histogram(aes(duration, after_stat(density), fill = set), binwidth = 1) +
    scale_x_continuous(limits = c(-1, 25)) +
    facet_wrap(~set) +
    labs(
        title = 'TCP and UDP - Session Duration - Real vs. Simulated Datasets',
        subtitle = 'Density Histogram',
        x = 'Duration (Seconds)',
        y = 'Density',
        fill = 'Data Set'
    )
```

    Warning: Removed 1387506 rows containing non-finite outside the scale range
    (`stat_bin()`).

    Warning: Removed 4 rows containing missing values or values outside the scale range
    (`geom_bar()`).

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-6-1.png" width="672" />

# Simulating Users

``` r
posterior_distros <-
    tcp_fit |>
    recover_types() |>
    spread_draws(cps_sim[i], duration_sim[i])
```

``` r
# This function takes a vector of durations and returns a vector of
# connections initiated at each point int time.
connections <- function(duration) {
    n <- length(duration)
    concurrent <- rep(0, n) 
    
    for (x in 1:n) {
        duration_len <- length(duration[[x]])
        # duration[x] is a list of doubles
        if(duration_len == 0) { next }
        
        for (y in 1:length(duration_len)) {
            # Increase the connection at the current time
            concurrent[x] <- concurrent[x] + 1
            
            # Decrease the connections after the duration
            #session_duration <- ceiling(duration[[x]])
            session_duration <- ceiling(duration[[x]][y])
            
            session_end <- x + session_duration
           
            # Don't decrement if it's past the end of our session window 
            if (session_end > n) {
                next
            }
            
            concurrent[session_end] <- concurrent[session_end] - 1
        }
    }
    
    concurrent
}
```

``` r
# What's our 'real' concurrent connections per second?
real_concurrent_connections <-
    tcp_segments |>
    arrange(time) |> 
    mutate(time = as.integer(time)) |> 
    group_by(tcp.stream) |> 
    # Filter out any where by haven't seen the initial SYN
    filter(any(tcp.flags.syn == 1 & tcp.flags.ack == 0)) |>
    # Filter out any where we've ONLY seen the initial SYN
    filter(!all(tcp.flags.syn == 1)) |>
    mutate(
        start_end = case_when(
            row_number() == 1 ~ 1,
            row_number() == n() ~ -1,
            .default = 0
        )
    ) |>
    ungroup() |> 
    select(time, tcp.stream, start_end) |> 
    full_join(
        tibble(
            time = as.integer( first(pcap_reduced$time):last(pcap_reduced$time) ),
        ),
        by = 'time'
    ) |>
    arrange(time) |>
    mutate(start_end = replace_na(start_end, 0)) |> 
    group_by(time) |>
    summarise(connections_per_second = sum(start_end)) |>
    mutate(concurrent_connections = cumsum(connections_per_second)) |>
    select(time, concurrent_connections) |>
    mutate(time = (time - first(time) + 1))
```

``` r
simulated_concurrent_connections <-
    expand_grid(
       time = 1:last(real_concurrent_connections$time),
       user = 1,
    ) |>
    mutate(
        cps = sample(posterior_distros$cps_sim, size = n(), replace = TRUE),
        duration = map(cps, ~{ sample(posterior_distros$duration_sim, size = .x, replace = TRUE) })
    ) |> 
    group_by(time) |>
    summarise(duration = list(unlist(duration)) ) |>  
    mutate(
        connections = connections(duration),
        concurrent_connections = cumsum(connections)
    ) |>
    select(time, concurrent_connections)

real_distro_drawn_connections <-
    expand_grid(
       time = 1:last(real_concurrent_connections$time),
       user = 1,
    ) |>
    mutate(
        cps = sample(tcp_connections$cps, size = n(), replace = TRUE),
        duration = map(cps, ~{ sample(tcp_session_duration$duration, size = .x, replace = TRUE) })
    ) |> 
    group_by(time) |>
    summarise(duration = list(unlist(duration)) ) |>  
    mutate(
        connections = connections(duration),
        concurrent_connections = cumsum(connections)
    ) |>
    select(time, concurrent_connections)
```

``` r
connection_datasets <-
    bind_rows(
        real_concurrent_connections,
        simulated_concurrent_connections,
        real_distro_drawn_connections,
        .id = 'dataset'
    )

connection_datasets |> 
    mutate(set  = case_when(dataset == 1 ~ 'real', dataset == 2 ~ 'simulated_synthetic', dataset == 3 ~ 'simulated_real')) |>
    ggplot() +
    geom_point(aes(time, concurrent_connections, colour = set), size = .1, alpha = .5)
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-10-1.png" width="672" />

``` r
connection_datasets |> 
    mutate(set  = case_when(dataset == 1 ~ 'real', dataset == 2 ~ 'simulated_synthetic', dataset == 3 ~ 'simulated_real')) |>
    ggplot() +
    geom_histogram(aes(concurrent_connections, after_stat(density), group = set, fill = set), binwidth = 1, alpha = .5) +
    facet_grid(~set)
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-10-2.png" width="672" />

``` r
map(c(1:10), ~{ expand_grid(users = .x, user = 1:.x, time = 1:(60 * 60 * 3)) }) |> 
    bind_rows() |>
    group_by(users) |>
    mutate(
        cps = sample(posterior_distros$cps_sim, size = n(), replace = TRUE),
        duration = map(cps, ~{ sample(posterior_distros$duration_sim, size = .x, replace = TRUE) })
    ) |>
    group_by(users, time) |> 
    summarise(duration = list(unlist(duration)), .groups = 'drop_last') |>
    mutate(
        connections = connections(duration),
        concurrent_connections = cumsum(connections)
    ) |>
    ggplot() +
    geom_histogram(aes(concurrent_connections, fill = as.factor(users), group = as.factor(users)), binwidth = 1, alpha = .7)
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-11-1.png" width="672" />

``` r
    #geom_boxplot(aes(users, concurrent_connections, group = users))
```
