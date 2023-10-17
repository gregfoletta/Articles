---
title: Honest Insurance Company
author: Greg Foletta
date: '2023-09-28'
slug: []
categories: [R Bayesian]
tags: []
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

Last month my car - a Toyota Kluger - was run into while parked in front of my house. Luckily no one was injured and while annoying, the person had insurance (coincidently with the same company as my). The insurance company came back and determined that the car had been written off and I would be paid out the market value of the car. But what is the market value? How could I keep the insurance company honest and make sure I wasn’t getting stiffed?

In this post I’ll go through the process I used to keep the insurance company honest. There’s data acquisition and visiualisation of the current market, then modelling of the market price.

# Data Aquisition

The first step was to acquire some data on the current market for Toyota Klugers. I used [carsales.com.au](https://www.carsales.com.au/cars/used/toyota/kluger/) as my source. The Carsales site requires Javascript to render, so simply requesting the pages wasn’t going to work. Instead we need to render the page in a browser. To do this I used a docker instance of the webdriver [Selenium](https://www.selenium.dev/), interfacing into this with the R package [RSelenium](https://github.com/ropensci/RSelenium). This allows us to browse to the site from a ‘remotely controller’ browser, Javascript and all, and retrieve the information we need.

First up, we connect to the docker instance, setting the page load strategy to eager so that it will return when the initial HTML is loaded and not wait for stylesheets, images, etc.

``` r
rs <- remoteDriver(remoteServerAddr = '172.17.0.2', port = 4444L)
rs$extraCapabilities$pageLoadStrategy <- "eager"
rs$open()
```

Each page of Klugers for sale is determined by an offset of 12. We generate the offsets (12, 24, 36 etc) and the URIs based on these offsets. We then navigate to each page, reading the source, and parsing into a structuered XML document.

``` r
kluger_source <-
    tibble(
        # Generate offsets
        offset = 12 * c(0:100),
        # Create URIs based on offsets
        uri = glue("https://www.carsales.com.au/cars/used/toyota/kluger/?offset={offset}")
    ) |> 
    mutate(
        # Naviate to each URI, read and parse the source
        source = map(uri, ~{ 
            rs$navigate(uri)
            rs$getPageSource() |> pluck(1) |> read_html()
        } )
    )
```

With the raw source in our hands, we can move on to extracting the pieces of data we need from each of them.

# Data Extractiion

First up, we define a small helper function which finds an element based on its XPath, and pulls out the text of that element.

``` r
# XPath helper function, xpt short for xpath_text
xpt <- function(html, xpath) {
    html_elements(html, xpath = xpath) |> 
    html_text()
}
```

Each ‘card’ has the details of a car for sale. The issue we ran into is that not all of them have the odometer reading, which is the critical variable we’re going to use in our modelling later. To get around this, we use a some convoluted XPath. We find all the
<li>
tags that have the odometer reading, then go back up the tree to find the ancestor
<div>

tags that define the entire card. This ensures that all the cards we’ve pulled out have odometer readings.

From there, it’s trivial to extract specific properties from the car sale.

``` r
kluger_data <-
    kluger_source |> 
    mutate(
        # Get entires that have odometer
        cards = map(source, ~html_elements(.x, xpath = "//li[@data-type = 'Odometer']/ancestor::div[@class = 'card-body']")),
        # Extract specific values of each car sale
        price = map(cards, ~xpt(.x, xpath = ".//a[@data-webm-clickvalue = 'sv-price']")),
        title = map(cards, ~xpt(.x, xpath = ".//a[@data-webm-clickvalue = 'sv-title']")),
        odometer = map(cards, ~xpt(.x, xpath = ".//li[@data-type = 'Odometer']")),
        body = map(cards, ~xpt(.x, xpath = ".//li[@data-type = 'Body Style']")),
        transmission = map(cards, ~xpt(.x, xpath = ".//li[@data-type = 'Transmission']")),
        engine = map(cards, ~xpt(.x, xpath = ".//li[@data-type = 'Engine']"))
    ) |>
    select(-c(source, cards, offset)) |>
    unnest(everything())
```

At this stage, the data is a bit raw: the odometer and price are character strings with dollar signs and commas, and other important pieces of info are in the title:

<div id="emzqrgnlzi" class=".gt_table" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#emzqrgnlzi table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#emzqrgnlzi thead, #emzqrgnlzi tbody, #emzqrgnlzi tfoot, #emzqrgnlzi tr, #emzqrgnlzi td, #emzqrgnlzi th {
  border-style: none;
}
&#10;#emzqrgnlzi p {
  margin: 0;
  padding: 0;
}
&#10;#emzqrgnlzi .gt_table {
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
&#10;#emzqrgnlzi .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#emzqrgnlzi .gt_title {
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
&#10;#emzqrgnlzi .gt_subtitle {
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
&#10;#emzqrgnlzi .gt_heading {
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
&#10;#emzqrgnlzi .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#emzqrgnlzi .gt_col_headings {
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
&#10;#emzqrgnlzi .gt_col_heading {
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
&#10;#emzqrgnlzi .gt_column_spanner_outer {
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
&#10;#emzqrgnlzi .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#emzqrgnlzi .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#emzqrgnlzi .gt_column_spanner {
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
&#10;#emzqrgnlzi .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#emzqrgnlzi .gt_group_heading {
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
&#10;#emzqrgnlzi .gt_empty_group_heading {
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
&#10;#emzqrgnlzi .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#emzqrgnlzi .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#emzqrgnlzi .gt_row {
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
&#10;#emzqrgnlzi .gt_stub {
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
&#10;#emzqrgnlzi .gt_stub_row_group {
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
&#10;#emzqrgnlzi .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#emzqrgnlzi .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#emzqrgnlzi .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#emzqrgnlzi .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#emzqrgnlzi .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#emzqrgnlzi .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#emzqrgnlzi .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#emzqrgnlzi .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#emzqrgnlzi .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#emzqrgnlzi .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#emzqrgnlzi .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#emzqrgnlzi .gt_footnotes {
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
&#10;#emzqrgnlzi .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#emzqrgnlzi .gt_sourcenotes {
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
&#10;#emzqrgnlzi .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#emzqrgnlzi .gt_left {
  text-align: left;
}
&#10;#emzqrgnlzi .gt_center {
  text-align: center;
}
&#10;#emzqrgnlzi .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#emzqrgnlzi .gt_font_normal {
  font-weight: normal;
}
&#10;#emzqrgnlzi .gt_font_bold {
  font-weight: bold;
}
&#10;#emzqrgnlzi .gt_font_italic {
  font-style: italic;
}
&#10;#emzqrgnlzi .gt_super {
  font-size: 65%;
}
&#10;#emzqrgnlzi .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#emzqrgnlzi .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#emzqrgnlzi .gt_indent_1 {
  text-indent: 5px;
}
&#10;#emzqrgnlzi .gt_indent_2 {
  text-indent: 10px;
}
&#10;#emzqrgnlzi .gt_indent_3 {
  text-indent: 15px;
}
&#10;#emzqrgnlzi .gt_indent_4 {
  text-indent: 20px;
}
&#10;#emzqrgnlzi .gt_indent_5 {
  text-indent: 25px;
}
</style>
<div id="emzqrgnlzi" class="reactable html-widget " style="width:auto;height:auto;"></div>
<script type="application/json" data-for="emzqrgnlzi">{"x":{"tag":{"name":"Reactable","attribs":{"data":{"price":["$66,994*","$39,990","$57,490*","$39,990*","$31,990","$13,989","$33,990*","$45,750*","$64,888","$67,990","$65,990*","$66,990*","$42,500*","$39,990","$79,490*","$64,500*","$68,888*","$75,499*","$46,888*","$33,990","$53,000*","$61,895","$45,990*","$56,990*","$30,998*","$59,990*","$31,490*","$14,700*","$51,999","$35,000*","$33,790*","$16,500*","$44,990","$75,000*","$21,900*","$18,500*","$18,000*","$43,000*","$65,990","$12,500*","$37,000*","$46,990","$66,990*","$39,990*","$13,000*","$41,990","$66,999*","$25,999*","$17,990*","$37,990*","$49,999*","$68,000*","$68,950","$22,300*","$37,900*","$30,990*","$14,990*","$59,999","$52,990*","$21,990*","$48,990","$38,990*","$46,000*","$26,987*","$36,990","$35,500*","$35,979*","$67,990*","$56,500*","$16,991","$81,888*","$36,990","$11,600*","$44,950*","$65,990*","$34,458","$31,990","$10,000*","$35,490*","$63,999*","$16,000*","$61,888*","$29,480","$55,498","$37,990","$37,850*","$10,990","$38,999*","$56,990*","$46,990","$36,990","$67,350*","$21,500*","$43,990*","$34,990","$9,990","$33,000*","$38,888*","$44,888*","$32,990*","$24,388*","$68,888","$24,990*","$53,990*","$16,888*","$39,800*","$44,999","$17,990*","$35,990*","$8,900*","$76,990*","$47,988","$34,995*","$37,990","$41,990*","$40,990","$48,980","$64,700*","$35,500*","$28,990*","$39,999*","$47,988*","$20,000*","$54,555*","$77,000*","$35,990*","$41,990*","$40,990*","$65,990*","$19,979*","$58,970","$44,990*","$28,990*","$40,999","$56,490*","$38,850*","$39,900*","$42,990","$49,888*","$38,888*","$38,990*","$27,890*","$38,990*","$33,500*","$11,000*","$16,500*","$53,888*","$14,000*","$37,990*","$50,990","$50,990","$44,888","$71,000*","$8,000*","$80,999*","$34,990","$28,763*","$27,995*","$26,990*","$58,500","$51,990*","$12,500*","$16,000*","$21,738*","$72,850*","$47,990*","$9,488","$42,800*","$57,000*","$78,993*","$34,990*","$59,999*","$27,900*","$19,000*","$60,999","$49,990*","$40,000*","$44,000*","$19,990*","$32,990*","$75,990*","$12,500*","$31,950*","$64,880*","$37,990","$53,888","$43,989*","$32,561*","$33,000*","$41,990*","$31,990*","$23,590*","$48,990*","$49,999*","$22,000*","$34,990*","$49,990*","$54,990*","$67,950*","$37,880*"],"title":["2021 Toyota Kluger Grande Auto AWD","2017 Toyota Kluger Grande Auto AWD","2021 Toyota Kluger GX Auto eFour","2016 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GX Auto AWD","2009 Toyota Kluger KX-S Auto 2WD","2016 Toyota Kluger GX Auto 2WD","2018 Toyota Kluger GXL Auto AWD","2021 Toyota Kluger GXL Auto eFour","2021 Toyota Kluger GXL Auto eFour","2023 Toyota Kluger GX Auto eFour","2021 Toyota Kluger GXL Auto eFour","2017 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GX Auto 2WD","2022 Toyota Kluger Grande Auto eFour","2021 Toyota Kluger Grande Auto AWD","2021 Toyota Kluger Grande Auto AWD","2022 Toyota Kluger Grande Auto eFour","2019 Toyota Kluger GXL Auto 2WD","2017 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger Grande Auto AWD","2021 Toyota Kluger GX Auto eFour","2017 Toyota Kluger Grande Auto AWD","2021 Toyota Kluger GXL Auto 2WD","2017 Toyota Kluger GX Auto AWD","2021 Toyota Kluger GX Auto eFour","2018 Toyota Kluger GX Auto 2WD","2008 Toyota Kluger Grande Auto 2WD","2019 Toyota Kluger Grande Auto AWD","2017 Toyota Kluger GX Auto 2WD","2016 Toyota Kluger GXL Auto 2WD","2013 Toyota Kluger KX-R Auto AWD","2017 Toyota Kluger Grande Auto AWD","2021 Toyota Kluger Grande Auto eFour","2015 Toyota Kluger GX Auto 2WD","2013 Toyota Kluger KX-S Auto 2WD","2010 Toyota Kluger KX-S Auto 2WD","2019 Toyota Kluger GXL Auto AWD","2021 Toyota Kluger Grande Auto 2WD","2008 Toyota Kluger KX-R Auto 2WD","2018 Toyota Kluger GXL Auto 2WD","2018 Toyota Kluger GXL Auto 2WD","2022 Toyota Kluger GXL Auto eFour","2018 Toyota Kluger Grande Auto AWD","2011 Toyota Kluger KX-S Auto AWD MY11","2019 Toyota Kluger GX Auto AWD","2021 Toyota Kluger Grande Auto AWD","2010 Toyota Kluger KX-S Auto 2WD","2013 Toyota Kluger KX-R Auto 2WD","2017 Toyota Kluger Grande Auto AWD","2018 Toyota Kluger GXL Auto AWD","2021 Toyota Kluger Grande Auto AWD","2022 Toyota Kluger GXL Auto eFour","2013 Toyota Kluger Altitude Auto 2WD","2018 Toyota Kluger GXL Auto 2WD","2016 Toyota Kluger GX Auto 2WD","2010 Toyota Kluger KX-S Auto 2WD","2021 Toyota Kluger GX Auto eFour","2021 Toyota Kluger GXL Auto 2WD","2011 Toyota Kluger Grande Auto 2WD MY11","2017 Toyota Kluger Grande Auto AWD","2018 Toyota Kluger GX Auto 2WD","2017 Toyota Kluger Grande Auto AWD","2014 Toyota Kluger Grande Auto 2WD","2019 Toyota Kluger GX Auto AWD","2016 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger GXL Auto 2WD","2022 Toyota Kluger GX Auto eFour","2021 Toyota Kluger GXL Auto 2WD","2009 Toyota Kluger KX-S Auto 2WD","2023 Toyota Kluger Grande Auto eFour","2017 Toyota Kluger GXL Auto 2WD","2009 Toyota Kluger KX-S Auto AWD","2017 Toyota Kluger Grande Auto AWD","2021 Toyota Kluger GX Auto eFour","2018 Toyota Kluger GX Auto 2WD","2018 Toyota Kluger GX Auto AWD","2008 Toyota Kluger KX-S Auto AWD","2017 Toyota Kluger GXL Auto 2WD","2021 Toyota Kluger GXL Auto eFour","2009 Toyota Kluger KX-S Auto AWD","2021 Toyota Kluger GX Auto eFour","2017 Toyota Kluger GX Auto 2WD","2018 Toyota Kluger Grande Auto 2WD","2017 Toyota Kluger GX Auto AWD","2019 Toyota Kluger GX Auto 2WD","2008 Toyota Kluger KX-R Auto 2WD","2018 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger GX Auto eFour","2019 Toyota Kluger GXL Auto 2WD","2017 Toyota Kluger GX Auto 2WD","2023 Toyota Kluger GX Auto eFour","2013 Toyota Kluger Altitude Auto AWD","2019 Toyota Kluger GXL Auto 2WD","2016 Toyota Kluger GXL Auto 2WD","2008 Toyota Kluger KX-R Auto AWD","2013 Toyota Kluger Grande Auto AWD","2017 Toyota Kluger GX Auto AWD","2021 Toyota Kluger GX Auto 2WD","2015 Toyota Kluger Grande Auto AWD","2015 Toyota Kluger Grande Auto 2WD","2021 Toyota Kluger GXL Auto eFour","2014 Toyota Kluger GX Auto 2WD","2022 Toyota Kluger GX Auto 2WD","2011 Toyota Kluger KX-R Auto AWD MY11","2018 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger Black Edition Auto 2WD","2013 Toyota Kluger Altitude Auto 2WD","2018 Toyota Kluger GX Auto AWD","2009 Toyota Kluger KX-R Auto 2WD","2021 Toyota Kluger Grande Auto eFour","2018 Toyota Kluger Grande Auto 2WD","2014 Toyota Kluger GXL Auto AWD","2018 Toyota Kluger GX Auto AWD","2018 Toyota Kluger GXL Auto 2WD","2018 Toyota Kluger GXL Auto AWD","2017 Toyota Kluger Grande Auto 2WD","2022 Toyota Kluger GX Auto 2WD","2018 Toyota Kluger GX Auto 2WD","2015 Toyota Kluger GX Auto AWD","2017 Toyota Kluger GX Auto AWD","2018 Toyota Kluger Grande Auto 2WD","2014 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger GX Auto eFour","2021 Toyota Kluger Grande Auto eFour","2016 Toyota Kluger GXL Auto 2WD","2018 Toyota Kluger GXL Auto AWD","2018 Toyota Kluger GXL Auto AWD","2021 Toyota Kluger GXL Auto eFour","2012 Toyota Kluger Altitude Auto 2WD MY12","2019 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger Black Edition Auto AWD","2016 Toyota Kluger GX Auto AWD","2019 Toyota Kluger GX Auto AWD","2021 Toyota Kluger GX Auto eFour","2016 Toyota Kluger Grande Auto AWD","2018 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger GXL Auto 2WD","2018 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger GX Auto AWD","2019 Toyota Kluger GX Auto 2WD","2014 Toyota Kluger GX Auto AWD","2017 Toyota Kluger Grande Auto 2WD","2019 Toyota Kluger GXL Auto 2WD","2009 Toyota Kluger KX-R Auto 2WD","2010 Toyota Kluger KX-R Auto AWD","2019 Toyota Kluger Grande Auto AWD","2010 Toyota Kluger KX-R Auto 2WD","2016 Toyota Kluger GXL Auto AWD","2018 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger Grande Auto AWD","2017 Toyota Kluger Grande Auto 2WD","2021 Toyota Kluger Grande Auto AWD","2010 Toyota Kluger KX-R Auto AWD","2023 Toyota Kluger Grande Auto eFour","2017 Toyota Kluger GXL Auto AWD","2015 Toyota Kluger GX Auto AWD","2015 Toyota Kluger GX Auto 2WD","2015 Toyota Kluger GXL Auto 2WD","2022 Toyota Kluger GXL Auto 2WD","2018 Toyota Kluger Grande Auto AWD","2009 Toyota Kluger KX-R Auto 2WD","2011 Toyota Kluger KX-R Auto 2WD MY11","2014 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger Grande Auto eFour","2019 Toyota Kluger GXL Auto AWD","2007 Toyota Kluger KX-S Auto 2WD","2019 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger GXL Auto AWD","2022 Toyota Kluger Grande Auto eFour","2018 Toyota Kluger GX Auto 2WD","2022 Toyota Kluger GX Auto eFour","2016 Toyota Kluger GX Auto 2WD","2012 Toyota Kluger KX-R Auto AWD MY12","2021 Toyota Kluger GX Auto eFour","2021 Toyota Kluger GX Auto AWD","2016 Toyota Kluger Grande Auto AWD","2016 Toyota Kluger Grande Auto AWD","2012 Toyota Kluger KX-S Auto AWD MY12","2018 Toyota Kluger GX Auto 2WD","2023 Toyota Kluger GXL Auto eFour","2007 Toyota Kluger KX-R Auto 2WD","2018 Toyota Kluger GX Auto 2WD","2022 Toyota Kluger Grande Auto 2WD","2019 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger Black Edition Auto AWD","2019 Toyota Kluger GX Auto 2WD","2014 Toyota Kluger Grande Auto AWD","2015 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GX Auto 2WD","2015 Toyota Kluger Grande Auto 2WD","2013 Toyota Kluger Grande Auto 2WD","2019 Toyota Kluger Black Edition Auto 2WD","2019 Toyota Kluger GXL Auto AWD","2013 Toyota Kluger KX-R Auto 2WD","2018 Toyota Kluger GX Auto AWD","2021 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger Black Edition Auto AWD","2023 Toyota Kluger GX Auto eFour","2018 Toyota Kluger GX Auto 2WD"],"odometer":["23,000 km","127,073 km","32,500 km","79,226 km","138,978 km","283,996 km","81,224 km","58,000 km","45,807 km","45,298 km","1,946 km","50,032 km","79,610 km","77,317 km","12,025 km","24,020 km","19,068 km","19,500 km","28,434 km","144,002 km","58,000 km","34,985 km","106,854 km","24,571 km","119,075 km","49,703 km","110,037 km","297,247 km","68,018 km","75,000 km","73,068 km","244,300 km","98,213 km","20,000 km","183,197 km","252,000 km","220,000 km","106,250 km","31,429 km","168,000 km","70,000 km","62,950 km","34,980 km","127,123 km","388,000 km","73,715 km","38,214 km","195,000 km","167,710 km","123,365 km","22,506 km","33,000 km","29,793 km","154,000 km","79,824 km","70,376 km","230,039 km","47,988 km","39,850 km","165,500 km","95,310 km","64,223 km","91,327 km","165,000 km","101,681 km","56,500 km","103,232 km","19 km","24,000 km","212,983 km","5,311 km","93,313 km","210,000 km","69,000 km","18,332 km","107,421 km","146,481 km","330,000 km","97,875 km","32,451 km","198,478 km","14,957 km","111,792 km","14,347 km","72,172 km","54,909 km","344,122 km","58,024 km","58,261 km","86,865 km","60,789 km","35 km","203,000 km","35,560 km","94,595 km","345,220 km","87,470 km","91,847 km","52,531 km","118,570 km","175,741 km","41,044 km","166,219 km","10,702 km","247,441 km","43,000 km","75,328 km","168,124 km","104,131 km","280,000 km","25,976 km","73,977 km","141,555 km","66,030 km","144,846 km","96,026 km","58,719 km","5,919 km","94,699 km","136,417 km","71,000 km","65,857 km","180,000 km","79,967 km","12,240 km","114,373 km","96,448 km","94,178 km","53,257 km","153,338 km","32,402 km","115,663 km","148,000 km","61,382 km","56,355 km","96,696 km","115,488 km","60,042 km","72,291 km","113,415 km","89,943 km","129,070 km","109,021 km","143,511 km","224,000 km","169,000 km","48,299 km","279,000 km","99,090 km","65,139 km","58,057 km","87,827 km","8,690 km","277,000 km","10,549 km","102,445 km","95,301 km","143,000 km","146,695 km","10,266 km","68,832 km","325,000 km","167,850 km","178,465 km","19,250 km","60,000 km","301,519 km","33,000 km","11,500 km","9,454 km","91,497 km","22,000 km","132,300 km","189,000 km","34,277 km","26,863 km","106,000 km","137,000 km","187,620 km","116,586 km","300 km","250,000 km","132,765 km","19,203 km","82,713 km","62,662 km","34,508 km","120,424 km","127,000 km","47,203 km","134,094 km","142,471 km","28,297 km","32,000 km","153,677 km","93,827 km","20,965 km","36,562 km","50 km","81,342 km"],"body":["SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV"],"transmission":["Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic"],"engine":["6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","2.5i/184kW Hybrid","2.5i/184kW Hybrid","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol"]},"columns":[{"id":"price","name":"price","type":"character","style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","cell":["$66,994*","$39,990","$57,490*","$39,990*","$31,990","$13,989","$33,990*","$45,750*","$64,888","$67,990","$65,990*","$66,990*","$42,500*","$39,990","$79,490*","$64,500*","$68,888*","$75,499*","$46,888*","$33,990","$53,000*","$61,895","$45,990*","$56,990*","$30,998*","$59,990*","$31,490*","$14,700*","$51,999","$35,000*","$33,790*","$16,500*","$44,990","$75,000*","$21,900*","$18,500*","$18,000*","$43,000*","$65,990","$12,500*","$37,000*","$46,990","$66,990*","$39,990*","$13,000*","$41,990","$66,999*","$25,999*","$17,990*","$37,990*","$49,999*","$68,000*","$68,950","$22,300*","$37,900*","$30,990*","$14,990*","$59,999","$52,990*","$21,990*","$48,990","$38,990*","$46,000*","$26,987*","$36,990","$35,500*","$35,979*","$67,990*","$56,500*","$16,991","$81,888*","$36,990","$11,600*","$44,950*","$65,990*","$34,458","$31,990","$10,000*","$35,490*","$63,999*","$16,000*","$61,888*","$29,480","$55,498","$37,990","$37,850*","$10,990","$38,999*","$56,990*","$46,990","$36,990","$67,350*","$21,500*","$43,990*","$34,990","$9,990","$33,000*","$38,888*","$44,888*","$32,990*","$24,388*","$68,888","$24,990*","$53,990*","$16,888*","$39,800*","$44,999","$17,990*","$35,990*","$8,900*","$76,990*","$47,988","$34,995*","$37,990","$41,990*","$40,990","$48,980","$64,700*","$35,500*","$28,990*","$39,999*","$47,988*","$20,000*","$54,555*","$77,000*","$35,990*","$41,990*","$40,990*","$65,990*","$19,979*","$58,970","$44,990*","$28,990*","$40,999","$56,490*","$38,850*","$39,900*","$42,990","$49,888*","$38,888*","$38,990*","$27,890*","$38,990*","$33,500*","$11,000*","$16,500*","$53,888*","$14,000*","$37,990*","$50,990","$50,990","$44,888","$71,000*","$8,000*","$80,999*","$34,990","$28,763*","$27,995*","$26,990*","$58,500","$51,990*","$12,500*","$16,000*","$21,738*","$72,850*","$47,990*","$9,488","$42,800*","$57,000*","$78,993*","$34,990*","$59,999*","$27,900*","$19,000*","$60,999","$49,990*","$40,000*","$44,000*","$19,990*","$32,990*","$75,990*","$12,500*","$31,950*","$64,880*","$37,990","$53,888","$43,989*","$32,561*","$33,000*","$41,990*","$31,990*","$23,590*","$48,990*","$49,999*","$22,000*","$34,990*","$49,990*","$54,990*","$67,950*","$37,880*"],"html":true,"align":"right","headerStyle":{"font-weight":"normal"}},{"id":"title","name":"title","type":"character","style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","cell":["2021 Toyota Kluger Grande Auto AWD","2017 Toyota Kluger Grande Auto AWD","2021 Toyota Kluger GX Auto eFour","2016 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GX Auto AWD","2009 Toyota Kluger KX-S Auto 2WD","2016 Toyota Kluger GX Auto 2WD","2018 Toyota Kluger GXL Auto AWD","2021 Toyota Kluger GXL Auto eFour","2021 Toyota Kluger GXL Auto eFour","2023 Toyota Kluger GX Auto eFour","2021 Toyota Kluger GXL Auto eFour","2017 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GX Auto 2WD","2022 Toyota Kluger Grande Auto eFour","2021 Toyota Kluger Grande Auto AWD","2021 Toyota Kluger Grande Auto AWD","2022 Toyota Kluger Grande Auto eFour","2019 Toyota Kluger GXL Auto 2WD","2017 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger Grande Auto AWD","2021 Toyota Kluger GX Auto eFour","2017 Toyota Kluger Grande Auto AWD","2021 Toyota Kluger GXL Auto 2WD","2017 Toyota Kluger GX Auto AWD","2021 Toyota Kluger GX Auto eFour","2018 Toyota Kluger GX Auto 2WD","2008 Toyota Kluger Grande Auto 2WD","2019 Toyota Kluger Grande Auto AWD","2017 Toyota Kluger GX Auto 2WD","2016 Toyota Kluger GXL Auto 2WD","2013 Toyota Kluger KX-R Auto AWD","2017 Toyota Kluger Grande Auto AWD","2021 Toyota Kluger Grande Auto eFour","2015 Toyota Kluger GX Auto 2WD","2013 Toyota Kluger KX-S Auto 2WD","2010 Toyota Kluger KX-S Auto 2WD","2019 Toyota Kluger GXL Auto AWD","2021 Toyota Kluger Grande Auto 2WD","2008 Toyota Kluger KX-R Auto 2WD","2018 Toyota Kluger GXL Auto 2WD","2018 Toyota Kluger GXL Auto 2WD","2022 Toyota Kluger GXL Auto eFour","2018 Toyota Kluger Grande Auto AWD","2011 Toyota Kluger KX-S Auto AWD MY11","2019 Toyota Kluger GX Auto AWD","2021 Toyota Kluger Grande Auto AWD","2010 Toyota Kluger KX-S Auto 2WD","2013 Toyota Kluger KX-R Auto 2WD","2017 Toyota Kluger Grande Auto AWD","2018 Toyota Kluger GXL Auto AWD","2021 Toyota Kluger Grande Auto AWD","2022 Toyota Kluger GXL Auto eFour","2013 Toyota Kluger Altitude Auto 2WD","2018 Toyota Kluger GXL Auto 2WD","2016 Toyota Kluger GX Auto 2WD","2010 Toyota Kluger KX-S Auto 2WD","2021 Toyota Kluger GX Auto eFour","2021 Toyota Kluger GXL Auto 2WD","2011 Toyota Kluger Grande Auto 2WD MY11","2017 Toyota Kluger Grande Auto AWD","2018 Toyota Kluger GX Auto 2WD","2017 Toyota Kluger Grande Auto AWD","2014 Toyota Kluger Grande Auto 2WD","2019 Toyota Kluger GX Auto AWD","2016 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger GXL Auto 2WD","2022 Toyota Kluger GX Auto eFour","2021 Toyota Kluger GXL Auto 2WD","2009 Toyota Kluger KX-S Auto 2WD","2023 Toyota Kluger Grande Auto eFour","2017 Toyota Kluger GXL Auto 2WD","2009 Toyota Kluger KX-S Auto AWD","2017 Toyota Kluger Grande Auto AWD","2021 Toyota Kluger GX Auto eFour","2018 Toyota Kluger GX Auto 2WD","2018 Toyota Kluger GX Auto AWD","2008 Toyota Kluger KX-S Auto AWD","2017 Toyota Kluger GXL Auto 2WD","2021 Toyota Kluger GXL Auto eFour","2009 Toyota Kluger KX-S Auto AWD","2021 Toyota Kluger GX Auto eFour","2017 Toyota Kluger GX Auto 2WD","2018 Toyota Kluger Grande Auto 2WD","2017 Toyota Kluger GX Auto AWD","2019 Toyota Kluger GX Auto 2WD","2008 Toyota Kluger KX-R Auto 2WD","2018 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger GX Auto eFour","2019 Toyota Kluger GXL Auto 2WD","2017 Toyota Kluger GX Auto 2WD","2023 Toyota Kluger GX Auto eFour","2013 Toyota Kluger Altitude Auto AWD","2019 Toyota Kluger GXL Auto 2WD","2016 Toyota Kluger GXL Auto 2WD","2008 Toyota Kluger KX-R Auto AWD","2013 Toyota Kluger Grande Auto AWD","2017 Toyota Kluger GX Auto AWD","2021 Toyota Kluger GX Auto 2WD","2015 Toyota Kluger Grande Auto AWD","2015 Toyota Kluger Grande Auto 2WD","2021 Toyota Kluger GXL Auto eFour","2014 Toyota Kluger GX Auto 2WD","2022 Toyota Kluger GX Auto 2WD","2011 Toyota Kluger KX-R Auto AWD MY11","2018 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger Black Edition Auto 2WD","2013 Toyota Kluger Altitude Auto 2WD","2018 Toyota Kluger GX Auto AWD","2009 Toyota Kluger KX-R Auto 2WD","2021 Toyota Kluger Grande Auto eFour","2018 Toyota Kluger Grande Auto 2WD","2014 Toyota Kluger GXL Auto AWD","2018 Toyota Kluger GX Auto AWD","2018 Toyota Kluger GXL Auto 2WD","2018 Toyota Kluger GXL Auto AWD","2017 Toyota Kluger Grande Auto 2WD","2022 Toyota Kluger GX Auto 2WD","2018 Toyota Kluger GX Auto 2WD","2015 Toyota Kluger GX Auto AWD","2017 Toyota Kluger GX Auto AWD","2018 Toyota Kluger Grande Auto 2WD","2014 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger GX Auto eFour","2021 Toyota Kluger Grande Auto eFour","2016 Toyota Kluger GXL Auto 2WD","2018 Toyota Kluger GXL Auto AWD","2018 Toyota Kluger GXL Auto AWD","2021 Toyota Kluger GXL Auto eFour","2012 Toyota Kluger Altitude Auto 2WD MY12","2019 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger Black Edition Auto AWD","2016 Toyota Kluger GX Auto AWD","2019 Toyota Kluger GX Auto AWD","2021 Toyota Kluger GX Auto eFour","2016 Toyota Kluger Grande Auto AWD","2018 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger GXL Auto 2WD","2018 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger GX Auto AWD","2019 Toyota Kluger GX Auto 2WD","2014 Toyota Kluger GX Auto AWD","2017 Toyota Kluger Grande Auto 2WD","2019 Toyota Kluger GXL Auto 2WD","2009 Toyota Kluger KX-R Auto 2WD","2010 Toyota Kluger KX-R Auto AWD","2019 Toyota Kluger Grande Auto AWD","2010 Toyota Kluger KX-R Auto 2WD","2016 Toyota Kluger GXL Auto AWD","2018 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger Grande Auto AWD","2017 Toyota Kluger Grande Auto 2WD","2021 Toyota Kluger Grande Auto AWD","2010 Toyota Kluger KX-R Auto AWD","2023 Toyota Kluger Grande Auto eFour","2017 Toyota Kluger GXL Auto AWD","2015 Toyota Kluger GX Auto AWD","2015 Toyota Kluger GX Auto 2WD","2015 Toyota Kluger GXL Auto 2WD","2022 Toyota Kluger GXL Auto 2WD","2018 Toyota Kluger Grande Auto AWD","2009 Toyota Kluger KX-R Auto 2WD","2011 Toyota Kluger KX-R Auto 2WD MY11","2014 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger Grande Auto eFour","2019 Toyota Kluger GXL Auto AWD","2007 Toyota Kluger KX-S Auto 2WD","2019 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger GXL Auto AWD","2022 Toyota Kluger Grande Auto eFour","2018 Toyota Kluger GX Auto 2WD","2022 Toyota Kluger GX Auto eFour","2016 Toyota Kluger GX Auto 2WD","2012 Toyota Kluger KX-R Auto AWD MY12","2021 Toyota Kluger GX Auto eFour","2021 Toyota Kluger GX Auto AWD","2016 Toyota Kluger Grande Auto AWD","2016 Toyota Kluger Grande Auto AWD","2012 Toyota Kluger KX-S Auto AWD MY12","2018 Toyota Kluger GX Auto 2WD","2023 Toyota Kluger GXL Auto eFour","2007 Toyota Kluger KX-R Auto 2WD","2018 Toyota Kluger GX Auto 2WD","2022 Toyota Kluger Grande Auto 2WD","2019 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger Black Edition Auto AWD","2019 Toyota Kluger GX Auto 2WD","2014 Toyota Kluger Grande Auto AWD","2015 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GX Auto 2WD","2015 Toyota Kluger Grande Auto 2WD","2013 Toyota Kluger Grande Auto 2WD","2019 Toyota Kluger Black Edition Auto 2WD","2019 Toyota Kluger GXL Auto AWD","2013 Toyota Kluger KX-R Auto 2WD","2018 Toyota Kluger GX Auto AWD","2021 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger Black Edition Auto AWD","2023 Toyota Kluger GX Auto eFour","2018 Toyota Kluger GX Auto 2WD"],"html":true,"align":"left","headerStyle":{"font-weight":"normal"}},{"id":"odometer","name":"odometer","type":"character","style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","cell":["23,000 km","127,073 km","32,500 km","79,226 km","138,978 km","283,996 km","81,224 km","58,000 km","45,807 km","45,298 km","1,946 km","50,032 km","79,610 km","77,317 km","12,025 km","24,020 km","19,068 km","19,500 km","28,434 km","144,002 km","58,000 km","34,985 km","106,854 km","24,571 km","119,075 km","49,703 km","110,037 km","297,247 km","68,018 km","75,000 km","73,068 km","244,300 km","98,213 km","20,000 km","183,197 km","252,000 km","220,000 km","106,250 km","31,429 km","168,000 km","70,000 km","62,950 km","34,980 km","127,123 km","388,000 km","73,715 km","38,214 km","195,000 km","167,710 km","123,365 km","22,506 km","33,000 km","29,793 km","154,000 km","79,824 km","70,376 km","230,039 km","47,988 km","39,850 km","165,500 km","95,310 km","64,223 km","91,327 km","165,000 km","101,681 km","56,500 km","103,232 km","19 km","24,000 km","212,983 km","5,311 km","93,313 km","210,000 km","69,000 km","18,332 km","107,421 km","146,481 km","330,000 km","97,875 km","32,451 km","198,478 km","14,957 km","111,792 km","14,347 km","72,172 km","54,909 km","344,122 km","58,024 km","58,261 km","86,865 km","60,789 km","35 km","203,000 km","35,560 km","94,595 km","345,220 km","87,470 km","91,847 km","52,531 km","118,570 km","175,741 km","41,044 km","166,219 km","10,702 km","247,441 km","43,000 km","75,328 km","168,124 km","104,131 km","280,000 km","25,976 km","73,977 km","141,555 km","66,030 km","144,846 km","96,026 km","58,719 km","5,919 km","94,699 km","136,417 km","71,000 km","65,857 km","180,000 km","79,967 km","12,240 km","114,373 km","96,448 km","94,178 km","53,257 km","153,338 km","32,402 km","115,663 km","148,000 km","61,382 km","56,355 km","96,696 km","115,488 km","60,042 km","72,291 km","113,415 km","89,943 km","129,070 km","109,021 km","143,511 km","224,000 km","169,000 km","48,299 km","279,000 km","99,090 km","65,139 km","58,057 km","87,827 km","8,690 km","277,000 km","10,549 km","102,445 km","95,301 km","143,000 km","146,695 km","10,266 km","68,832 km","325,000 km","167,850 km","178,465 km","19,250 km","60,000 km","301,519 km","33,000 km","11,500 km","9,454 km","91,497 km","22,000 km","132,300 km","189,000 km","34,277 km","26,863 km","106,000 km","137,000 km","187,620 km","116,586 km","300 km","250,000 km","132,765 km","19,203 km","82,713 km","62,662 km","34,508 km","120,424 km","127,000 km","47,203 km","134,094 km","142,471 km","28,297 km","32,000 km","153,677 km","93,827 km","20,965 km","36,562 km","50 km","81,342 km"],"html":true,"align":"left","headerStyle":{"font-weight":"normal"}},{"id":"body","name":"body","type":"character","style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","cell":["SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV"],"html":true,"align":"left","headerStyle":{"font-weight":"normal"}},{"id":"transmission","name":"transmission","type":"character","style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","cell":["Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic"],"html":true,"align":"left","headerStyle":{"font-weight":"normal"}},{"id":"engine","name":"engine","type":"character","style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","cell":["6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","2.5i/184kW Hybrid","2.5i/184kW Hybrid","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol"],"html":true,"align":"left","headerStyle":{"font-weight":"normal"}}],"defaultPageSize":10,"showPageSizeOptions":false,"pageSizeOptions":[10,25,50,100],"paginationType":"numbers","showPagination":true,"showPageInfo":true,"minRows":1,"showSortable":true,"height":"auto","theme":{"color":"#333333","backgroundColor":"#FFFFFF","stripedColor":"rgba(128,128,128,0.05)","style":{"fontFamily":"system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif"},"headerStyle":{"borderTopStyle":"solid","borderTopWidth":"2px","borderTopColor":"#D3D3D3","borderBottomStyle":"solid","borderBottomWidth":"2px","borderBottomColor":"#D3D3D3"}},"elementId":"emzqrgnlzi","dataKey":"dcddbec9b377d604751118c46893da44"},"children":[]},"class":"reactR_markup"},"evals":["tag.attribs.columns.0.style","tag.attribs.columns.1.style","tag.attribs.columns.2.style","tag.attribs.columns.3.style","tag.attribs.columns.4.style","tag.attribs.columns.5.style"],"jsHooks":[]}</script>
</div>

