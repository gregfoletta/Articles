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
<script src="{{< blogdown/postref >}}index_files/core-js/shim.min.js"></script>
<script src="{{< blogdown/postref >}}index_files/react/react.min.js"></script>
<script src="{{< blogdown/postref >}}index_files/react/react-dom.min.js"></script>
<script src="{{< blogdown/postref >}}index_files/reactwidget/react-tools.js"></script>
<script src="{{< blogdown/postref >}}index_files/htmlwidgets/htmlwidgets.js"></script>
<link href="{{< blogdown/postref >}}index_files/reactable/reactable.css" rel="stylesheet" />
<script src="{{< blogdown/postref >}}index_files/reactable-binding/reactable.js"></script>
<script src="{{< blogdown/postref >}}index_files/core-js/shim.min.js"></script>
<script src="{{< blogdown/postref >}}index_files/react/react.min.js"></script>
<script src="{{< blogdown/postref >}}index_files/react/react-dom.min.js"></script>
<script src="{{< blogdown/postref >}}index_files/reactwidget/react-tools.js"></script>
<script src="{{< blogdown/postref >}}index_files/htmlwidgets/htmlwidgets.js"></script>
<link href="{{< blogdown/postref >}}index_files/reactable/reactable.css" rel="stylesheet" />
<script src="{{< blogdown/postref >}}index_files/reactable-binding/reactable.js"></script>
<script src="{{< blogdown/postref >}}index_files/core-js/shim.min.js"></script>
<script src="{{< blogdown/postref >}}index_files/react/react.min.js"></script>
<script src="{{< blogdown/postref >}}index_files/react/react-dom.min.js"></script>
<script src="{{< blogdown/postref >}}index_files/reactwidget/react-tools.js"></script>
<script src="{{< blogdown/postref >}}index_files/htmlwidgets/htmlwidgets.js"></script>
<link href="{{< blogdown/postref >}}index_files/reactable/reactable.css" rel="stylesheet" />
<script src="{{< blogdown/postref >}}index_files/reactable-binding/reactable.js"></script>
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

