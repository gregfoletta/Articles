---
title: 'A Day in the Life: The BGP Table'
author: Greg Foletta
date: '2024-11-12'
slug: []
categories: [C BGP Networking]
---

<script src="{{< blogdown/postref >}}index_files/core-js/shim.min.js"></script>
<script src="{{< blogdown/postref >}}index_files/react/react.min.js"></script>
<script src="{{< blogdown/postref >}}index_files/react/react-dom.min.js"></script>
<script src="{{< blogdown/postref >}}index_files/reactwidget/react-tools.js"></script>
<script src="{{< blogdown/postref >}}index_files/htmlwidgets/htmlwidgets.js"></script>
<link href="{{< blogdown/postref >}}index_files/reactable/reactable.css" rel="stylesheet" />
<script src="{{< blogdown/postref >}}index_files/reactable-binding/reactable.js"></script>

Much has been written and a lot of analysis performed on the global BGP table over the years, a significant portion by the inimitable [Geoff Huston](https://bgp.potaroo.net/). However this often focuses on is long term trends, like the growth of the routing table or the adoption of IPv6 , dealing with timeframes of of months or years.

I was interested in what was happening in the short term: what does it look like on the front line for those poor routers connected to the churning, foamy chaos of the interenet, trying their best to adhere to [Postel’s Law](https://en.wikipedia.org/wiki/Robustness_principle)? In this article we’ll take a look at a day in the life of the global BGP tabale, investigating the intra-day shenanigans with an eye to finding some of the ridiculous things that go on out there.

There’s a problem with this: the data set it really interesting. I could go on for hours looking at different aspects of it. That doesn’t make for the most compelling of articles, so I’ve focuesed on three areas:

- The behaviour over the course of the day
- Outlier path attributes
- Noisy neighbours

Let’s dive in.

# Let the Yak SHaving Begin

The first step, as always, is to get some data to work with. Because I was interested in pure BGP UPDATEs not the resulting routing table itself, and didn’t want to have to parse debug output from a virtual router like bird or frr, I decided to write something myself.

More specifically I went back to a half-finished project and got it into a much more polished, working state. The result is **[bgpsee](https://github.com/gregfoletta/bgpsee)**, a multi-threaded BGP peering tool for the CLI. Once peered with another router, the BGP messages are converted into JSON so you can quickly view their contents, or in the case of this article, analyse what’s going on.

Here’s a single BGP update from the dataset I collected, with some of the irrelevant fields removed.

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

The dataset was collected between the 6/1/2024 tot he 7/1/2024, and consists of 464,673 BGP UPDATE messages received from a peer (thanks [Andrew Vinton](https://www.linkedin.com/in/andrew-vinton/)) with a full BGP table.

The JSON has been transformed into a semi-rectangular format, with one row for each UPDATE:

With a better understanding of the source and the structure of the data, let’s take a look at what actually goes on.

# Initial Send, Number of v4 and v6 Paths

When you first bring up a BGP peering with a router you get a big dump of of UPDATEs, what I’ll call the ‘first tranche’. This consists of all paths and associated network layer reachability information (NLRI, or more simply ‘routes’) in the router’s BGP table. From this point onwards you will only receive UPDATEs for paths that have changed, or withdrawn routes which no longer have any paths. There’s no structural difference between the batch and the ongoing UPDATEs, except for the fact you received the first batch in the first 10 or so seconds of the peering coming up.

Here’s a breakdown of the number of distinct paths received in that first batch, separated into IPv4 vs IPv6:

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-7-1.png" width="672" />
It’s important to highlight that this is a count of BGP paths, **not** routes. Each path is a unique comvbination of path attributes with associated NLRI information attached, and each one sent in a distinct BGP UPDATE message. Each one could have one or one-thousand routes associated with it. Doing the math on this dataset, the total number of routes across all of these paths is 949483. Cross referencing across [Geoff’s data](https://bgp.potaroo.net/as2.0/bgp-active.txt) for the same period, his shows 942,594. We’re in the same ballpark.

# A Garden Host or a Fire Hose?

That’s all we’ll look at of the first tranche, let’s see how much change there is across the day. The animation below shows the number of BGP UPDATEs received every 30 seconds for IPv4 and IPv6:

![](index_files/figure-html/unnamed-chunk-8-1.gif)<!-- -->
There’s a couple of things that stand out straight away, but before we look at that let’s take a different perspective. The animation shows how many BGP updates - and therefore path changes - were received. But each of those updates could have one, or could have one-thousand routes of various different prefix lengths.

Instead of looking at the total count of udpates, we can look at the total aggregate IP address change across all updates in each 30 second interval. We do this by calculating the total IP addresses, then taking the log2() of the sum. So for example: a /22, a /23 and a /24 would be `$$log_2(2^{32-22} + 2^{32-23} + 2^{32-24})$$`

Below shows the time series and the density of the log2() of the IP space advertised during the day. So on average, every 30 seconds, around 2^16 IP addresses (i.e a /16) change paths in the global routing table, with 95% falling between is between \$$2^{20.75}$ (approx. a /11) and `\(2^{13.85}\)` (approx. a ~/18).

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-9-1.png" width="672" />

What is apparent in both the path and IP space changes over time is that there is some sort of cycle occuring in the BGPv4 updated. To determine the period of this cycle we can use an [ACF](https://otexts.com/fpp3/acf.html) or autocorrelation plot. We’ll calculate the correlation between the number of paths received at time `\(y_t\)` versus the number received at `\(y_{t-\{1,2,3,...,n\}}\)`. I’ve grouped the updates together into 1 minute intervals, so 1 lag = 1 minute.

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-10-1.png" width="672" />
You see there’s a correlation in the first 10 lags, which intuitively makes sense to me as path changes are likely to create other path changes as they propagate around the world. But interestingly there’s also a very strong correlation at lags 40 and 41.

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-11-1.png" width="672" />

<div id="ahqlpfkzkv" class=".gt_table" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#ahqlpfkzkv table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#ahqlpfkzkv thead, #ahqlpfkzkv tbody, #ahqlpfkzkv tfoot, #ahqlpfkzkv tr, #ahqlpfkzkv td, #ahqlpfkzkv th {
  border-style: none;
}
&#10;#ahqlpfkzkv p {
  margin: 0;
  padding: 0;
}
&#10;#ahqlpfkzkv .gt_table {
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
&#10;#ahqlpfkzkv .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#ahqlpfkzkv .gt_title {
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
&#10;#ahqlpfkzkv .gt_subtitle {
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
&#10;#ahqlpfkzkv .gt_heading {
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
&#10;#ahqlpfkzkv .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#ahqlpfkzkv .gt_col_headings {
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
&#10;#ahqlpfkzkv .gt_col_heading {
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
&#10;#ahqlpfkzkv .gt_column_spanner_outer {
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
&#10;#ahqlpfkzkv .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#ahqlpfkzkv .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#ahqlpfkzkv .gt_column_spanner {
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
&#10;#ahqlpfkzkv .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#ahqlpfkzkv .gt_group_heading {
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
&#10;#ahqlpfkzkv .gt_empty_group_heading {
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
&#10;#ahqlpfkzkv .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#ahqlpfkzkv .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#ahqlpfkzkv .gt_row {
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
&#10;#ahqlpfkzkv .gt_stub {
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
&#10;#ahqlpfkzkv .gt_stub_row_group {
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
&#10;#ahqlpfkzkv .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#ahqlpfkzkv .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#ahqlpfkzkv .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#ahqlpfkzkv .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#ahqlpfkzkv .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#ahqlpfkzkv .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#ahqlpfkzkv .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#ahqlpfkzkv .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#ahqlpfkzkv .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#ahqlpfkzkv .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#ahqlpfkzkv .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#ahqlpfkzkv .gt_footnotes {
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
&#10;#ahqlpfkzkv .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#ahqlpfkzkv .gt_sourcenotes {
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
&#10;#ahqlpfkzkv .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#ahqlpfkzkv .gt_left {
  text-align: left;
}
&#10;#ahqlpfkzkv .gt_center {
  text-align: center;
}
&#10;#ahqlpfkzkv .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#ahqlpfkzkv .gt_font_normal {
  font-weight: normal;
}
&#10;#ahqlpfkzkv .gt_font_bold {
  font-weight: bold;
}
&#10;#ahqlpfkzkv .gt_font_italic {
  font-style: italic;
}
&#10;#ahqlpfkzkv .gt_super {
  font-size: 65%;
}
&#10;#ahqlpfkzkv .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#ahqlpfkzkv .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#ahqlpfkzkv .gt_indent_1 {
  text-indent: 5px;
}
&#10;#ahqlpfkzkv .gt_indent_2 {
  text-indent: 10px;
}
&#10;#ahqlpfkzkv .gt_indent_3 {
  text-indent: 15px;
}
&#10;#ahqlpfkzkv .gt_indent_4 {
  text-indent: 20px;
}
&#10;#ahqlpfkzkv .gt_indent_5 {
  text-indent: 25px;
}
&#10;#ahqlpfkzkv .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#ahqlpfkzkv div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>
<div id="ahqlpfkzkv" class="reactable html-widget" style="width:auto;height:auto;"></div>
<script type="application/json" data-for="ahqlpfkzkv">{"x":{"tag":{"name":"Reactable","attribs":{"data":{"n":[3547,3547,1166,1138,723,629,491,367,288,281],"organisation":["Wideband Networks Pty Ltd","Ossini Pty Ltd","Angola Cables","NTT America, Inc.","Level 3 Parent, LLC","Cogent Communications","RETN Limited","SAMM Sociedade de Atividades em Multimidia LTDA","Columbus Networks USA, Inc.","MEGA TELE INFORMATICA"],"asn":["4764","45270","37468","2914","3356","174","9002","52551","23520","265269"],"source":["APNIC","APNIC","AFRINIC","ARIN","ARIN","ARIN","RIPE","LACNIC","ARIN","LACNIC"],"country":["AU","AU","AO","US","US","US","GB","BR","US","BR"]},"columns":[{"id":"n","name":"n","type":"numeric","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"right"},{"id":"organisation","name":"organisation","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"left"},{"id":"asn","name":"asn","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"right"},{"id":"source","name":"source","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"left"},{"id":"country","name":"country","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"left"}],"defaultPageSize":10,"showPageSizeOptions":false,"pageSizeOptions":[10,25,50,100],"paginationType":"numbers","showPagination":true,"showPageInfo":true,"minRows":1,"height":"auto","theme":{"color":"#333333","backgroundColor":"#FFFFFF","stripedColor":"rgba(128,128,128,0.05)","style":{"font-family":"system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif","fontSize":"16px"},"tableStyle":{"borderTopStyle":"solid","borderTopWidth":"2px","borderTopColor":"#D3D3D3"},"headerStyle":{"fontWeight":"normal","backgroundColor":"transparent","borderBottomStyle":"solid","borderBottomWidth":"2px","borderBottomColor":"#D3D3D3"},"groupHeaderStyle":{"fontWeight":"normal","backgroundColor":"transparent","borderBottomStyle":"solid","borderBottomWidth":"2px","borderBottomColor":"#D3D3D3"},"cellStyle":{"fontWeight":"normal"}},"elementId":"ahqlpfkzkv","dataKey":"2b0271bee813a74b6cbe855c9a59d4b1"},"children":[]},"class":"reactR_markup"},"evals":["tag.attribs.columns.0.style","tag.attribs.columns.1.style","tag.attribs.columns.2.style","tag.attribs.columns.3.style","tag.attribs.columns.4.style"],"jsHooks":[]}</script>
</div>

# Prepending Madness

If you’re a network admin, there’s a couple of different ways you can influence how traffic entering your ASN. You can use longer network prefixes, but this doesn’t scale well and you’re not being a polite BGP citizen. You can use the MED attribute, but it’s non-transitive so it doesn’t work if you’re peered to multiple AS. Primarily you’ll modify the AS path length by prepending your own AS one or more times.

The problem is some people take this prepending too far, which has in the past caused [large, global problems](https://blog.ipspace.net/2009/02/root-cause-analysis-oversized-as-paths/). Let’s take a look at the top 50 AS path lengths we’ve received in updates throughought the day, split by IP version:

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-13-1.png" width="672" />
What is really interesting here is the difference between IPv4 and IPv6. The largest IPv4 path length is 105, which is still ridiculous given the fact that the largest non-prepended path in this dataset has a length of 14. But compared to the IPv6 paths it’s outright sensible: top of the table for IPv6 comes in at a whopping 599 ASes! An AS path is actually made up of one or more [AS sets or AS sequences](https://datatracker.ietf.org/doc/html/rfc4271#section-5.1.2), each of which have a maximum length of 255. So it’s taken three AS sequences to announce those routes.

Here’s the longest IPv4 path in all it’s glory with its 105 ASNs. It originated from AS149381 “Dinas Komunikasi dan Informatika Kabupaten Tulungagung” in Indonesia.

    [1] "45270 4764 9002 136106 45305 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381"

Around 6 hours and 50 minutes later, they’ve realised the error in their ways and announce a path with only four ASes, rather than 105:

<div id="gpvgnumnwz" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#gpvgnumnwz table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#gpvgnumnwz thead, #gpvgnumnwz tbody, #gpvgnumnwz tfoot, #gpvgnumnwz tr, #gpvgnumnwz td, #gpvgnumnwz th {
  border-style: none;
}
&#10;#gpvgnumnwz p {
  margin: 0;
  padding: 0;
}
&#10;#gpvgnumnwz .gt_table {
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
&#10;#gpvgnumnwz .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#gpvgnumnwz .gt_title {
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
&#10;#gpvgnumnwz .gt_subtitle {
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
&#10;#gpvgnumnwz .gt_heading {
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
&#10;#gpvgnumnwz .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#gpvgnumnwz .gt_col_headings {
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
&#10;#gpvgnumnwz .gt_col_heading {
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
&#10;#gpvgnumnwz .gt_column_spanner_outer {
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
&#10;#gpvgnumnwz .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#gpvgnumnwz .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#gpvgnumnwz .gt_column_spanner {
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
&#10;#gpvgnumnwz .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#gpvgnumnwz .gt_group_heading {
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
&#10;#gpvgnumnwz .gt_empty_group_heading {
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
&#10;#gpvgnumnwz .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#gpvgnumnwz .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#gpvgnumnwz .gt_row {
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
&#10;#gpvgnumnwz .gt_stub {
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
&#10;#gpvgnumnwz .gt_stub_row_group {
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
&#10;#gpvgnumnwz .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#gpvgnumnwz .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#gpvgnumnwz .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#gpvgnumnwz .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#gpvgnumnwz .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#gpvgnumnwz .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#gpvgnumnwz .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#gpvgnumnwz .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#gpvgnumnwz .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#gpvgnumnwz .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#gpvgnumnwz .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#gpvgnumnwz .gt_footnotes {
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
&#10;#gpvgnumnwz .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#gpvgnumnwz .gt_sourcenotes {
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
&#10;#gpvgnumnwz .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#gpvgnumnwz .gt_left {
  text-align: left;
}
&#10;#gpvgnumnwz .gt_center {
  text-align: center;
}
&#10;#gpvgnumnwz .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#gpvgnumnwz .gt_font_normal {
  font-weight: normal;
}
&#10;#gpvgnumnwz .gt_font_bold {
  font-weight: bold;
}
&#10;#gpvgnumnwz .gt_font_italic {
  font-style: italic;
}
&#10;#gpvgnumnwz .gt_super {
  font-size: 65%;
}
&#10;#gpvgnumnwz .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#gpvgnumnwz .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#gpvgnumnwz .gt_indent_1 {
  text-indent: 5px;
}
&#10;#gpvgnumnwz .gt_indent_2 {
  text-indent: 10px;
}
&#10;#gpvgnumnwz .gt_indent_3 {
  text-indent: 15px;
}
&#10;#gpvgnumnwz .gt_indent_4 {
  text-indent: 20px;
}
&#10;#gpvgnumnwz .gt_indent_5 {
  text-indent: 25px;
}
&#10;#gpvgnumnwz .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#gpvgnumnwz div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
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

