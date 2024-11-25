---
title: 'A Day in the Life: The Global BGP Table'
author: Greg Foletta
date: '2024-11-12'
slug: []
categories: [C BGP Networking]
---

Much has been written and a lot of analysis performed on the global BGP table over the years, a significant portion by the inimitable [Geoff Huston](https://bgp.potaroo.net/). However this often focuses on is long term trends, like the growth of the routing table or the adoption of IPv6 , dealing with time frames of of months or years.

I was more interested in what was happening in the short term: what does it look like on the front line for those poor routers connected to the churning, foamy chaos of the interenet, trying their best to adhere to [Postel’s Law](https://en.wikipedia.org/wiki/Robustness_principle)? What we’ll look at in this article is “a day in the life of the global BGP table”, exploring the intra-day shenanigans with an eye to finding some of the ridiculous things that go on out.

We’ll focus in on three key areas:
- General behaviour over the course of the day
- Outlier path attributes
- Flappy paths

As you’ll see, we end up with more questions than answers, but I think that’s the hallmark of good exploratory work. Let’s dive in.

# Let the Yak Shaving Begin

The first step, as always, is to get some data to work with. Parsing the debug outputs from various routers seemed like a recipe for disaster, so instead I did a little yak-shaving. I went back to a half-finished project BGP daemon I’d started writing years ago into a working state. The result is **[bgpsee](https://github.com/gregfoletta/bgpsee)**, a multi-threaded BGP peering tool for the CLI. Once peered with another router, all the BGP messages like OPENs, KEEPALIVES, and most importantly UPDATEs, are parsed and output as JSON.

For example, heres one of the BGP updates from the dataset we’re working with in this article:

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
      "origin": "IGP"
    },
    {
      "type": "AS_PATH", "type_code": 2,
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
      "next_hop": "61.245.147.114"
    },
    {
      "type": "AS4_PATH", "type_code": 17,
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

Collected between the 6/1/2024 tot he 7/1/2024, the full dataset consists of 464,673 BGP UPDATE messages received from a peer (thanks [Andrew Vinton](https://www.linkedin.com/in/andrew-vinton/)) with a full BGP table. Let’s take a look at how this full table behaves over the course of the day.

# Initial Send, Number of v4 and v6 Paths

When you first bring up a BGP peering with a router you get a big dump of of UPDATEs, what I’ll call the ‘first tranche’. It consists of all paths and associated network layer reachability information (NLRI, or more simply ‘routes’) in the router’s BGP table. After this first tranche, the peering only receives UPDATEs for paths that have changed, or withdrawn routes which no longer have any paths. There’s no structural difference between the batch and the ongoing UPDATEs, except for the fact you received the first batch in the first 5 or so seconds of the peering coming up.

Here’s a breakdown of the number of distinct paths received in that first batch, separated into IPv4 vs IPv6:

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-7-1.png" width="672" />
It’s important to highlight that this is a count of BGP paths, **not** routes. Each path is a unique combination of path attributes with associated NLRI information attached, sent in a distinct BGP UPDATE message. There could be one, or one-thousand routes associated with each path. In this first tranche the total number of routes across all of these paths is 949483.

# A Garden Hose or a Fire Hose?

That’s all we’ll to look at in the first tranche, so we focus our attention to the rest of the updates received across the day. The updates aren’t sent as a real-time stream, but in bunches based on the [Route Advertisement Interval](https://datatracker.ietf.org/doc/html/rfc4271#section-10) timer, which for this peering was 30 seconds.

![](index_files/figure-html/unnamed-chunk-8-1.gif)<!-- -->
So for IPv4 paths, you’re looking on average at around 50 path updates every 30 seconds. For IPv6 it’s slightly lower, at around 47 path updates. While the averages are close, the variance is quite different, a standard deviation of 64.3 and 43 for v4 and v6 respectively.

Instead of looking at the total count of udpates, we can instead look at the total aggregate IP address change. We do this by adding up the total amount of IP addresses across all updates for every 30 seconds interval, then take the log2() of the sum. So for example: a /2, a /23 and a /24 would be \\(log_2(2^{32-22} + 2^{32-23} + 2^{32-24})\\)

Below is the time series and the density of the log2() of the IPv4 space advertised during the day. It shows that on average, every 30 seconds, around 2^16 IP addresses (i.e a /16) change paths in the global routing table, with 95% falling between is between \\(2^{20.75}\\) (approx. a /11) and \\(2^{13.85}\\) (approx. a ~/18).

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-9-1.png" width="672" />

What is apparent in both the path and IP space changes over time is that there is some sort of cyclic behaviourin the IPv4 updates. To determine the period of this cycle we can use an [ACF](https://otexts.com/fpp3/acf.html) or autocorrelation plot. We’ll calculate the correlation between the number of paths received at time \\(y_t\\) versus the number received at \\(y\_{t-{1,2,3,…,n}}\\). I’ve grouped the updates together into 1 minute intervals, so 1 lag = 1 minute.

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-10-1.png" width="672" />
There is a strong correlation in the first 7 or so lags, which intuitively makes sense to me as path changes have the potentia to create other path changes as they propagate around the world. But there also appears to be strong correlation at lags 40 and 41, indicating some cyclic behaviour every forty minutes. This gives us the first question which I’ll leave unanswered: *why does the global IPv4 BGP table have a 40 minute cycle?*.

# Prepending Madness

If you’re a network admin, there’s a couple of different ways you can influence how traffic entering your ASN. You can use longer network prefixes, but this doesn’t scale well and you’re not being a polite BGP citizen. You can use the MED attribute, but it’s non-transitive so it doesn’t work if you’re peered to multiple AS. Primarily you’ll modify the AS path length by prepending your own AS one or more times.

The issue is that some people take this prepending too far, which has in the past caused [large, global problems](https://blog.ipspace.net/2009/02/root-cause-analysis-oversized-as-paths/). In the graphic below we show the top 50 AS path lengths for IPv4 and IPv6 updates respectively:

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-11-1.png" width="672" />
What stands out is the difference between IPv4 and IPv6. The largest IPv4 path length is 105, which is still ridiculous given the fact that the largest non-prepended path in this dataset has a length of 14. But compared to the IPv6 paths it’s outright sensible: top of the table for IPv6 comes in at a whopping 599 ASes! An AS path is actually made up of one or more [AS sets or AS sequences](https://datatracker.ietf.org/doc/html/rfc4271#section-5.1.2), each of which have a maximum length of 255. So it’s taken three AS sequences to announce those routes.

Here’s the longest IPv4 path in all it’s glory with its 105 ASNs. It originated from AS149381 “Dinas Komunikasi dan Informatika Kabupaten Tulungagung” in Indonesia.

    [1] "45270 4764 9002 136106 45305 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381"

We see that around 6 hours and 50 minutes later they realise the error in their ways and announce a path with only four ASes, rather than 105:

<div id="qnbnambcbz" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#qnbnambcbz table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#qnbnambcbz thead, #qnbnambcbz tbody, #qnbnambcbz tfoot, #qnbnambcbz tr, #qnbnambcbz td, #qnbnambcbz th {
  border-style: none;
}
&#10;#qnbnambcbz p {
  margin: 0;
  padding: 0;
}
&#10;#qnbnambcbz .gt_table {
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
&#10;#qnbnambcbz .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#qnbnambcbz .gt_title {
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
&#10;#qnbnambcbz .gt_subtitle {
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
&#10;#qnbnambcbz .gt_heading {
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
&#10;#qnbnambcbz .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#qnbnambcbz .gt_col_headings {
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
&#10;#qnbnambcbz .gt_col_heading {
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
&#10;#qnbnambcbz .gt_column_spanner_outer {
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
&#10;#qnbnambcbz .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#qnbnambcbz .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#qnbnambcbz .gt_column_spanner {
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
&#10;#qnbnambcbz .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#qnbnambcbz .gt_group_heading {
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
&#10;#qnbnambcbz .gt_empty_group_heading {
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
&#10;#qnbnambcbz .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#qnbnambcbz .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#qnbnambcbz .gt_row {
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
&#10;#qnbnambcbz .gt_stub {
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
&#10;#qnbnambcbz .gt_stub_row_group {
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
&#10;#qnbnambcbz .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#qnbnambcbz .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#qnbnambcbz .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#qnbnambcbz .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#qnbnambcbz .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#qnbnambcbz .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#qnbnambcbz .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#qnbnambcbz .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#qnbnambcbz .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#qnbnambcbz .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#qnbnambcbz .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#qnbnambcbz .gt_footnotes {
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
&#10;#qnbnambcbz .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#qnbnambcbz .gt_sourcenotes {
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
&#10;#qnbnambcbz .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#qnbnambcbz .gt_left {
  text-align: left;
}
&#10;#qnbnambcbz .gt_center {
  text-align: center;
}
&#10;#qnbnambcbz .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#qnbnambcbz .gt_font_normal {
  font-weight: normal;
}
&#10;#qnbnambcbz .gt_font_bold {
  font-weight: bold;
}
&#10;#qnbnambcbz .gt_font_italic {
  font-style: italic;
}
&#10;#qnbnambcbz .gt_super {
  font-size: 65%;
}
&#10;#qnbnambcbz .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#qnbnambcbz .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#qnbnambcbz .gt_indent_1 {
  text-indent: 5px;
}
&#10;#qnbnambcbz .gt_indent_2 {
  text-indent: 10px;
}
&#10;#qnbnambcbz .gt_indent_3 {
  text-indent: 15px;
}
&#10;#qnbnambcbz .gt_indent_4 {
  text-indent: 20px;
}
&#10;#qnbnambcbz .gt_indent_5 {
  text-indent: 25px;
}
&#10;#qnbnambcbz .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#qnbnambcbz div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>
<table class="gt_table" data-quarto-disable-processing="false" data-quarto-bootstrap="false">
  <thead>
    <tr class="gt_col_headings">
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="recv_time">recv_time</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_center" rowspan="1" colspan="1" scope="col" id="time_difference">time_difference</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="id">id</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="as_path_length">as_path_length</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="type">type</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="nlri">nlri</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr><td headers="recv_time" class="gt_row gt_right">2024-01-06 06:31:18</td>
<td headers="time_difference" class="gt_row gt_center">NA</td>
<td headers="id" class="gt_row gt_right">66121</td>
<td headers="as_path_length" class="gt_row gt_right">105</td>
<td headers="type" class="gt_row gt_left">UPDATE</td>
<td headers="nlri" class="gt_row gt_right">103.179.250.0/24</td></tr>
    <tr><td headers="recv_time" class="gt_row gt_right">2024-01-06 13:21:35</td>