<div id="lbxfcbqeax" class=".gt_table" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#lbxfcbqeax table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#lbxfcbqeax thead, #lbxfcbqeax tbody, #lbxfcbqeax tfoot, #lbxfcbqeax tr, #lbxfcbqeax td, #lbxfcbqeax th {
  border-style: none;
}
&#10;#lbxfcbqeax p {
  margin: 0;
  padding: 0;
}
&#10;#lbxfcbqeax .gt_table {
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
&#10;#lbxfcbqeax .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#lbxfcbqeax .gt_title {
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
&#10;#lbxfcbqeax .gt_subtitle {
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
&#10;#lbxfcbqeax .gt_heading {
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
&#10;#lbxfcbqeax .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#lbxfcbqeax .gt_col_headings {
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
&#10;#lbxfcbqeax .gt_col_heading {
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
&#10;#lbxfcbqeax .gt_column_spanner_outer {
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
&#10;#lbxfcbqeax .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#lbxfcbqeax .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#lbxfcbqeax .gt_column_spanner {
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
&#10;#lbxfcbqeax .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#lbxfcbqeax .gt_group_heading {
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
&#10;#lbxfcbqeax .gt_empty_group_heading {
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
&#10;#lbxfcbqeax .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#lbxfcbqeax .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#lbxfcbqeax .gt_row {
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
&#10;#lbxfcbqeax .gt_stub {
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
&#10;#lbxfcbqeax .gt_stub_row_group {
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
&#10;#lbxfcbqeax .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#lbxfcbqeax .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#lbxfcbqeax .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#lbxfcbqeax .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#lbxfcbqeax .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#lbxfcbqeax .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#lbxfcbqeax .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#lbxfcbqeax .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#lbxfcbqeax .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#lbxfcbqeax .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#lbxfcbqeax .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#lbxfcbqeax .gt_footnotes {
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
&#10;#lbxfcbqeax .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#lbxfcbqeax .gt_sourcenotes {
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
&#10;#lbxfcbqeax .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#lbxfcbqeax .gt_left {
  text-align: left;
}
&#10;#lbxfcbqeax .gt_center {
  text-align: center;
}
&#10;#lbxfcbqeax .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#lbxfcbqeax .gt_font_normal {
  font-weight: normal;
}
&#10;#lbxfcbqeax .gt_font_bold {
  font-weight: bold;
}
&#10;#lbxfcbqeax .gt_font_italic {
  font-style: italic;
}
&#10;#lbxfcbqeax .gt_super {
  font-size: 65%;
}
&#10;#lbxfcbqeax .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#lbxfcbqeax .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#lbxfcbqeax .gt_indent_1 {
  text-indent: 5px;
}
&#10;#lbxfcbqeax .gt_indent_2 {
  text-indent: 10px;
}
&#10;#lbxfcbqeax .gt_indent_3 {
  text-indent: 15px;
}
&#10;#lbxfcbqeax .gt_indent_4 {
  text-indent: 20px;
}
&#10;#lbxfcbqeax .gt_indent_5 {
  text-indent: 25px;
}
&#10;#lbxfcbqeax .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#lbxfcbqeax div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>
<div id="lbxfcbqeax" class="reactable html-widget" style="width:auto;height:auto;"></div>
<script type="application/json" data-for="lbxfcbqeax">{"x":{"tag":{"name":"Reactable","attribs":{"data":{"recv_time":["2024-01-05T19:31:44Z","2024-01-05T19:31:44Z","2024-01-05T19:31:44Z","2024-01-05T19:31:44Z","2024-01-05T19:31:44Z","2024-01-05T19:31:44Z"],"id":[190538,190539,190540,190541,190542,190543],"type":["UPDATE","UPDATE","UPDATE","UPDATE","UPDATE","UPDATE"],"nlri":["41.211.42.0/24\n41.211.32.0/24\n41.211.47.0/24\n41.211.38.0/24\n41.211.37.0/24\n41.211.36.0/24","103.177.87.0/24\n103.177.86.0/24","38.172.160.0/24","176.124.58.0/24","103.103.34.0/24","117.103.87.0/24"],"withdrawn_routes":["130.137.140.0/24, 130.137.99.0/24, 130.137.121.0/24, 50.117.116.0/24, 205.65.44.0/22, 185.241.10.0/24, 130.137.105.0/24","","","","",""],"path_attributes":[{"type":["ORIGIN","AS_PATH","NEXT_HOP","AS4_PATH"],"type_code":[1,2,3,17],"flags":[["well-known","transitive","complete","standard"],["well-known","transitive","complete","standard"],["well-known","transitive","complete","standard"],["optional","non-transitive","partial","extended"]],"flags_low_nibble":[0,0,0,0],"origin":["IGP",null,null,null],"n_as_segments":["NA",1,"NA",1],"n_total_as":["NA",6,"NA",6],"path_segments":[null,{"type":["AS_SEQUENCE"],"n_as":[6],"asns":[[45270,4764,1299,174,16637,23456]]},null,{"type":["AS_SEQUENCE"],"n_as":[6],"asns":[[45270,4764,1299,174,16637,327765]]}],"next_hop":[null,null,"61.245.147.114",null]},{"type":["ORIGIN","AS_PATH","NEXT_HOP","AS4_PATH"],"type_code":[1,2,3,17],"flags":[["well-known","transitive","complete","standard"],["well-known","transitive","complete","standard"],["well-known","transitive","complete","standard"],["optional","non-transitive","partial","extended"]],"flags_low_nibble":[0,0,0,0],"origin":["IGP",null,null,null],"n_as_segments":["NA",1,"NA",1],"n_total_as":["NA",8,"NA",8],"path_segments":[null,{"type":["AS_SEQUENCE"],"n_as":[8],"asns":[[45270,4764,174,23456,23456,23456,23456,23456]]},null,{"type":["AS_SEQUENCE"],"n_as":[8],"asns":[[45270,4764,174,136255,136975,133524,134840,149038]]}],"next_hop":[null,null,"61.245.147.114",null]},{"type":["ORIGIN","AS_PATH","NEXT_HOP","AS4_PATH"],"type_code":[1,2,3,17],"flags":[["well-known","transitive","complete","standard"],["well-known","transitive","complete","standard"],["well-known","transitive","complete","standard"],["optional","non-transitive","partial","extended"]],"flags_low_nibble":[0,0,0,0],"origin":["IGP",null,null,null],"n_as_segments":["NA",1,"NA",1],"n_total_as":["NA",12,"NA",12],"path_segments":[null,{"type":["AS_SEQUENCE"],"n_as":[12],"asns":[[45270,4764,1299,23520,23456,23456,23456,23456,23456,23456,23456,23456]]},null,{"type":["AS_SEQUENCE"],"n_as":[12],"asns":[[45270,4764,1299,23520,263703,270026,270026,270026,270026,270026,270026,270026]]}],"next_hop":[null,null,"61.245.147.114",null]},{"type":["ORIGIN","AS_PATH","NEXT_HOP","AS4_PATH"],"type_code":[1,2,3,17],"flags":[["well-known","transitive","complete","standard"],["well-known","transitive","complete","standard"],["well-known","transitive","complete","standard"],["optional","non-transitive","partial","extended"]],"flags_low_nibble":[0,0,0,0],"origin":["IGP",null,null,null],"n_as_segments":["NA",1,"NA",1],"n_total_as":["NA",6,"NA",6],"path_segments":[null,{"type":["AS_SEQUENCE"],"n_as":[6],"asns":[[45270,4764,174,12310,44679,23456]]},null,{"type":["AS_SEQUENCE"],"n_as":[6],"asns":[[45270,4764,174,12310,44679,209856]]}],"next_hop":[null,null,"61.245.147.114",null]},{"type":["ORIGIN","AS_PATH","NEXT_HOP","AS4_PATH"],"type_code":[1,2,3,17],"flags":[["well-known","transitive","complete","standard"],["well-known","transitive","complete","standard"],["well-known","transitive","complete","standard"],["optional","non-transitive","partial","extended"]],"flags_low_nibble":[0,0,0,0],"origin":["IGP",null,null,null],"n_as_segments":["NA",1,"NA",1],"n_total_as":["NA",7,"NA",7],"path_segments":[null,{"type":["AS_SEQUENCE"],"n_as":[7],"asns":[[45270,4764,23456,23456,23456,23456,23456]]},null,{"type":["AS_SEQUENCE"],"n_as":[7],"asns":[[45270,4764,139901,137048,137048,137048,137048]]}],"next_hop":[null,null,"61.245.147.114",null]},{"type":["ORIGIN","AS_PATH","NEXT_HOP","AS4_PATH"],"type_code":[1,2,3,17],"flags":[["well-known","transitive","complete","standard"],["well-known","transitive","complete","standard"],["well-known","transitive","complete","standard"],["optional","non-transitive","partial","extended"]],"flags_low_nibble":[0,0,0,0],"origin":["IGP",null,null,null],"n_as_segments":["NA",1,"NA",1],"n_total_as":["NA",8,"NA",8],"path_segments":[null,{"type":["AS_SEQUENCE"],"n_as":[8],"asns":[[45270,4764,23456,64018,38614,38614,38614,38614]]},null,{"type":["AS_SEQUENCE"],"n_as":[8],"asns":[[45270,4764,139901,64018,38614,38614,38614,38614]]}],"next_hop":[null,null,"61.245.147.114",null]}]},"columns":[{"id":"recv_time","name":"recv_time","type":"Date","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"right"},{"id":"id","name":"id","type":"numeric","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"right"},{"id":"type","name":"type","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"left"},{"id":"nlri","name":"nlri","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"left"},{"id":"withdrawn_routes","name":"withdrawn_routes","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"right"},{"id":"path_attributes","name":"path_attributes","type":"list","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"center"}],"defaultPageSize":10,"showPageSizeOptions":false,"pageSizeOptions":[10,25,50,100],"paginationType":"numbers","showPagination":true,"showPageInfo":true,"minRows":1,"height":"auto","theme":{"color":"#333333","backgroundColor":"#FFFFFF","stripedColor":"rgba(128,128,128,0.05)","style":{"font-family":"system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif","fontSize":"16px"},"tableStyle":{"borderTopStyle":"solid","borderTopWidth":"2px","borderTopColor":"#D3D3D3"},"headerStyle":{"fontWeight":"normal","backgroundColor":"transparent","borderBottomStyle":"solid","borderBottomWidth":"2px","borderBottomColor":"#D3D3D3"},"groupHeaderStyle":{"fontWeight":"normal","backgroundColor":"transparent","borderBottomStyle":"solid","borderBottomWidth":"2px","borderBottomColor":"#D3D3D3"},"cellStyle":{"fontWeight":"normal"}},"elementId":"lbxfcbqeax","dataKey":"d46682d79a13ac6ce2276f67bebd2df0"},"children":[]},"class":"reactR_markup"},"evals":["tag.attribs.columns.0.style","tag.attribs.columns.1.style","tag.attribs.columns.2.style","tag.attribs.columns.3.style","tag.attribs.columns.4.style","tag.attribs.columns.5.style"],"jsHooks":[]}</script>
</div>