So the question is: why is there such a difference between the largest IPv4 and IPv6 path lengths? If we count the total number of ASNs in all positions in thbe path for those top 50 longest paths, it becomes apparent what’s happening:

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-17-1.png" width="672" />

# Path Attributes

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-19-1.png" width="672" />

<div id="gpjuumrkdq" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#gpjuumrkdq table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#gpjuumrkdq thead, #gpjuumrkdq tbody, #gpjuumrkdq tfoot, #gpjuumrkdq tr, #gpjuumrkdq td, #gpjuumrkdq th {
  border-style: none;
}
&#10;#gpjuumrkdq p {
  margin: 0;
  padding: 0;
}
&#10;#gpjuumrkdq .gt_table {
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
&#10;#gpjuumrkdq .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#gpjuumrkdq .gt_title {
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
&#10;#gpjuumrkdq .gt_subtitle {
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
&#10;#gpjuumrkdq .gt_heading {
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
&#10;#gpjuumrkdq .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#gpjuumrkdq .gt_col_headings {
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
&#10;#gpjuumrkdq .gt_col_heading {
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
&#10;#gpjuumrkdq .gt_column_spanner_outer {
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
&#10;#gpjuumrkdq .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#gpjuumrkdq .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#gpjuumrkdq .gt_column_spanner {
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
&#10;#gpjuumrkdq .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#gpjuumrkdq .gt_group_heading {
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
&#10;#gpjuumrkdq .gt_empty_group_heading {
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
&#10;#gpjuumrkdq .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#gpjuumrkdq .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#gpjuumrkdq .gt_row {
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
&#10;#gpjuumrkdq .gt_stub {
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
&#10;#gpjuumrkdq .gt_stub_row_group {
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
&#10;#gpjuumrkdq .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#gpjuumrkdq .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#gpjuumrkdq .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#gpjuumrkdq .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#gpjuumrkdq .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#gpjuumrkdq .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#gpjuumrkdq .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#gpjuumrkdq .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#gpjuumrkdq .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#gpjuumrkdq .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#gpjuumrkdq .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#gpjuumrkdq .gt_footnotes {
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
&#10;#gpjuumrkdq .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#gpjuumrkdq .gt_sourcenotes {
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
&#10;#gpjuumrkdq .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#gpjuumrkdq .gt_left {
  text-align: left;
}
&#10;#gpjuumrkdq .gt_center {
  text-align: center;
}
&#10;#gpjuumrkdq .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#gpjuumrkdq .gt_font_normal {
  font-weight: normal;
}
&#10;#gpjuumrkdq .gt_font_bold {
  font-weight: bold;
}
&#10;#gpjuumrkdq .gt_font_italic {
  font-style: italic;
}
&#10;#gpjuumrkdq .gt_super {
  font-size: 65%;
}
&#10;#gpjuumrkdq .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#gpjuumrkdq .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#gpjuumrkdq .gt_indent_1 {
  text-indent: 5px;
}
&#10;#gpjuumrkdq .gt_indent_2 {
  text-indent: 10px;
}
&#10;#gpjuumrkdq .gt_indent_3 {
  text-indent: 15px;
}
&#10;#gpjuumrkdq .gt_indent_4 {
  text-indent: 20px;
}
&#10;#gpjuumrkdq .gt_indent_5 {
  text-indent: 25px;
}
&#10;#gpjuumrkdq .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#gpjuumrkdq div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>
<table class="gt_table" data-quarto-disable-processing="false" data-quarto-bootstrap="false">
  <thead>
    <tr class="gt_col_headings">
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="originating_asn">originating_asn</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="organisation">organisation</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="source">source</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="country">country</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr><td headers="originating_asn" class="gt_row gt_right">42912</td>
<td headers="organisation" class="gt_row gt_left">Al mouakhah lil khadamat al logesteih wa al itisalat</td>
<td headers="source" class="gt_row gt_left">RIPE</td>
<td headers="country" class="gt_row gt_left">JO</td></tr>
    <tr><td headers="originating_asn" class="gt_row gt_right">23872</td>