<td headers="time_difference" class="gt_row gt_center">6.84</td>
<td headers="id" class="gt_row gt_right">280028</td>
<td headers="as_path_length" class="gt_row gt_right">4</td>
<td headers="type" class="gt_row gt_left">UPDATE</td>
<td headers="nlri" class="gt_row gt_right">103.179.250.0/24</td></tr>
  </tbody>
  &#10;  
</table>
</div>

Here’s the largest IPv6 path, with its mammoth 599 prefixes; I’ll let you all enjoy scrolling to the right on this one:

    [1] "45270 4764 2914 29632 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 200579 200579 203868"

Interestingly it’s not the originator that’s prepending, but as8772 ‘NetAssist LLC’, an ISP out of Ukraine prepending to make paths to asn203868 (Rifqi Arief Pamungkas, again out of Indonesia).

Why is there such a difference between the largest IPv4 and IPv6 path lengths? I had a couple of different theories, but then looked at the total number of ASNs in *all* positions in the path for those top 50 longest paths, and it became apparent what was happening:

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-15-1.png" width="672" />
Looks like they let the network admin at NetAssist (8772) on to the tools too early!

# Path Attributes

Each BGP update consist of network layer reachability information (routes) and path attributes. For example AS_PATH, NEXT_HOP, etc. There are four kinds of attributes:

