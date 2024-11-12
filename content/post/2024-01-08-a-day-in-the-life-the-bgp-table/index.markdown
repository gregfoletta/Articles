---
title: 'A Day in the Life: The BGP Table'
author: Greg Foletta
date: '2024-01-08'
slug: []
categories: []
tags: []
images: []
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

``` r
# ASN Whois
caida_asn_lookup <- function(asn) {
    asn_info <-
    request("https://api.asrank.caida.org") |>
    req_url_path(glue("/v2/restful/asns/{asn}")) |>
    req_perform() |>
    resp_body_json(simplifyVector = TRUE) 
  
    asn_tbl <- 
    asn_info |> 
      pluck('data', 'asn') |> 
      discard(~is.null(.x)) |> 
      _[c('rank', 'asn', 'asnName', 'source', 'cliqueMember', 'seen', 'longitude', 'latitude', 'organization', 'country')] |> 
      as_tibble() |>
      unnest(c(country, organization)) 
    
    if (is.null(asn_info$data$asn$organization$orgId)) {
        return("")
    }
        
    orgID <- asn_info |> pluck('data', 'asn', 'organization', 'orgId')
   
    org_info <-
    request("https://api.asrank.caida.org") |>
    req_url_path(glue("/restful/organizations/{orgID}")) |>
    req_perform() |>
    resp_body_json(simplifyVector = TRUE) 
   
    org_info |> 
      pluck('data', 'organization', 'orgName') |> 
      as_tibble() |>
      bind_cols(asn_tbl)
}
```

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