<td headers="organisation" class="gt_row gt_left">delDSL Internet Pvt. Ltd.</td>
<td headers="source" class="gt_row gt_left">APNIC</td>
<td headers="country" class="gt_row gt_left">IN</td></tr>
    <tr><td headers="originating_asn" class="gt_row gt_right">204667</td>
<td headers="organisation" class="gt_row gt_left">Juan Ramon Jerez Suarez</td>
<td headers="source" class="gt_row gt_left">RIPE</td>
<td headers="country" class="gt_row gt_left">ES</td></tr>
    <tr><td headers="originating_asn" class="gt_row gt_right">48832</td>
<td headers="organisation" class="gt_row gt_left">Jordanian mobile phone services Ltd</td>
<td headers="source" class="gt_row gt_left">RIPE</td>
<td headers="country" class="gt_row gt_left">JO</td></tr>
    <tr><td headers="originating_asn" class="gt_row gt_right">41297</td>
<td headers="organisation" class="gt_row gt_left">Adam Dlugosz trading as ABAKS</td>
<td headers="source" class="gt_row gt_left">RIPE</td>
<td headers="country" class="gt_row gt_left">PL</td></tr>
    <tr><td headers="originating_asn" class="gt_row gt_right">52564</td>
<td headers="organisation" class="gt_row gt_left">Biazi Telecom</td>
<td headers="source" class="gt_row gt_left">LACNIC</td>
<td headers="country" class="gt_row gt_left">BR</td></tr>
    <tr><td headers="originating_asn" class="gt_row gt_right">52746</td>