1.  Well-known mandatory
2.  Well-known discretionary
3.  Optional transitive
4.  Optional non-transitive

[Section 5](https://datatracker.ietf.org/doc/html/rfc4271#section-5) of RFC4271 has a good description of all of these.

What we can do is take a look at the number of attributes we’ve seen across all of our IPv4 paths, placing this on on a log scale to make it easier to view:

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-17-1.png" width="672" />

The well-known mandatory attributes, ORIGIN, NEXT_HOP, and AS_PATH, are present in all updates, and have the same counts. There’s a few other common attributes (e.g. AGGREGATOR), and some less common ones (AS_PATHLIMIT and ATTR_SET). However some ASes have attached attribute 255, which is the [reserved for development](https://www.rfc-editor.org/rfc/rfc2042.html) attribute, to their updates.

Now at the time of receiving the updates my bgpsee daemon didn’t save value of these esoteric path attributes. But using [routeviews.org](https://routeviews.org) we can see that some ASes are still announcing paths with this reserved for development attribute and observe its raw values:

    - AS265999 attrib. 255 value:       0000 07DB 0000 0001 0001 000A FF08 0000 0000 0C49 75B3
    - AS10429 attrib. 255 value:        0000 07DB 0000 0001 0001 000A FF08 0000 0003 43DC 75C3
    - AS52564 attrib. 255 valuue:       0000 07DB 0000 0001 0001 0012 FF10 0000 0000 0C49 75B3 0000 0000 4003 F1C9

Three different ISPs, all announcing paths with this strange path attribute, and raw bytes of the attribute having a similar structure.

This leads us to the second question which I’ll leave here without an answer: *what vendor is deciding it’s a good idea to use this reserved for development attribute, and what are they using it for?*.

# Flippy-Flappy: Who’s Having a Bad Time?

Finally, let’s see who’s having a bad time: which routes are shifting paths or being withdrawn completely the most during the day. Here’s the top 10 active NLRIs with the number of times the route was included in an UPDATE:

<div id="vzzqlmdkdg" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#vzzqlmdkdg table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#vzzqlmdkdg thead, #vzzqlmdkdg tbody, #vzzqlmdkdg tfoot, #vzzqlmdkdg tr, #vzzqlmdkdg td, #vzzqlmdkdg th {
  border-style: none;
}
&#10;#vzzqlmdkdg p {
  margin: 0;
  padding: 0;
}
&#10;#vzzqlmdkdg .gt_table {
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
&#10;#vzzqlmdkdg .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#vzzqlmdkdg .gt_title {
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
&#10;#vzzqlmdkdg .gt_subtitle {
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
&#10;#vzzqlmdkdg .gt_heading {
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
&#10;#vzzqlmdkdg .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#vzzqlmdkdg .gt_col_headings {
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
&#10;#vzzqlmdkdg .gt_col_heading {
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
&#10;#vzzqlmdkdg .gt_column_spanner_outer {
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
&#10;#vzzqlmdkdg .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#vzzqlmdkdg .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#vzzqlmdkdg .gt_column_spanner {
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
&#10;#vzzqlmdkdg .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#vzzqlmdkdg .gt_group_heading {
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
&#10;#vzzqlmdkdg .gt_empty_group_heading {
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
&#10;#vzzqlmdkdg .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#vzzqlmdkdg .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#vzzqlmdkdg .gt_row {
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
&#10;#vzzqlmdkdg .gt_stub {
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
&#10;#vzzqlmdkdg .gt_stub_row_group {
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
&#10;#vzzqlmdkdg .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#vzzqlmdkdg .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#vzzqlmdkdg .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#vzzqlmdkdg .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#vzzqlmdkdg .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#vzzqlmdkdg .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#vzzqlmdkdg .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#vzzqlmdkdg .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#vzzqlmdkdg .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#vzzqlmdkdg .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#vzzqlmdkdg .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#vzzqlmdkdg .gt_footnotes {
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
&#10;#vzzqlmdkdg .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#vzzqlmdkdg .gt_sourcenotes {
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
&#10;#vzzqlmdkdg .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#vzzqlmdkdg .gt_left {
  text-align: left;
}
&#10;#vzzqlmdkdg .gt_center {
  text-align: center;
}
&#10;#vzzqlmdkdg .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#vzzqlmdkdg .gt_font_normal {
  font-weight: normal;
}
&#10;#vzzqlmdkdg .gt_font_bold {
  font-weight: bold;
}
&#10;#vzzqlmdkdg .gt_font_italic {
  font-style: italic;
}
&#10;#vzzqlmdkdg .gt_super {
  font-size: 65%;
}
&#10;#vzzqlmdkdg .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#vzzqlmdkdg .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#vzzqlmdkdg .gt_indent_1 {
  text-indent: 5px;
}
&#10;#vzzqlmdkdg .gt_indent_2 {
  text-indent: 10px;
}
&#10;#vzzqlmdkdg .gt_indent_3 {
  text-indent: 15px;
}
&#10;#vzzqlmdkdg .gt_indent_4 {
  text-indent: 20px;
}
&#10;#vzzqlmdkdg .gt_indent_5 {
  text-indent: 25px;
}
&#10;#vzzqlmdkdg .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#vzzqlmdkdg div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>
<table class="gt_table" data-quarto-disable-processing="false" data-quarto-bootstrap="false">
  <thead>
    <tr class="gt_col_headings">
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="nlri">nlri</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="update_count">update_count</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr><td headers="nlri" class="gt_row gt_right">140.99.244.0/23</td>
<td headers="update_count" class="gt_row gt_right">2596</td></tr>
    <tr><td headers="nlri" class="gt_row gt_right">107.154.97.0/24</td>
