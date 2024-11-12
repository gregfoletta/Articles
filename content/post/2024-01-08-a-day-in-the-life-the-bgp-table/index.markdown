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

Much has been writted and a lot of analysis performed on the BGP table over the years, a significant portion by the inimitable [Geoff Huston](https://bgp.potaroo.net/). However this often focuses on is long term trends, like the growth of the routing table or the the adoption of IPv6 over the span of months or years.

I was interested in what was happening in the short term: what does it look like for a router connected to the churning, foamy chaos of the interenet during a single day? In this article we’ll investigate the intra-day shenanigans of the global routing table with an eye to finding some of the ridiculous things that go on out there.

# Let the Yak SHaving Begin

The first step, as always, is to get some data to work with. Thanks to my colleague Andrew Vinton

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

<div id="omlodipexi" class=".gt_table" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#omlodipexi table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#omlodipexi thead, #omlodipexi tbody, #omlodipexi tfoot, #omlodipexi tr, #omlodipexi td, #omlodipexi th {
  border-style: none;
}
&#10;#omlodipexi p {
  margin: 0;
  padding: 0;
}
&#10;#omlodipexi .gt_table {
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
&#10;#omlodipexi .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#omlodipexi .gt_title {
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
&#10;#omlodipexi .gt_subtitle {
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
&#10;#omlodipexi .gt_heading {
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
&#10;#omlodipexi .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#omlodipexi .gt_col_headings {
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
&#10;#omlodipexi .gt_col_heading {
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
&#10;#omlodipexi .gt_column_spanner_outer {
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
&#10;#omlodipexi .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#omlodipexi .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#omlodipexi .gt_column_spanner {
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
&#10;#omlodipexi .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#omlodipexi .gt_group_heading {
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
&#10;#omlodipexi .gt_empty_group_heading {
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
&#10;#omlodipexi .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#omlodipexi .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#omlodipexi .gt_row {
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
&#10;#omlodipexi .gt_stub {
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
&#10;#omlodipexi .gt_stub_row_group {
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
&#10;#omlodipexi .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#omlodipexi .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#omlodipexi .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#omlodipexi .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#omlodipexi .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#omlodipexi .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#omlodipexi .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#omlodipexi .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#omlodipexi .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#omlodipexi .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#omlodipexi .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#omlodipexi .gt_footnotes {
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
&#10;#omlodipexi .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#omlodipexi .gt_sourcenotes {
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
&#10;#omlodipexi .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#omlodipexi .gt_left {
  text-align: left;
}
&#10;#omlodipexi .gt_center {
  text-align: center;
}
&#10;#omlodipexi .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#omlodipexi .gt_font_normal {
  font-weight: normal;
}
&#10;#omlodipexi .gt_font_bold {
  font-weight: bold;
}
&#10;#omlodipexi .gt_font_italic {
  font-style: italic;
}
&#10;#omlodipexi .gt_super {
  font-size: 65%;
}
&#10;#omlodipexi .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#omlodipexi .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#omlodipexi .gt_indent_1 {
  text-indent: 5px;
}
&#10;#omlodipexi .gt_indent_2 {
  text-indent: 10px;
}
&#10;#omlodipexi .gt_indent_3 {
  text-indent: 15px;
}
&#10;#omlodipexi .gt_indent_4 {
  text-indent: 20px;
}
&#10;#omlodipexi .gt_indent_5 {
  text-indent: 25px;
}
&#10;#omlodipexi .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#omlodipexi div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>
<div id="omlodipexi" class="reactable html-widget" style="width:auto;height:auto;"></div>
<script type="application/json" data-for="omlodipexi">{"x":{"tag":{"name":"Reactable","attribs":{"data":{"recv_time":["2024-01-05T19:31:44Z","2024-01-05T19:31:44Z","2024-01-05T19:31:44Z","2024-01-05T19:31:44Z","2024-01-05T19:31:44Z","2024-01-05T19:31:44Z"],"id":[190538,190539,190540,190541,190542,190543],"type":["UPDATE","UPDATE","UPDATE","UPDATE","UPDATE","UPDATE"],"nlri":["41.211.42.0/24\n41.211.32.0/24\n41.211.47.0/24\n41.211.38.0/24\n41.211.37.0/24\n41.211.36.0/24","103.177.87.0/24\n103.177.86.0/24","38.172.160.0/24","176.124.58.0/24","103.103.34.0/24","117.103.87.0/24"],"withdrawn_routes":["130.137.140.0/24, 130.137.99.0/24, 130.137.121.0/24, 50.117.116.0/24, 205.65.44.0/22, 185.241.10.0/24, 130.137.105.0/24","","","","",""],"path_attributes":[{"type":["ORIGIN","AS_PATH","NEXT_HOP","AS4_PATH"],"type_code":[1,2,3,17],"flags":[["well-known","transitive","complete","standard"],["well-known","transitive","complete","standard"],["well-known","transitive","complete","standard"],["optional","non-transitive","partial","extended"]],"flags_low_nibble":[0,0,0,0],"origin":["IGP",null,null,null],"n_as_segments":["NA",1,"NA",1],"n_total_as":["NA",6,"NA",6],"path_segments":[null,{"type":["AS_SEQUENCE"],"n_as":[6],"asns":[[45270,4764,1299,174,16637,23456]]},null,{"type":["AS_SEQUENCE"],"n_as":[6],"asns":[[45270,4764,1299,174,16637,327765]]}],"next_hop":[null,null,"61.245.147.114",null]},{"type":["ORIGIN","AS_PATH","NEXT_HOP","AS4_PATH"],"type_code":[1,2,3,17],"flags":[["well-known","transitive","complete","standard"],["well-known","transitive","complete","standard"],["well-known","transitive","complete","standard"],["optional","non-transitive","partial","extended"]],"flags_low_nibble":[0,0,0,0],"origin":["IGP",null,null,null],"n_as_segments":["NA",1,"NA",1],"n_total_as":["NA",8,"NA",8],"path_segments":[null,{"type":["AS_SEQUENCE"],"n_as":[8],"asns":[[45270,4764,174,23456,23456,23456,23456,23456]]},null,{"type":["AS_SEQUENCE"],"n_as":[8],"asns":[[45270,4764,174,136255,136975,133524,134840,149038]]}],"next_hop":[null,null,"61.245.147.114",null]},{"type":["ORIGIN","AS_PATH","NEXT_HOP","AS4_PATH"],"type_code":[1,2,3,17],"flags":[["well-known","transitive","complete","standard"],["well-known","transitive","complete","standard"],["well-known","transitive","complete","standard"],["optional","non-transitive","partial","extended"]],"flags_low_nibble":[0,0,0,0],"origin":["IGP",null,null,null],"n_as_segments":["NA",1,"NA",1],"n_total_as":["NA",12,"NA",12],"path_segments":[null,{"type":["AS_SEQUENCE"],"n_as":[12],"asns":[[45270,4764,1299,23520,23456,23456,23456,23456,23456,23456,23456,23456]]},null,{"type":["AS_SEQUENCE"],"n_as":[12],"asns":[[45270,4764,1299,23520,263703,270026,270026,270026,270026,270026,270026,270026]]}],"next_hop":[null,null,"61.245.147.114",null]},{"type":["ORIGIN","AS_PATH","NEXT_HOP","AS4_PATH"],"type_code":[1,2,3,17],"flags":[["well-known","transitive","complete","standard"],["well-known","transitive","complete","standard"],["well-known","transitive","complete","standard"],["optional","non-transitive","partial","extended"]],"flags_low_nibble":[0,0,0,0],"origin":["IGP",null,null,null],"n_as_segments":["NA",1,"NA",1],"n_total_as":["NA",6,"NA",6],"path_segments":[null,{"type":["AS_SEQUENCE"],"n_as":[6],"asns":[[45270,4764,174,12310,44679,23456]]},null,{"type":["AS_SEQUENCE"],"n_as":[6],"asns":[[45270,4764,174,12310,44679,209856]]}],"next_hop":[null,null,"61.245.147.114",null]},{"type":["ORIGIN","AS_PATH","NEXT_HOP","AS4_PATH"],"type_code":[1,2,3,17],"flags":[["well-known","transitive","complete","standard"],["well-known","transitive","complete","standard"],["well-known","transitive","complete","standard"],["optional","non-transitive","partial","extended"]],"flags_low_nibble":[0,0,0,0],"origin":["IGP",null,null,null],"n_as_segments":["NA",1,"NA",1],"n_total_as":["NA",7,"NA",7],"path_segments":[null,{"type":["AS_SEQUENCE"],"n_as":[7],"asns":[[45270,4764,23456,23456,23456,23456,23456]]},null,{"type":["AS_SEQUENCE"],"n_as":[7],"asns":[[45270,4764,139901,137048,137048,137048,137048]]}],"next_hop":[null,null,"61.245.147.114",null]},{"type":["ORIGIN","AS_PATH","NEXT_HOP","AS4_PATH"],"type_code":[1,2,3,17],"flags":[["well-known","transitive","complete","standard"],["well-known","transitive","complete","standard"],["well-known","transitive","complete","standard"],["optional","non-transitive","partial","extended"]],"flags_low_nibble":[0,0,0,0],"origin":["IGP",null,null,null],"n_as_segments":["NA",1,"NA",1],"n_total_as":["NA",8,"NA",8],"path_segments":[null,{"type":["AS_SEQUENCE"],"n_as":[8],"asns":[[45270,4764,23456,64018,38614,38614,38614,38614]]},null,{"type":["AS_SEQUENCE"],"n_as":[8],"asns":[[45270,4764,139901,64018,38614,38614,38614,38614]]}],"next_hop":[null,null,"61.245.147.114",null]}]},"columns":[{"id":"recv_time","name":"recv_time","type":"Date","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"right"},{"id":"id","name":"id","type":"numeric","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"right"},{"id":"type","name":"type","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"left"},{"id":"nlri","name":"nlri","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"left"},{"id":"withdrawn_routes","name":"withdrawn_routes","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"right"},{"id":"path_attributes","name":"path_attributes","type":"list","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"center"}],"defaultPageSize":10,"showPageSizeOptions":false,"pageSizeOptions":[10,25,50,100],"paginationType":"numbers","showPagination":true,"showPageInfo":true,"minRows":1,"height":"auto","theme":{"color":"#333333","backgroundColor":"#FFFFFF","stripedColor":"rgba(128,128,128,0.05)","style":{"font-family":"system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif","fontSize":"16px"},"tableStyle":{"borderTopStyle":"solid","borderTopWidth":"2px","borderTopColor":"#D3D3D3"},"headerStyle":{"fontWeight":"normal","backgroundColor":"transparent","borderBottomStyle":"solid","borderBottomWidth":"2px","borderBottomColor":"#D3D3D3"},"groupHeaderStyle":{"fontWeight":"normal","backgroundColor":"transparent","borderBottomStyle":"solid","borderBottomWidth":"2px","borderBottomColor":"#D3D3D3"},"cellStyle":{"fontWeight":"normal"}},"elementId":"omlodipexi","dataKey":"d46682d79a13ac6ce2276f67bebd2df0"},"children":[]},"class":"reactR_markup"},"evals":["tag.attribs.columns.0.style","tag.attribs.columns.1.style","tag.attribs.columns.2.style","tag.attribs.columns.3.style","tag.attribs.columns.4.style","tag.attribs.columns.5.style"],"jsHooks":[]}</script>
</div>
<div id="efumjzsdmz" class=".gt_table" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#efumjzsdmz table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#efumjzsdmz thead, #efumjzsdmz tbody, #efumjzsdmz tfoot, #efumjzsdmz tr, #efumjzsdmz td, #efumjzsdmz th {
  border-style: none;
}
&#10;#efumjzsdmz p {
  margin: 0;
  padding: 0;
}
&#10;#efumjzsdmz .gt_table {
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
&#10;#efumjzsdmz .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#efumjzsdmz .gt_title {
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
&#10;#efumjzsdmz .gt_subtitle {
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
&#10;#efumjzsdmz .gt_heading {
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
&#10;#efumjzsdmz .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#efumjzsdmz .gt_col_headings {
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
&#10;#efumjzsdmz .gt_col_heading {
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
&#10;#efumjzsdmz .gt_column_spanner_outer {
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
&#10;#efumjzsdmz .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#efumjzsdmz .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#efumjzsdmz .gt_column_spanner {
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
&#10;#efumjzsdmz .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#efumjzsdmz .gt_group_heading {
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
&#10;#efumjzsdmz .gt_empty_group_heading {
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
&#10;#efumjzsdmz .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#efumjzsdmz .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#efumjzsdmz .gt_row {
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
&#10;#efumjzsdmz .gt_stub {
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
&#10;#efumjzsdmz .gt_stub_row_group {
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
&#10;#efumjzsdmz .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#efumjzsdmz .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#efumjzsdmz .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#efumjzsdmz .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#efumjzsdmz .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#efumjzsdmz .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#efumjzsdmz .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#efumjzsdmz .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#efumjzsdmz .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#efumjzsdmz .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#efumjzsdmz .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#efumjzsdmz .gt_footnotes {
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
&#10;#efumjzsdmz .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#efumjzsdmz .gt_sourcenotes {
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
&#10;#efumjzsdmz .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#efumjzsdmz .gt_left {
  text-align: left;
}
&#10;#efumjzsdmz .gt_center {
  text-align: center;
}
&#10;#efumjzsdmz .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#efumjzsdmz .gt_font_normal {
  font-weight: normal;
}
&#10;#efumjzsdmz .gt_font_bold {
  font-weight: bold;
}
&#10;#efumjzsdmz .gt_font_italic {
  font-style: italic;
}
&#10;#efumjzsdmz .gt_super {
  font-size: 65%;
}
&#10;#efumjzsdmz .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#efumjzsdmz .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#efumjzsdmz .gt_indent_1 {
  text-indent: 5px;
}
&#10;#efumjzsdmz .gt_indent_2 {
  text-indent: 10px;
}
&#10;#efumjzsdmz .gt_indent_3 {
  text-indent: 15px;
}
&#10;#efumjzsdmz .gt_indent_4 {
  text-indent: 20px;
}
&#10;#efumjzsdmz .gt_indent_5 {
  text-indent: 25px;
}
&#10;#efumjzsdmz .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#efumjzsdmz div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>
<div id="efumjzsdmz" class="reactable html-widget" style="width:auto;height:auto;"></div>
<script type="application/json" data-for="efumjzsdmz">{"x":{"tag":{"name":"Reactable","attribs":{"data":{"id":[695,695,695,695,695,695,695,695],"type":["ORIGIN","AS_PATH","NEXT_HOP","AGGREGATOR","AGGREGATOR","AS4_PATH","AS4_AGGREGATOR","AS4_AGGREGATOR"],"type_code":[1,2,3,7,7,17,18,18],"flags":["well-known, transitive, complete, standard","well-known, transitive, complete, standard","well-known, transitive, complete, standard","optional, non-transitive, partial, extended","optional, non-transitive, partial, extended","optional, non-transitive, partial, extended","optional, non-transitive, partial, extended","optional, non-transitive, partial, extended"],"value":["IGP","AS_SEQUENCE c(45270, 4764, 4651, 23456, 23456)","61.245.147.114","23456","110.77.255.21","AS_SEQUENCE c(45270, 4764, 4651, 131090, 131090)","131090","110.77.255.21"]},"columns":[{"id":"id","name":"id","type":"numeric","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"right"},{"id":"type","name":"type","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"left"},{"id":"type_code","name":"type_code","type":"numeric","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"right"},{"id":"flags","name":"flags","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"left"},{"id":"value","name":"value","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"left"}],"defaultPageSize":10,"showPageSizeOptions":false,"pageSizeOptions":[10,25,50,100],"paginationType":"numbers","showPagination":true,"showPageInfo":true,"minRows":1,"height":"auto","theme":{"color":"#333333","backgroundColor":"#FFFFFF","stripedColor":"rgba(128,128,128,0.05)","style":{"font-family":"system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif","fontSize":"16px"},"tableStyle":{"borderTopStyle":"solid","borderTopWidth":"2px","borderTopColor":"#D3D3D3"},"headerStyle":{"fontWeight":"normal","backgroundColor":"transparent","borderBottomStyle":"solid","borderBottomWidth":"2px","borderBottomColor":"#D3D3D3"},"groupHeaderStyle":{"fontWeight":"normal","backgroundColor":"transparent","borderBottomStyle":"solid","borderBottomWidth":"2px","borderBottomColor":"#D3D3D3"},"cellStyle":{"fontWeight":"normal"}},"elementId":"efumjzsdmz","dataKey":"7e017aac901c0f27d62cd5116c70e9d7"},"children":[]},"class":"reactR_markup"},"evals":["tag.attribs.columns.0.style","tag.attribs.columns.1.style","tag.attribs.columns.2.style","tag.attribs.columns.3.style","tag.attribs.columns.4.style"],"jsHooks":[]}</script>
</div>

# Initial Send, Number of v4 and v6 Paths

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-9-1.png" width="672" />

Number of routes is 949483. [Geoff’s data](https://bgp.potaroo.net/as2.0/bgp-active.txt) shows 942,594

# Updates Over Time

![](index_files/figure-html/unnamed-chunk-10-1.gif)<!-- -->
<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-11-1.png" width="672" />

<div id="ysvwgudkrf" class=".gt_table" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#ysvwgudkrf table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#ysvwgudkrf thead, #ysvwgudkrf tbody, #ysvwgudkrf tfoot, #ysvwgudkrf tr, #ysvwgudkrf td, #ysvwgudkrf th {
  border-style: none;
}
&#10;#ysvwgudkrf p {
  margin: 0;
  padding: 0;
}
&#10;#ysvwgudkrf .gt_table {
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
&#10;#ysvwgudkrf .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#ysvwgudkrf .gt_title {
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
&#10;#ysvwgudkrf .gt_subtitle {
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
&#10;#ysvwgudkrf .gt_heading {
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
&#10;#ysvwgudkrf .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#ysvwgudkrf .gt_col_headings {
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
&#10;#ysvwgudkrf .gt_col_heading {
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
&#10;#ysvwgudkrf .gt_column_spanner_outer {
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
&#10;#ysvwgudkrf .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#ysvwgudkrf .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#ysvwgudkrf .gt_column_spanner {
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
&#10;#ysvwgudkrf .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#ysvwgudkrf .gt_group_heading {
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
&#10;#ysvwgudkrf .gt_empty_group_heading {
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
&#10;#ysvwgudkrf .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#ysvwgudkrf .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#ysvwgudkrf .gt_row {
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
&#10;#ysvwgudkrf .gt_stub {
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
&#10;#ysvwgudkrf .gt_stub_row_group {
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
&#10;#ysvwgudkrf .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#ysvwgudkrf .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#ysvwgudkrf .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#ysvwgudkrf .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#ysvwgudkrf .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#ysvwgudkrf .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#ysvwgudkrf .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#ysvwgudkrf .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#ysvwgudkrf .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#ysvwgudkrf .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#ysvwgudkrf .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#ysvwgudkrf .gt_footnotes {
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
&#10;#ysvwgudkrf .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#ysvwgudkrf .gt_sourcenotes {
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
&#10;#ysvwgudkrf .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#ysvwgudkrf .gt_left {
  text-align: left;
}
&#10;#ysvwgudkrf .gt_center {
  text-align: center;
}
&#10;#ysvwgudkrf .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#ysvwgudkrf .gt_font_normal {
  font-weight: normal;
}
&#10;#ysvwgudkrf .gt_font_bold {
  font-weight: bold;
}
&#10;#ysvwgudkrf .gt_font_italic {
  font-style: italic;
}
&#10;#ysvwgudkrf .gt_super {
  font-size: 65%;
}
&#10;#ysvwgudkrf .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#ysvwgudkrf .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#ysvwgudkrf .gt_indent_1 {
  text-indent: 5px;
}
&#10;#ysvwgudkrf .gt_indent_2 {
  text-indent: 10px;
}
&#10;#ysvwgudkrf .gt_indent_3 {
  text-indent: 15px;
}
&#10;#ysvwgudkrf .gt_indent_4 {
  text-indent: 20px;
}
&#10;#ysvwgudkrf .gt_indent_5 {
  text-indent: 25px;
}
&#10;#ysvwgudkrf .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#ysvwgudkrf div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>
<div id="ysvwgudkrf" class="reactable html-widget" style="width:auto;height:auto;"></div>
<script type="application/json" data-for="ysvwgudkrf">{"x":{"tag":{"name":"Reactable","attribs":{"data":{"n":[3547,3547,1166,1138,723,629,491,367,288,281],"organisation":["Wideband Networks Pty Ltd","Ossini Pty Ltd","Angola Cables","NTT America, Inc.","Level 3 Parent, LLC","Cogent Communications","RETN Limited","SAMM Sociedade de Atividades em Multimidia LTDA","Columbus Networks USA, Inc.","MEGA TELE INFORMATICA"],"asn":["4764","45270","37468","2914","3356","174","9002","52551","23520","265269"],"source":["APNIC","APNIC","AFRINIC","ARIN","ARIN","ARIN","RIPE","LACNIC","ARIN","LACNIC"],"country":["AU","AU","AO","US","US","US","GB","BR","US","BR"]},"columns":[{"id":"n","name":"n","type":"numeric","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"right"},{"id":"organisation","name":"organisation","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"left"},{"id":"asn","name":"asn","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"right"},{"id":"source","name":"source","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"left"},{"id":"country","name":"country","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"left"}],"defaultPageSize":10,"showPageSizeOptions":false,"pageSizeOptions":[10,25,50,100],"paginationType":"numbers","showPagination":true,"showPageInfo":true,"minRows":1,"height":"auto","theme":{"color":"#333333","backgroundColor":"#FFFFFF","stripedColor":"rgba(128,128,128,0.05)","style":{"font-family":"system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif","fontSize":"16px"},"tableStyle":{"borderTopStyle":"solid","borderTopWidth":"2px","borderTopColor":"#D3D3D3"},"headerStyle":{"fontWeight":"normal","backgroundColor":"transparent","borderBottomStyle":"solid","borderBottomWidth":"2px","borderBottomColor":"#D3D3D3"},"groupHeaderStyle":{"fontWeight":"normal","backgroundColor":"transparent","borderBottomStyle":"solid","borderBottomWidth":"2px","borderBottomColor":"#D3D3D3"},"cellStyle":{"fontWeight":"normal"}},"elementId":"ysvwgudkrf","dataKey":"2b0271bee813a74b6cbe855c9a59d4b1"},"children":[]},"class":"reactR_markup"},"evals":["tag.attribs.columns.0.style","tag.attribs.columns.1.style","tag.attribs.columns.2.style","tag.attribs.columns.3.style","tag.attribs.columns.4.style"],"jsHooks":[]}</script>
</div>

# Prepending Madness

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-13-1.png" width="672" />

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

<div id="sucjmgwgsz" class=".gt_table" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#sucjmgwgsz table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#sucjmgwgsz thead, #sucjmgwgsz tbody, #sucjmgwgsz tfoot, #sucjmgwgsz tr, #sucjmgwgsz td, #sucjmgwgsz th {
  border-style: none;
}
&#10;#sucjmgwgsz p {
  margin: 0;
  padding: 0;
}
&#10;#sucjmgwgsz .gt_table {
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
&#10;#sucjmgwgsz .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#sucjmgwgsz .gt_title {
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
&#10;#sucjmgwgsz .gt_subtitle {
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
&#10;#sucjmgwgsz .gt_heading {
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
&#10;#sucjmgwgsz .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#sucjmgwgsz .gt_col_headings {
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
&#10;#sucjmgwgsz .gt_col_heading {
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
&#10;#sucjmgwgsz .gt_column_spanner_outer {
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
&#10;#sucjmgwgsz .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#sucjmgwgsz .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#sucjmgwgsz .gt_column_spanner {
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
&#10;#sucjmgwgsz .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#sucjmgwgsz .gt_group_heading {
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
&#10;#sucjmgwgsz .gt_empty_group_heading {
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
&#10;#sucjmgwgsz .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#sucjmgwgsz .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#sucjmgwgsz .gt_row {
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
&#10;#sucjmgwgsz .gt_stub {
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
&#10;#sucjmgwgsz .gt_stub_row_group {
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
&#10;#sucjmgwgsz .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#sucjmgwgsz .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#sucjmgwgsz .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#sucjmgwgsz .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#sucjmgwgsz .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#sucjmgwgsz .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#sucjmgwgsz .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#sucjmgwgsz .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#sucjmgwgsz .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#sucjmgwgsz .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#sucjmgwgsz .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#sucjmgwgsz .gt_footnotes {
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
&#10;#sucjmgwgsz .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#sucjmgwgsz .gt_sourcenotes {
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
&#10;#sucjmgwgsz .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#sucjmgwgsz .gt_left {
  text-align: left;
}
&#10;#sucjmgwgsz .gt_center {
  text-align: center;
}
&#10;#sucjmgwgsz .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#sucjmgwgsz .gt_font_normal {
  font-weight: normal;
}
&#10;#sucjmgwgsz .gt_font_bold {
  font-weight: bold;
}
&#10;#sucjmgwgsz .gt_font_italic {
  font-style: italic;
}
&#10;#sucjmgwgsz .gt_super {
  font-size: 65%;
}
&#10;#sucjmgwgsz .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#sucjmgwgsz .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#sucjmgwgsz .gt_indent_1 {
  text-indent: 5px;
}
&#10;#sucjmgwgsz .gt_indent_2 {
  text-indent: 10px;
}
&#10;#sucjmgwgsz .gt_indent_3 {
  text-indent: 15px;
}
&#10;#sucjmgwgsz .gt_indent_4 {
  text-indent: 20px;
}
&#10;#sucjmgwgsz .gt_indent_5 {
  text-indent: 25px;
}
&#10;#sucjmgwgsz .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#sucjmgwgsz div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>
<div id="sucjmgwgsz" class="reactable html-widget" style="width:auto;height:auto;"></div>
<script type="application/json" data-for="sucjmgwgsz">{"x":{"tag":{"name":"Reactable","attribs":{"data":{"id":[280028],"as_path":[[45270,4764,4761,149381]],"recv_time":["2024-01-06T02:21:35Z"],"type":["UPDATE"],"nlri":["103.179.250.0/24"]},"columns":[{"id":"id","name":"id","type":"numeric","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"right"},{"id":"as_path","name":"as_path","type":"list","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"center"},{"id":"recv_time","name":"recv_time","type":"Date","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"right"},{"id":"type","name":"type","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"left"},{"id":"nlri","name":"nlri","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"right"}],"defaultPageSize":10,"showPageSizeOptions":false,"pageSizeOptions":[10,25,50,100],"paginationType":"numbers","showPagination":true,"showPageInfo":true,"minRows":1,"height":"auto","theme":{"color":"#333333","backgroundColor":"#FFFFFF","stripedColor":"rgba(128,128,128,0.05)","style":{"font-family":"system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif","fontSize":"16px"},"tableStyle":{"borderTopStyle":"solid","borderTopWidth":"2px","borderTopColor":"#D3D3D3"},"headerStyle":{"fontWeight":"normal","backgroundColor":"transparent","borderBottomStyle":"solid","borderBottomWidth":"2px","borderBottomColor":"#D3D3D3"},"groupHeaderStyle":{"fontWeight":"normal","backgroundColor":"transparent","borderBottomStyle":"solid","borderBottomWidth":"2px","borderBottomColor":"#D3D3D3"},"cellStyle":{"fontWeight":"normal"}},"elementId":"sucjmgwgsz","dataKey":"6698bb22d36d6d2b7f66c398723e4637"},"children":[]},"class":"reactR_markup"},"evals":["tag.attribs.columns.0.style","tag.attribs.columns.1.style","tag.attribs.columns.2.style","tag.attribs.columns.3.style","tag.attribs.columns.4.style"],"jsHooks":[]}</script>
</div>

    [1] "45270 4764 2914 29632 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 200579 200579 203868"

This time we’ve got what appears to be transit provider asn8772 (NetAssist LLC), prepending to make paths to asn203868 (Rifqi Arief Pamungkas, again out of Indonesia)

# Path Attributes

``` r
bgpv4_attr <-
    bgp |>
    filter(ip_version == 'v4') |> 
    unnest(path_attributes, names_sep = '.')
```

``` r
bgpv4_attr |>
    #filter(!path_attributes.type_code %in% c(1,2,3)) |>
    mutate(pa = glue('{path_attributes.type} ({path_attributes.type_code})')) |>
    count(pa) |>
    mutate(pa = fct_reorder(pa, n)) |> 
    ggplot() +
    geom_col(aes(pa, log(n), fill = 'red')) +
    geom_label(aes(pa, log(n), label = n), nudge_y = -.2) +
    coord_flip() +
    scale_fill_discrete(guide = 'none') + 
    labs(
        title = 'Foo'
    )
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-18-1.png" width="672" />

``` r
 bgpv4_attr |>
    filter(path_attributes.type_code == 255) |>
    distinct(originating_asn) |>
    mutate(organisation = map_df(originating_asn, ~caida_asn_lookup(.x))) |>
    unnest(organisation) |>
    select(originating_asn, organisation = value, source, country)
```

    # A tibble: 18 × 4
       originating_asn organisation                                   source country
                 <int> <chr>                                          <chr>  <chr>  
     1           42912 Al mouakhah lil khadamat al logesteih wa al i… RIPE   JO     
     2           23872 delDSL Internet Pvt. Ltd.                      APNIC  IN     
     3          204667 Juan Ramon Jerez Suarez                        RIPE   ES     
     4           48832 Jordanian mobile phone services Ltd            RIPE   JO     
     5           41297 Adam Dlugosz trading as ABAKS                  RIPE   PL     
     6           52564 Biazi Telecom                                  LACNIC BR     
     7           52746 Primanet Internet LTDA                         LACNIC BR     
     8           61639 BCNET INFORMÁTICA LTDA                         LACNIC BR     
     9           10429 TELEFÔNICA BRASIL S.A                          LACNIC BR     
    10          265999 Cianet Provedor de Internet EIRELI             LACNIC BR     
    11          264901 Ailon Rodrigo Oliveira Lima ME                 LACNIC BR     
    12          264954 Virtual Connect                                LACNIC BR     
    13           52935 Infobarra Solucoes em Informatica Ltda         LACNIC BR     
    14          262426 TELECOMUNICAÇÕES RONDONOPOLIS LTDA - ME        LACNIC BR     
    15          263454 Ines Waltmann - Me                             LACNIC BR     
    16           27976 Coop. de Servicios Públicos de Morteros Ltda.  LACNIC AR     
    17          267434 Xingu Assessoria em Redes Ltda ME              LACNIC BR     
    18          273379 V. M. De Melo Informatica - MIDIA INFORMATICA  LACNIC BR     

# Flippy-Flappy: Who’s Having a Bad Time?

``` r
bgp |>
    unnest(nlri) |>
    count(nlri) |>
    slice_max(n, n = 50) |>
    gt() |> 
    opt_interactive()
```

<div id="zfdfhmynna" class=".gt_table" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#zfdfhmynna table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#zfdfhmynna thead, #zfdfhmynna tbody, #zfdfhmynna tfoot, #zfdfhmynna tr, #zfdfhmynna td, #zfdfhmynna th {
  border-style: none;
}
&#10;#zfdfhmynna p {
  margin: 0;
  padding: 0;
}
&#10;#zfdfhmynna .gt_table {
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
&#10;#zfdfhmynna .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#zfdfhmynna .gt_title {
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
&#10;#zfdfhmynna .gt_subtitle {
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
&#10;#zfdfhmynna .gt_heading {
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
&#10;#zfdfhmynna .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#zfdfhmynna .gt_col_headings {
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
&#10;#zfdfhmynna .gt_col_heading {
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
&#10;#zfdfhmynna .gt_column_spanner_outer {
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
&#10;#zfdfhmynna .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#zfdfhmynna .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#zfdfhmynna .gt_column_spanner {
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
&#10;#zfdfhmynna .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#zfdfhmynna .gt_group_heading {
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
&#10;#zfdfhmynna .gt_empty_group_heading {
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
&#10;#zfdfhmynna .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#zfdfhmynna .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#zfdfhmynna .gt_row {
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
&#10;#zfdfhmynna .gt_stub {
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
&#10;#zfdfhmynna .gt_stub_row_group {
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
&#10;#zfdfhmynna .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#zfdfhmynna .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#zfdfhmynna .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#zfdfhmynna .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#zfdfhmynna .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#zfdfhmynna .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#zfdfhmynna .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#zfdfhmynna .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#zfdfhmynna .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#zfdfhmynna .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#zfdfhmynna .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#zfdfhmynna .gt_footnotes {
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
&#10;#zfdfhmynna .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#zfdfhmynna .gt_sourcenotes {
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
&#10;#zfdfhmynna .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#zfdfhmynna .gt_left {
  text-align: left;
}
&#10;#zfdfhmynna .gt_center {
  text-align: center;
}
&#10;#zfdfhmynna .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#zfdfhmynna .gt_font_normal {
  font-weight: normal;
}
&#10;#zfdfhmynna .gt_font_bold {
  font-weight: bold;
}
&#10;#zfdfhmynna .gt_font_italic {
  font-style: italic;
}
&#10;#zfdfhmynna .gt_super {
  font-size: 65%;
}
&#10;#zfdfhmynna .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#zfdfhmynna .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#zfdfhmynna .gt_indent_1 {
  text-indent: 5px;
}
&#10;#zfdfhmynna .gt_indent_2 {
  text-indent: 10px;
}
&#10;#zfdfhmynna .gt_indent_3 {
  text-indent: 15px;
}
&#10;#zfdfhmynna .gt_indent_4 {
  text-indent: 20px;
}
&#10;#zfdfhmynna .gt_indent_5 {
  text-indent: 25px;
}
&#10;#zfdfhmynna .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#zfdfhmynna div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>
<div id="zfdfhmynna" class="reactable html-widget" style="width:auto;height:auto;"></div>
<script type="application/json" data-for="zfdfhmynna">{"x":{"tag":{"name":"Reactable","attribs":{"data":{"nlri":["140.99.244.0/23","107.154.97.0/24","45.172.92.0/22","151.236.111.0/24","205.164.85.0/24","41.209.0.0/18","143.255.204.0/22","176.124.58.0/24","187.1.11.0/24","187.1.13.0/24","103.248.132.0/22","185.200.123.0/24","138.121.151.0/24","193.105.107.0/24","83.243.112.0/21","202.45.88.0/24","203.145.74.0/24","203.145.78.0/24","209.54.122.0/24","103.177.86.0/24","103.177.87.0/24","103.223.2.0/24","188.130.192.0/22","109.248.130.0/24","41.75.208.0/20","67.211.53.0/24","207.167.116.0/22","213.204.81.0/24","102.220.224.0/24","102.220.227.0/24","102.220.226.0/24","154.88.8.0/24","78.142.198.0/24","209.22.66.0/24","209.22.67.0/24","185.116.216.0/22","213.204.80.0/24","64.68.236.0/22","178.22.141.0/24","130.137.230.0/24","113.23.173.0/24","112.33.120.0/24","185.18.201.0/24","170.238.225.0/24","186.170.29.0/24","181.225.48.0/24","181.225.43.0/24","183.90.162.0/24","183.90.163.0/24","207.244.192.0/22"],"n":[2596,2583,2494,2312,2189,2069,2048,1584,1582,1580,1512,1489,1395,1245,1190,1171,1171,1171,1062,987,987,848,839,829,791,745,672,640,604,603,601,561,558,533,533,462,441,439,432,426,399,383,367,356,347,345,338,319,317,316]},"columns":[{"id":"nlri","name":"nlri","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"right"},{"id":"n","name":"n","type":"numeric","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"right"}],"defaultPageSize":10,"showPageSizeOptions":false,"pageSizeOptions":[10,25,50,100],"paginationType":"numbers","showPagination":true,"showPageInfo":true,"minRows":1,"height":"auto","theme":{"color":"#333333","backgroundColor":"#FFFFFF","stripedColor":"rgba(128,128,128,0.05)","style":{"font-family":"system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif","fontSize":"16px"},"tableStyle":{"borderTopStyle":"solid","borderTopWidth":"2px","borderTopColor":"#D3D3D3"},"headerStyle":{"fontWeight":"normal","backgroundColor":"transparent","borderBottomStyle":"solid","borderBottomWidth":"2px","borderBottomColor":"#D3D3D3"},"groupHeaderStyle":{"fontWeight":"normal","backgroundColor":"transparent","borderBottomStyle":"solid","borderBottomWidth":"2px","borderBottomColor":"#D3D3D3"},"cellStyle":{"fontWeight":"normal"}},"elementId":"zfdfhmynna","dataKey":"aa65f028c6a1d7935c0915a52c053439"},"children":[]},"class":"reactR_markup"},"evals":["tag.attribs.columns.0.style","tag.attribs.columns.1.style"],"jsHooks":[]}</script>
</div>

``` r
bind_rows(
    bgp |> unnest(withdrawn_routes) |> filter(withdrawn_routes == '140.99.244.0/23') |> select(-nlri),
    bgp |> unnest(nlri) |> filter(nlri == '140.99.244.0/23') |> select(-withdrawn_routes)
) |> select(id, recv_time, withdrawn_routes, nlri) |>
    mutate(type = if_else(is.na(withdrawn_routes), 'UPDATE', 'WITHDRAW')) |>
    select(id, recv_time, type) |>
    group_by(type) |>
    mutate(n = row_number()) |>
    ungroup() |>
    ggplot() +
    geom_point(aes(recv_time, n, colour = type), size = .5) +
    facet_grid(vars(type), scales = 'free_y')
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-21-1.png" width="672" />

``` r
bgp |> unnest(withdrawn_routes) |> filter(withdrawn_routes == '140.99.244.0/23')
```

    # A tibble: 41 × 14
           id as_path    recv_time           type   nlri      withdrawn_routes
        <int> <list>     <dttm>              <chr>  <list>    <chr>           
     1 200833 <int [10]> 2024-01-06 07:26:32 UPDATE <chr [1]> 140.99.244.0/23 
     2 204783 <int [8]>  2024-01-06 07:44:32 UPDATE <chr [1]> 140.99.244.0/23 
     3 211020 <int [4]>  2024-01-06 08:18:04 UPDATE <chr [1]> 140.99.244.0/23 
     4 215439 <int [6]>  2024-01-06 08:42:04 UPDATE <chr [2]> 140.99.244.0/23 
     5 216001 <int [5]>  2024-01-06 08:45:04 UPDATE <chr [1]> 140.99.244.0/23 
     6 239134 <int [6]>  2024-01-06 09:44:04 UPDATE <chr [1]> 140.99.244.0/23 
     7 243597 <int [6]>  2024-01-06 10:03:33 UPDATE <chr [1]> 140.99.244.0/23 
     8 253293 <int [6]>  2024-01-06 10:55:04 UPDATE <chr [1]> 140.99.244.0/23 
     9 259087 <int [7]>  2024-01-06 11:28:34 UPDATE <chr [2]> 140.99.244.0/23 
    10 261794 <int [6]>  2024-01-06 11:44:04 UPDATE <chr [1]> 140.99.244.0/23 
    # ℹ 31 more rows
    # ℹ 8 more variables: path_attributes <list>, ip_version <chr>,
    #   pure_withdraw <lgl>, n_routes <int>, address_space <dbl>,
    #   initial_send <lgl>, originating_asn <int>, as_path_len <int>