<td headers="organisation" class="gt_row gt_left">Primanet Internet LTDA</td>
<td headers="source" class="gt_row gt_left">LACNIC</td>
<td headers="country" class="gt_row gt_left">BR</td></tr>
    <tr><td headers="originating_asn" class="gt_row gt_right">61639</td>
<td headers="organisation" class="gt_row gt_left">BCNET INFORMÁTICA LTDA</td>
<td headers="source" class="gt_row gt_left">LACNIC</td>
<td headers="country" class="gt_row gt_left">BR</td></tr>
    <tr><td headers="originating_asn" class="gt_row gt_right">10429</td>
<td headers="organisation" class="gt_row gt_left">TELEFÔNICA BRASIL S.A</td>
<td headers="source" class="gt_row gt_left">LACNIC</td>
<td headers="country" class="gt_row gt_left">BR</td></tr>
    <tr><td headers="originating_asn" class="gt_row gt_right">265999</td>
<td headers="organisation" class="gt_row gt_left">Cianet Provedor de Internet EIRELI</td>
<td headers="source" class="gt_row gt_left">LACNIC</td>
<td headers="country" class="gt_row gt_left">BR</td></tr>
    <tr><td headers="originating_asn" class="gt_row gt_right">264901</td>
<td headers="organisation" class="gt_row gt_left">Ailon Rodrigo Oliveira Lima ME</td>
<td headers="source" class="gt_row gt_left">LACNIC</td>
<td headers="country" class="gt_row gt_left">BR</td></tr>
    <tr><td headers="originating_asn" class="gt_row gt_right">264954</td>