<div id="nofmcgpzfi" class=".gt_table" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#nofmcgpzfi table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#nofmcgpzfi thead, #nofmcgpzfi tbody, #nofmcgpzfi tfoot, #nofmcgpzfi tr, #nofmcgpzfi td, #nofmcgpzfi th {
  border-style: none;
}
&#10;#nofmcgpzfi p {
  margin: 0;
  padding: 0;
}
&#10;#nofmcgpzfi .gt_table {
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
&#10;#nofmcgpzfi .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#nofmcgpzfi .gt_title {
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
&#10;#nofmcgpzfi .gt_subtitle {
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
&#10;#nofmcgpzfi .gt_heading {
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
&#10;#nofmcgpzfi .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#nofmcgpzfi .gt_col_headings {
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
&#10;#nofmcgpzfi .gt_col_heading {
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
&#10;#nofmcgpzfi .gt_column_spanner_outer {
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
&#10;#nofmcgpzfi .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#nofmcgpzfi .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#nofmcgpzfi .gt_column_spanner {
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
&#10;#nofmcgpzfi .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#nofmcgpzfi .gt_group_heading {
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
&#10;#nofmcgpzfi .gt_empty_group_heading {
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
&#10;#nofmcgpzfi .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#nofmcgpzfi .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#nofmcgpzfi .gt_row {
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
&#10;#nofmcgpzfi .gt_stub {
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
&#10;#nofmcgpzfi .gt_stub_row_group {
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
&#10;#nofmcgpzfi .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#nofmcgpzfi .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#nofmcgpzfi .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#nofmcgpzfi .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#nofmcgpzfi .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#nofmcgpzfi .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#nofmcgpzfi .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#nofmcgpzfi .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#nofmcgpzfi .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#nofmcgpzfi .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#nofmcgpzfi .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#nofmcgpzfi .gt_footnotes {
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
&#10;#nofmcgpzfi .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#nofmcgpzfi .gt_sourcenotes {
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
&#10;#nofmcgpzfi .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#nofmcgpzfi .gt_left {
  text-align: left;
}
&#10;#nofmcgpzfi .gt_center {
  text-align: center;
}
&#10;#nofmcgpzfi .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#nofmcgpzfi .gt_font_normal {
  font-weight: normal;
}
&#10;#nofmcgpzfi .gt_font_bold {
  font-weight: bold;
}
&#10;#nofmcgpzfi .gt_font_italic {
  font-style: italic;
}
&#10;#nofmcgpzfi .gt_super {
  font-size: 65%;
}
&#10;#nofmcgpzfi .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#nofmcgpzfi .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#nofmcgpzfi .gt_indent_1 {
  text-indent: 5px;
}
&#10;#nofmcgpzfi .gt_indent_2 {
  text-indent: 10px;
}
&#10;#nofmcgpzfi .gt_indent_3 {
  text-indent: 15px;
}
&#10;#nofmcgpzfi .gt_indent_4 {
  text-indent: 20px;
}
&#10;#nofmcgpzfi .gt_indent_5 {
  text-indent: 25px;
}
&#10;#nofmcgpzfi .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#nofmcgpzfi div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>
<div id="nofmcgpzfi" class="reactable html-widget" style="width:auto;height:auto;"></div>
<script type="application/json" data-for="nofmcgpzfi">{"x":{"tag":{"name":"Reactable","attribs":{"data":{"recv_time":["2024-01-05T19:31:44Z","2024-01-05T19:31:44Z","2024-01-05T19:31:44Z","2024-01-05T19:31:44Z","2024-01-05T19:31:44Z","2024-01-05T19:31:44Z"],"id":[190538,190539,190540,190541,190542,190543],"type":["UPDATE","UPDATE","UPDATE","UPDATE","UPDATE","UPDATE"],"nlri":["41.211.42.0/24\n41.211.32.0/24\n41.211.47.0/24\n41.211.38.0/24\n41.211.37.0/24\n41.211.36.0/24","103.177.87.0/24\n103.177.86.0/24","38.172.160.0/24","176.124.58.0/24","103.103.34.0/24","117.103.87.0/24"],"withdrawn_routes":["130.137.140.0/24, 130.137.99.0/24, 130.137.121.0/24, 50.117.116.0/24, 205.65.44.0/22, 185.241.10.0/24, 130.137.105.0/24","","","","",""],"path_attributes":[{"type":["ORIGIN","AS_PATH","NEXT_HOP","AS4_PATH"],"type_code":[1,2,3,17],"flags":[["well-known","transitive","complete","standard"],["well-known","transitive","complete","standard"],["well-known","transitive","complete","standard"],["optional","non-transitive","partial","extended"]],"flags_low_nibble":[0,0,0,0],"origin":["IGP",null,null,null],"n_as_segments":["NA",1,"NA",1],"n_total_as":["NA",6,"NA",6],"path_segments":[null,{"type":["AS_SEQUENCE"],"n_as":[6],"asns":[[45270,4764,1299,174,16637,23456]]},null,{"type":["AS_SEQUENCE"],"n_as":[6],"asns":[[45270,4764,1299,174,16637,327765]]}],"next_hop":[null,null,"61.245.147.114",null]},{"type":["ORIGIN","AS_PATH","NEXT_HOP","AS4_PATH"],"type_code":[1,2,3,17],"flags":[["well-known","transitive","complete","standard"],["well-known","transitive","complete","standard"],["well-known","transitive","complete","standard"],["optional","non-transitive","partial","extended"]],"flags_low_nibble":[0,0,0,0],"origin":["IGP",null,null,null],"n_as_segments":["NA",1,"NA",1],"n_total_as":["NA",8,"NA",8],"path_segments":[null,{"type":["AS_SEQUENCE"],"n_as":[8],"asns":[[45270,4764,174,23456,23456,23456,23456,23456]]},null,{"type":["AS_SEQUENCE"],"n_as":[8],"asns":[[45270,4764,174,136255,136975,133524,134840,149038]]}],"next_hop":[null,null,"61.245.147.114",null]},{"type":["ORIGIN","AS_PATH","NEXT_HOP","AS4_PATH"],"type_code":[1,2,3,17],"flags":[["well-known","transitive","complete","standard"],["well-known","transitive","complete","standard"],["well-known","transitive","complete","standard"],["optional","non-transitive","partial","extended"]],"flags_low_nibble":[0,0,0,0],"origin":["IGP",null,null,null],"n_as_segments":["NA",1,"NA",1],"n_total_as":["NA",12,"NA",12],"path_segments":[null,{"type":["AS_SEQUENCE"],"n_as":[12],"asns":[[45270,4764,1299,23520,23456,23456,23456,23456,23456,23456,23456,23456]]},null,{"type":["AS_SEQUENCE"],"n_as":[12],"asns":[[45270,4764,1299,23520,263703,270026,270026,270026,270026,270026,270026,270026]]}],"next_hop":[null,null,"61.245.147.114",null]},{"type":["ORIGIN","AS_PATH","NEXT_HOP","AS4_PATH"],"type_code":[1,2,3,17],"flags":[["well-known","transitive","complete","standard"],["well-known","transitive","complete","standard"],["well-known","transitive","complete","standard"],["optional","non-transitive","partial","extended"]],"flags_low_nibble":[0,0,0,0],"origin":["IGP",null,null,null],"n_as_segments":["NA",1,"NA",1],"n_total_as":["NA",6,"NA",6],"path_segments":[null,{"type":["AS_SEQUENCE"],"n_as":[6],"asns":[[45270,4764,174,12310,44679,23456]]},null,{"type":["AS_SEQUENCE"],"n_as":[6],"asns":[[45270,4764,174,12310,44679,209856]]}],"next_hop":[null,null,"61.245.147.114",null]},{"type":["ORIGIN","AS_PATH","NEXT_HOP","AS4_PATH"],"type_code":[1,2,3,17],"flags":[["well-known","transitive","complete","standard"],["well-known","transitive","complete","standard"],["well-known","transitive","complete","standard"],["optional","non-transitive","partial","extended"]],"flags_low_nibble":[0,0,0,0],"origin":["IGP",null,null,null],"n_as_segments":["NA",1,"NA",1],"n_total_as":["NA",7,"NA",7],"path_segments":[null,{"type":["AS_SEQUENCE"],"n_as":[7],"asns":[[45270,4764,23456,23456,23456,23456,23456]]},null,{"type":["AS_SEQUENCE"],"n_as":[7],"asns":[[45270,4764,139901,137048,137048,137048,137048]]}],"next_hop":[null,null,"61.245.147.114",null]},{"type":["ORIGIN","AS_PATH","NEXT_HOP","AS4_PATH"],"type_code":[1,2,3,17],"flags":[["well-known","transitive","complete","standard"],["well-known","transitive","complete","standard"],["well-known","transitive","complete","standard"],["optional","non-transitive","partial","extended"]],"flags_low_nibble":[0,0,0,0],"origin":["IGP",null,null,null],"n_as_segments":["NA",1,"NA",1],"n_total_as":["NA",8,"NA",8],"path_segments":[null,{"type":["AS_SEQUENCE"],"n_as":[8],"asns":[[45270,4764,23456,64018,38614,38614,38614,38614]]},null,{"type":["AS_SEQUENCE"],"n_as":[8],"asns":[[45270,4764,139901,64018,38614,38614,38614,38614]]}],"next_hop":[null,null,"61.245.147.114",null]}]},"columns":[{"id":"recv_time","name":"recv_time","type":"Date","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"right"},{"id":"id","name":"id","type":"numeric","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"right"},{"id":"type","name":"type","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"left"},{"id":"nlri","name":"nlri","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"left"},{"id":"withdrawn_routes","name":"withdrawn_routes","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"right"},{"id":"path_attributes","name":"path_attributes","type":"list","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"center"}],"defaultPageSize":10,"showPageSizeOptions":false,"pageSizeOptions":[10,25,50,100],"paginationType":"numbers","showPagination":true,"showPageInfo":true,"minRows":1,"height":"auto","theme":{"color":"#333333","backgroundColor":"#FFFFFF","stripedColor":"rgba(128,128,128,0.05)","style":{"font-family":"system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif","fontSize":"16px"},"tableStyle":{"borderTopStyle":"solid","borderTopWidth":"2px","borderTopColor":"#D3D3D3"},"headerStyle":{"fontWeight":"normal","backgroundColor":"transparent","borderBottomStyle":"solid","borderBottomWidth":"2px","borderBottomColor":"#D3D3D3"},"groupHeaderStyle":{"fontWeight":"normal","backgroundColor":"transparent","borderBottomStyle":"solid","borderBottomWidth":"2px","borderBottomColor":"#D3D3D3"},"cellStyle":{"fontWeight":"normal"}},"elementId":"nofmcgpzfi","dataKey":"d46682d79a13ac6ce2276f67bebd2df0"},"children":[]},"class":"reactR_markup"},"evals":["tag.attribs.columns.0.style","tag.attribs.columns.1.style","tag.attribs.columns.2.style","tag.attribs.columns.3.style","tag.attribs.columns.4.style","tag.attribs.columns.5.style"],"jsHooks":[]}</script>
</div>
<div id="hodvwijmiu" class=".gt_table" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#hodvwijmiu table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#hodvwijmiu thead, #hodvwijmiu tbody, #hodvwijmiu tfoot, #hodvwijmiu tr, #hodvwijmiu td, #hodvwijmiu th {
  border-style: none;
}
&#10;#hodvwijmiu p {
  margin: 0;
  padding: 0;
}
&#10;#hodvwijmiu .gt_table {
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
&#10;#hodvwijmiu .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#hodvwijmiu .gt_title {
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
&#10;#hodvwijmiu .gt_subtitle {
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
&#10;#hodvwijmiu .gt_heading {
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
&#10;#hodvwijmiu .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#hodvwijmiu .gt_col_headings {
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
&#10;#hodvwijmiu .gt_col_heading {
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
&#10;#hodvwijmiu .gt_column_spanner_outer {
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
&#10;#hodvwijmiu .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#hodvwijmiu .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#hodvwijmiu .gt_column_spanner {
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
&#10;#hodvwijmiu .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#hodvwijmiu .gt_group_heading {
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
&#10;#hodvwijmiu .gt_empty_group_heading {
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
&#10;#hodvwijmiu .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#hodvwijmiu .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#hodvwijmiu .gt_row {
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
&#10;#hodvwijmiu .gt_stub {
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
&#10;#hodvwijmiu .gt_stub_row_group {
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
&#10;#hodvwijmiu .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#hodvwijmiu .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#hodvwijmiu .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#hodvwijmiu .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#hodvwijmiu .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#hodvwijmiu .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#hodvwijmiu .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#hodvwijmiu .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#hodvwijmiu .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#hodvwijmiu .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#hodvwijmiu .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#hodvwijmiu .gt_footnotes {
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
&#10;#hodvwijmiu .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#hodvwijmiu .gt_sourcenotes {
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
&#10;#hodvwijmiu .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#hodvwijmiu .gt_left {
  text-align: left;
}
&#10;#hodvwijmiu .gt_center {
  text-align: center;
}
&#10;#hodvwijmiu .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#hodvwijmiu .gt_font_normal {
  font-weight: normal;
}
&#10;#hodvwijmiu .gt_font_bold {
  font-weight: bold;
}
&#10;#hodvwijmiu .gt_font_italic {
  font-style: italic;
}
&#10;#hodvwijmiu .gt_super {
  font-size: 65%;
}
&#10;#hodvwijmiu .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#hodvwijmiu .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#hodvwijmiu .gt_indent_1 {
  text-indent: 5px;
}
&#10;#hodvwijmiu .gt_indent_2 {
  text-indent: 10px;
}
&#10;#hodvwijmiu .gt_indent_3 {
  text-indent: 15px;
}
&#10;#hodvwijmiu .gt_indent_4 {
  text-indent: 20px;
}
&#10;#hodvwijmiu .gt_indent_5 {
  text-indent: 25px;
}
&#10;#hodvwijmiu .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#hodvwijmiu div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>
<div id="hodvwijmiu" class="reactable html-widget" style="width:auto;height:auto;"></div>
<script type="application/json" data-for="hodvwijmiu">{"x":{"tag":{"name":"Reactable","attribs":{"data":{"id":[190538,190538,190538,190538],"type":["ORIGIN","AS_PATH","NEXT_HOP","AS4_PATH"],"type_code":[1,2,3,17],"flags":["well-known, transitive, complete, standard","well-known, transitive, complete, standard","well-known, transitive, complete, standard","optional, non-transitive, partial, extended"],"value":["IGP","AS_SEQUENCE c(45270, 4764, 1299, 174, 16637, 23456)","61.245.147.114","AS_SEQUENCE c(45270, 4764, 1299, 174, 16637, 327765)"]},"columns":[{"id":"id","name":"id","type":"numeric","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"right"},{"id":"type","name":"type","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"left"},{"id":"type_code","name":"type_code","type":"numeric","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"right"},{"id":"flags","name":"flags","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"left"},{"id":"value","name":"value","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"left"}],"defaultPageSize":10,"showPageSizeOptions":false,"pageSizeOptions":[10,25,50,100],"paginationType":"numbers","showPagination":true,"showPageInfo":true,"minRows":1,"height":"auto","theme":{"color":"#333333","backgroundColor":"#FFFFFF","stripedColor":"rgba(128,128,128,0.05)","style":{"font-family":"system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif","fontSize":"16px"},"tableStyle":{"borderTopStyle":"solid","borderTopWidth":"2px","borderTopColor":"#D3D3D3"},"headerStyle":{"fontWeight":"normal","backgroundColor":"transparent","borderBottomStyle":"solid","borderBottomWidth":"2px","borderBottomColor":"#D3D3D3"},"groupHeaderStyle":{"fontWeight":"normal","backgroundColor":"transparent","borderBottomStyle":"solid","borderBottomWidth":"2px","borderBottomColor":"#D3D3D3"},"cellStyle":{"fontWeight":"normal"}},"elementId":"hodvwijmiu","dataKey":"ac50fa68803cb9c8ad37557443c2e87b"},"children":[]},"class":"reactR_markup"},"evals":["tag.attribs.columns.0.style","tag.attribs.columns.1.style","tag.attribs.columns.2.style","tag.attribs.columns.3.style","tag.attribs.columns.4.style"],"jsHooks":[]}</script>
</div>

``` r
# This pulls the as path up into the top level as a column, and also adds the 'originating_asn' 
# as a column
 bgp <-
    bgp |> 
    unnest(path_attributes, names_sep = '.') |> 
    # Get AS4_PATH if it exists, otherwise get AS_PATH
    filter(path_attributes.type %in% c('AS_PATH', 'AS4_PATH')) |>
    group_by(id) |>
    slice_tail(n = 1) |>
    ungroup() |> 
    select(id, path_attributes.path_segments) |>
    unnest(path_attributes.path_segments) |>
    unnest(asns) |>
    # Concatenate the al path segments into one list 
    group_by(id) |>
    summarise(as_path = list(asns)) |> 
    ungroup() |> 
    # Joint back with original tibble
    right_join(bgp, by = 'id') |> 
    # Pull out the last (originating) AS as a separate column
    mutate(
        originating_asn = map_int(as_path, ~{ 
            if (is.null(.x)) { return(NA_integer_) }
            n = length(.x)
            .x[[n]] 
        }),
        as_path_len = map_int(as_path, ~length(.x))
    )
```

# Initial Send, Number of v4 and v6 Paths

``` r
bgp |> 
    filter(initial_send) |> 
    group_by(ip_version) |> 
    count(recv_time) |>
    summarise(paths = sum(n)) |>
    ggplot() +
    geom_col(aes(ip_version, paths, fill = ip_version)) +
    labs(
        title = 'Initial Send of BGP Paths',
        subtitle = 'IPv4 and IPv6',
        fill = 'IP Version',
        x = 'IP Version',
        y = 'Paths'
    ) +
    scale_y_continuous(labels = scales::comma)
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-9-1.png" width="672" />

Number of routes is 949483. [Geoff’s data](https://bgp.potaroo.net/as2.0/bgp-active.txt) shows 942,594

# Updates Over Time

``` r
{ bgp |> 
    filter(!initial_send & ip_version == 'v4') |> 
    count(recv_time = floor_date(recv_time, unit = '5 minutes')) |>
    mutate(mean_n = mean(n)) |> 
    ggplot(aes(recv_time, n)) +
    geom_line(size = .3) +
    geom_hline(aes(yintercept = mean_n), linetype = 2) +
    transition_reveal(recv_time) +  
    scale_x_datetime() +
    coord_cartesian(clip = 'off') +
    labs(
      title = "BGP v4 Path Advertisements Over Time",
      subtitle = "Dashed Line: Mean, Time: {floor_date(frame_along, '1 minute')}",
      x = "Time",
      y = "Number of Paths Advertised"
    ) } |> animate(renderer = gifski_renderer()) 
```

![](index_files/figure-html/unnamed-chunk-10-1.gif)<!-- -->

``` r
bgp |> 
    filter(!initial_send & ip_version == 'v4') |> 
    count(recv_time = floor_date(recv_time, unit = '5 minutes')) |>
    ggplot() +
    geom_histogram(aes(n), binwidth = 5, ) +
    geom_density(aes(n), )
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-11-1.png" width="672" />

``` r
bgp |> 
    filter(!initial_send & ip_version == 'v4') |>
    add_count(recv_time = floor_date(recv_time, unit = '5 minutes')) |>
    slice_max(order_by = n, n = 1) |>
    unnest(asn = as_path) |>
    count(asn, sort = TRUE) |>
    slice_head(n = 10) |>
    mutate(as_info = map(asn, ~caida_asn_lookup(.x))) |>
    select(n, as_info) |>
    unnest(as_info) |>
    select(n, organisation = value, asn, source, country) |>  
    gt() |>  
    opt_interactive()
```

    ## Warning: `unnest()` has a new interface. See `?unnest` for details.
    ## ℹ Try `df %>% unnest(c(asn))`, with `mutate()` if needed.

<div id="wlvwmjyrxy" class=".gt_table" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#wlvwmjyrxy table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#wlvwmjyrxy thead, #wlvwmjyrxy tbody, #wlvwmjyrxy tfoot, #wlvwmjyrxy tr, #wlvwmjyrxy td, #wlvwmjyrxy th {
  border-style: none;
}
&#10;#wlvwmjyrxy p {
  margin: 0;
  padding: 0;
}
&#10;#wlvwmjyrxy .gt_table {
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
&#10;#wlvwmjyrxy .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#wlvwmjyrxy .gt_title {
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
&#10;#wlvwmjyrxy .gt_subtitle {
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
&#10;#wlvwmjyrxy .gt_heading {
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
&#10;#wlvwmjyrxy .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#wlvwmjyrxy .gt_col_headings {
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
&#10;#wlvwmjyrxy .gt_col_heading {
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
&#10;#wlvwmjyrxy .gt_column_spanner_outer {
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
&#10;#wlvwmjyrxy .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#wlvwmjyrxy .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#wlvwmjyrxy .gt_column_spanner {
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
&#10;#wlvwmjyrxy .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#wlvwmjyrxy .gt_group_heading {
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
&#10;#wlvwmjyrxy .gt_empty_group_heading {
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
&#10;#wlvwmjyrxy .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#wlvwmjyrxy .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#wlvwmjyrxy .gt_row {
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
&#10;#wlvwmjyrxy .gt_stub {
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
&#10;#wlvwmjyrxy .gt_stub_row_group {
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
&#10;#wlvwmjyrxy .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#wlvwmjyrxy .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#wlvwmjyrxy .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#wlvwmjyrxy .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#wlvwmjyrxy .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#wlvwmjyrxy .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#wlvwmjyrxy .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#wlvwmjyrxy .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#wlvwmjyrxy .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#wlvwmjyrxy .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#wlvwmjyrxy .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#wlvwmjyrxy .gt_footnotes {
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
&#10;#wlvwmjyrxy .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#wlvwmjyrxy .gt_sourcenotes {
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
&#10;#wlvwmjyrxy .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#wlvwmjyrxy .gt_left {
  text-align: left;
}
&#10;#wlvwmjyrxy .gt_center {
  text-align: center;
}
&#10;#wlvwmjyrxy .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#wlvwmjyrxy .gt_font_normal {
  font-weight: normal;
}
&#10;#wlvwmjyrxy .gt_font_bold {
  font-weight: bold;
}
&#10;#wlvwmjyrxy .gt_font_italic {
  font-style: italic;
}
&#10;#wlvwmjyrxy .gt_super {
  font-size: 65%;
}
&#10;#wlvwmjyrxy .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#wlvwmjyrxy .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#wlvwmjyrxy .gt_indent_1 {
  text-indent: 5px;
}
&#10;#wlvwmjyrxy .gt_indent_2 {
  text-indent: 10px;
}
&#10;#wlvwmjyrxy .gt_indent_3 {
  text-indent: 15px;
}
&#10;#wlvwmjyrxy .gt_indent_4 {
  text-indent: 20px;
}
&#10;#wlvwmjyrxy .gt_indent_5 {
  text-indent: 25px;
}
&#10;#wlvwmjyrxy .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#wlvwmjyrxy div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>
<div id="wlvwmjyrxy" class="reactable html-widget" style="width:auto;height:auto;"></div>
<script type="application/json" data-for="wlvwmjyrxy">{"x":{"tag":{"name":"Reactable","attribs":{"data":{"n":[3547,3547,1166,1138,723,629,491,367,288,281],"organisation":["Wideband Networks Pty Ltd","Ossini Pty Ltd","Angola Cables","NTT America, Inc.","Level 3 Parent, LLC","Cogent Communications","RETN Limited","SAMM Sociedade de Atividades em Multimidia LTDA","Columbus Networks USA, Inc.","MEGA TELE INFORMATICA"],"asn":["4764","45270","37468","2914","3356","174","9002","52551","23520","265269"],"source":["APNIC","APNIC","AFRINIC","ARIN","ARIN","ARIN","RIPE","LACNIC","ARIN","LACNIC"],"country":["AU","AU","AO","US","US","US","GB","BR","US","BR"]},"columns":[{"id":"n","name":"n","type":"numeric","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"right"},{"id":"organisation","name":"organisation","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"left"},{"id":"asn","name":"asn","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"right"},{"id":"source","name":"source","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"left"},{"id":"country","name":"country","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"left"}],"defaultPageSize":10,"showPageSizeOptions":false,"pageSizeOptions":[10,25,50,100],"paginationType":"numbers","showPagination":true,"showPageInfo":true,"minRows":1,"height":"auto","theme":{"color":"#333333","backgroundColor":"#FFFFFF","stripedColor":"rgba(128,128,128,0.05)","style":{"font-family":"system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif","fontSize":"16px"},"tableStyle":{"borderTopStyle":"solid","borderTopWidth":"2px","borderTopColor":"#D3D3D3"},"headerStyle":{"fontWeight":"normal","backgroundColor":"transparent","borderBottomStyle":"solid","borderBottomWidth":"2px","borderBottomColor":"#D3D3D3"},"groupHeaderStyle":{"fontWeight":"normal","backgroundColor":"transparent","borderBottomStyle":"solid","borderBottomWidth":"2px","borderBottomColor":"#D3D3D3"},"cellStyle":{"fontWeight":"normal"}},"elementId":"wlvwmjyrxy","dataKey":"2b0271bee813a74b6cbe855c9a59d4b1"},"children":[]},"class":"reactR_markup"},"evals":["tag.attribs.columns.0.style","tag.attribs.columns.1.style","tag.attribs.columns.2.style","tag.attribs.columns.3.style","tag.attribs.columns.4.style"],"jsHooks":[]}</script>
</div>

# Prepending Madness

``` r
bgp |>
    group_by(ip_version) |> 
    slice_max(order_by = as_path_len, n = 50, with_ties = FALSE) |>
    mutate(order = row_number()) |>
    ungroup() |> 
    ggplot() +
    geom_col(aes(order, as_path_len, fill = ip_version)) +
    facet_grid(vars(ip_version)) 
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-13-1.png" width="672" />

``` r
bgp |>
    filter(ip_version == 'v4') |>
    slice_max(order_by = as_path_len, n = 1) |>
    pluck('as_path', 1) |>
    paste(collapse = ' ')
```

    ## [1] "45270 4764 9002 136106 45305 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381 149381"

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

<div id="pslaqtevlm" class=".gt_table" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#pslaqtevlm table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#pslaqtevlm thead, #pslaqtevlm tbody, #pslaqtevlm tfoot, #pslaqtevlm tr, #pslaqtevlm td, #pslaqtevlm th {
  border-style: none;
}
&#10;#pslaqtevlm p {
  margin: 0;
  padding: 0;
}
&#10;#pslaqtevlm .gt_table {
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
&#10;#pslaqtevlm .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#pslaqtevlm .gt_title {
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
&#10;#pslaqtevlm .gt_subtitle {
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
&#10;#pslaqtevlm .gt_heading {
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
&#10;#pslaqtevlm .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#pslaqtevlm .gt_col_headings {
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
&#10;#pslaqtevlm .gt_col_heading {
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
&#10;#pslaqtevlm .gt_column_spanner_outer {
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
&#10;#pslaqtevlm .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#pslaqtevlm .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#pslaqtevlm .gt_column_spanner {
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
&#10;#pslaqtevlm .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#pslaqtevlm .gt_group_heading {
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
&#10;#pslaqtevlm .gt_empty_group_heading {
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
&#10;#pslaqtevlm .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#pslaqtevlm .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#pslaqtevlm .gt_row {
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
&#10;#pslaqtevlm .gt_stub {
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
&#10;#pslaqtevlm .gt_stub_row_group {
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
&#10;#pslaqtevlm .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#pslaqtevlm .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#pslaqtevlm .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#pslaqtevlm .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#pslaqtevlm .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#pslaqtevlm .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#pslaqtevlm .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#pslaqtevlm .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#pslaqtevlm .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#pslaqtevlm .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#pslaqtevlm .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#pslaqtevlm .gt_footnotes {
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
&#10;#pslaqtevlm .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#pslaqtevlm .gt_sourcenotes {
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
&#10;#pslaqtevlm .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#pslaqtevlm .gt_left {
  text-align: left;
}
&#10;#pslaqtevlm .gt_center {
  text-align: center;
}
&#10;#pslaqtevlm .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#pslaqtevlm .gt_font_normal {
  font-weight: normal;
}
&#10;#pslaqtevlm .gt_font_bold {
  font-weight: bold;
}
&#10;#pslaqtevlm .gt_font_italic {
  font-style: italic;
}
&#10;#pslaqtevlm .gt_super {
  font-size: 65%;
}
&#10;#pslaqtevlm .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#pslaqtevlm .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#pslaqtevlm .gt_indent_1 {
  text-indent: 5px;
}
&#10;#pslaqtevlm .gt_indent_2 {
  text-indent: 10px;
}
&#10;#pslaqtevlm .gt_indent_3 {
  text-indent: 15px;
}
&#10;#pslaqtevlm .gt_indent_4 {
  text-indent: 20px;
}
&#10;#pslaqtevlm .gt_indent_5 {
  text-indent: 25px;
}
&#10;#pslaqtevlm .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#pslaqtevlm div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>
<div id="pslaqtevlm" class="reactable html-widget" style="width:auto;height:auto;"></div>
<script type="application/json" data-for="pslaqtevlm">{"x":{"tag":{"name":"Reactable","attribs":{"data":{"id":[280028],"as_path":[[45270,4764,4761,149381]],"recv_time":["2024-01-06T02:21:35Z"],"type":["UPDATE"],"nlri":["103.179.250.0/24"]},"columns":[{"id":"id","name":"id","type":"numeric","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"right"},{"id":"as_path","name":"as_path","type":"list","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"center"},{"id":"recv_time","name":"recv_time","type":"Date","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"right"},{"id":"type","name":"type","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"left"},{"id":"nlri","name":"nlri","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"right"}],"defaultPageSize":10,"showPageSizeOptions":false,"pageSizeOptions":[10,25,50,100],"paginationType":"numbers","showPagination":true,"showPageInfo":true,"minRows":1,"height":"auto","theme":{"color":"#333333","backgroundColor":"#FFFFFF","stripedColor":"rgba(128,128,128,0.05)","style":{"font-family":"system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif","fontSize":"16px"},"tableStyle":{"borderTopStyle":"solid","borderTopWidth":"2px","borderTopColor":"#D3D3D3"},"headerStyle":{"fontWeight":"normal","backgroundColor":"transparent","borderBottomStyle":"solid","borderBottomWidth":"2px","borderBottomColor":"#D3D3D3"},"groupHeaderStyle":{"fontWeight":"normal","backgroundColor":"transparent","borderBottomStyle":"solid","borderBottomWidth":"2px","borderBottomColor":"#D3D3D3"},"cellStyle":{"fontWeight":"normal"}},"elementId":"pslaqtevlm","dataKey":"6698bb22d36d6d2b7f66c398723e4637"},"children":[]},"class":"reactR_markup"},"evals":["tag.attribs.columns.0.style","tag.attribs.columns.1.style","tag.attribs.columns.2.style","tag.attribs.columns.3.style","tag.attribs.columns.4.style"],"jsHooks":[]}</script>
</div>

``` r
bgp |>
    filter(ip_version == 'v6') |>
    slice_max(order_by = as_path_len, n = 1) |>
    pluck('as_path', 1) |>
    paste(collapse = ' ')
```

    ## [1] "45270 4764 2914 29632 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 8772 200579 200579 203868"

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
    geom_col(aes(pa, log(n))) +
    geom_label(aes(pa, log(n), label = n), nudge_y = -.2) +
    coord_flip()
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

    ## # A tibble: 18 × 4
    ##    originating_asn organisation                                   source country
    ##              <int> <chr>                                          <chr>  <chr>  
    ##  1           42912 Al mouakhah lil khadamat al logesteih wa al i… RIPE   JO     
    ##  2           23872 delDSL Internet Pvt. Ltd.                      APNIC  IN     
    ##  3          204667 Juan Ramon Jerez Suarez                        RIPE   ES     
    ##  4           48832 Jordanian mobile phone services Ltd            RIPE   JO     
    ##  5           41297 Adam Dlugosz trading as ABAKS                  RIPE   PL     
    ##  6           52564 Biazi Telecom                                  LACNIC BR     
    ##  7           52746 Primanet Internet LTDA                         LACNIC BR     
    ##  8           61639 BCNET INFORMÁTICA LTDA                         LACNIC BR     
    ##  9           10429 TELEFÔNICA BRASIL S.A                          LACNIC BR     
    ## 10          265999 Cianet Provedor de Internet EIRELI             LACNIC BR     
    ## 11          264901 Ailon Rodrigo Oliveira Lima ME                 LACNIC BR     
    ## 12          264954 Virtual Connect                                LACNIC BR     
    ## 13           52935 Infobarra Solucoes em Informatica Ltda         LACNIC BR     
    ## 14          262426 TELECOMUNICAÇÕES RONDONOPOLIS LTDA - ME        LACNIC BR     
    ## 15          263454 Ines Waltmann - Me                             LACNIC BR     
    ## 16           27976 Coop. de Servicios Públicos de Morteros Ltda.  LACNIC AR     
    ## 17          267434 Xingu Assessoria em Redes Ltda ME              LACNIC BR     
    ## 18          273379 V. M. De Melo Informatica - MIDIA INFORMATICA  LACNIC BR

# Flippy-Flappy: Who’s Having a Bad Time?

``` r
bgp |>
    unnest(nlri) |>
    count(nlri) |>
    slice_max(n, n = 50) |>
    gt() |> 
    opt_interactive()
```

<div id="efmzwqxpkk" class=".gt_table" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#efmzwqxpkk table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#efmzwqxpkk thead, #efmzwqxpkk tbody, #efmzwqxpkk tfoot, #efmzwqxpkk tr, #efmzwqxpkk td, #efmzwqxpkk th {
  border-style: none;
}
&#10;#efmzwqxpkk p {
  margin: 0;
  padding: 0;
}
&#10;#efmzwqxpkk .gt_table {
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
&#10;#efmzwqxpkk .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#efmzwqxpkk .gt_title {
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
&#10;#efmzwqxpkk .gt_subtitle {
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
&#10;#efmzwqxpkk .gt_heading {
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
&#10;#efmzwqxpkk .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#efmzwqxpkk .gt_col_headings {
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
&#10;#efmzwqxpkk .gt_col_heading {
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
&#10;#efmzwqxpkk .gt_column_spanner_outer {
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
&#10;#efmzwqxpkk .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#efmzwqxpkk .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#efmzwqxpkk .gt_column_spanner {
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
&#10;#efmzwqxpkk .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#efmzwqxpkk .gt_group_heading {
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
&#10;#efmzwqxpkk .gt_empty_group_heading {
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
&#10;#efmzwqxpkk .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#efmzwqxpkk .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#efmzwqxpkk .gt_row {
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
&#10;#efmzwqxpkk .gt_stub {
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
&#10;#efmzwqxpkk .gt_stub_row_group {
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
&#10;#efmzwqxpkk .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#efmzwqxpkk .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#efmzwqxpkk .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#efmzwqxpkk .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#efmzwqxpkk .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#efmzwqxpkk .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#efmzwqxpkk .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#efmzwqxpkk .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#efmzwqxpkk .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#efmzwqxpkk .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#efmzwqxpkk .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#efmzwqxpkk .gt_footnotes {
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
&#10;#efmzwqxpkk .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#efmzwqxpkk .gt_sourcenotes {
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
&#10;#efmzwqxpkk .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#efmzwqxpkk .gt_left {
  text-align: left;
}
&#10;#efmzwqxpkk .gt_center {
  text-align: center;
}
&#10;#efmzwqxpkk .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#efmzwqxpkk .gt_font_normal {
  font-weight: normal;
}
&#10;#efmzwqxpkk .gt_font_bold {
  font-weight: bold;
}
&#10;#efmzwqxpkk .gt_font_italic {
  font-style: italic;
}
&#10;#efmzwqxpkk .gt_super {
  font-size: 65%;
}
&#10;#efmzwqxpkk .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#efmzwqxpkk .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#efmzwqxpkk .gt_indent_1 {
  text-indent: 5px;
}
&#10;#efmzwqxpkk .gt_indent_2 {
  text-indent: 10px;
}
&#10;#efmzwqxpkk .gt_indent_3 {
  text-indent: 15px;
}
&#10;#efmzwqxpkk .gt_indent_4 {
  text-indent: 20px;
}
&#10;#efmzwqxpkk .gt_indent_5 {
  text-indent: 25px;
}
&#10;#efmzwqxpkk .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#efmzwqxpkk div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>
<div id="efmzwqxpkk" class="reactable html-widget" style="width:auto;height:auto;"></div>
<script type="application/json" data-for="efmzwqxpkk">{"x":{"tag":{"name":"Reactable","attribs":{"data":{"nlri":["140.99.244.0/23","107.154.97.0/24","45.172.92.0/22","151.236.111.0/24","205.164.85.0/24","41.209.0.0/18","143.255.204.0/22","176.124.58.0/24","187.1.11.0/24","187.1.13.0/24","103.248.132.0/22","185.200.123.0/24","138.121.151.0/24","193.105.107.0/24","83.243.112.0/21","202.45.88.0/24","203.145.74.0/24","203.145.78.0/24","209.54.122.0/24","103.177.86.0/24","103.177.87.0/24","103.223.2.0/24","188.130.192.0/22","109.248.130.0/24","41.75.208.0/20","67.211.53.0/24","207.167.116.0/22","213.204.81.0/24","102.220.224.0/24","102.220.227.0/24","102.220.226.0/24","154.88.8.0/24","78.142.198.0/24","209.22.66.0/24","209.22.67.0/24","185.116.216.0/22","213.204.80.0/24","64.68.236.0/22","178.22.141.0/24","130.137.230.0/24","113.23.173.0/24","112.33.120.0/24","185.18.201.0/24","170.238.225.0/24","186.170.29.0/24","181.225.48.0/24","181.225.43.0/24","183.90.162.0/24","183.90.163.0/24","207.244.192.0/22"],"n":[2596,2583,2494,2312,2189,2069,2048,1584,1582,1580,1512,1489,1395,1245,1190,1171,1171,1171,1062,987,987,848,839,829,791,745,672,640,604,603,601,561,558,533,533,462,441,439,432,426,399,383,367,356,347,345,338,319,317,316]},"columns":[{"id":"nlri","name":"nlri","type":"character","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"right"},{"id":"n","name":"n","type":"numeric","na":"NA","minWidth":125,"style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","html":true,"align":"right"}],"defaultPageSize":10,"showPageSizeOptions":false,"pageSizeOptions":[10,25,50,100],"paginationType":"numbers","showPagination":true,"showPageInfo":true,"minRows":1,"height":"auto","theme":{"color":"#333333","backgroundColor":"#FFFFFF","stripedColor":"rgba(128,128,128,0.05)","style":{"font-family":"system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif","fontSize":"16px"},"tableStyle":{"borderTopStyle":"solid","borderTopWidth":"2px","borderTopColor":"#D3D3D3"},"headerStyle":{"fontWeight":"normal","backgroundColor":"transparent","borderBottomStyle":"solid","borderBottomWidth":"2px","borderBottomColor":"#D3D3D3"},"groupHeaderStyle":{"fontWeight":"normal","backgroundColor":"transparent","borderBottomStyle":"solid","borderBottomWidth":"2px","borderBottomColor":"#D3D3D3"},"cellStyle":{"fontWeight":"normal"}},"elementId":"efmzwqxpkk","dataKey":"aa65f028c6a1d7935c0915a52c053439"},"children":[]},"class":"reactR_markup"},"evals":["tag.attribs.columns.0.style","tag.attribs.columns.1.style"],"jsHooks":[]}</script>
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

    ## # A tibble: 41 × 14
    ##        id as_path    recv_time           type   nlri      withdrawn_routes
    ##     <int> <list>     <dttm>              <chr>  <list>    <chr>           
    ##  1 200833 <int [10]> 2024-01-06 07:26:32 UPDATE <chr [1]> 140.99.244.0/23 
    ##  2 204783 <int [8]>  2024-01-06 07:44:32 UPDATE <chr [1]> 140.99.244.0/23 
    ##  3 211020 <int [4]>  2024-01-06 08:18:04 UPDATE <chr [1]> 140.99.244.0/23 
    ##  4 215439 <int [6]>  2024-01-06 08:42:04 UPDATE <chr [2]> 140.99.244.0/23 
    ##  5 216001 <int [5]>  2024-01-06 08:45:04 UPDATE <chr [1]> 140.99.244.0/23 
    ##  6 239134 <int [6]>  2024-01-06 09:44:04 UPDATE <chr [1]> 140.99.244.0/23 
    ##  7 243597 <int [6]>  2024-01-06 10:03:33 UPDATE <chr [1]> 140.99.244.0/23 
    ##  8 253293 <int [6]>  2024-01-06 10:55:04 UPDATE <chr [1]> 140.99.244.0/23 
    ##  9 259087 <int [7]>  2024-01-06 11:28:34 UPDATE <chr [2]> 140.99.244.0/23 
    ## 10 261794 <int [6]>  2024-01-06 11:44:04 UPDATE <chr [1]> 140.99.244.0/23 
    ## # ℹ 31 more rows
    ## # ℹ 8 more variables: path_attributes <list>, ip_version <chr>,
    ## #   pure_withdraw <lgl>, n_routes <int>, address_space <dbl>,
    ## #   initial_send <lgl>, originating_asn <int>, as_path_len <int>