The path attributes are nested within each row, and they look like this:

<div id="oczjtmtlmv" class=".gt_table" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#oczjtmtlmv table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#oczjtmtlmv thead, #oczjtmtlmv tbody, #oczjtmtlmv tfoot, #oczjtmtlmv tr, #oczjtmtlmv td, #oczjtmtlmv th {
  border-style: none;
}
&#10;#oczjtmtlmv p {
  margin: 0;
  padding: 0;
}
&#10;#oczjtmtlmv .gt_table {
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
&#10;#oczjtmtlmv .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#oczjtmtlmv .gt_title {
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
&#10;#oczjtmtlmv .gt_subtitle {
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
&#10;#oczjtmtlmv .gt_heading {
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
&#10;#oczjtmtlmv .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#oczjtmtlmv .gt_col_headings {
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
&#10;#oczjtmtlmv .gt_col_heading {
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
&#10;#oczjtmtlmv .gt_column_spanner_outer {
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
&#10;#oczjtmtlmv .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#oczjtmtlmv .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#oczjtmtlmv .gt_column_spanner {
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
&#10;#oczjtmtlmv .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#oczjtmtlmv .gt_group_heading {
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
&#10;#oczjtmtlmv .gt_empty_group_heading {
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
&#10;#oczjtmtlmv .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#oczjtmtlmv .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#oczjtmtlmv .gt_row {
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
&#10;#oczjtmtlmv .gt_stub {
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
&#10;#oczjtmtlmv .gt_stub_row_group {
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
&#10;#oczjtmtlmv .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#oczjtmtlmv .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#oczjtmtlmv .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#oczjtmtlmv .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#oczjtmtlmv .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#oczjtmtlmv .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#oczjtmtlmv .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#oczjtmtlmv .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#oczjtmtlmv .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#oczjtmtlmv .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#oczjtmtlmv .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#oczjtmtlmv .gt_footnotes {
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
&#10;#oczjtmtlmv .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#oczjtmtlmv .gt_sourcenotes {
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
&#10;#oczjtmtlmv .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#oczjtmtlmv .gt_left {
  text-align: left;
}
&#10;#oczjtmtlmv .gt_center {
  text-align: center;
}
&#10;#oczjtmtlmv .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#oczjtmtlmv .gt_font_normal {
  font-weight: normal;
}
&#10;#oczjtmtlmv .gt_font_bold {
  font-weight: bold;
}
&#10;#oczjtmtlmv .gt_font_italic {
  font-style: italic;
}
&#10;#oczjtmtlmv .gt_super {
  font-size: 65%;
}
&#10;#oczjtmtlmv .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#oczjtmtlmv .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#oczjtmtlmv .gt_indent_1 {
  text-indent: 5px;
}
&#10;#oczjtmtlmv .gt_indent_2 {
  text-indent: 10px;
}
&#10;#oczjtmtlmv .gt_indent_3 {
  text-indent: 15px;
}
&#10;#oczjtmtlmv .gt_indent_4 {
  text-indent: 20px;
}
&#10;#oczjtmtlmv .gt_indent_5 {
  text-indent: 25px;
}
&#10;#oczjtmtlmv .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#oczjtmtlmv div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>
<div id="oczjtmtlmv" class="reactable html-widget" style="width:auto;height:auto;"></div>
<script type="application/json" data-for="oczjtmtlmv">{"x":{"tag":{"name":"Reactable","attribs":{"data":{"id":[695,695,695,695,695,695,695,695],"type":["ORIGIN","AS_PATH","NEXT_HOP","AGGREGATOR","AGGREGATOR","AS4_PATH","AS4_AGGREGATOR","AS4_AGGREGATOR"],"type_code":[1,2,3,7,7,17,18,18],"flags":["well-known, transitive, complete, standard","well-known, transitive, complete, standard","well-known, transitive, complete, standard","optional, non-transitive, partial, extended","optional, non-transitive, partial, extended","optional, non-transitive, partial, extended","optional, non-transitive, partial, extended","optional, non-transitive, partial, extended"],"value":["IGP","AS_SEQUENCE c(45270, 4764, 4651, 23456, 23456)","61.245.147.114","23456","110.77.255.21","AS_SEQUENCE c(45270, 4764, 4651, 131090, 131090)","131090","110.77.255.21"]},"columns":[{"id":"id","name":"id","type":"numeric","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"right"},{"id":"type","name":"type","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"left"},{"id":"type_code","name":"type_code","type":"numeric","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"right"},{"id":"flags","name":"flags","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"left"},{"id":"value","name":"value","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"left"}],"defaultPageSize":10,"showPageSizeOptions":false,"pageSizeOptions":[10,25,50,100],"paginationType":"numbers","showPagination":true,"showPageInfo":true,"minRows":1,"height":"auto","theme":{"color":"#333333","backgroundColor":"#FFFFFF","stripedColor":"rgba(128,128,128,0.05)","style":{"font-family":"system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif","fontSize":"16px"},"tableStyle":{"borderTopStyle":"solid","borderTopWidth":"2px","borderTopColor":"#D3D3D3"},"headerStyle":{"fontWeight":"normal","backgroundColor":"transparent","borderBottomStyle":"solid","borderBottomWidth":"2px","borderBottomColor":"#D3D3D3"},"groupHeaderStyle":{"fontWeight":"normal","backgroundColor":"transparent","borderBottomStyle":"solid","borderBottomWidth":"2px","borderBottomColor":"#D3D3D3"},"cellStyle":{"fontWeight":"normal"}},"elementId":"oczjtmtlmv","dataKey":"7e017aac901c0f27d62cd5116c70e9d7"},"children":[]},"class":"reactR_markup"},"evals":["tag.attribs.columns.0.style","tag.attribs.columns.1.style","tag.attribs.columns.2.style","tag.attribs.columns.3.style","tag.attribs.columns.4.style"],"jsHooks":[]}</script>
</div>

With a better understanding of the source and the structure of the data, let’s take a look at what actually goes on.

# Initial Send, Number of v4 and v6 Paths

When you first bring up a BGP peering with a router you get a large amount of UPDATEs consisting of all paths and associated network layer reachability information (NLRI, or more simply ‘routes’) in the router’s BGP table. From this point onwards you will only receive UPDATEs for paths that have changed, or withdrawn routes which no longer have any paths. There’s no structural difference between the batch and the ongoing UPDATEs, except for the fact you received the first batch in the first 10 or so seconds of the peering coming up.

Here’s a breakdown of the number of distinct paths received in that first batch, separated into IPv4 vs IPv6:

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-9-1.png" width="672" />
It’s important to highlight that this is a count of BGP paths, **not** routes. Each path is a unique comvbination of path attributes with associated NLRI information attached, and each one sent in a distinct BGP UPDATE message. Each one could have one or one-thousand routes associated with it. Doing the math on this dataset, the total number of routes across all of these paths is 949483. Cross referencing across [Geoff’s data](https://bgp.potaroo.net/as2.0/bgp-active.txt) for the same period, his shows 942,594. We’re in the same ballpark.

# A Garden Host or a Fire Hose?

That’s enough of the first tranche, let’s see how much change there is across the day. The animation below shows the number of BGP UPDATEs received every 30 seconds, along with the mean and median statistics:

    Warning: Using `size` aesthetic for lines was deprecated in ggplot2 3.4.0.
    ℹ Please use `linewidth` instead.
    This warning is displayed once every 8 hours.
    Call `lifecycle::last_lifecycle_warnings()` to see where this warning was
    generated.

    `geom_line()`: Each group consists of only one observation.
    ℹ Do you need to adjust the group aesthetic?
    `geom_line()`: Each group consists of only one observation.
    ℹ Do you need to adjust the group aesthetic?
    `geom_line()`: Each group consists of only one observation.
    ℹ Do you need to adjust the group aesthetic?
    `geom_line()`: Each group consists of only one observation.
    ℹ Do you need to adjust the group aesthetic?

![](index_files/figure-html/unnamed-chunk-10-1.gif)<!-- -->
So on average you’re looking at around ~50 path changes on the internet every 30 seconds. This isn’t a great representaton of global routing table change, as each one of those UPDATEs could have any number of routes,

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-11-1.png" width="672" />

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-12-1.png" width="672" />

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-13-1.png" width="672" />

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-14-1.png" width="672" />

<div id="gxvomnzqun" class=".gt_table" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#gxvomnzqun table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#gxvomnzqun thead, #gxvomnzqun tbody, #gxvomnzqun tfoot, #gxvomnzqun tr, #gxvomnzqun td, #gxvomnzqun th {
  border-style: none;
}
&#10;#gxvomnzqun p {
  margin: 0;
  padding: 0;
}
&#10;#gxvomnzqun .gt_table {
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
&#10;#gxvomnzqun .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#gxvomnzqun .gt_title {
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
&#10;#gxvomnzqun .gt_subtitle {
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
&#10;#gxvomnzqun .gt_heading {
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
&#10;#gxvomnzqun .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#gxvomnzqun .gt_col_headings {
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
&#10;#gxvomnzqun .gt_col_heading {
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
&#10;#gxvomnzqun .gt_column_spanner_outer {
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
&#10;#gxvomnzqun .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#gxvomnzqun .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#gxvomnzqun .gt_column_spanner {
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
&#10;#gxvomnzqun .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#gxvomnzqun .gt_group_heading {
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
&#10;#gxvomnzqun .gt_empty_group_heading {
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
&#10;#gxvomnzqun .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#gxvomnzqun .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#gxvomnzqun .gt_row {
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
&#10;#gxvomnzqun .gt_stub {
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
&#10;#gxvomnzqun .gt_stub_row_group {
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
&#10;#gxvomnzqun .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#gxvomnzqun .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#gxvomnzqun .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#gxvomnzqun .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#gxvomnzqun .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#gxvomnzqun .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#gxvomnzqun .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#gxvomnzqun .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#gxvomnzqun .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#gxvomnzqun .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#gxvomnzqun .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#gxvomnzqun .gt_footnotes {
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
&#10;#gxvomnzqun .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#gxvomnzqun .gt_sourcenotes {
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
&#10;#gxvomnzqun .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#gxvomnzqun .gt_left {
  text-align: left;
}
&#10;#gxvomnzqun .gt_center {
  text-align: center;
}
&#10;#gxvomnzqun .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#gxvomnzqun .gt_font_normal {
  font-weight: normal;
}
&#10;#gxvomnzqun .gt_font_bold {
  font-weight: bold;
}
&#10;#gxvomnzqun .gt_font_italic {
  font-style: italic;
}
&#10;#gxvomnzqun .gt_super {
  font-size: 65%;
}
&#10;#gxvomnzqun .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#gxvomnzqun .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#gxvomnzqun .gt_indent_1 {
  text-indent: 5px;
}
&#10;#gxvomnzqun .gt_indent_2 {
  text-indent: 10px;
}
&#10;#gxvomnzqun .gt_indent_3 {
  text-indent: 15px;
}
&#10;#gxvomnzqun .gt_indent_4 {
  text-indent: 20px;
}
&#10;#gxvomnzqun .gt_indent_5 {
  text-indent: 25px;
}
&#10;#gxvomnzqun .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#gxvomnzqun div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>
<div id="gxvomnzqun" class="reactable html-widget" style="width:auto;height:auto;"></div>
<script type="application/json" data-for="gxvomnzqun">{"x":{"tag":{"name":"Reactable","attribs":{"data":{"n":[3547,3547,1166,1138,723,629,491,367,288,281],"organisation":["Wideband Networks Pty Ltd","Ossini Pty Ltd","Angola Cables","NTT America, Inc.","Level 3 Parent, LLC","Cogent Communications","RETN Limited","SAMM Sociedade de Atividades em Multimidia LTDA","Columbus Networks USA, Inc.","MEGA TELE INFORMATICA"],"asn":["4764","45270","37468","2914","3356","174","9002","52551","23520","265269"],"source":["APNIC","APNIC","AFRINIC","ARIN","ARIN","ARIN","RIPE","LACNIC","ARIN","LACNIC"],"country":["AU","AU","AO","US","US","US","GB","BR","US","BR"]},"columns":[{"id":"n","name":"n","type":"numeric","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"right"},{"id":"organisation","name":"organisation","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"left"},{"id":"asn","name":"asn","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"right"},{"id":"source","name":"source","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"left"},{"id":"country","name":"country","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"left"}],"defaultPageSize":10,"showPageSizeOptions":false,"pageSizeOptions":[10,25,50,100],"paginationType":"numbers","showPagination":true,"showPageInfo":true,"minRows":1,"height":"auto","theme":{"color":"#333333","backgroundColor":"#FFFFFF","stripedColor":"rgba(128,128,128,0.05)","style":{"font-family":"system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif","fontSize":"16px"},"tableStyle":{"borderTopStyle":"solid","borderTopWidth":"2px","borderTopColor":"#D3D3D3"},"headerStyle":{"fontWeight":"normal","backgroundColor":"transparent","borderBottomStyle":"solid","borderBottomWidth":"2px","borderBottomColor":"#D3D3D3"},"groupHeaderStyle":{"fontWeight":"normal","backgroundColor":"transparent","borderBottomStyle":"solid","borderBottomWidth":"2px","borderBottomColor":"#D3D3D3"},"cellStyle":{"fontWeight":"normal"}},"elementId":"gxvomnzqun","dataKey":"2b0271bee813a74b6cbe855c9a59d4b1"},"children":[]},"class":"reactR_markup"},"evals":["tag.attribs.columns.0.style","tag.attribs.columns.1.style","tag.attribs.columns.2.style","tag.attribs.columns.3.style","tag.attribs.columns.4.style"],"jsHooks":[]}</script>
</div>

# Prepending Madness

There’s a couple of path attributes you can use to modify how traffic flows within an autonomous system: MED for neighbours,

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-16-1.png" width="672" />

    [1] "45270 4764 9002 136106 45305 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381"

Someone at asn 45270, ‘Dinas Komunikasi dan Informatika Kabupaten Tulungagung’ out of Indonesia, really wanted the NLRI ‘103.179.250.0/24’ to be less preferable.

``` r
bgp |>
    filter(ip_version == 'v4') |>
    unnest(nlri) |>
    filter(nlri == '103.179.250.0/24') |>
    slice_tail() |> 
    select(id, as_path, recv_time, type, nlri) |>
    gt() |>
    opt_interactive()
```

<div id="prozuucmib" class=".gt_table" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#prozuucmib table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#prozuucmib thead, #prozuucmib tbody, #prozuucmib tfoot, #prozuucmib tr, #prozuucmib td, #prozuucmib th {
  border-style: none;
}
&#10;#prozuucmib p {
  margin: 0;
  padding: 0;
}
&#10;#prozuucmib .gt_table {
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
&#10;#prozuucmib .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#prozuucmib .gt_title {
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
&#10;#prozuucmib .gt_subtitle {
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
&#10;#prozuucmib .gt_heading {
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
&#10;#prozuucmib .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#prozuucmib .gt_col_headings {
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
&#10;#prozuucmib .gt_col_heading {
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
&#10;#prozuucmib .gt_column_spanner_outer {
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
&#10;#prozuucmib .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#prozuucmib .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#prozuucmib .gt_column_spanner {
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
&#10;#prozuucmib .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#prozuucmib .gt_group_heading {
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
&#10;#prozuucmib .gt_empty_group_heading {
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
&#10;#prozuucmib .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#prozuucmib .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#prozuucmib .gt_row {
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
&#10;#prozuucmib .gt_stub {
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
&#10;#prozuucmib .gt_stub_row_group {
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
&#10;#prozuucmib .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#prozuucmib .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#prozuucmib .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#prozuucmib .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#prozuucmib .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#prozuucmib .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#prozuucmib .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#prozuucmib .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#prozuucmib .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#prozuucmib .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#prozuucmib .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#prozuucmib .gt_footnotes {
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
&#10;#prozuucmib .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#prozuucmib .gt_sourcenotes {
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
&#10;#prozuucmib .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#prozuucmib .gt_left {
  text-align: left;
}
&#10;#prozuucmib .gt_center {
  text-align: center;
}
&#10;#prozuucmib .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#prozuucmib .gt_font_normal {
  font-weight: normal;
}
&#10;#prozuucmib .gt_font_bold {
  font-weight: bold;
}
&#10;#prozuucmib .gt_font_italic {
  font-style: italic;
}
&#10;#prozuucmib .gt_super {
  font-size: 65%;
}
&#10;#prozuucmib .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#prozuucmib .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#prozuucmib .gt_indent_1 {
  text-indent: 5px;
}
&#10;#prozuucmib .gt_indent_2 {
  text-indent: 10px;
}
&#10;#prozuucmib .gt_indent_3 {
  text-indent: 15px;
}
&#10;#prozuucmib .gt_indent_4 {
  text-indent: 20px;
}
&#10;#prozuucmib .gt_indent_5 {
  text-indent: 25px;
}
&#10;#prozuucmib .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#prozuucmib div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>
<div id="prozuucmib" class="reactable html-widget" style="width:auto;height:auto;"></div>
<script type="application/json" data-for="prozuucmib">{"x":{"tag":{"name":"Reactable","attribs":{"data":{"id":[280028],"as_path":[[45270,4764,4761,149381]],"recv_time":["2024-01-06T02:21:35Z"],"type":["UPDATE"],"nlri":["103.179.250.0/24"]},"columns":[{"id":"id","name":"id","type":"numeric","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"right"},{"id":"as_path","name":"as_path","type":"list","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"center"},{"id":"recv_time","name":"recv_time","type":"Date","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"right"},{"id":"type","name":"type","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"left"},{"id":"nlri","name":"nlri","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"right"}],"defaultPageSize":10,"showPageSizeOptions":false,"pageSizeOptions":[10,25,50,100],"paginationType":"numbers","showPagination":true,"showPageInfo":true,"minRows":1,"height":"auto","theme":{"color":"#333333","backgroundColor":"#FFFFFF","stripedColor":"rgba(128,128,128,0.05)","style":{"font-family":"system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif","fontSize":"16px"},"tableStyle":{"borderTopStyle":"solid","borderTopWidth":"2px","borderTopColor":"#D3D3D3"},"headerStyle":{"fontWeight":"normal","backgroundColor":"transparent","borderBottomStyle":"solid","borderBottomWidth":"2px","borderBottomColor":"#D3D3D3"},"groupHeaderStyle":{"fontWeight":"normal","backgroundColor":"transparent","borderBottomStyle":"solid","borderBottomWidth":"2px","borderBottomColor":"#D3D3D3"},"cellStyle":{"fontWeight":"normal"}},"elementId":"prozuucmib","dataKey":"6698bb22d36d6d2b7f66c398723e4637"},"children":[]},"class":"reactR_markup"},"evals":["tag.attribs.columns.0.style","tag.attribs.columns.1.style","tag.attribs.columns.2.style","tag.attribs.columns.3.style","tag.attribs.columns.4.style"],"jsHooks":[]}</script>
</div>

    [1] "45270 4764 2914 29632 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 200579 200579 203868"

This time we’ve got what appears to be transit provider asn8772 (NetAssist LLC), prepending to make paths to asn203868 (Rifqi Arief Pamungkas, again out of Indonesia)

# Path Attributes

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-21-1.png" width="672" />

<div id="gjzgffubca" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#gjzgffubca table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#gjzgffubca thead, #gjzgffubca tbody, #gjzgffubca tfoot, #gjzgffubca tr, #gjzgffubca td, #gjzgffubca th {
  border-style: none;
}
&#10;#gjzgffubca p {
  margin: 0;
  padding: 0;
}
&#10;#gjzgffubca .gt_table {
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
&#10;#gjzgffubca .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#gjzgffubca .gt_title {
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
&#10;#gjzgffubca .gt_subtitle {
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
&#10;#gjzgffubca .gt_heading {
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
&#10;#gjzgffubca .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#gjzgffubca .gt_col_headings {
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
&#10;#gjzgffubca .gt_col_heading {
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
&#10;#gjzgffubca .gt_column_spanner_outer {
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
&#10;#gjzgffubca .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#gjzgffubca .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#gjzgffubca .gt_column_spanner {
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
&#10;#gjzgffubca .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#gjzgffubca .gt_group_heading {
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
&#10;#gjzgffubca .gt_empty_group_heading {
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
&#10;#gjzgffubca .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#gjzgffubca .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#gjzgffubca .gt_row {
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
&#10;#gjzgffubca .gt_stub {
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
&#10;#gjzgffubca .gt_stub_row_group {
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
&#10;#gjzgffubca .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#gjzgffubca .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#gjzgffubca .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#gjzgffubca .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#gjzgffubca .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#gjzgffubca .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#gjzgffubca .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#gjzgffubca .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#gjzgffubca .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#gjzgffubca .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#gjzgffubca .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#gjzgffubca .gt_footnotes {
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
&#10;#gjzgffubca .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#gjzgffubca .gt_sourcenotes {
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
&#10;#gjzgffubca .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#gjzgffubca .gt_left {
  text-align: left;
}
&#10;#gjzgffubca .gt_center {
  text-align: center;
}
&#10;#gjzgffubca .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#gjzgffubca .gt_font_normal {
  font-weight: normal;
}
&#10;#gjzgffubca .gt_font_bold {
  font-weight: bold;
}
&#10;#gjzgffubca .gt_font_italic {
  font-style: italic;
}
&#10;#gjzgffubca .gt_super {
  font-size: 65%;
}
&#10;#gjzgffubca .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#gjzgffubca .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#gjzgffubca .gt_indent_1 {
  text-indent: 5px;
}
&#10;#gjzgffubca .gt_indent_2 {
  text-indent: 10px;
}
&#10;#gjzgffubca .gt_indent_3 {
  text-indent: 15px;
}
&#10;#gjzgffubca .gt_indent_4 {
  text-indent: 20px;
}
&#10;#gjzgffubca .gt_indent_5 {
  text-indent: 25px;
}
&#10;#gjzgffubca .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#gjzgffubca div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
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