<td headers="organisation" class="gt_row gt_left">Virtual Connect</td>
<td headers="source" class="gt_row gt_left">LACNIC</td>
<td headers="country" class="gt_row gt_left">BR</td></tr>
    <tr><td headers="originating_asn" class="gt_row gt_right">52935</td>
<td headers="organisation" class="gt_row gt_left">Infobarra Solucoes em Informatica Ltda</td>
<td headers="source" class="gt_row gt_left">LACNIC</td>
<td headers="country" class="gt_row gt_left">BR</td></tr>
    <tr><td headers="originating_asn" class="gt_row gt_right">262426</td>
<td headers="organisation" class="gt_row gt_left">TELECOMUNICAÇÕES RONDONOPOLIS LTDA - ME</td>
<td headers="source" class="gt_row gt_left">LACNIC</td>
<td headers="country" class="gt_row gt_left">BR</td></tr>
    <tr><td headers="originating_asn" class="gt_row gt_right">263454</td>
<td headers="organisation" class="gt_row gt_left">Ines Waltmann - Me</td>
<td headers="source" class="gt_row gt_left">LACNIC</td>
<td headers="country" class="gt_row gt_left">BR</td></tr>
    <tr><td headers="originating_asn" class="gt_row gt_right">27976</td>
<td headers="organisation" class="gt_row gt_left">Coop. de Servicios Públicos de Morteros Ltda.</td>
<td headers="source" class="gt_row gt_left">LACNIC</td>
<td headers="country" class="gt_row gt_left">AR</td></tr>
    <tr><td headers="originating_asn" class="gt_row gt_right">267434</td>