<td headers="update_count" class="gt_row gt_right">2583</td></tr>
    <tr><td headers="nlri" class="gt_row gt_right">45.172.92.0/22</td>
<td headers="update_count" class="gt_row gt_right">2494</td></tr>
    <tr><td headers="nlri" class="gt_row gt_right">151.236.111.0/24</td>
<td headers="update_count" class="gt_row gt_right">2312</td></tr>
    <tr><td headers="nlri" class="gt_row gt_right">205.164.85.0/24</td>
<td headers="update_count" class="gt_row gt_right">2189</td></tr>
    <tr><td headers="nlri" class="gt_row gt_right">41.209.0.0/18</td>
<td headers="update_count" class="gt_row gt_right">2069</td></tr>
    <tr><td headers="nlri" class="gt_row gt_right">143.255.204.0/22</td>
<td headers="update_count" class="gt_row gt_right">2048</td></tr>
    <tr><td headers="nlri" class="gt_row gt_right">176.124.58.0/24</td>
<td headers="update_count" class="gt_row gt_right">1584</td></tr>
    <tr><td headers="nlri" class="gt_row gt_right">187.1.11.0/24</td>
<td headers="update_count" class="gt_row gt_right">1582</td></tr>
    <tr><td headers="nlri" class="gt_row gt_right">187.1.13.0/24</td>