<div id="uxfpudugza" class=".gt_table" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#uxfpudugza table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#uxfpudugza thead, #uxfpudugza tbody, #uxfpudugza tfoot, #uxfpudugza tr, #uxfpudugza td, #uxfpudugza th {
  border-style: none;
}
&#10;#uxfpudugza p {
  margin: 0;
  padding: 0;
}
&#10;#uxfpudugza .gt_table {
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
&#10;#uxfpudugza .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#uxfpudugza .gt_title {
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
&#10;#uxfpudugza .gt_subtitle {
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
&#10;#uxfpudugza .gt_heading {
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
&#10;#uxfpudugza .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#uxfpudugza .gt_col_headings {
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
&#10;#uxfpudugza .gt_col_heading {
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
&#10;#uxfpudugza .gt_column_spanner_outer {
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
&#10;#uxfpudugza .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#uxfpudugza .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#uxfpudugza .gt_column_spanner {
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
&#10;#uxfpudugza .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#uxfpudugza .gt_group_heading {
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
&#10;#uxfpudugza .gt_empty_group_heading {
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
&#10;#uxfpudugza .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#uxfpudugza .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#uxfpudugza .gt_row {
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
&#10;#uxfpudugza .gt_stub {
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
&#10;#uxfpudugza .gt_stub_row_group {
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
&#10;#uxfpudugza .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#uxfpudugza .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#uxfpudugza .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#uxfpudugza .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#uxfpudugza .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#uxfpudugza .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#uxfpudugza .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#uxfpudugza .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#uxfpudugza .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#uxfpudugza .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#uxfpudugza .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#uxfpudugza .gt_footnotes {
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
&#10;#uxfpudugza .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#uxfpudugza .gt_sourcenotes {
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
&#10;#uxfpudugza .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#uxfpudugza .gt_left {
  text-align: left;
}
&#10;#uxfpudugza .gt_center {
  text-align: center;
}
&#10;#uxfpudugza .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#uxfpudugza .gt_font_normal {
  font-weight: normal;
}
&#10;#uxfpudugza .gt_font_bold {
  font-weight: bold;
}
&#10;#uxfpudugza .gt_font_italic {
  font-style: italic;
}
&#10;#uxfpudugza .gt_super {
  font-size: 65%;
}
&#10;#uxfpudugza .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#uxfpudugza .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#uxfpudugza .gt_indent_1 {
  text-indent: 5px;
}
&#10;#uxfpudugza .gt_indent_2 {
  text-indent: 10px;
}
&#10;#uxfpudugza .gt_indent_3 {
  text-indent: 15px;
}
&#10;#uxfpudugza .gt_indent_4 {
  text-indent: 20px;
}
&#10;#uxfpudugza .gt_indent_5 {
  text-indent: 25px;
}
&#10;#uxfpudugza .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#uxfpudugza div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>
<div id="uxfpudugza" class="reactable html-widget" style="width:auto;height:auto;"></div>
<script type="application/json" data-for="uxfpudugza">{"x":{"tag":{"name":"Reactable","attribs":{"data":{"nlri":["140.99.244.0/23","107.154.97.0/24","45.172.92.0/22","151.236.111.0/24","205.164.85.0/24","41.209.0.0/18","143.255.204.0/22","176.124.58.0/24","187.1.11.0/24","187.1.13.0/24","103.248.132.0/22","185.200.123.0/24","138.121.151.0/24","193.105.107.0/24","83.243.112.0/21","202.45.88.0/24","203.145.74.0/24","203.145.78.0/24","209.54.122.0/24","103.177.86.0/24","103.177.87.0/24","103.223.2.0/24","188.130.192.0/22","109.248.130.0/24","41.75.208.0/20","67.211.53.0/24","207.167.116.0/22","213.204.81.0/24","102.220.224.0/24","102.220.227.0/24","102.220.226.0/24","154.88.8.0/24","78.142.198.0/24","209.22.66.0/24","209.22.67.0/24","185.116.216.0/22","213.204.80.0/24","64.68.236.0/22","178.22.141.0/24","130.137.230.0/24","113.23.173.0/24","112.33.120.0/24","185.18.201.0/24","170.238.225.0/24","186.170.29.0/24","181.225.48.0/24","181.225.43.0/24","183.90.162.0/24","183.90.163.0/24","207.244.192.0/22"],"n":[2596,2583,2494,2312,2189,2069,2048,1584,1582,1580,1512,1489,1395,1245,1190,1171,1171,1171,1062,987,987,848,839,829,791,745,672,640,604,603,601,561,558,533,533,462,441,439,432,426,399,383,367,356,347,345,338,319,317,316]},"columns":[{"id":"nlri","name":"nlri","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"right"},{"id":"n","name":"n","type":"numeric","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"right"}],"defaultPageSize":10,"showPageSizeOptions":false,"pageSizeOptions":[10,25,50,100],"paginationType":"numbers","showPagination":true,"showPageInfo":true,"minRows":1,"height":"auto","theme":{"color":"#333333","backgroundColor":"#FFFFFF","stripedColor":"rgba(128,128,128,0.05)","style":{"font-family":"system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif","fontSize":"16px"},"tableStyle":{"borderTopStyle":"solid","borderTopWidth":"2px","borderTopColor":"#D3D3D3"},"headerStyle":{"fontWeight":"normal","backgroundColor":"transparent","borderBottomStyle":"solid","borderBottomWidth":"2px","borderBottomColor":"#D3D3D3"},"groupHeaderStyle":{"fontWeight":"normal","backgroundColor":"transparent","borderBottomStyle":"solid","borderBottomWidth":"2px","borderBottomColor":"#D3D3D3"},"cellStyle":{"fontWeight":"normal"}},"elementId":"uxfpudugza","dataKey":"aa65f028c6a1d7935c0915a52c053439"},"children":[]},"class":"reactR_markup"},"evals":["tag.attribs.columns.0.style","tag.attribs.columns.1.style"],"jsHooks":[]}</script>
</div>

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-24-1.png" width="672" />

``` r
as_tbl_graph(as_path_edges, directed = TRUE) |>
    ggraph(layout = 'igraph', algorithm = 'fr') +
    geom_edge_link(arrow = arrow(type = 'closed', length = unit(4, 'mm')), end_cap = circle(7, 'mm')) +
    geom_node_point(size = 17) +
    geom_node_text(aes(label = name), colour = 'white') +
    guides(edge_width = FALSE) +
    theme_graph()
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-26-1.png" width="672" />