<td headers="organisation" class="gt_row gt_left">Xingu Assessoria em Redes Ltda ME</td>
<td headers="source" class="gt_row gt_left">LACNIC</td>
<td headers="country" class="gt_row gt_left">BR</td></tr>
    <tr><td headers="originating_asn" class="gt_row gt_right">273379</td>
<td headers="organisation" class="gt_row gt_left">V. M. De Melo Informatica - MIDIA INFORMATICA</td>
<td headers="source" class="gt_row gt_left">LACNIC</td>
<td headers="country" class="gt_row gt_left">BR</td></tr>
  </tbody>
  &#10;  
</table>
</div>

# Flippy-Flappy: Who’s Having a Bad Time?

Finally, let’s see who’s having a bad time: which routes are shifting paths or being withdrawn completely the most during the day. Here’s the top 10 with the number of times the route was included in an UPDATE:

<div id="bmxhcfpoza" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#bmxhcfpoza table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#bmxhcfpoza thead, #bmxhcfpoza tbody, #bmxhcfpoza tfoot, #bmxhcfpoza tr, #bmxhcfpoza td, #bmxhcfpoza th {
  border-style: none;
}
&#10;#bmxhcfpoza p {
  margin: 0;
  padding: 0;
}
&#10;#bmxhcfpoza .gt_table {
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
&#10;#bmxhcfpoza .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#bmxhcfpoza .gt_title {
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
&#10;#bmxhcfpoza .gt_subtitle {
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
&#10;#bmxhcfpoza .gt_heading {
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
&#10;#bmxhcfpoza .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#bmxhcfpoza .gt_col_headings {
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
&#10;#bmxhcfpoza .gt_col_heading {
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
&#10;#bmxhcfpoza .gt_column_spanner_outer {
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
&#10;#bmxhcfpoza .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#bmxhcfpoza .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#bmxhcfpoza .gt_column_spanner {
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
&#10;#bmxhcfpoza .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#bmxhcfpoza .gt_group_heading {
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
&#10;#bmxhcfpoza .gt_empty_group_heading {
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
&#10;#bmxhcfpoza .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#bmxhcfpoza .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#bmxhcfpoza .gt_row {
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
&#10;#bmxhcfpoza .gt_stub {
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
&#10;#bmxhcfpoza .gt_stub_row_group {
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
&#10;#bmxhcfpoza .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#bmxhcfpoza .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#bmxhcfpoza .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#bmxhcfpoza .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#bmxhcfpoza .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#bmxhcfpoza .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#bmxhcfpoza .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#bmxhcfpoza .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#bmxhcfpoza .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#bmxhcfpoza .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#bmxhcfpoza .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#bmxhcfpoza .gt_footnotes {
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
&#10;#bmxhcfpoza .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#bmxhcfpoza .gt_sourcenotes {
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
&#10;#bmxhcfpoza .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#bmxhcfpoza .gt_left {
  text-align: left;
}
&#10;#bmxhcfpoza .gt_center {
  text-align: center;
}
&#10;#bmxhcfpoza .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#bmxhcfpoza .gt_font_normal {
  font-weight: normal;
}
&#10;#bmxhcfpoza .gt_font_bold {
  font-weight: bold;
}
&#10;#bmxhcfpoza .gt_font_italic {
  font-style: italic;
}
&#10;#bmxhcfpoza .gt_super {
  font-size: 65%;
}
&#10;#bmxhcfpoza .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#bmxhcfpoza .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#bmxhcfpoza .gt_indent_1 {
  text-indent: 5px;
}
&#10;#bmxhcfpoza .gt_indent_2 {
  text-indent: 10px;
}
&#10;#bmxhcfpoza .gt_indent_3 {
  text-indent: 15px;
}
&#10;#bmxhcfpoza .gt_indent_4 {
  text-indent: 20px;
}
&#10;#bmxhcfpoza .gt_indent_5 {
  text-indent: 25px;
}
&#10;#bmxhcfpoza .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#bmxhcfpoza div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>
<table class="gt_table" data-quarto-disable-processing="false" data-quarto-bootstrap="false">
  <thead>
    <tr class="gt_col_headings">
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="nlri">nlri</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="n">n</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr><td headers="nlri" class="gt_row gt_right">140.99.244.0/23</td>
<td headers="n" class="gt_row gt_right">2596</td></tr>
    <tr><td headers="nlri" class="gt_row gt_right">107.154.97.0/24</td>