<td headers="update_count" class="gt_row gt_right">1580</td></tr>
  </tbody>
  &#10;  
</table>
</div>

Looks like anyone on **140.99.244.0/23** was having a bad time. Hilariously this space is owned by a company called [EpicUp](https://www.epicup.com/)… more like EpicDown! \*groans\*.Graphing the updates and complete withdraws over the course of the day paints a bad picture

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-19-1.png" width="672" />
The top graph looks like a straight line, but that’s because this route is present in almost every single 30 second block of updates. There are 2,879 30-second blocks and it’s present as either a different path or a withdrawn route in 2,637 of them, or 92.8%!

We know the routes is flapping, but *how* is it flapping, and who is to blame? The best way to visualise this is a graph, placing all the ASNs that exist in paths announcing this network as on a graph, then colourising the edges by how many updates were seen with each pair of ASes. I’ve binned the number of updates into blocks of 300:

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-21-1.png" width="672" />
What a mess! You can make out the primary path down the centre through NTT (2914) and Lumen/Level3 (3356), but for whatever reason (bad link? power outages? who knows) the path is moving between these tier 1 ISPS and others, including Arelion (1299) and PCCW (3419). While it’s almost impossible to identify the know the exact reason using this data only, what it does show is the amazing diversity of peering of modern global networks, and the marvel of a ~33 year old routing protocol!

# Just The Beginning

There’s a big problem with a data set like this: it’s to interesting! You can see