There’s a small amount of housekeeping to be done. The price and odometer are in a textual format, so these are converted to integers. we also create a new *megametre* variable (i.e. thousands of kilometers). The year, model, and drivetrain are pulled out of the title of the advert using regex.

``` r
kluger_data <-
kluger_data |>
    mutate(
        odometer = parse_number(odometer),
        odometer_Mm = odometer / 1000,
        price = parse_number(price),
        year = as.integer( str_extract(title, "^(\\d{4})", group = TRUE) ),
        drivetrain = str_extract(title, "\\w+$"),
        model = str_extract(title, "Toyota Kluger ([-\\w]+)", group = TRUE)
    )
```

<div id="lbpescdidb" class=".gt_table" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#lbpescdidb table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#lbpescdidb thead, #lbpescdidb tbody, #lbpescdidb tfoot, #lbpescdidb tr, #lbpescdidb td, #lbpescdidb th {
  border-style: none;
}
&#10;#lbpescdidb p {
  margin: 0;
  padding: 0;
}
&#10;#lbpescdidb .gt_table {
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
&#10;#lbpescdidb .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#lbpescdidb .gt_title {
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
&#10;#lbpescdidb .gt_subtitle {
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
&#10;#lbpescdidb .gt_heading {
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
&#10;#lbpescdidb .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#lbpescdidb .gt_col_headings {
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
&#10;#lbpescdidb .gt_col_heading {
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
&#10;#lbpescdidb .gt_column_spanner_outer {
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
&#10;#lbpescdidb .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#lbpescdidb .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#lbpescdidb .gt_column_spanner {
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
&#10;#lbpescdidb .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#lbpescdidb .gt_group_heading {
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
&#10;#lbpescdidb .gt_empty_group_heading {
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
&#10;#lbpescdidb .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#lbpescdidb .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#lbpescdidb .gt_row {
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
&#10;#lbpescdidb .gt_stub {
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
&#10;#lbpescdidb .gt_stub_row_group {
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
&#10;#lbpescdidb .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#lbpescdidb .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#lbpescdidb .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#lbpescdidb .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#lbpescdidb .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#lbpescdidb .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#lbpescdidb .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#lbpescdidb .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#lbpescdidb .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#lbpescdidb .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#lbpescdidb .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#lbpescdidb .gt_footnotes {
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
&#10;#lbpescdidb .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#lbpescdidb .gt_sourcenotes {
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
&#10;#lbpescdidb .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#lbpescdidb .gt_left {
  text-align: left;
}
&#10;#lbpescdidb .gt_center {
  text-align: center;
}
&#10;#lbpescdidb .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#lbpescdidb .gt_font_normal {
  font-weight: normal;
}
&#10;#lbpescdidb .gt_font_bold {
  font-weight: bold;
}
&#10;#lbpescdidb .gt_font_italic {
  font-style: italic;
}
&#10;#lbpescdidb .gt_super {
  font-size: 65%;
}
&#10;#lbpescdidb .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#lbpescdidb .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#lbpescdidb .gt_indent_1 {
  text-indent: 5px;
}
&#10;#lbpescdidb .gt_indent_2 {
  text-indent: 10px;
}
&#10;#lbpescdidb .gt_indent_3 {
  text-indent: 15px;
}
&#10;#lbpescdidb .gt_indent_4 {
  text-indent: 20px;
}
&#10;#lbpescdidb .gt_indent_5 {
  text-indent: 25px;
}
</style>
<div id="lbpescdidb" class="reactable html-widget " style="width:auto;height:auto;"></div>
<script type="application/json" data-for="lbpescdidb">{"x":{"tag":{"name":"Reactable","attribs":{"data":{"price":[62999,44999,32880,19999,39990,44877,34990,40000,31950,10999,68500,16990,14800,57000,43990,58990,17000,33000,69990,37990,37990,19999,27990,10990,69950,39990,69777,34999,39000,34500,27990,49990,47990,31990,27900,13250,22999,35000,39990,33000,34990,27997,12500,64500,24388,68888,46990,60999,27000,68490,13400,49880,59999,38990,48990,54990,38999,19800,53990,46990,55990,40990,47880,76990,39990,30990,48990,17990,8800,37999,67990,8995,45000,35990,63970,11000,19990,10000,37990,56950,19888,16990,64880,43900,26950,83699,59999,27999,29999,43990,35500,41000,27990,16000,61990,27999,16990,39990,84980,44970,31000,31989,46990,43989,38990,8000,49999,33000,32390,49988,17490,40990,42990,47999,37990,48888,16990,46999,22500,33000,68888,81477,49990,40990,78600,23950,14400,45000,48990,27490,52990,34990,72690,75000,31000,44990,35999,21995,17980,34990,25750,34900,15600,50990,42000,68000,58990,35888,52990,43990,32995,43888,30990,39990,35500,42888,42990,26399,16488,35500,5600,40996,65990,46990,33990,38990,66994,33990,65990,29990,9990,33990,28900,39990,28000,61990,39490,26990,37888,19800,29500,11000,67950,66990,63990,76880,49990,27000,49999,65990,64990,15990,58500,21990,59990,15500,33000,25500,77000,53888],"title":["2021 Toyota Kluger GXL Auto eFour","2018 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger GX Auto AWD","2014 Toyota Kluger GX Auto AWD","2019 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger Black Edition Auto AWD","2019 Toyota Kluger GX Auto 2WD","2016 Toyota Kluger Grande Auto AWD","2018 Toyota Kluger GX Auto 2WD","2010 Toyota Kluger Altitude Auto 2WD","2021 Toyota Kluger Grande Auto AWD","2011 Toyota Kluger KX-S Auto AWD MY11","2010 Toyota Kluger Altitude Auto 2WD","2021 Toyota Kluger GXL Auto AWD","2019 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger GX Auto eFour","2010 Toyota Kluger KX-R Auto 2WD","2015 Toyota Kluger Grande Auto AWD","2021 Toyota Kluger GXL Auto AWD","2019 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger GX Auto AWD","2010 Toyota Kluger KX-R Auto AWD MY11","2014 Toyota Kluger GXL Auto 2WD","2008 Toyota Kluger KX-R Auto 2WD","2021 Toyota Kluger Grande Auto AWD","2015 Toyota Kluger GXL Auto 2WD","2023 Toyota Kluger GX Auto eFour","2017 Toyota Kluger GXL Auto 2WD","2017 Toyota Kluger Grande Auto AWD","2015 Toyota Kluger Grande Auto 2WD","2014 Toyota Kluger Grande Auto 2WD","2018 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GX Auto 2WD","2017 Toyota Kluger GX Auto AWD","2009 Toyota Kluger KX-R Auto 2WD","2010 Toyota Kluger KX-R Auto 2WD","2014 Toyota Kluger GXL Auto AWD","2017 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger GX Auto 2WD","2013 Toyota Kluger Grande Auto AWD","2017 Toyota Kluger GX Auto 2WD","2016 Toyota Kluger GX Auto 2WD","2009 Toyota Kluger KX-R Auto 2WD","2021 Toyota Kluger Grande Auto 2WD","2015 Toyota Kluger Grande Auto 2WD","2021 Toyota Kluger GXL Auto eFour","2018 Toyota Kluger GXL Auto 2WD","2021 Toyota Kluger GX Auto eFour","2015 Toyota Kluger GXL Auto 2WD","2021 Toyota Kluger Grande Auto eFour","2009 Toyota Kluger KX-S Auto AWD","2021 Toyota Kluger GX Auto 2WD","2022 Toyota Kluger GX Auto eFour","2018 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger GX Auto eFour","2018 Toyota Kluger GX Auto 2WD","2013 Toyota Kluger KX-S Auto AWD","2022 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger GXL Auto 2WD","2022 Toyota Kluger GX Auto 2WD","2018 Toyota Kluger GXL Auto AWD","2021 Toyota Kluger GX Auto 2WD","2022 Toyota Kluger GXL Auto eFour","2019 Toyota Kluger GX Auto 2WD","2016 Toyota Kluger GX Auto 2WD","2017 Toyota Kluger Grande Auto AWD","2013 Toyota Kluger Altitude Auto 2WD","2008 Toyota Kluger KX-R Auto 2WD","2017 Toyota Kluger GX Auto 2WD","2022 Toyota Kluger Grande Auto AWD","2004 Toyota Kluger CVX Auto AWD","2018 Toyota Kluger Grande Auto AWD","2018 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger Grande Auto 2WD","2009 Toyota Kluger KX-R Auto 2WD","2010 Toyota Kluger Grande Auto AWD MY11","2008 Toyota Kluger KX-S Auto AWD","2015 Toyota Kluger Grande Auto AWD","2022 Toyota Kluger GX Auto AWD","2010 Toyota Kluger Grande Auto AWD MY11","2010 Toyota Kluger KX-R Auto 2WD","2022 Toyota Kluger Grande Auto 2WD","2017 Toyota Kluger Grande Auto 2WD","2016 Toyota Kluger GX Auto AWD","2022 Toyota Kluger Grande Auto AWD","2021 Toyota Kluger GX Auto eFour","2015 Toyota Kluger GXL Auto 2WD","2018 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger GXL Auto AWD","2015 Toyota Kluger GXL Auto AWD","2011 Toyota Kluger KX-R Auto 2WD MY11","2021 Toyota Kluger GX Auto eFour","2014 Toyota Kluger GXL Auto 2WD","2009 Toyota Kluger Altitude Auto AWD","2019 Toyota Kluger GX Auto 2WD","2023 Toyota Kluger Grande Auto eFour","2019 Toyota Kluger Black Edition Auto 2WD","2014 Toyota Kluger Grande Auto 2WD","2018 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GX Auto 2WD","2016 Toyota Kluger Grande Auto 2WD","2010 Toyota Kluger KX-R Auto AWD","2018 Toyota Kluger GXL Auto AWD","2017 Toyota Kluger GX Auto 2WD","2017 Toyota Kluger GX Auto AWD","2019 Toyota Kluger Black Edition Auto AWD","2011 Toyota Kluger KX-S Auto AWD MY11","2019 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger GX Auto AWD","2021 Toyota Kluger GX Auto 2WD","2015 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger Black Edition Auto 2WD","2010 Toyota Kluger KX-R Auto 2WD","2017 Toyota Kluger GXL Auto AWD","2013 Toyota Kluger KX-R Auto AWD","2016 Toyota Kluger GXL Auto AWD","2021 Toyota Kluger Grande Auto AWD","2022 Toyota Kluger Grande Auto eFour","2019 Toyota Kluger GXL Auto AWD","2019 Toyota Kluger GXL Auto AWD","2023 Toyota Kluger GXL Auto eFour","2013 Toyota Kluger Altitude Auto 2WD","2009 Toyota Kluger Grande Auto 2WD","2016 Toyota Kluger Grande Auto AWD","2017 Toyota Kluger GXL Auto AWD","2016 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger GXL Auto 2WD","2016 Toyota Kluger GXL Auto 2WD","2023 Toyota Kluger GXL Auto eFour","2021 Toyota Kluger Grande Auto eFour","2016 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger GX Auto 2WD","2009 Toyota Kluger KX-S Auto 2WD","2014 Toyota Kluger GX Auto AWD","2019 Toyota Kluger GX Auto AWD","2015 Toyota Kluger GXL Auto 2WD","2018 Toyota Kluger GX Auto 2WD","2012 Toyota Kluger KX-R Auto 2WD MY12","2019 Toyota Kluger Grande Auto AWD","2017 Toyota Kluger GXL Auto 2WD","2022 Toyota Kluger GXL Auto eFour","2021 Toyota Kluger Grande Auto 2WD","2018 Toyota Kluger GXL Auto 2WD","2022 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger GX Auto AWD","2015 Toyota Kluger Grande Auto 2WD","2018 Toyota Kluger GXL Auto AWD","2014 Toyota Kluger Grande Auto AWD","2018 Toyota Kluger GX Auto 2WD","2016 Toyota Kluger GX Auto 2WD","2018 Toyota Kluger GXL Auto AWD","2019 Toyota Kluger GXL Auto AWD","2014 Toyota Kluger GXL Auto AWD","2011 Toyota Kluger Grande Auto 2WD MY11","2015 Toyota Kluger Grande Auto 2WD","2005 Toyota Kluger CVX Auto AWD","2018 Toyota Kluger Grande Auto 2WD","2021 Toyota Kluger GXL Auto eFour","2019 Toyota Kluger GXL Auto 2WD","2017 Toyota Kluger GX Auto 2WD","2017 Toyota Kluger Grande Auto 2WD","2021 Toyota Kluger Grande Auto AWD","2016 Toyota Kluger GXL Auto 2WD","2023 Toyota Kluger GX Auto eFour","2016 Toyota Kluger GX Auto 2WD","2008 Toyota Kluger KX-R Auto AWD","2015 Toyota Kluger Grande Auto AWD","2015 Toyota Kluger GX Auto 2WD","2018 Toyota Kluger Grande Auto AWD","2015 Toyota Kluger GX Auto 2WD","2022 Toyota Kluger GX Auto eFour","2019 Toyota Kluger GXL Auto 2WD","2013 Toyota Kluger Grande Auto AWD","2018 Toyota Kluger GX Auto 2WD","2013 Toyota Kluger KX-R Auto 2WD","2017 Toyota Kluger GX Auto AWD","2009 Toyota Kluger KX-S Auto AWD","2023 Toyota Kluger GX Auto eFour","2021 Toyota Kluger GXL Auto eFour","2022 Toyota Kluger GX Auto eFour","2022 Toyota Kluger Grande Auto eFour","2019 Toyota Kluger GXL Auto AWD","2015 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger GXL Auto AWD","2021 Toyota Kluger Grande Auto 2WD","2021 Toyota Kluger GXL Auto eFour","2013 Toyota Kluger KX-R Auto 2WD","2021 Toyota Kluger GXL Auto 2WD","2011 Toyota Kluger Grande Auto 2WD MY11","2021 Toyota Kluger GX Auto eFour","2011 Toyota Kluger KX-R Auto AWD MY11","2018 Toyota Kluger GX Auto AWD","2015 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger Grande Auto eFour","2019 Toyota Kluger Grande Auto AWD"],"odometer":[32726,50339,110102,158213,83836,95913,105586,106000,132765,257852,25546,218243,220852,11500,42082,18987,191500,127000,43589,82713,89866,192000,143349,344122,17280,60985,11,100589,113000,102000,197895,49603,55198,118917,70412,285005,210500,75000,78244,87470,118104,160942,325000,15499,175741,41044,62950,34277,128613,45600,229700,32945,22000,64223,49756,81941,58024,223767,10702,61525,6602,96026,42934,18,77317,70376,95310,168124,259618,62050,20543,299414,119000,140363,26898,224000,169515,330000,105702,5400,182000,226831,19203,77148,165828,2800,47988,122577,123192,35560,156000,111000,141046,167850,21415,122940,169560,37463,100,71304,107000,119591,79339,34508,82698,277000,22506,84000,108102,84924,203998,68544,75286,27963,22118,48459,175121,78291,110000,128000,19068,13936,48378,97006,571,138122,289000,59319,45161,154603,39850,94595,105,7500,58700,20094,86711,227415,246192,89740,131000,93903,145771,58057,118000,32500,16038,120772,11221,51970,142613,55629,147500,60341,56500,67560,77869,165221,285000,90000,241710,111850,53257,86865,107728,109021,23000,123330,1946,156406,345220,100346,97000,127123,195000,24697,110503,176716,78591,115458,113880,286010,50,50032,12242,26012,34500,150500,32000,31429,51215,233461,19500,165500,58851,190000,118000,163000,12240,48299],"body":["SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV"],"transmission":["Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic"],"engine":["2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","4cyl 2.4L Turbo Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.3L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.3L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","2.5i/184kW Hybrid","2.5i/184kW Hybrid","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol"],"odometer_Mm":[32.726,50.339,110.102,158.213,83.836,95.913,105.586,106,132.765,257.852,25.546,218.243,220.852,11.5,42.082,18.987,191.5,127,43.589,82.713,89.866,192,143.349,344.122,17.28,60.985,0.011,100.589,113,102,197.895,49.603,55.198,118.917,70.412,285.005,210.5,75,78.244,87.47,118.104,160.942,325,15.499,175.741,41.044,62.95,34.277,128.613,45.6,229.7,32.945,22,64.223,49.756,81.941,58.024,223.767,10.702,61.525,6.602,96.026,42.934,0.018,77.317,70.376,95.31,168.124,259.618,62.05,20.543,299.414,119,140.363,26.898,224,169.515,330,105.702,5.4,182,226.831,19.203,77.148,165.828,2.8,47.988,122.577,123.192,35.56,156,111,141.046,167.85,21.415,122.94,169.56,37.463,0.1,71.304,107,119.591,79.339,34.508,82.698,277,22.506,84,108.102,84.924,203.998,68.544,75.286,27.963,22.118,48.459,175.121,78.291,110,128,19.068,13.936,48.378,97.006,0.571,138.122,289,59.319,45.161,154.603,39.85,94.595,0.105,7.5,58.7,20.094,86.711,227.415,246.192,89.74,131,93.903,145.771,58.057,118,32.5,16.038,120.772,11.221,51.97,142.613,55.629,147.5,60.341,56.5,67.56,77.869,165.221,285,90,241.71,111.85,53.257,86.865,107.728,109.021,23,123.33,1.946,156.406,345.22,100.346,97,127.123,195,24.697,110.503,176.716,78.591,115.458,113.88,286.01,0.05,50.032,12.242,26.012,34.5,150.5,32,31.429,51.215,233.461,19.5,165.5,58.851,190,118,163,12.24,48.299],"year":[2021,2018,2019,2014,2019,2019,2019,2016,2018,2010,2021,2011,2010,2021,2019,2021,2010,2015,2021,2019,2019,2010,2014,2008,2021,2015,2023,2017,2017,2015,2014,2018,2019,2017,2009,2010,2014,2017,2019,2013,2017,2016,2009,2021,2015,2021,2018,2021,2015,2021,2009,2021,2022,2018,2021,2021,2018,2013,2022,2019,2022,2018,2021,2022,2019,2016,2017,2013,2008,2017,2022,2004,2018,2018,2021,2009,2010,2008,2015,2022,2010,2010,2022,2017,2016,2022,2021,2015,2018,2019,2019,2019,2015,2011,2021,2014,2009,2019,2023,2019,2014,2018,2019,2019,2016,2010,2018,2017,2017,2019,2011,2019,2019,2021,2015,2019,2010,2017,2013,2016,2021,2022,2019,2019,2023,2013,2009,2016,2017,2016,2021,2016,2023,2021,2016,2019,2019,2009,2014,2019,2015,2018,2012,2019,2017,2022,2021,2018,2022,2019,2015,2018,2014,2018,2016,2018,2019,2014,2011,2015,2005,2018,2021,2019,2017,2017,2021,2016,2023,2016,2008,2015,2015,2018,2015,2022,2019,2013,2018,2013,2017,2009,2023,2021,2022,2022,2019,2015,2019,2021,2021,2013,2021,2011,2021,2011,2018,2015,2021,2019],"drivetrain":["eFour","2WD","AWD","AWD","2WD","AWD","2WD","AWD","2WD","2WD","AWD","MY11","2WD","AWD","2WD","eFour","2WD","AWD","AWD","2WD","AWD","MY11","2WD","2WD","AWD","2WD","eFour","2WD","AWD","2WD","2WD","AWD","2WD","AWD","2WD","2WD","AWD","2WD","2WD","AWD","2WD","2WD","2WD","2WD","2WD","eFour","2WD","eFour","2WD","eFour","AWD","2WD","eFour","2WD","2WD","eFour","2WD","AWD","2WD","2WD","2WD","AWD","2WD","eFour","2WD","2WD","AWD","2WD","2WD","2WD","AWD","AWD","AWD","2WD","2WD","2WD","MY11","AWD","AWD","AWD","MY11","2WD","2WD","2WD","AWD","AWD","eFour","2WD","2WD","2WD","2WD","AWD","AWD","MY11","eFour","2WD","AWD","2WD","eFour","2WD","2WD","2WD","AWD","2WD","2WD","AWD","AWD","2WD","AWD","AWD","MY11","2WD","AWD","2WD","2WD","2WD","2WD","AWD","AWD","AWD","AWD","eFour","AWD","AWD","eFour","2WD","2WD","AWD","AWD","2WD","2WD","2WD","eFour","eFour","2WD","2WD","2WD","2WD","AWD","AWD","2WD","2WD","MY12","AWD","2WD","eFour","2WD","2WD","2WD","AWD","2WD","AWD","AWD","2WD","2WD","AWD","AWD","AWD","MY11","2WD","AWD","2WD","eFour","2WD","2WD","2WD","AWD","2WD","eFour","2WD","AWD","AWD","2WD","AWD","2WD","eFour","2WD","AWD","2WD","2WD","AWD","AWD","eFour","eFour","eFour","eFour","AWD","2WD","AWD","2WD","eFour","2WD","2WD","MY11","eFour","MY11","AWD","2WD","eFour","AWD"],"model":["GXL","GXL","GX","GX","GX","Black","GX","Grande","GX","Altitude","Grande","KX-S","Altitude","GXL","GX","GX","KX-R","Grande","GXL","GX","GX","KX-R","GXL","KX-R","Grande","GXL","GX","GXL","Grande","Grande","Grande","Grande","GX","GX","KX-R","KX-R","GXL","GX","GX","Grande","GX","GX","KX-R","Grande","Grande","GXL","GXL","GX","GXL","Grande","KX-S","GX","GX","GX","GX","GX","GX","KX-S","GX","GXL","GX","GXL","GX","GXL","GX","GX","Grande","Altitude","KX-R","GX","Grande","CVX","Grande","GX","Grande","KX-R","Grande","KX-S","Grande","GX","Grande","KX-R","Grande","Grande","GX","Grande","GX","GXL","GX","GXL","GXL","GXL","GXL","KX-R","GX","GXL","Altitude","GX","Grande","Black","Grande","GX","Grande","GX","Grande","KX-R","GXL","GX","GX","Black","KX-S","GX","GX","GX","GXL","Black","KX-R","GXL","KX-R","GXL","Grande","Grande","GXL","GXL","GXL","Altitude","Grande","Grande","GXL","GX","GXL","GXL","GXL","Grande","GX","GX","GX","KX-S","GX","GX","GXL","GX","KX-R","Grande","GXL","GXL","Grande","GXL","GX","GX","Grande","GXL","Grande","GX","GX","GXL","GXL","GXL","Grande","Grande","CVX","Grande","GXL","GXL","GX","Grande","Grande","GXL","GX","GX","KX-R","Grande","GX","Grande","GX","GX","GXL","Grande","GX","KX-R","GX","KX-S","GX","GXL","GX","Grande","GXL","GX","GXL","Grande","GXL","KX-R","GXL","Grande","GX","KX-R","GX","GX","Grande","Grande"]},"columns":[{"id":"price","name":"price","type":"numeric","style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","cell":["62999","44999","32880","19999","39990","44877","34990","40000","31950","10999","68500","16990","14800","57000","43990","58990","17000","33000","69990","37990","37990","19999","27990","10990","69950","39990","69777","34999","39000","34500","27990","49990","47990","31990","27900","13250","22999","35000","39990","33000","34990","27997","12500","64500","24388","68888","46990","60999","27000","68490","13400","49880","59999","38990","48990","54990","38999","19800","53990","46990","55990","40990","47880","76990","39990","30990","48990","17990","8800","37999","67990","8995","45000","35990","63970","11000","19990","10000","37990","56950","19888","16990","64880","43900","26950","83699","59999","27999","29999","43990","35500","41000","27990","16000","61990","27999","16990","39990","84980","44970","31000","31989","46990","43989","38990","8000","49999","33000","32390","49988","17490","40990","42990","47999","37990","48888","16990","46999","22500","33000","68888","81477","49990","40990","78600","23950","14400","45000","48990","27490","52990","34990","72690","75000","31000","44990","35999","21995","17980","34990","25750","34900","15600","50990","42000","68000","58990","35888","52990","43990","32995","43888","30990","39990","35500","42888","42990","26399","16488","35500","5600","40996","65990","46990","33990","38990","66994","33990","65990","29990","9990","33990","28900","39990","28000","61990","39490","26990","37888","19800","29500","11000","67950","66990","63990","76880","49990","27000","49999","65990","64990","15990","58500","21990","59990","15500","33000","25500","77000","53888"],"html":true,"align":"right","headerStyle":{"font-weight":"normal"}},{"id":"title","name":"title","type":"character","style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","cell":["2021 Toyota Kluger GXL Auto eFour","2018 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger GX Auto AWD","2014 Toyota Kluger GX Auto AWD","2019 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger Black Edition Auto AWD","2019 Toyota Kluger GX Auto 2WD","2016 Toyota Kluger Grande Auto AWD","2018 Toyota Kluger GX Auto 2WD","2010 Toyota Kluger Altitude Auto 2WD","2021 Toyota Kluger Grande Auto AWD","2011 Toyota Kluger KX-S Auto AWD MY11","2010 Toyota Kluger Altitude Auto 2WD","2021 Toyota Kluger GXL Auto AWD","2019 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger GX Auto eFour","2010 Toyota Kluger KX-R Auto 2WD","2015 Toyota Kluger Grande Auto AWD","2021 Toyota Kluger GXL Auto AWD","2019 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger GX Auto AWD","2010 Toyota Kluger KX-R Auto AWD MY11","2014 Toyota Kluger GXL Auto 2WD","2008 Toyota Kluger KX-R Auto 2WD","2021 Toyota Kluger Grande Auto AWD","2015 Toyota Kluger GXL Auto 2WD","2023 Toyota Kluger GX Auto eFour","2017 Toyota Kluger GXL Auto 2WD","2017 Toyota Kluger Grande Auto AWD","2015 Toyota Kluger Grande Auto 2WD","2014 Toyota Kluger Grande Auto 2WD","2018 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GX Auto 2WD","2017 Toyota Kluger GX Auto AWD","2009 Toyota Kluger KX-R Auto 2WD","2010 Toyota Kluger KX-R Auto 2WD","2014 Toyota Kluger GXL Auto AWD","2017 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger GX Auto 2WD","2013 Toyota Kluger Grande Auto AWD","2017 Toyota Kluger GX Auto 2WD","2016 Toyota Kluger GX Auto 2WD","2009 Toyota Kluger KX-R Auto 2WD","2021 Toyota Kluger Grande Auto 2WD","2015 Toyota Kluger Grande Auto 2WD","2021 Toyota Kluger GXL Auto eFour","2018 Toyota Kluger GXL Auto 2WD","2021 Toyota Kluger GX Auto eFour","2015 Toyota Kluger GXL Auto 2WD","2021 Toyota Kluger Grande Auto eFour","2009 Toyota Kluger KX-S Auto AWD","2021 Toyota Kluger GX Auto 2WD","2022 Toyota Kluger GX Auto eFour","2018 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger GX Auto eFour","2018 Toyota Kluger GX Auto 2WD","2013 Toyota Kluger KX-S Auto AWD","2022 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger GXL Auto 2WD","2022 Toyota Kluger GX Auto 2WD","2018 Toyota Kluger GXL Auto AWD","2021 Toyota Kluger GX Auto 2WD","2022 Toyota Kluger GXL Auto eFour","2019 Toyota Kluger GX Auto 2WD","2016 Toyota Kluger GX Auto 2WD","2017 Toyota Kluger Grande Auto AWD","2013 Toyota Kluger Altitude Auto 2WD","2008 Toyota Kluger KX-R Auto 2WD","2017 Toyota Kluger GX Auto 2WD","2022 Toyota Kluger Grande Auto AWD","2004 Toyota Kluger CVX Auto AWD","2018 Toyota Kluger Grande Auto AWD","2018 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger Grande Auto 2WD","2009 Toyota Kluger KX-R Auto 2WD","2010 Toyota Kluger Grande Auto AWD MY11","2008 Toyota Kluger KX-S Auto AWD","2015 Toyota Kluger Grande Auto AWD","2022 Toyota Kluger GX Auto AWD","2010 Toyota Kluger Grande Auto AWD MY11","2010 Toyota Kluger KX-R Auto 2WD","2022 Toyota Kluger Grande Auto 2WD","2017 Toyota Kluger Grande Auto 2WD","2016 Toyota Kluger GX Auto AWD","2022 Toyota Kluger Grande Auto AWD","2021 Toyota Kluger GX Auto eFour","2015 Toyota Kluger GXL Auto 2WD","2018 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger GXL Auto AWD","2015 Toyota Kluger GXL Auto AWD","2011 Toyota Kluger KX-R Auto 2WD MY11","2021 Toyota Kluger GX Auto eFour","2014 Toyota Kluger GXL Auto 2WD","2009 Toyota Kluger Altitude Auto AWD","2019 Toyota Kluger GX Auto 2WD","2023 Toyota Kluger Grande Auto eFour","2019 Toyota Kluger Black Edition Auto 2WD","2014 Toyota Kluger Grande Auto 2WD","2018 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GX Auto 2WD","2016 Toyota Kluger Grande Auto 2WD","2010 Toyota Kluger KX-R Auto AWD","2018 Toyota Kluger GXL Auto AWD","2017 Toyota Kluger GX Auto 2WD","2017 Toyota Kluger GX Auto AWD","2019 Toyota Kluger Black Edition Auto AWD","2011 Toyota Kluger KX-S Auto AWD MY11","2019 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger GX Auto AWD","2021 Toyota Kluger GX Auto 2WD","2015 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger Black Edition Auto 2WD","2010 Toyota Kluger KX-R Auto 2WD","2017 Toyota Kluger GXL Auto AWD","2013 Toyota Kluger KX-R Auto AWD","2016 Toyota Kluger GXL Auto AWD","2021 Toyota Kluger Grande Auto AWD","2022 Toyota Kluger Grande Auto eFour","2019 Toyota Kluger GXL Auto AWD","2019 Toyota Kluger GXL Auto AWD","2023 Toyota Kluger GXL Auto eFour","2013 Toyota Kluger Altitude Auto 2WD","2009 Toyota Kluger Grande Auto 2WD","2016 Toyota Kluger Grande Auto AWD","2017 Toyota Kluger GXL Auto AWD","2016 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger GXL Auto 2WD","2016 Toyota Kluger GXL Auto 2WD","2023 Toyota Kluger GXL Auto eFour","2021 Toyota Kluger Grande Auto eFour","2016 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger GX Auto 2WD","2009 Toyota Kluger KX-S Auto 2WD","2014 Toyota Kluger GX Auto AWD","2019 Toyota Kluger GX Auto AWD","2015 Toyota Kluger GXL Auto 2WD","2018 Toyota Kluger GX Auto 2WD","2012 Toyota Kluger KX-R Auto 2WD MY12","2019 Toyota Kluger Grande Auto AWD","2017 Toyota Kluger GXL Auto 2WD","2022 Toyota Kluger GXL Auto eFour","2021 Toyota Kluger Grande Auto 2WD","2018 Toyota Kluger GXL Auto 2WD","2022 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger GX Auto AWD","2015 Toyota Kluger Grande Auto 2WD","2018 Toyota Kluger GXL Auto AWD","2014 Toyota Kluger Grande Auto AWD","2018 Toyota Kluger GX Auto 2WD","2016 Toyota Kluger GX Auto 2WD","2018 Toyota Kluger GXL Auto AWD","2019 Toyota Kluger GXL Auto AWD","2014 Toyota Kluger GXL Auto AWD","2011 Toyota Kluger Grande Auto 2WD MY11","2015 Toyota Kluger Grande Auto 2WD","2005 Toyota Kluger CVX Auto AWD","2018 Toyota Kluger Grande Auto 2WD","2021 Toyota Kluger GXL Auto eFour","2019 Toyota Kluger GXL Auto 2WD","2017 Toyota Kluger GX Auto 2WD","2017 Toyota Kluger Grande Auto 2WD","2021 Toyota Kluger Grande Auto AWD","2016 Toyota Kluger GXL Auto 2WD","2023 Toyota Kluger GX Auto eFour","2016 Toyota Kluger GX Auto 2WD","2008 Toyota Kluger KX-R Auto AWD","2015 Toyota Kluger Grande Auto AWD","2015 Toyota Kluger GX Auto 2WD","2018 Toyota Kluger Grande Auto AWD","2015 Toyota Kluger GX Auto 2WD","2022 Toyota Kluger GX Auto eFour","2019 Toyota Kluger GXL Auto 2WD","2013 Toyota Kluger Grande Auto AWD","2018 Toyota Kluger GX Auto 2WD","2013 Toyota Kluger KX-R Auto 2WD","2017 Toyota Kluger GX Auto AWD","2009 Toyota Kluger KX-S Auto AWD","2023 Toyota Kluger GX Auto eFour","2021 Toyota Kluger GXL Auto eFour","2022 Toyota Kluger GX Auto eFour","2022 Toyota Kluger Grande Auto eFour","2019 Toyota Kluger GXL Auto AWD","2015 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger GXL Auto AWD","2021 Toyota Kluger Grande Auto 2WD","2021 Toyota Kluger GXL Auto eFour","2013 Toyota Kluger KX-R Auto 2WD","2021 Toyota Kluger GXL Auto 2WD","2011 Toyota Kluger Grande Auto 2WD MY11","2021 Toyota Kluger GX Auto eFour","2011 Toyota Kluger KX-R Auto AWD MY11","2018 Toyota Kluger GX Auto AWD","2015 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger Grande Auto eFour","2019 Toyota Kluger Grande Auto AWD"],"html":true,"align":"left","headerStyle":{"font-weight":"normal"}},{"id":"odometer","name":"odometer","type":"numeric","style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","cell":["32726","50339","110102","158213","83836","95913","105586","106000","132765","257852","25546","218243","220852","11500","42082","18987","191500","127000","43589","82713","89866","192000","143349","344122","17280","60985","11","100589","113000","102000","197895","49603","55198","118917","70412","285005","210500","75000","78244","87470","118104","160942","325000","15499","175741","41044","62950","34277","128613","45600","229700","32945","22000","64223","49756","81941","58024","223767","10702","61525","6602","96026","42934","18","77317","70376","95310","168124","259618","62050","20543","299414","119000","140363","26898","224000","169515","330000","105702","5400","182000","226831","19203","77148","165828","2800","47988","122577","123192","35560","156000","111000","141046","167850","21415","122940","169560","37463","100","71304","107000","119591","79339","34508","82698","277000","22506","84000","108102","84924","203998","68544","75286","27963","22118","48459","175121","78291","110000","128000","19068","13936","48378","97006","571","138122","289000","59319","45161","154603","39850","94595","105","7500","58700","20094","86711","227415","246192","89740","131000","93903","145771","58057","118000","32500","16038","120772","11221","51970","142613","55629","147500","60341","56500","67560","77869","165221","285000","90000","241710","111850","53257","86865","107728","109021","23000","123330","1946","156406","345220","100346","97000","127123","195000","24697","110503","176716","78591","115458","113880","286010","50","50032","12242","26012","34500","150500","32000","31429","51215","233461","19500","165500","58851","190000","118000","163000","12240","48299"],"html":true,"align":"right","headerStyle":{"font-weight":"normal"}},{"id":"body","name":"body","type":"character","style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","cell":["SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV"],"html":true,"align":"left","headerStyle":{"font-weight":"normal"}},{"id":"transmission","name":"transmission","type":"character","style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","cell":["Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic"],"html":true,"align":"left","headerStyle":{"font-weight":"normal"}},{"id":"engine","name":"engine","type":"character","style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","cell":["2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","4cyl 2.4L Turbo Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.3L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.3L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","2.5i/184kW Hybrid","2.5i/184kW Hybrid","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol"],"html":true,"align":"left","headerStyle":{"font-weight":"normal"}},{"id":"odometer_Mm","name":"odometer_Mm","type":"numeric","style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","cell":["32.726","50.339","110.102","158.213","83.836","95.913","105.586","106.000","132.765","257.852","25.546","218.243","220.852","11.500","42.082","18.987","191.500","127.000","43.589","82.713","89.866","192.000","143.349","344.122","17.280","60.985","0.011","100.589","113.000","102.000","197.895","49.603","55.198","118.917","70.412","285.005","210.500","75.000","78.244","87.470","118.104","160.942","325.000","15.499","175.741","41.044","62.950","34.277","128.613","45.600","229.700","32.945","22.000","64.223","49.756","81.941","58.024","223.767","10.702","61.525","6.602","96.026","42.934","0.018","77.317","70.376","95.310","168.124","259.618","62.050","20.543","299.414","119.000","140.363","26.898","224.000","169.515","330.000","105.702","5.400","182.000","226.831","19.203","77.148","165.828","2.800","47.988","122.577","123.192","35.560","156.000","111.000","141.046","167.850","21.415","122.940","169.560","37.463","0.100","71.304","107.000","119.591","79.339","34.508","82.698","277.000","22.506","84.000","108.102","84.924","203.998","68.544","75.286","27.963","22.118","48.459","175.121","78.291","110.000","128.000","19.068","13.936","48.378","97.006","0.571","138.122","289.000","59.319","45.161","154.603","39.850","94.595","0.105","7.500","58.700","20.094","86.711","227.415","246.192","89.740","131.000","93.903","145.771","58.057","118.000","32.500","16.038","120.772","11.221","51.970","142.613","55.629","147.500","60.341","56.500","67.560","77.869","165.221","285.000","90.000","241.710","111.850","53.257","86.865","107.728","109.021","23.000","123.330","1.946","156.406","345.220","100.346","97.000","127.123","195.000","24.697","110.503","176.716","78.591","115.458","113.880","286.010","0.050","50.032","12.242","26.012","34.500","150.500","32.000","31.429","51.215","233.461","19.500","165.500","58.851","190.000","118.000","163.000","12.240","48.299"],"html":true,"align":"right","headerStyle":{"font-weight":"normal"}},{"id":"year","name":"year","type":"numeric","style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","cell":["2021","2018","2019","2014","2019","2019","2019","2016","2018","2010","2021","2011","2010","2021","2019","2021","2010","2015","2021","2019","2019","2010","2014","2008","2021","2015","2023","2017","2017","2015","2014","2018","2019","2017","2009","2010","2014","2017","2019","2013","2017","2016","2009","2021","2015","2021","2018","2021","2015","2021","2009","2021","2022","2018","2021","2021","2018","2013","2022","2019","2022","2018","2021","2022","2019","2016","2017","2013","2008","2017","2022","2004","2018","2018","2021","2009","2010","2008","2015","2022","2010","2010","2022","2017","2016","2022","2021","2015","2018","2019","2019","2019","2015","2011","2021","2014","2009","2019","2023","2019","2014","2018","2019","2019","2016","2010","2018","2017","2017","2019","2011","2019","2019","2021","2015","2019","2010","2017","2013","2016","2021","2022","2019","2019","2023","2013","2009","2016","2017","2016","2021","2016","2023","2021","2016","2019","2019","2009","2014","2019","2015","2018","2012","2019","2017","2022","2021","2018","2022","2019","2015","2018","2014","2018","2016","2018","2019","2014","2011","2015","2005","2018","2021","2019","2017","2017","2021","2016","2023","2016","2008","2015","2015","2018","2015","2022","2019","2013","2018","2013","2017","2009","2023","2021","2022","2022","2019","2015","2019","2021","2021","2013","2021","2011","2021","2011","2018","2015","2021","2019"],"html":true,"align":"right","headerStyle":{"font-weight":"normal"}},{"id":"drivetrain","name":"drivetrain","type":"character","style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","cell":["eFour","2WD","AWD","AWD","2WD","AWD","2WD","AWD","2WD","2WD","AWD","MY11","2WD","AWD","2WD","eFour","2WD","AWD","AWD","2WD","AWD","MY11","2WD","2WD","AWD","2WD","eFour","2WD","AWD","2WD","2WD","AWD","2WD","AWD","2WD","2WD","AWD","2WD","2WD","AWD","2WD","2WD","2WD","2WD","2WD","eFour","2WD","eFour","2WD","eFour","AWD","2WD","eFour","2WD","2WD","eFour","2WD","AWD","2WD","2WD","2WD","AWD","2WD","eFour","2WD","2WD","AWD","2WD","2WD","2WD","AWD","AWD","AWD","2WD","2WD","2WD","MY11","AWD","AWD","AWD","MY11","2WD","2WD","2WD","AWD","AWD","eFour","2WD","2WD","2WD","2WD","AWD","AWD","MY11","eFour","2WD","AWD","2WD","eFour","2WD","2WD","2WD","AWD","2WD","2WD","AWD","AWD","2WD","AWD","AWD","MY11","2WD","AWD","2WD","2WD","2WD","2WD","AWD","AWD","AWD","AWD","eFour","AWD","AWD","eFour","2WD","2WD","AWD","AWD","2WD","2WD","2WD","eFour","eFour","2WD","2WD","2WD","2WD","AWD","AWD","2WD","2WD","MY12","AWD","2WD","eFour","2WD","2WD","2WD","AWD","2WD","AWD","AWD","2WD","2WD","AWD","AWD","AWD","MY11","2WD","AWD","2WD","eFour","2WD","2WD","2WD","AWD","2WD","eFour","2WD","AWD","AWD","2WD","AWD","2WD","eFour","2WD","AWD","2WD","2WD","AWD","AWD","eFour","eFour","eFour","eFour","AWD","2WD","AWD","2WD","eFour","2WD","2WD","MY11","eFour","MY11","AWD","2WD","eFour","AWD"],"html":true,"align":"left","headerStyle":{"font-weight":"normal"}},{"id":"model","name":"model","type":"character","style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","cell":["GXL","GXL","GX","GX","GX","Black","GX","Grande","GX","Altitude","Grande","KX-S","Altitude","GXL","GX","GX","KX-R","Grande","GXL","GX","GX","KX-R","GXL","KX-R","Grande","GXL","GX","GXL","Grande","Grande","Grande","Grande","GX","GX","KX-R","KX-R","GXL","GX","GX","Grande","GX","GX","KX-R","Grande","Grande","GXL","GXL","GX","GXL","Grande","KX-S","GX","GX","GX","GX","GX","GX","KX-S","GX","GXL","GX","GXL","GX","GXL","GX","GX","Grande","Altitude","KX-R","GX","Grande","CVX","Grande","GX","Grande","KX-R","Grande","KX-S","Grande","GX","Grande","KX-R","Grande","Grande","GX","Grande","GX","GXL","GX","GXL","GXL","GXL","GXL","KX-R","GX","GXL","Altitude","GX","Grande","Black","Grande","GX","Grande","GX","Grande","KX-R","GXL","GX","GX","Black","KX-S","GX","GX","GX","GXL","Black","KX-R","GXL","KX-R","GXL","Grande","Grande","GXL","GXL","GXL","Altitude","Grande","Grande","GXL","GX","GXL","GXL","GXL","Grande","GX","GX","GX","KX-S","GX","GX","GXL","GX","KX-R","Grande","GXL","GXL","Grande","GXL","GX","GX","Grande","GXL","Grande","GX","GX","GXL","GXL","GXL","Grande","Grande","CVX","Grande","GXL","GXL","GX","Grande","Grande","GXL","GX","GX","KX-R","Grande","GX","Grande","GX","GX","GXL","Grande","GX","KX-R","GX","KX-S","GX","GXL","GX","Grande","GXL","GX","GXL","Grande","GXL","KX-R","GXL","Grande","GX","KX-R","GX","GX","Grande","Grande"],"html":true,"align":"left","headerStyle":{"font-weight":"normal"}}],"defaultPageSize":10,"showPageSizeOptions":false,"pageSizeOptions":[10,25,50,100],"paginationType":"numbers","showPagination":true,"showPageInfo":true,"minRows":1,"showSortable":true,"height":"auto","theme":{"color":"#333333","backgroundColor":"#FFFFFF","stripedColor":"rgba(128,128,128,0.05)","style":{"fontFamily":"system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif"},"headerStyle":{"borderTopStyle":"solid","borderTopWidth":"2px","borderTopColor":"#D3D3D3","borderBottomStyle":"solid","borderBottomWidth":"2px","borderBottomColor":"#D3D3D3"}},"elementId":"lbpescdidb","dataKey":"6dbd3da97a0af465da5ac3b78a9a77b8"},"children":[]},"class":"reactR_markup"},"evals":["tag.attribs.columns.0.style","tag.attribs.columns.1.style","tag.attribs.columns.2.style","tag.attribs.columns.3.style","tag.attribs.columns.4.style","tag.attribs.columns.5.style","tag.attribs.columns.6.style","tag.attribs.columns.7.style","tag.attribs.columns.8.style","tag.attribs.columns.9.style"],"jsHooks":[]}</script>
</div>