<td headers="n" class="gt_row gt_right">2583</td></tr>
    <tr><td headers="nlri" class="gt_row gt_right">45.172.92.0/22</td>
<td headers="n" class="gt_row gt_right">2494</td></tr>
    <tr><td headers="nlri" class="gt_row gt_right">151.236.111.0/24</td>
<td headers="n" class="gt_row gt_right">2312</td></tr>
    <tr><td headers="nlri" class="gt_row gt_right">205.164.85.0/24</td>
<td headers="n" class="gt_row gt_right">2189</td></tr>
    <tr><td headers="nlri" class="gt_row gt_right">41.209.0.0/18</td>
<td headers="n" class="gt_row gt_right">2069</td></tr>
    <tr><td headers="nlri" class="gt_row gt_right">143.255.204.0/22</td>
<td headers="n" class="gt_row gt_right">2048</td></tr>
    <tr><td headers="nlri" class="gt_row gt_right">176.124.58.0/24</td>
<td headers="n" class="gt_row gt_right">1584</td></tr>
    <tr><td headers="nlri" class="gt_row gt_right">187.1.11.0/24</td>
<td headers="n" class="gt_row gt_right">1582</td></tr>
    <tr><td headers="nlri" class="gt_row gt_right">187.1.13.0/24</td>
<td headers="n" class="gt_row gt_right">1580</td></tr>
  </tbody>
  &#10;  
</table>
</div>

Drilling down into the route that’s beeing update the most, **140.99.244.0/23**, we can graph the points during the day when it’s been in an update, or when it’s been withdrawn completely. The x-axis below is the ID of the BGP update:

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-22-1.png" width="672" />
The top graph looks like a straight line, but that’s because this route is present in almost every single 30 second block of updates. There are 2,879 30-second blocks and it’s present as either a different path or a withdrawn route in 2,637 of them, or 92.8%!

We know the routes is flapping, but *how* is it flapping? What are the different paths that it’s flapping across, which AS in the path seems to be to blame? The best way to visualise this is a graph, placing all the ASNs that exist in all the paths as on a graph, then colourising the edges by how many updates were seen with each pair of ASes. I’ve bi

``` r
as_tbl_graph(as_path_edges, directed = TRUE) |>
    activate(edges) |>
    mutate(n_binned = cut(n, breaks = c(0, cumsum(rep(300, 9))), dig.lab = 20)) |> 
    ggraph(layout = 'igraph', algorithm = 'kk') +
    geom_edge_link(aes(colour = n_binned), arrow = arrow(type = 'closed', length = unit(4, 'mm')), end_cap = circle(7, 'mm')) +
    geom_node_point(size = 17) +
    geom_node_text(aes(label = name), colour = 'white') +
    guides(edge_width = FALSE) +
    scale_x_continuous(expand = expand_scale(c(.10, .10))) +
    scale_y_continuous(expand = expand_scale(c(.13, .13))) +
    labs(
        title = 'Route 140.99.244.0/23 - Intra-Day AS Path Changes',
        subtitle = 'Graph of unqiue ASNs present in all AS paths seen'
    )
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-24-1.png" width="672" />
It’s a bit messy, but the take