# Taking a Quick Look

Let’s visualise key features of the data. First up we’ll, how does the market price for a Kluger change as the odometers (in megametres):

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-12-1.png" width="672" />
The thing I notice is that looks suspiciously like there’s some sort of negative exponential relationship between the the odometer and price. What if we take a look at the odometer versus the log of the price?

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-13-1.png" width="672" />
There’s some good news, and some bad news here. With the log transform we’ve now got a linear relationship between the number odometer of the car and the price. This is going to allow us to fit a nice, simple linear model to the data.

The bad news is that the data varies significantly (heteroskedacticity) across the odometer ranges. This won’t affect our linear model, but will likely affect the prediction capability of our model. We’ll persevere nonetheless.

The log transform provides a nice interpretation for the slope of this line. Recall that in general when you fit a line to x and y, the slope (\\beta\\) of that line is “the change in the y variable given a change of one unit of the x variable”. When you fit a line to to x and log(y) (called log-linear), for small \\\\, \\e^\\ is the percentage change in y for a one unit change of x.

Here’s the same view, but we split it out by model:

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-14-1.png" width="672" />

# Modelling

Let’s start by thinking about the generative model of the price. Our observed variables odometer, year, model, and drivetrain are likely going to have an affect on price. There are some unobserved variables, such as the condition of the car its popularity that would also have an affect. There’s some [confounds](https://en.wikipedia.org/wiki/Confounding) that may need to be dealt with as well: year directly affects price, but also affects through the odometer (older cards are more likely to have more kilometres). Model affects price, but also affects through the drivetrain (certain models have certain drivetrains).

The best way to visualise this is using the directed acyclic graph (DAG):

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-15-1.png" width="672" />
While I do have these variables available to me, I’d like to start with the most simple modelcan: log of the price predicted by the odometer (in megametres). In doing this I’m leaving a lot of variability on the table, so the model’s ability to predict is likely going to be hampered. But better to start simple a build up (also leaves the door open for follow-up articles).

At this point I could rip our a standard linear regression, get the coefficients and *bang* we’re done. But where’s the sport in that? Instead, I’ll use this as an opportunity to model this in a Bayesian manner.

# Bayesian Modeling

I’m going to be using [Stan](https://mc-stan.org/) to perform the statistical modelling, executing it from R using the [cmdstanr](https://mc-stan.org/cmdstanr/) package. Here’s the program I’ve written:

    data {
        int<lower=0> n;
        vector[n] odometer_Mm;
        vector[n] price;
    }
    parameters {
        real a;
        real b;
        real<lower=0> sigma;
    }
    model {
        log(price) ~ normal(a + b * odometer_Mm, sigma);
    }    
    generated quantities {
        array[n] real y_s = normal_rng(a + b * odometer_Mm, sigma);
        
        real price_pred = exp( normal_rng(a + b * 60, sigma) );
    }

It should be relatively easy to read: the data is our observed odometer (in megametres) and price, the parameters we’re looking to find are *a* (for alpha, the intercept), *b* (for beta, the slope), and *sigma* (our variance). I’m pretty sure the slope is going

The generated values helps us with prediction. For each of our *n* ovbservations the model is run with the parameters drawn out of the posterior distribution and the results stored in *y_s*. This allows us to compare what our model thinks is are resonable outcomes and help us determine how well the model performs. The *price_pred* is the prediction at 60,000km, which was the reading on the odometer of my car that was written off.

Let’s run the model with the data:

``` r
kluger_fit <- kluger_model$sample(
    data = compose_data(kluger_data),
    seed = 123,
    chains = 4,
    parallel_chains = 4,
    refresh = 500,
)
```

    Running MCMC with 4 parallel chains...

    Chain 1 Iteration:    1 / 2000 [  0%]  (Warmup) 
    Chain 2 Iteration:    1 / 2000 [  0%]  (Warmup) 
    Chain 3 Iteration:    1 / 2000 [  0%]  (Warmup) 
    Chain 4 Iteration:    1 / 2000 [  0%]  (Warmup) 
    Chain 2 Iteration:  500 / 2000 [ 25%]  (Warmup) 
    Chain 3 Iteration:  500 / 2000 [ 25%]  (Warmup) 
    Chain 1 Iteration:  500 / 2000 [ 25%]  (Warmup) 
    Chain 4 Iteration:  500 / 2000 [ 25%]  (Warmup) 
    Chain 2 Iteration: 1000 / 2000 [ 50%]  (Warmup) 
    Chain 2 Iteration: 1001 / 2000 [ 50%]  (Sampling) 
    Chain 3 Iteration: 1000 / 2000 [ 50%]  (Warmup) 
    Chain 3 Iteration: 1001 / 2000 [ 50%]  (Sampling) 
    Chain 4 Iteration: 1000 / 2000 [ 50%]  (Warmup) 
    Chain 4 Iteration: 1001 / 2000 [ 50%]  (Sampling) 
    Chain 1 Iteration: 1000 / 2000 [ 50%]  (Warmup) 
    Chain 1 Iteration: 1001 / 2000 [ 50%]  (Sampling) 
    Chain 2 Iteration: 1500 / 2000 [ 75%]  (Sampling) 
    Chain 3 Iteration: 1500 / 2000 [ 75%]  (Sampling) 
    Chain 4 Iteration: 1500 / 2000 [ 75%]  (Sampling) 
    Chain 1 Iteration: 1500 / 2000 [ 75%]  (Sampling) 
    Chain 2 Iteration: 2000 / 2000 [100%]  (Sampling) 
    Chain 2 finished in 3.6 seconds.
    Chain 3 Iteration: 2000 / 2000 [100%]  (Sampling) 
    Chain 3 finished in 3.9 seconds.
    Chain 4 Iteration: 2000 / 2000 [100%]  (Sampling) 
    Chain 4 finished in 4.5 seconds.
    Chain 1 Iteration: 2000 / 2000 [100%]  (Sampling) 
    Chain 1 finished in 4.9 seconds.

    All 4 chains finished successfully.
    Mean chain execution time: 4.2 seconds.
    Total execution time: 5.0 seconds.

# Assessing the Model

We want to take a look at the resulting parameters and make sure they’re reasonable. First up is a histogram of the posterior distributions of each of the parameters.

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-20-1.png" width="672" />
This looks good, each looks Gaussian in shape, and each of the chains has a similar view of the posterior distribution. A related check is the *trace plot*. We want these to look like “fuzzy caterpillars”, shows that each chain is exploring the distribution in a similar way, and isn’t wandering off on its own for too long.
<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-21-1.png" width="672" />
So we’re reasonably confident that all of the chains have converged, let’s take a look at how the distribution of parameters looks over our observations. We’re not dealing with point estimates as we would with a linear regression. Instead we’ve got a distribution of plausible intercepts and slopes. One way to visualise this is to plot each line from the distribution, colouring it with its distance from the mean.

![](index_files/figure-html/unnamed-chunk-22-1.gif)<!-- -->
But plotting each of the draws from the posterior distribution, what we end up getting is a view of the confidence interval of the intercept and slope parameters. The good news here is that the distribution is not very wide (which we saw in the histograms above). Looking at the 89% interval of the slope parameter we see it’s between -0.0064036 and -0.0061194. Exponentiating this to get percent change gives us 0.9936169 and 0.9936169.

The bad news is news we really already knew - the variance around our line is very large and it changes as the odometer value changes. A check for this is posterior prediction, which uses the *generated values* section from our Stan program. That section generated log(price) values based on the linear model, using parameters pulled from the posterior distribution. What we want to see is, using random data, how close to the real observations is our generated model?

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-23-1.png" width="672" />
So while our parmaeters for the linear model look good, the linear model is not great. At odometer values close to zero it’s too conservative, with the all the prices falling well inside our prediced bands in light blue. At the other end of the scale the model is too conservative, with many of the real overservations falling outside of our predictive bands.

Despite this, let’s see where we ended up with the question at hand: “what is the market sell price for a Toyota Kluger with 60,000kms on the odometer?” We use the results of the *generated values* section, with parameters drawn from the posterior distribution but this time fixing the odometer reading at 60 megametres. Here’s the resulting distribution of prices with an 89% confidence interval (5.5% and 94.5% quaniles):

``` r
kluger_quantile <-
    kluger_fit |>
    spread_draws(price_pred) |>
    reframe(
        interval = c(.055, .945),
        value = quantile(price_pred, interval)
    ) |>
    spread(interval, value)

kluger_fit |>
    recover_types() |>
    spread_draws(price_pred) |>
    ggplot() +
    geom_histogram(aes(price_pred), bins = 200) +
    geom_vline(xintercept = kluger_quantile[['0.055']], color = 'blue', linewidth = 1, linetype = 'dotted') +
    geom_vline(xintercept = kluger_quantile[['0.945']], color = 'blue', linewidth = 1, linetype = 'dotted') +
    scale_x_continuous(labels = scales::dollar) +
    scale_y_continuous(labels = scales::comma) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) + 
    labs(
        x = "Count",
        y = "Predicted Price ($)",
        title = "Toyota Kluger Price Prediction",
        subtitle = "Distribution of Price Prediction at 60,000km with 89% Quantiles"
    )
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-24-1.png" width="672" />
That’s a large spread, with an 89% interval between \$33,878.97 and \$65,575.44. That’s too large to be of any use to us in validating the market value the insurance company gave me for my car.
