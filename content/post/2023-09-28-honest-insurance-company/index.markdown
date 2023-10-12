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

<div id="fhmbohzcwq" class=".gt_table" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#fhmbohzcwq table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#fhmbohzcwq thead, #fhmbohzcwq tbody, #fhmbohzcwq tfoot, #fhmbohzcwq tr, #fhmbohzcwq td, #fhmbohzcwq th {
  border-style: none;
}
&#10;#fhmbohzcwq p {
  margin: 0;
  padding: 0;
}
&#10;#fhmbohzcwq .gt_table {
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
&#10;#fhmbohzcwq .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#fhmbohzcwq .gt_title {
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
&#10;#fhmbohzcwq .gt_subtitle {
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
&#10;#fhmbohzcwq .gt_heading {
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
&#10;#fhmbohzcwq .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#fhmbohzcwq .gt_col_headings {
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
&#10;#fhmbohzcwq .gt_col_heading {
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
&#10;#fhmbohzcwq .gt_column_spanner_outer {
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
&#10;#fhmbohzcwq .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#fhmbohzcwq .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#fhmbohzcwq .gt_column_spanner {
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
&#10;#fhmbohzcwq .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#fhmbohzcwq .gt_group_heading {
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
&#10;#fhmbohzcwq .gt_empty_group_heading {
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
&#10;#fhmbohzcwq .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#fhmbohzcwq .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#fhmbohzcwq .gt_row {
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
&#10;#fhmbohzcwq .gt_stub {
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
&#10;#fhmbohzcwq .gt_stub_row_group {
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
&#10;#fhmbohzcwq .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#fhmbohzcwq .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#fhmbohzcwq .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#fhmbohzcwq .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#fhmbohzcwq .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#fhmbohzcwq .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#fhmbohzcwq .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#fhmbohzcwq .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#fhmbohzcwq .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#fhmbohzcwq .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#fhmbohzcwq .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#fhmbohzcwq .gt_footnotes {
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
&#10;#fhmbohzcwq .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#fhmbohzcwq .gt_sourcenotes {
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
&#10;#fhmbohzcwq .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#fhmbohzcwq .gt_left {
  text-align: left;
}
&#10;#fhmbohzcwq .gt_center {
  text-align: center;
}
&#10;#fhmbohzcwq .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#fhmbohzcwq .gt_font_normal {
  font-weight: normal;
}
&#10;#fhmbohzcwq .gt_font_bold {
  font-weight: bold;
}
&#10;#fhmbohzcwq .gt_font_italic {
  font-style: italic;
}
&#10;#fhmbohzcwq .gt_super {
  font-size: 65%;
}
&#10;#fhmbohzcwq .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#fhmbohzcwq .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#fhmbohzcwq .gt_indent_1 {
  text-indent: 5px;
}
&#10;#fhmbohzcwq .gt_indent_2 {
  text-indent: 10px;
}
&#10;#fhmbohzcwq .gt_indent_3 {
  text-indent: 15px;
}
&#10;#fhmbohzcwq .gt_indent_4 {
  text-indent: 20px;
}
&#10;#fhmbohzcwq .gt_indent_5 {
  text-indent: 25px;
}
</style>
<div id="fhmbohzcwq" class="reactable html-widget " style="width:auto;height:auto;"></div>
<script type="application/json" data-for="fhmbohzcwq">{"x":{"tag":{"name":"Reactable","attribs":{"data":{"price":["$16,991","$70,970","$83,699","$21,995","$36,990*","$71,850","$34,770","$30,000*","$41,498","$36,888*","$31,989","$43,000*","$24,990*","$10,000*","$38,390*","$39,990*","$65,990","$61,880","$34,995*","$33,000*","$74,950*","$21,719*","$11,000*","$41,990*","$31,444","$73,990","$76,880*","$64,989*","$30,998*","$37,990*","$29,990*","$18,000*","$45,000*","$12,500*","$33,500*","$56,990*","$13,000*","$54,999*","$33,999","$37,900*","$46,990","$55,498","$22,000*","$35,990*","$16,990*","$25,750*","$49,490","$62,990*","$14,995*","$12,995*","$39,990*","$39,000*","$46,990*","$8,000*","$49,990*","$32,990","$26,950*","$31,888","$39,990*","$12,000*","$53,990","$28,990*","$68,500*","$28,999*","$69,990*","$52,990*","$29,995","$43,990","$35,990*","$40,977","$46,990","$36,888*","$34,990*","$46,000*","$46,000*","$35,900*","$37,990*","$27,990*","$37,990*","$77,800*","$68,950*","$25,999","$69,990","$38,000*","$78,990*","$68,888*","$15,990*","$40,990","$43,000*","$11,900*","$25,750*","$40,552","$39,999*","$13,490*","$16,990","$41,990*","$49,888*","$8,400*","$25,990","$38,990*","$40,800","$42,777*","$34,990","$39,980","$35,980*","$19,926*","$58,777","$41,990","$30,000*","$24,880*","$47,000*","$74,910*","$37,490","$60,999","$49,990","$47,950","$37,990*","$37,990*","$33,500*","$67,990*","$53,900*","$28,990*","$24,900*","$69,950","$74,300*","$28,900*","$44,950","$16,990*","$14,800*","$77,970","$38,990","$34,990","$41,989*","$38,500*","$69,990*","$13,400*","$18,500*","$37,990","$27,900*","$21,990*","$37,990*","$16,888*","$35,990*","$44,999","$59,999*","$64,990","$79,000*","$72,895","$66,994*","$67,990","$76,990*","$49,999","$39,990*","$34,490*","$35,500*","$43,990*","$40,990","$18,990","$66,500*","$34,950*","$69,950","$34,490*","$53,990*","$79,968*","$37,990*","$39,990*","$54,990*","$19,888*","$36,990","$49,990","$72,850*","$27,888*","$31,990","$66,990*","$14,800*","$65,989*","$42,888*","$68,000*","$61,990*","$43,990","$25,000*","$19,980*","$41,990*","$67,990","$57,000*","$44,990","$42,990","$39,999*","$61,990*","$34,993*","$59,980*","$25,990*","$49,990","$45,990*","$36,900*","$46,888*","$18,400*","$49,750*","$69,000*","$53,990*"],"title":["2009 Toyota Kluger KX-S Auto 2WD","2021 Toyota Kluger Grande Auto eFour","2022 Toyota Kluger Grande Auto AWD","2009 Toyota Kluger KX-S Auto 2WD","2017 Toyota Kluger GXL Auto 2WD","2021 Toyota Kluger GXL Auto eFour","2017 Toyota Kluger GX Auto AWD","2015 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger Black Edition Auto 2WD","2016 Toyota Kluger Grande Auto AWD","2015 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger Grande Auto AWD","2015 Toyota Kluger GX Auto 2WD","2008 Toyota Kluger KX-S Auto AWD","2018 Toyota Kluger GX Auto AWD","2017 Toyota Kluger GXL Auto AWD","2022 Toyota Kluger GXL Auto AWD","2021 Toyota Kluger Grande Auto 2WD","2014 Toyota Kluger GXL Auto AWD","2017 Toyota Kluger GX Auto 2WD","2022 Toyota Kluger GXL Auto 2WD","2013 Toyota Kluger Grande Auto 2WD","2009 Toyota Kluger KX-R Auto 2WD","2018 Toyota Kluger GXL Auto AWD","2018 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger Grande Auto eFour","2022 Toyota Kluger Grande Auto eFour","2021 Toyota Kluger GXL Auto eFour","2017 Toyota Kluger GX Auto AWD","2016 Toyota Kluger Grande Auto AWD","2016 Toyota Kluger GX Auto 2WD","2011 Toyota Kluger KX-S Auto 2WD MY11","2018 Toyota Kluger Grande Auto AWD","2009 Toyota Kluger KX-R Auto 2WD","2015 Toyota Kluger GXL Auto AWD","2021 Toyota Kluger GX Auto eFour","2012 Toyota Kluger KX-R Auto 2WD MY12","2021 Toyota Kluger GX Auto AWD","2018 Toyota Kluger GX Auto 2WD","2018 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GXL Auto 2WD","2018 Toyota Kluger Grande Auto 2WD","2013 Toyota Kluger KX-R Auto 2WD","2018 Toyota Kluger GX Auto AWD","2010 Toyota Kluger KX-R Auto 2WD","2016 Toyota Kluger GX Auto 2WD","2017 Toyota Kluger Grande Auto AWD","2021 Toyota Kluger GXL Auto eFour","2011 Toyota Kluger Grande Auto AWD MY11","2009 Toyota Kluger KX-R Auto 2WD","2019 Toyota Kluger GX Auto AWD","2017 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GXL Auto AWD","2010 Toyota Kluger KX-R Auto AWD","2021 Toyota Kluger GXL Auto 2WD","2017 Toyota Kluger GXL Auto 2WD","2016 Toyota Kluger GX Auto AWD","2015 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger GX Auto AWD","2010 Toyota Kluger KX-R Auto AWD MY11","2019 Toyota Kluger Black Edition Auto AWD","2015 Toyota Kluger GX Auto AWD","2021 Toyota Kluger Grande Auto AWD","2017 Toyota Kluger GX Auto 2WD","2023 Toyota Kluger GXL Auto AWD","2022 Toyota Kluger GX Auto 2WD","2015 Toyota Kluger GXL Auto 2WD","2018 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger GX Auto 2WD","2018 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger GXL Auto AWD","2019 Toyota Kluger GX Auto AWD","2018 Toyota Kluger GX Auto AWD","2018 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger Grande Auto 2WD","2017 Toyota Kluger GX Auto AWD","2019 Toyota Kluger GX Auto AWD","2015 Toyota Kluger GXL Auto AWD","2018 Toyota Kluger GX Auto AWD","2023 Toyota Kluger GXL Auto eFour","2023 Toyota Kluger GX Auto eFour","2014 Toyota Kluger GX Auto 2WD","2022 Toyota Kluger GXL Auto eFour","2018 Toyota Kluger GXL Auto 2WD","2021 Toyota Kluger Grande Auto eFour","2021 Toyota Kluger Grande Auto AWD","2013 Toyota Kluger KX-R Auto 2WD","2019 Toyota Kluger GXL Auto AWD","2019 Toyota Kluger GXL Auto AWD","2005 Toyota Kluger CV Auto AWD MY06","2015 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger GX Auto 2WD","2017 Toyota Kluger GX Auto AWD","2009 Toyota Kluger KX-S Auto 2WD","2009 Toyota Kluger Altitude Auto AWD","2018 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger GXL Auto AWD","2006 Toyota Kluger CVX Auto AWD MY06","2013 Toyota Kluger Grande Auto 2WD","2018 Toyota Kluger GXL Auto AWD","2014 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger GX Auto AWD","2018 Toyota Kluger GX Auto AWD","2016 Toyota Kluger GX Auto AWD","2014 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GXL Auto 2WD","2015 Toyota Kluger GXL Auto 2WD","2015 Toyota Kluger GX Auto AWD","2019 Toyota Kluger GXL Auto AWD","2021 Toyota Kluger Grande Auto eFour","2019 Toyota Kluger GX Auto AWD","2021 Toyota Kluger GX Auto eFour","2019 Toyota Kluger Black Edition Auto AWD","2019 Toyota Kluger Black Edition Auto 2WD","2015 Toyota Kluger GXL Auto 2WD","2017 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GXL Auto 2WD","2022 Toyota Kluger GX Auto eFour","2021 Toyota Kluger GX Auto eFour","2016 Toyota Kluger GX Auto AWD","2015 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger Grande Auto AWD","2022 Toyota Kluger GXL Auto eFour","2015 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger Black Edition Auto 2WD","2007 Toyota Kluger KX-S Auto AWD","2009 Toyota Kluger Altitude Auto 2WD","2022 Toyota Kluger GXL Auto eFour","2018 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GX Auto AWD","2019 Toyota Kluger GX Auto AWD","2018 Toyota Kluger GXL Auto 2WD","2022 Toyota Kluger GX Auto eFour","2009 Toyota Kluger KX-S Auto AWD","2011 Toyota Kluger Grande Auto 2WD MY11","2017 Toyota Kluger GX Auto AWD","2016 Toyota Kluger GX Auto 2WD","2011 Toyota Kluger Grande Auto 2WD MY11","2019 Toyota Kluger GX Auto AWD","2011 Toyota Kluger KX-R Auto AWD MY11","2016 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger Black Edition Auto 2WD","2019 Toyota Kluger Black Edition Auto 2WD","2023 Toyota Kluger GX Auto 2WD","2022 Toyota Kluger Grande Auto eFour","2022 Toyota Kluger Grande Auto 2WD","2021 Toyota Kluger Grande Auto AWD","2021 Toyota Kluger Grande Auto 2WD","2021 Toyota Kluger Grande Auto eFour","2019 Toyota Kluger GXL Auto AWD","2016 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GX Auto AWD","2015 Toyota Kluger Grande Auto 2WD","2019 Toyota Kluger GXL Auto 2WD","2016 Toyota Kluger Grande Auto 2WD","2011 Toyota Kluger KX-R Auto 2WD MY11","2021 Toyota Kluger GXL Auto eFour","2017 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger GXL Auto eFour","2014 Toyota Kluger GXL Auto AWD","2022 Toyota Kluger GX Auto 2WD","2022 Toyota Kluger Grande Auto eFour","2016 Toyota Kluger GXL Auto AWD","2018 Toyota Kluger GX Auto AWD","2022 Toyota Kluger GX Auto 2WD","2010 Toyota Kluger Grande Auto AWD MY11","2019 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger GXL Auto AWD","2021 Toyota Kluger Grande Auto eFour","2012 Toyota Kluger Grande Auto AWD MY12","2015 Toyota Kluger GX Auto AWD","2022 Toyota Kluger GXL Auto eFour","2010 Toyota Kluger Altitude Auto 2WD","2021 Toyota Kluger GXL Auto eFour","2019 Toyota Kluger GXL Auto 2WD","2022 Toyota Kluger GXL Auto eFour","2021 Toyota Kluger GX Auto eFour","2019 Toyota Kluger GX Auto 2WD","2016 Toyota Kluger GX Auto 2WD","2013 Toyota Kluger KX-R Auto 2WD","2019 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger GXL Auto eFour","2021 Toyota Kluger GXL Auto AWD","2019 Toyota Kluger GXL Auto AWD","2019 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger GX Auto eFour","2017 Toyota Kluger GX Auto AWD","2021 Toyota Kluger GX Auto eFour","2014 Toyota Kluger GX Auto AWD","2019 Toyota Kluger Grande Auto AWD","2017 Toyota Kluger Grande Auto AWD","2018 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger Grande Auto 2WD","2009 Toyota Kluger KX-S Auto 2WD","2019 Toyota Kluger GXL Auto AWD","2022 Toyota Kluger GXL Auto eFour","2021 Toyota Kluger GX Auto eFour"],"odometer":["212,983 km","62,130 km","2,800 km","227,415 km","75,896 km","50,559 km","104,000 km","158,900 km","94,959 km","132,274 km","164,087 km","134,000 km","139,776 km","330,000 km","69,573 km","84,687 km","22,430 km","10,888 km","141,555 km","140,000 km","295 km","150,949 km","224,000 km","96,448 km","128,602 km","51,261 km","26,012 km","49,916 km","119,075 km","84,123 km","143,922 km","148,000 km","119,000 km","325,000 km","123,226 km","58,261 km","312,995 km","18,712 km","68,203 km","133,428 km","86,865 km","14,347 km","153,677 km","104,131 km","226,831 km","145,000 km","45,380 km","52,004 km","278,423 km","267,212 km","90,740 km","113,000 km","56,050 km","277,000 km","75,030 km","149,161 km","165,828 km","91,187 km","83,753 km","209,472 km","30,614 km","144,437 km","25,546 km","195,337 km","44 km","11,221 km","113,263 km","62,300 km","79,756 km","62,147 km","77,367 km","100,592 km","93,827 km","52,200 km","59,256 km","102,000 km","109,000 km","141,046 km","170,427 km","30 km","19 km","138,762 km","14,518 km","101,202 km","25,000 km","19,068 km","233,461 km","97,006 km","106,250 km","129,641 km","131,000 km","77,799 km","71,000 km","204,607 km","169,560 km","144,846 km","57,100 km","171,781 km","108,960 km","83,000 km","34,208 km","23,095 km","89,740 km","77,930 km","94,334 km","214,020 km","43,775 km","70,362 km","185,000 km","167,014 km","52,800 km","25,651 km","84,677 km","34,277 km","102,491 km","51,324 km","22,118 km","123,365 km","143,511 km","45 km","86,750 km","148,000 km","114,150 km","17,280 km","14,422 km","97,000 km","82,112 km","213,608 km","160,450 km","2,051 km","106,343 km","85,690 km","68,752 km","99,491 km","20 km","229,700 km","203,500 km","72,172 km","72,095 km","165,500 km","71,653 km","247,441 km","114,373 km","75,328 km","26,442 km","2,295 km","21,000 km","5,918 km","23,000 km","6,313 km","25,976 km","38,155 km","79,226 km","139,025 km","90,000 km","35,560 km","82,011 km","194,786 km","29,880 km","87,278 km","23,066 km","77,263 km","10,702 km","6,876 km","99,090 km","91,000 km","18,492 km","182,000 km","106,792 km","48,378 km","19,250 km","164,454 km","153,050 km","34,980 km","220,852 km","55,682 km","90,857 km","32,500 km","43,743 km","42,082 km","146,724 km","131,314 km","62,167 km","20,034 km","11,500 km","109,510 km","117,873 km","79,836 km","21,415 km","113,072 km","28,071 km","152,914 km","62,131 km","106,854 km","40,451 km","91,590 km","130,712 km","38,000 km","42,500 km","72,631 km"],"body":["SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV"],"transmission":["Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic"],"engine":["6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","4cyl 2.4L Turbo Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","2.5i/184kW Hybrid","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","4cyl 2.4L Turbo Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","2.5i/184kW Hybrid","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.3L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.3L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","4cyl 2.4L Turbo Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","2.5i/184kW Hybrid","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","2.5i/184kW Hybrid"]},"columns":[{"id":"price","name":"price","type":"character","style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","cell":["$16,991","$70,970","$83,699","$21,995","$36,990*","$71,850","$34,770","$30,000*","$41,498","$36,888*","$31,989","$43,000*","$24,990*","$10,000*","$38,390*","$39,990*","$65,990","$61,880","$34,995*","$33,000*","$74,950*","$21,719*","$11,000*","$41,990*","$31,444","$73,990","$76,880*","$64,989*","$30,998*","$37,990*","$29,990*","$18,000*","$45,000*","$12,500*","$33,500*","$56,990*","$13,000*","$54,999*","$33,999","$37,900*","$46,990","$55,498","$22,000*","$35,990*","$16,990*","$25,750*","$49,490","$62,990*","$14,995*","$12,995*","$39,990*","$39,000*","$46,990*","$8,000*","$49,990*","$32,990","$26,950*","$31,888","$39,990*","$12,000*","$53,990","$28,990*","$68,500*","$28,999*","$69,990*","$52,990*","$29,995","$43,990","$35,990*","$40,977","$46,990","$36,888*","$34,990*","$46,000*","$46,000*","$35,900*","$37,990*","$27,990*","$37,990*","$77,800*","$68,950*","$25,999","$69,990","$38,000*","$78,990*","$68,888*","$15,990*","$40,990","$43,000*","$11,900*","$25,750*","$40,552","$39,999*","$13,490*","$16,990","$41,990*","$49,888*","$8,400*","$25,990","$38,990*","$40,800","$42,777*","$34,990","$39,980","$35,980*","$19,926*","$58,777","$41,990","$30,000*","$24,880*","$47,000*","$74,910*","$37,490","$60,999","$49,990","$47,950","$37,990*","$37,990*","$33,500*","$67,990*","$53,900*","$28,990*","$24,900*","$69,950","$74,300*","$28,900*","$44,950","$16,990*","$14,800*","$77,970","$38,990","$34,990","$41,989*","$38,500*","$69,990*","$13,400*","$18,500*","$37,990","$27,900*","$21,990*","$37,990*","$16,888*","$35,990*","$44,999","$59,999*","$64,990","$79,000*","$72,895","$66,994*","$67,990","$76,990*","$49,999","$39,990*","$34,490*","$35,500*","$43,990*","$40,990","$18,990","$66,500*","$34,950*","$69,950","$34,490*","$53,990*","$79,968*","$37,990*","$39,990*","$54,990*","$19,888*","$36,990","$49,990","$72,850*","$27,888*","$31,990","$66,990*","$14,800*","$65,989*","$42,888*","$68,000*","$61,990*","$43,990","$25,000*","$19,980*","$41,990*","$67,990","$57,000*","$44,990","$42,990","$39,999*","$61,990*","$34,993*","$59,980*","$25,990*","$49,990","$45,990*","$36,900*","$46,888*","$18,400*","$49,750*","$69,000*","$53,990*"],"html":true,"align":"right","headerStyle":{"font-weight":"normal"}},{"id":"title","name":"title","type":"character","style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","cell":["2009 Toyota Kluger KX-S Auto 2WD","2021 Toyota Kluger Grande Auto eFour","2022 Toyota Kluger Grande Auto AWD","2009 Toyota Kluger KX-S Auto 2WD","2017 Toyota Kluger GXL Auto 2WD","2021 Toyota Kluger GXL Auto eFour","2017 Toyota Kluger GX Auto AWD","2015 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger Black Edition Auto 2WD","2016 Toyota Kluger Grande Auto AWD","2015 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger Grande Auto AWD","2015 Toyota Kluger GX Auto 2WD","2008 Toyota Kluger KX-S Auto AWD","2018 Toyota Kluger GX Auto AWD","2017 Toyota Kluger GXL Auto AWD","2022 Toyota Kluger GXL Auto AWD","2021 Toyota Kluger Grande Auto 2WD","2014 Toyota Kluger GXL Auto AWD","2017 Toyota Kluger GX Auto 2WD","2022 Toyota Kluger GXL Auto 2WD","2013 Toyota Kluger Grande Auto 2WD","2009 Toyota Kluger KX-R Auto 2WD","2018 Toyota Kluger GXL Auto AWD","2018 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger Grande Auto eFour","2022 Toyota Kluger Grande Auto eFour","2021 Toyota Kluger GXL Auto eFour","2017 Toyota Kluger GX Auto AWD","2016 Toyota Kluger Grande Auto AWD","2016 Toyota Kluger GX Auto 2WD","2011 Toyota Kluger KX-S Auto 2WD MY11","2018 Toyota Kluger Grande Auto AWD","2009 Toyota Kluger KX-R Auto 2WD","2015 Toyota Kluger GXL Auto AWD","2021 Toyota Kluger GX Auto eFour","2012 Toyota Kluger KX-R Auto 2WD MY12","2021 Toyota Kluger GX Auto AWD","2018 Toyota Kluger GX Auto 2WD","2018 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GXL Auto 2WD","2018 Toyota Kluger Grande Auto 2WD","2013 Toyota Kluger KX-R Auto 2WD","2018 Toyota Kluger GX Auto AWD","2010 Toyota Kluger KX-R Auto 2WD","2016 Toyota Kluger GX Auto 2WD","2017 Toyota Kluger Grande Auto AWD","2021 Toyota Kluger GXL Auto eFour","2011 Toyota Kluger Grande Auto AWD MY11","2009 Toyota Kluger KX-R Auto 2WD","2019 Toyota Kluger GX Auto AWD","2017 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GXL Auto AWD","2010 Toyota Kluger KX-R Auto AWD","2021 Toyota Kluger GXL Auto 2WD","2017 Toyota Kluger GXL Auto 2WD","2016 Toyota Kluger GX Auto AWD","2015 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger GX Auto AWD","2010 Toyota Kluger KX-R Auto AWD MY11","2019 Toyota Kluger Black Edition Auto AWD","2015 Toyota Kluger GX Auto AWD","2021 Toyota Kluger Grande Auto AWD","2017 Toyota Kluger GX Auto 2WD","2023 Toyota Kluger GXL Auto AWD","2022 Toyota Kluger GX Auto 2WD","2015 Toyota Kluger GXL Auto 2WD","2018 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger GX Auto 2WD","2018 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger GXL Auto AWD","2019 Toyota Kluger GX Auto AWD","2018 Toyota Kluger GX Auto AWD","2018 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger Grande Auto 2WD","2017 Toyota Kluger GX Auto AWD","2019 Toyota Kluger GX Auto AWD","2015 Toyota Kluger GXL Auto AWD","2018 Toyota Kluger GX Auto AWD","2023 Toyota Kluger GXL Auto eFour","2023 Toyota Kluger GX Auto eFour","2014 Toyota Kluger GX Auto 2WD","2022 Toyota Kluger GXL Auto eFour","2018 Toyota Kluger GXL Auto 2WD","2021 Toyota Kluger Grande Auto eFour","2021 Toyota Kluger Grande Auto AWD","2013 Toyota Kluger KX-R Auto 2WD","2019 Toyota Kluger GXL Auto AWD","2019 Toyota Kluger GXL Auto AWD","2005 Toyota Kluger CV Auto AWD MY06","2015 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger GX Auto 2WD","2017 Toyota Kluger GX Auto AWD","2009 Toyota Kluger KX-S Auto 2WD","2009 Toyota Kluger Altitude Auto AWD","2018 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger GXL Auto AWD","2006 Toyota Kluger CVX Auto AWD MY06","2013 Toyota Kluger Grande Auto 2WD","2018 Toyota Kluger GXL Auto AWD","2014 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger GX Auto AWD","2018 Toyota Kluger GX Auto AWD","2016 Toyota Kluger GX Auto AWD","2014 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GXL Auto 2WD","2015 Toyota Kluger GXL Auto 2WD","2015 Toyota Kluger GX Auto AWD","2019 Toyota Kluger GXL Auto AWD","2021 Toyota Kluger Grande Auto eFour","2019 Toyota Kluger GX Auto AWD","2021 Toyota Kluger GX Auto eFour","2019 Toyota Kluger Black Edition Auto AWD","2019 Toyota Kluger Black Edition Auto 2WD","2015 Toyota Kluger GXL Auto 2WD","2017 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GXL Auto 2WD","2022 Toyota Kluger GX Auto eFour","2021 Toyota Kluger GX Auto eFour","2016 Toyota Kluger GX Auto AWD","2015 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger Grande Auto AWD","2022 Toyota Kluger GXL Auto eFour","2015 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger Black Edition Auto 2WD","2007 Toyota Kluger KX-S Auto AWD","2009 Toyota Kluger Altitude Auto 2WD","2022 Toyota Kluger GXL Auto eFour","2018 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GX Auto AWD","2019 Toyota Kluger GX Auto AWD","2018 Toyota Kluger GXL Auto 2WD","2022 Toyota Kluger GX Auto eFour","2009 Toyota Kluger KX-S Auto AWD","2011 Toyota Kluger Grande Auto 2WD MY11","2017 Toyota Kluger GX Auto AWD","2016 Toyota Kluger GX Auto 2WD","2011 Toyota Kluger Grande Auto 2WD MY11","2019 Toyota Kluger GX Auto AWD","2011 Toyota Kluger KX-R Auto AWD MY11","2016 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger Black Edition Auto 2WD","2019 Toyota Kluger Black Edition Auto 2WD","2023 Toyota Kluger GX Auto 2WD","2022 Toyota Kluger Grande Auto eFour","2022 Toyota Kluger Grande Auto 2WD","2021 Toyota Kluger Grande Auto AWD","2021 Toyota Kluger Grande Auto 2WD","2021 Toyota Kluger Grande Auto eFour","2019 Toyota Kluger GXL Auto AWD","2016 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GX Auto AWD","2015 Toyota Kluger Grande Auto 2WD","2019 Toyota Kluger GXL Auto 2WD","2016 Toyota Kluger Grande Auto 2WD","2011 Toyota Kluger KX-R Auto 2WD MY11","2021 Toyota Kluger GXL Auto eFour","2017 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger GXL Auto eFour","2014 Toyota Kluger GXL Auto AWD","2022 Toyota Kluger GX Auto 2WD","2022 Toyota Kluger Grande Auto eFour","2016 Toyota Kluger GXL Auto AWD","2018 Toyota Kluger GX Auto AWD","2022 Toyota Kluger GX Auto 2WD","2010 Toyota Kluger Grande Auto AWD MY11","2019 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger GXL Auto AWD","2021 Toyota Kluger Grande Auto eFour","2012 Toyota Kluger Grande Auto AWD MY12","2015 Toyota Kluger GX Auto AWD","2022 Toyota Kluger GXL Auto eFour","2010 Toyota Kluger Altitude Auto 2WD","2021 Toyota Kluger GXL Auto eFour","2019 Toyota Kluger GXL Auto 2WD","2022 Toyota Kluger GXL Auto eFour","2021 Toyota Kluger GX Auto eFour","2019 Toyota Kluger GX Auto 2WD","2016 Toyota Kluger GX Auto 2WD","2013 Toyota Kluger KX-R Auto 2WD","2019 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger GXL Auto eFour","2021 Toyota Kluger GXL Auto AWD","2019 Toyota Kluger GXL Auto AWD","2019 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger GX Auto eFour","2017 Toyota Kluger GX Auto AWD","2021 Toyota Kluger GX Auto eFour","2014 Toyota Kluger GX Auto AWD","2019 Toyota Kluger Grande Auto AWD","2017 Toyota Kluger Grande Auto AWD","2018 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger Grande Auto 2WD","2009 Toyota Kluger KX-S Auto 2WD","2019 Toyota Kluger GXL Auto AWD","2022 Toyota Kluger GXL Auto eFour","2021 Toyota Kluger GX Auto eFour"],"html":true,"align":"left","headerStyle":{"font-weight":"normal"}},{"id":"odometer","name":"odometer","type":"character","style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","cell":["212,983 km","62,130 km","2,800 km","227,415 km","75,896 km","50,559 km","104,000 km","158,900 km","94,959 km","132,274 km","164,087 km","134,000 km","139,776 km","330,000 km","69,573 km","84,687 km","22,430 km","10,888 km","141,555 km","140,000 km","295 km","150,949 km","224,000 km","96,448 km","128,602 km","51,261 km","26,012 km","49,916 km","119,075 km","84,123 km","143,922 km","148,000 km","119,000 km","325,000 km","123,226 km","58,261 km","312,995 km","18,712 km","68,203 km","133,428 km","86,865 km","14,347 km","153,677 km","104,131 km","226,831 km","145,000 km","45,380 km","52,004 km","278,423 km","267,212 km","90,740 km","113,000 km","56,050 km","277,000 km","75,030 km","149,161 km","165,828 km","91,187 km","83,753 km","209,472 km","30,614 km","144,437 km","25,546 km","195,337 km","44 km","11,221 km","113,263 km","62,300 km","79,756 km","62,147 km","77,367 km","100,592 km","93,827 km","52,200 km","59,256 km","102,000 km","109,000 km","141,046 km","170,427 km","30 km","19 km","138,762 km","14,518 km","101,202 km","25,000 km","19,068 km","233,461 km","97,006 km","106,250 km","129,641 km","131,000 km","77,799 km","71,000 km","204,607 km","169,560 km","144,846 km","57,100 km","171,781 km","108,960 km","83,000 km","34,208 km","23,095 km","89,740 km","77,930 km","94,334 km","214,020 km","43,775 km","70,362 km","185,000 km","167,014 km","52,800 km","25,651 km","84,677 km","34,277 km","102,491 km","51,324 km","22,118 km","123,365 km","143,511 km","45 km","86,750 km","148,000 km","114,150 km","17,280 km","14,422 km","97,000 km","82,112 km","213,608 km","160,450 km","2,051 km","106,343 km","85,690 km","68,752 km","99,491 km","20 km","229,700 km","203,500 km","72,172 km","72,095 km","165,500 km","71,653 km","247,441 km","114,373 km","75,328 km","26,442 km","2,295 km","21,000 km","5,918 km","23,000 km","6,313 km","25,976 km","38,155 km","79,226 km","139,025 km","90,000 km","35,560 km","82,011 km","194,786 km","29,880 km","87,278 km","23,066 km","77,263 km","10,702 km","6,876 km","99,090 km","91,000 km","18,492 km","182,000 km","106,792 km","48,378 km","19,250 km","164,454 km","153,050 km","34,980 km","220,852 km","55,682 km","90,857 km","32,500 km","43,743 km","42,082 km","146,724 km","131,314 km","62,167 km","20,034 km","11,500 km","109,510 km","117,873 km","79,836 km","21,415 km","113,072 km","28,071 km","152,914 km","62,131 km","106,854 km","40,451 km","91,590 km","130,712 km","38,000 km","42,500 km","72,631 km"],"html":true,"align":"left","headerStyle":{"font-weight":"normal"}},{"id":"body","name":"body","type":"character","style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","cell":["SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV"],"html":true,"align":"left","headerStyle":{"font-weight":"normal"}},{"id":"transmission","name":"transmission","type":"character","style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","cell":["Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic"],"html":true,"align":"left","headerStyle":{"font-weight":"normal"}},{"id":"engine","name":"engine","type":"character","style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","cell":["6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","4cyl 2.4L Turbo Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","2.5i/184kW Hybrid","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","4cyl 2.4L Turbo Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","2.5i/184kW Hybrid","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.3L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.3L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","4cyl 2.4L Turbo Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","2.5i/184kW Hybrid","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","2.5i/184kW Hybrid"],"html":true,"align":"left","headerStyle":{"font-weight":"normal"}}],"defaultPageSize":10,"showPageSizeOptions":false,"pageSizeOptions":[10,25,50,100],"paginationType":"numbers","showPagination":true,"showPageInfo":true,"minRows":1,"showSortable":true,"height":"auto","theme":{"color":"#333333","backgroundColor":"#FFFFFF","stripedColor":"rgba(128,128,128,0.05)","style":{"fontFamily":"system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif"},"headerStyle":{"borderTopStyle":"solid","borderTopWidth":"2px","borderTopColor":"#D3D3D3","borderBottomStyle":"solid","borderBottomWidth":"2px","borderBottomColor":"#D3D3D3"}},"elementId":"fhmbohzcwq","dataKey":"4d5534a5ca2fba6e89e15f17fc972581"},"children":[]},"class":"reactR_markup"},"evals":["tag.attribs.columns.0.style","tag.attribs.columns.1.style","tag.attribs.columns.2.style","tag.attribs.columns.3.style","tag.attribs.columns.4.style","tag.attribs.columns.5.style"],"jsHooks":[]}</script>
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

<div id="sslhnmgzqr" class=".gt_table" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#sslhnmgzqr table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#sslhnmgzqr thead, #sslhnmgzqr tbody, #sslhnmgzqr tfoot, #sslhnmgzqr tr, #sslhnmgzqr td, #sslhnmgzqr th {
  border-style: none;
}
&#10;#sslhnmgzqr p {
  margin: 0;
  padding: 0;
}
&#10;#sslhnmgzqr .gt_table {
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
&#10;#sslhnmgzqr .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#sslhnmgzqr .gt_title {
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
&#10;#sslhnmgzqr .gt_subtitle {
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
&#10;#sslhnmgzqr .gt_heading {
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
&#10;#sslhnmgzqr .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#sslhnmgzqr .gt_col_headings {
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
&#10;#sslhnmgzqr .gt_col_heading {
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
&#10;#sslhnmgzqr .gt_column_spanner_outer {
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
&#10;#sslhnmgzqr .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#sslhnmgzqr .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#sslhnmgzqr .gt_column_spanner {
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
&#10;#sslhnmgzqr .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#sslhnmgzqr .gt_group_heading {
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
&#10;#sslhnmgzqr .gt_empty_group_heading {
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
&#10;#sslhnmgzqr .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#sslhnmgzqr .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#sslhnmgzqr .gt_row {
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
&#10;#sslhnmgzqr .gt_stub {
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
&#10;#sslhnmgzqr .gt_stub_row_group {
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
&#10;#sslhnmgzqr .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#sslhnmgzqr .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#sslhnmgzqr .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#sslhnmgzqr .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#sslhnmgzqr .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#sslhnmgzqr .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#sslhnmgzqr .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#sslhnmgzqr .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#sslhnmgzqr .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#sslhnmgzqr .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#sslhnmgzqr .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#sslhnmgzqr .gt_footnotes {
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
&#10;#sslhnmgzqr .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#sslhnmgzqr .gt_sourcenotes {
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
&#10;#sslhnmgzqr .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#sslhnmgzqr .gt_left {
  text-align: left;
}
&#10;#sslhnmgzqr .gt_center {
  text-align: center;
}
&#10;#sslhnmgzqr .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#sslhnmgzqr .gt_font_normal {
  font-weight: normal;
}
&#10;#sslhnmgzqr .gt_font_bold {
  font-weight: bold;
}
&#10;#sslhnmgzqr .gt_font_italic {
  font-style: italic;
}
&#10;#sslhnmgzqr .gt_super {
  font-size: 65%;
}
&#10;#sslhnmgzqr .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#sslhnmgzqr .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#sslhnmgzqr .gt_indent_1 {
  text-indent: 5px;
}
&#10;#sslhnmgzqr .gt_indent_2 {
  text-indent: 10px;
}
&#10;#sslhnmgzqr .gt_indent_3 {
  text-indent: 15px;
}
&#10;#sslhnmgzqr .gt_indent_4 {
  text-indent: 20px;
}
&#10;#sslhnmgzqr .gt_indent_5 {
  text-indent: 25px;
}
</style>
<div id="sslhnmgzqr" class="reactable html-widget " style="width:auto;height:auto;"></div>
<script type="application/json" data-for="sslhnmgzqr">{"x":{"tag":{"name":"Reactable","attribs":{"data":{"price":[33760,37000,33000,45990,34990,44950,48990,59900,35500,69990,16000,39990,61990,34990,20200,11000,72990,72999,36888,37990,20000,10490,45000,75499,56890,42990,69990,35990,16200,31000,78990,41880,35500,65950,33486,73517,42888,44999,39500,46990,47999,36970,38500,19500,33500,12000,47999,68500,77999,22999,39990,53990,37900,33990,16500,68990,53888,38990,34998,25000,39900,49990,12500,35977,25500,41800,41500,48990,15000,30000,47990,68888,29990,40950,45000,37980,18990,46000,33990,50990,41990,56500,39960,83699,68886,34900,39990,43000,56950,58970,46990,40990,28990,65990,11600,47950,24990,31880,44990,61980,22300,34995,17990,60880,55498,20000,44990,36989,66900,76990,40500,65990,39990,23590,49990,42500,61990,12990,66990,43990,42990,28450,31990,17000,49990,77970,35900,32990,35500,47880,41990,43990,41500,59990,35888,19979,37990,16000,38990,29900,41800,36990,47000,46500,14990,45000,44990,5600,14999,46990,31490,75000,39800,12900,54990,66994,49880,26950,71850,38990,65990,27900,33990,61888,33990,24350,72850,34990,49990,39990,41970,45500,63990,35990,71990,16500,56990,30990,27995,68950,15990,69990,43989,13250,46990,10990,19990,58990,19980,10999,49888,65200,68000,15600,32390,26990,43888,13000,28690,27000],"title":["2018 Toyota Kluger GX Auto AWD","2018 Toyota Kluger GXL Auto 2WD","2018 Toyota Kluger GX Auto AWD","2017 Toyota Kluger Grande Auto AWD","2015 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger Black Edition Auto 2WD","2021 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger GX Auto eFour","2015 Toyota Kluger Grande Auto 2WD","2023 Toyota Kluger GXL Auto AWD","2011 Toyota Kluger KX-R Auto 2WD MY11","2018 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger GX Auto eFour","2015 Toyota Kluger GXL Auto AWD","2011 Toyota Kluger Grande Auto AWD MY11","2009 Toyota Kluger KX-R Auto 2WD","2022 Toyota Kluger Grande Auto eFour","2021 Toyota Kluger Grande Auto eFour","2016 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GX Auto 2WD","2014 Toyota Kluger GX Auto 2WD","2008 Toyota Kluger KX-R Auto 2WD","2018 Toyota Kluger Grande Auto AWD","2022 Toyota Kluger Grande Auto eFour","2021 Toyota Kluger GX Auto eFour","2019 Toyota Kluger GX Auto AWD","2022 Toyota Kluger GXL Auto AWD","2014 Toyota Kluger Grande Auto 2WD","2011 Toyota Kluger KX-R Auto AWD MY11","2015 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger Grande Auto eFour","2018 Toyota Kluger GXL Auto 2WD","2014 Toyota Kluger Grande Auto 2WD","2022 Toyota Kluger GX Auto eFour","2016 Toyota Kluger GXL Auto 2WD","2022 Toyota Kluger Grande Auto AWD","2018 Toyota Kluger GXL Auto AWD","2018 Toyota Kluger GXL Auto 2WD","2017 Toyota Kluger Grande Auto AWD","2018 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger GXL Auto AWD","2018 Toyota Kluger GXL Auto AWD","2018 Toyota Kluger GXL Auto 2WD","2008 Toyota Kluger Grande Auto AWD","2015 Toyota Kluger GXL Auto AWD","2008 Toyota Kluger KX-S Auto 2WD","2021 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger Grande Auto AWD","2022 Toyota Kluger Grande Auto eFour","2014 Toyota Kluger GXL Auto AWD","2018 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger GX Auto eFour","2018 Toyota Kluger GXL Auto 2WD","2014 Toyota Kluger Grande Auto 2WD","2013 Toyota Kluger KX-R Auto AWD","2021 Toyota Kluger GXL Auto eFour","2019 Toyota Kluger Black Edition Auto AWD","2018 Toyota Kluger GXL Auto AWD","2017 Toyota Kluger GXL Auto 2WD","2016 Toyota Kluger GX Auto 2WD","2018 Toyota Kluger GXL Auto 2WD","2021 Toyota Kluger GX Auto AWD","2012 Toyota Kluger KX-R Auto 2WD MY12","2015 Toyota Kluger Grande Auto AWD","2011 Toyota Kluger Grande Auto AWD MY11","2019 Toyota Kluger Black Edition Auto 2WD","2019 Toyota Kluger GX Auto AWD","2019 Toyota Kluger GXL Auto 2WD","2011 Toyota Kluger KX-R Auto 2WD MY11","2015 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger Grande Auto AWD","2015 Toyota Kluger GXL Auto AWD","2019 Toyota Kluger GX Auto 2WD","2016 Toyota Kluger Grande Auto AWD","2017 Toyota Kluger GXL Auto AWD","2013 Toyota Kluger KX-R Auto 2WD","2017 Toyota Kluger Grande Auto AWD","2017 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GXL Auto 2WD","2021 Toyota Kluger GXL Auto 2WD","2017 Toyota Kluger GXL Auto 2WD","2022 Toyota Kluger Grande Auto AWD","2021 Toyota Kluger Grande Auto 2WD","2018 Toyota Kluger GX Auto 2WD","2015 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger GXL Auto AWD","2022 Toyota Kluger GX Auto AWD","2019 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GXL Auto AWD","2019 Toyota Kluger GXL Auto AWD","2014 Toyota Kluger GXL Auto AWD","2023 Toyota Kluger GX Auto eFour","2009 Toyota Kluger KX-S Auto AWD","2019 Toyota Kluger Black Edition Auto 2WD","2015 Toyota Kluger GXL Auto 2WD","2017 Toyota Kluger GX Auto 2WD","2018 Toyota Kluger GXL Auto 2WD","2021 Toyota Kluger GX Auto eFour","2013 Toyota Kluger Altitude Auto 2WD","2014 Toyota Kluger GXL Auto AWD","2013 Toyota Kluger KX-R Auto 2WD","2021 Toyota Kluger Grande Auto 2WD","2018 Toyota Kluger Grande Auto 2WD","2015 Toyota Kluger GX Auto 2WD","2017 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger Grande Auto AWD","2022 Toyota Kluger GXL Auto eFour","2019 Toyota Kluger GX Auto AWD","2021 Toyota Kluger Grande Auto 2WD","2019 Toyota Kluger GX Auto 2WD","2013 Toyota Kluger Grande Auto 2WD","2021 Toyota Kluger GX Auto 2WD","2018 Toyota Kluger Grande Auto AWD","2023 Toyota Kluger GX Auto eFour","2004 Toyota Kluger Grande Auto AWD","2021 Toyota Kluger GXL Auto 2WD","2018 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GX Auto 2WD","2015 Toyota Kluger GXL Auto 2WD","2018 Toyota Kluger GX Auto AWD","2010 Toyota Kluger KX-R Auto 2WD","2021 Toyota Kluger GX Auto 2WD","2022 Toyota Kluger GXL Auto eFour","2017 Toyota Kluger GX Auto AWD","2016 Toyota Kluger GX Auto 2WD","2016 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger GX Auto AWD","2018 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger GX Auto eFour","2018 Toyota Kluger GXL Auto 2WD","2012 Toyota Kluger Altitude Auto 2WD MY12","2019 Toyota Kluger GXL Auto 2WD","2009 Toyota Kluger KX-R Auto AWD","2019 Toyota Kluger GX Auto AWD","2015 Toyota Kluger GX Auto 2WD","2017 Toyota Kluger GX Auto 2WD","2018 Toyota Kluger GX Auto AWD","2019 Toyota Kluger GXL Auto AWD","2019 Toyota Kluger GXL Auto AWD","2008 Toyota Kluger KX-S Auto AWD","2017 Toyota Kluger Grande Auto 2WD","2019 Toyota Kluger GX Auto 2WD","2005 Toyota Kluger CVX Auto AWD","2012 Toyota Kluger KX-S Auto 2WD MY12","2019 Toyota Kluger GXL Auto 2WD","2018 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger Grande Auto eFour","2018 Toyota Kluger GXL Auto 2WD","2011 Toyota Kluger KX-R Auto 2WD MY11","2022 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GXL Auto 2WD","2016 Toyota Kluger GX Auto AWD","2021 Toyota Kluger GXL Auto eFour","2017 Toyota Kluger Grande Auto 2WD","2021 Toyota Kluger GXL Auto AWD","2009 Toyota Kluger KX-R Auto 2WD","2017 Toyota Kluger GXL Auto 2WD","2021 Toyota Kluger GX Auto eFour","2018 Toyota Kluger GX Auto 2WD","2016 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger Grande Auto eFour","2018 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger GXL Auto AWD","2019 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger GXL Auto 2WD","2021 Toyota Kluger GXL Auto eFour","2015 Toyota Kluger Grande Auto 2WD","2022 Toyota Kluger GXL Auto eFour","2010 Toyota Kluger KX-R Auto AWD","2021 Toyota Kluger GXL Auto 2WD","2018 Toyota Kluger GX Auto 2WD","2015 Toyota Kluger GX Auto 2WD","2022 Toyota Kluger GXL Auto eFour","2012 Toyota Kluger KX-R Auto AWD MY12","2022 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GX Auto 2WD","2010 Toyota Kluger KX-R Auto 2WD","2019 Toyota Kluger Grande Auto AWD","2008 Toyota Kluger KX-R Auto 2WD","2011 Toyota Kluger KX-R Auto AWD MY11","2019 Toyota Kluger Grande Auto AWD","2013 Toyota Kluger KX-R Auto 2WD","2010 Toyota Kluger Altitude Auto 2WD","2018 Toyota Kluger GXL Auto 2WD","2021 Toyota Kluger Grande Auto 2WD","2022 Toyota Kluger GXL Auto eFour","2012 Toyota Kluger KX-R Auto 2WD MY12","2017 Toyota Kluger GX Auto AWD","2013 Toyota Kluger Grande Auto AWD","2018 Toyota Kluger GXL Auto AWD","2012 Toyota Kluger KX-R Auto 2WD MY12","2015 Toyota Kluger GX Auto AWD","2015 Toyota Kluger GXL Auto 2WD"],"odometer":[95011,70000,118000,106854,86748,82112,49756,26000,90000,44,167850,64005,21415,120958,153000,224000,25079,31527,132274,68548,180000,225000,119000,19500,59803,75286,5544,144111,211524,90336,25000,62635,70100,209,83025,23749,67560,50339,95600,62950,60811,105413,99491,144534,54742,213000,27963,25546,11520,210500,49156,72631,79824,157713,244300,18878,62662,83000,97183,146724,115488,26863,245000,115531,200000,93943,70466,75757,290000,158900,55198,19068,123079,46430,59319,130484,156747,91327,107728,58057,70362,24000,84811,2800,28092,93903,60985,106250,5400,32402,56050,97006,137959,1946,210000,51324,176316,112345,68700,61531,154000,141555,167710,14986,14347,206675,103861,91607,20400,18,64650,31429,83836,142471,41680,92000,17642,209431,196,97309,78495,120490,146481,191500,20965,2051,102000,65083,56500,42934,47203,51970,23000,36057,120772,153338,133482,202000,45607,101000,69600,126474,52800,28000,196089,56500,20094,241710,208476,86865,110037,20000,43000,249000,18492,23000,19346,165828,50559,109021,14095,70412,144002,14957,80989,165633,19250,91497,41200,23500,51342,39000,52833,77000,13967,169000,24571,117317,143000,29793,215372,36255,34508,285005,79339,344122,183647,38448,131314,257852,72291,57376,32500,145771,108102,176716,55629,312995,101786,128613],"body":["SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV"],"transmission":["Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic"],"engine":["6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","4cyl 2.4L Turbo Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.3L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.3L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol"],"odometer_Mm":[95.011,70,118,106.854,86.748,82.112,49.756,26,90,0.044,167.85,64.005,21.415,120.958,153,224,25.079,31.527,132.274,68.548,180,225,119,19.5,59.803,75.286,5.544,144.111,211.524,90.336,25,62.635,70.1,0.209,83.025,23.749,67.56,50.339,95.6,62.95,60.811,105.413,99.491,144.534,54.742,213,27.963,25.546,11.52,210.5,49.156,72.631,79.824,157.713,244.3,18.878,62.662,83,97.183,146.724,115.488,26.863,245,115.531,200,93.943,70.466,75.757,290,158.9,55.198,19.068,123.079,46.43,59.319,130.484,156.747,91.327,107.728,58.057,70.362,24,84.811,2.8,28.092,93.903,60.985,106.25,5.4,32.402,56.05,97.006,137.959,1.946,210,51.324,176.316,112.345,68.7,61.531,154,141.555,167.71,14.986,14.347,206.675,103.861,91.607,20.4,0.018,64.65,31.429,83.836,142.471,41.68,92,17.642,209.431,0.196,97.309,78.495,120.49,146.481,191.5,20.965,2.051,102,65.083,56.5,42.934,47.203,51.97,23,36.057,120.772,153.338,133.482,202,45.607,101,69.6,126.474,52.8,28,196.089,56.5,20.094,241.71,208.476,86.865,110.037,20,43,249,18.492,23,19.346,165.828,50.559,109.021,14.095,70.412,144.002,14.957,80.989,165.633,19.25,91.497,41.2,23.5,51.342,39,52.833,77,13.967,169,24.571,117.317,143,29.793,215.372,36.255,34.508,285.005,79.339,344.122,183.647,38.448,131.314,257.852,72.291,57.376,32.5,145.771,108.102,176.716,55.629,312.995,101.786,128.613],"year":[2018,2018,2018,2017,2015,2019,2021,2021,2015,2023,2011,2018,2021,2015,2011,2009,2022,2021,2016,2019,2014,2008,2018,2022,2021,2019,2022,2014,2011,2015,2021,2018,2014,2022,2016,2022,2018,2018,2017,2018,2019,2018,2018,2008,2015,2008,2021,2021,2022,2014,2018,2021,2018,2014,2013,2021,2019,2018,2017,2016,2018,2021,2012,2015,2011,2019,2019,2019,2011,2015,2019,2021,2015,2019,2016,2017,2013,2017,2017,2019,2019,2021,2017,2022,2021,2018,2015,2019,2022,2019,2019,2019,2014,2023,2009,2019,2015,2017,2018,2021,2013,2014,2013,2021,2018,2015,2017,2019,2021,2022,2019,2021,2019,2013,2021,2018,2023,2004,2021,2018,2019,2015,2018,2010,2021,2022,2017,2016,2016,2021,2019,2019,2018,2021,2018,2012,2019,2009,2019,2015,2017,2018,2019,2019,2008,2017,2019,2005,2012,2019,2018,2021,2018,2011,2022,2021,2019,2016,2021,2017,2021,2009,2017,2021,2018,2016,2021,2018,2019,2019,2019,2019,2021,2015,2022,2010,2021,2018,2015,2022,2012,2022,2019,2010,2019,2008,2011,2019,2013,2010,2018,2021,2022,2012,2017,2013,2018,2012,2015,2015],"drivetrain":["AWD","2WD","AWD","AWD","2WD","2WD","2WD","eFour","2WD","AWD","MY11","2WD","eFour","AWD","MY11","2WD","eFour","eFour","AWD","2WD","2WD","2WD","AWD","eFour","eFour","AWD","AWD","2WD","MY11","2WD","eFour","2WD","2WD","eFour","2WD","AWD","AWD","2WD","AWD","2WD","AWD","AWD","2WD","AWD","AWD","2WD","2WD","AWD","eFour","AWD","2WD","eFour","2WD","2WD","AWD","eFour","AWD","AWD","2WD","2WD","2WD","AWD","MY12","AWD","MY11","2WD","AWD","2WD","MY11","AWD","2WD","AWD","AWD","2WD","AWD","AWD","2WD","AWD","2WD","AWD","2WD","2WD","2WD","AWD","2WD","2WD","2WD","AWD","AWD","AWD","AWD","AWD","AWD","eFour","AWD","2WD","2WD","2WD","2WD","eFour","2WD","AWD","2WD","2WD","2WD","2WD","AWD","2WD","AWD","eFour","AWD","2WD","2WD","2WD","2WD","AWD","eFour","AWD","2WD","AWD","2WD","2WD","AWD","2WD","2WD","eFour","AWD","2WD","2WD","2WD","2WD","AWD","2WD","eFour","2WD","MY12","2WD","AWD","AWD","2WD","2WD","AWD","AWD","AWD","AWD","2WD","2WD","AWD","MY12","2WD","2WD","eFour","2WD","MY11","2WD","AWD","2WD","AWD","eFour","2WD","AWD","2WD","2WD","eFour","2WD","2WD","eFour","2WD","AWD","2WD","2WD","2WD","eFour","2WD","eFour","AWD","2WD","2WD","2WD","eFour","MY12","AWD","2WD","2WD","AWD","2WD","MY11","AWD","2WD","2WD","2WD","2WD","eFour","MY12","AWD","AWD","AWD","MY12","AWD","2WD"],"model":["GX","GXL","GX","Grande","GX","Black","GX","GX","Grande","GXL","KX-R","GX","GX","GXL","Grande","KX-R","Grande","Grande","Grande","GX","GX","KX-R","Grande","Grande","GX","GX","GXL","Grande","KX-R","GX","Grande","GXL","Grande","GX","GXL","Grande","GXL","GXL","Grande","GXL","GXL","GXL","GXL","Grande","GXL","KX-S","GX","Grande","Grande","GXL","GX","GX","GXL","Grande","KX-R","GXL","Black","GXL","GXL","GX","GXL","GX","KX-R","Grande","Grande","Black","GX","GXL","KX-R","Grande","GX","Grande","GXL","GX","Grande","GXL","KX-R","Grande","GX","Grande","GXL","GXL","GXL","Grande","Grande","GX","GXL","GXL","GX","Grande","GXL","GXL","GXL","GX","KX-S","Black","GXL","GX","GXL","GX","Altitude","GXL","KX-R","Grande","Grande","GX","Grande","GX","Grande","GXL","GX","Grande","GX","Grande","GX","Grande","GX","Grande","GXL","Grande","GX","GXL","GX","KX-R","GX","GXL","GX","GX","GX","GX","GX","GX","GX","GX","GXL","Altitude","GXL","KX-R","GX","GX","GX","GX","GXL","GXL","KX-S","Grande","GX","CVX","KX-S","GXL","GX","Grande","GXL","KX-R","GX","Grande","GXL","GX","GXL","Grande","GXL","KX-R","GXL","GX","GX","GX","Grande","GX","GXL","GX","GX","GXL","GXL","Grande","GXL","KX-R","GXL","GX","GX","GXL","KX-R","Grande","GX","KX-R","Grande","KX-R","KX-R","Grande","KX-R","Altitude","GXL","Grande","GXL","KX-R","GX","Grande","GXL","KX-R","GX","GXL"]},"columns":[{"id":"price","name":"price","type":"numeric","style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","cell":["33760","37000","33000","45990","34990","44950","48990","59900","35500","69990","16000","39990","61990","34990","20200","11000","72990","72999","36888","37990","20000","10490","45000","75499","56890","42990","69990","35990","16200","31000","78990","41880","35500","65950","33486","73517","42888","44999","39500","46990","47999","36970","38500","19500","33500","12000","47999","68500","77999","22999","39990","53990","37900","33990","16500","68990","53888","38990","34998","25000","39900","49990","12500","35977","25500","41800","41500","48990","15000","30000","47990","68888","29990","40950","45000","37980","18990","46000","33990","50990","41990","56500","39960","83699","68886","34900","39990","43000","56950","58970","46990","40990","28990","65990","11600","47950","24990","31880","44990","61980","22300","34995","17990","60880","55498","20000","44990","36989","66900","76990","40500","65990","39990","23590","49990","42500","61990","12990","66990","43990","42990","28450","31990","17000","49990","77970","35900","32990","35500","47880","41990","43990","41500","59990","35888","19979","37990","16000","38990","29900","41800","36990","47000","46500","14990","45000","44990","5600","14999","46990","31490","75000","39800","12900","54990","66994","49880","26950","71850","38990","65990","27900","33990","61888","33990","24350","72850","34990","49990","39990","41970","45500","63990","35990","71990","16500","56990","30990","27995","68950","15990","69990","43989","13250","46990","10990","19990","58990","19980","10999","49888","65200","68000","15600","32390","26990","43888","13000","28690","27000"],"html":true,"align":"right","headerStyle":{"font-weight":"normal"}},{"id":"title","name":"title","type":"character","style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","cell":["2018 Toyota Kluger GX Auto AWD","2018 Toyota Kluger GXL Auto 2WD","2018 Toyota Kluger GX Auto AWD","2017 Toyota Kluger Grande Auto AWD","2015 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger Black Edition Auto 2WD","2021 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger GX Auto eFour","2015 Toyota Kluger Grande Auto 2WD","2023 Toyota Kluger GXL Auto AWD","2011 Toyota Kluger KX-R Auto 2WD MY11","2018 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger GX Auto eFour","2015 Toyota Kluger GXL Auto AWD","2011 Toyota Kluger Grande Auto AWD MY11","2009 Toyota Kluger KX-R Auto 2WD","2022 Toyota Kluger Grande Auto eFour","2021 Toyota Kluger Grande Auto eFour","2016 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GX Auto 2WD","2014 Toyota Kluger GX Auto 2WD","2008 Toyota Kluger KX-R Auto 2WD","2018 Toyota Kluger Grande Auto AWD","2022 Toyota Kluger Grande Auto eFour","2021 Toyota Kluger GX Auto eFour","2019 Toyota Kluger GX Auto AWD","2022 Toyota Kluger GXL Auto AWD","2014 Toyota Kluger Grande Auto 2WD","2011 Toyota Kluger KX-R Auto AWD MY11","2015 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger Grande Auto eFour","2018 Toyota Kluger GXL Auto 2WD","2014 Toyota Kluger Grande Auto 2WD","2022 Toyota Kluger GX Auto eFour","2016 Toyota Kluger GXL Auto 2WD","2022 Toyota Kluger Grande Auto AWD","2018 Toyota Kluger GXL Auto AWD","2018 Toyota Kluger GXL Auto 2WD","2017 Toyota Kluger Grande Auto AWD","2018 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger GXL Auto AWD","2018 Toyota Kluger GXL Auto AWD","2018 Toyota Kluger GXL Auto 2WD","2008 Toyota Kluger Grande Auto AWD","2015 Toyota Kluger GXL Auto AWD","2008 Toyota Kluger KX-S Auto 2WD","2021 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger Grande Auto AWD","2022 Toyota Kluger Grande Auto eFour","2014 Toyota Kluger GXL Auto AWD","2018 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger GX Auto eFour","2018 Toyota Kluger GXL Auto 2WD","2014 Toyota Kluger Grande Auto 2WD","2013 Toyota Kluger KX-R Auto AWD","2021 Toyota Kluger GXL Auto eFour","2019 Toyota Kluger Black Edition Auto AWD","2018 Toyota Kluger GXL Auto AWD","2017 Toyota Kluger GXL Auto 2WD","2016 Toyota Kluger GX Auto 2WD","2018 Toyota Kluger GXL Auto 2WD","2021 Toyota Kluger GX Auto AWD","2012 Toyota Kluger KX-R Auto 2WD MY12","2015 Toyota Kluger Grande Auto AWD","2011 Toyota Kluger Grande Auto AWD MY11","2019 Toyota Kluger Black Edition Auto 2WD","2019 Toyota Kluger GX Auto AWD","2019 Toyota Kluger GXL Auto 2WD","2011 Toyota Kluger KX-R Auto 2WD MY11","2015 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger Grande Auto AWD","2015 Toyota Kluger GXL Auto AWD","2019 Toyota Kluger GX Auto 2WD","2016 Toyota Kluger Grande Auto AWD","2017 Toyota Kluger GXL Auto AWD","2013 Toyota Kluger KX-R Auto 2WD","2017 Toyota Kluger Grande Auto AWD","2017 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GXL Auto 2WD","2021 Toyota Kluger GXL Auto 2WD","2017 Toyota Kluger GXL Auto 2WD","2022 Toyota Kluger Grande Auto AWD","2021 Toyota Kluger Grande Auto 2WD","2018 Toyota Kluger GX Auto 2WD","2015 Toyota Kluger GXL Auto 2WD","2019 Toyota Kluger GXL Auto AWD","2022 Toyota Kluger GX Auto AWD","2019 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GXL Auto AWD","2019 Toyota Kluger GXL Auto AWD","2014 Toyota Kluger GXL Auto AWD","2023 Toyota Kluger GX Auto eFour","2009 Toyota Kluger KX-S Auto AWD","2019 Toyota Kluger Black Edition Auto 2WD","2015 Toyota Kluger GXL Auto 2WD","2017 Toyota Kluger GX Auto 2WD","2018 Toyota Kluger GXL Auto 2WD","2021 Toyota Kluger GX Auto eFour","2013 Toyota Kluger Altitude Auto 2WD","2014 Toyota Kluger GXL Auto AWD","2013 Toyota Kluger KX-R Auto 2WD","2021 Toyota Kluger Grande Auto 2WD","2018 Toyota Kluger Grande Auto 2WD","2015 Toyota Kluger GX Auto 2WD","2017 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger Grande Auto AWD","2022 Toyota Kluger GXL Auto eFour","2019 Toyota Kluger GX Auto AWD","2021 Toyota Kluger Grande Auto 2WD","2019 Toyota Kluger GX Auto 2WD","2013 Toyota Kluger Grande Auto 2WD","2021 Toyota Kluger GX Auto 2WD","2018 Toyota Kluger Grande Auto AWD","2023 Toyota Kluger GX Auto eFour","2004 Toyota Kluger Grande Auto AWD","2021 Toyota Kluger GXL Auto 2WD","2018 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GX Auto 2WD","2015 Toyota Kluger GXL Auto 2WD","2018 Toyota Kluger GX Auto AWD","2010 Toyota Kluger KX-R Auto 2WD","2021 Toyota Kluger GX Auto 2WD","2022 Toyota Kluger GXL Auto eFour","2017 Toyota Kluger GX Auto AWD","2016 Toyota Kluger GX Auto 2WD","2016 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger GX Auto AWD","2018 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger GX Auto eFour","2018 Toyota Kluger GXL Auto 2WD","2012 Toyota Kluger Altitude Auto 2WD MY12","2019 Toyota Kluger GXL Auto 2WD","2009 Toyota Kluger KX-R Auto AWD","2019 Toyota Kluger GX Auto AWD","2015 Toyota Kluger GX Auto 2WD","2017 Toyota Kluger GX Auto 2WD","2018 Toyota Kluger GX Auto AWD","2019 Toyota Kluger GXL Auto AWD","2019 Toyota Kluger GXL Auto AWD","2008 Toyota Kluger KX-S Auto AWD","2017 Toyota Kluger Grande Auto 2WD","2019 Toyota Kluger GX Auto 2WD","2005 Toyota Kluger CVX Auto AWD","2012 Toyota Kluger KX-S Auto 2WD MY12","2019 Toyota Kluger GXL Auto 2WD","2018 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger Grande Auto eFour","2018 Toyota Kluger GXL Auto 2WD","2011 Toyota Kluger KX-R Auto 2WD MY11","2022 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GXL Auto 2WD","2016 Toyota Kluger GX Auto AWD","2021 Toyota Kluger GXL Auto eFour","2017 Toyota Kluger Grande Auto 2WD","2021 Toyota Kluger GXL Auto AWD","2009 Toyota Kluger KX-R Auto 2WD","2017 Toyota Kluger GXL Auto 2WD","2021 Toyota Kluger GX Auto eFour","2018 Toyota Kluger GX Auto 2WD","2016 Toyota Kluger GX Auto 2WD","2021 Toyota Kluger Grande Auto eFour","2018 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger GXL Auto AWD","2019 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger GX Auto 2WD","2019 Toyota Kluger GXL Auto 2WD","2021 Toyota Kluger GXL Auto eFour","2015 Toyota Kluger Grande Auto 2WD","2022 Toyota Kluger GXL Auto eFour","2010 Toyota Kluger KX-R Auto AWD","2021 Toyota Kluger GXL Auto 2WD","2018 Toyota Kluger GX Auto 2WD","2015 Toyota Kluger GX Auto 2WD","2022 Toyota Kluger GXL Auto eFour","2012 Toyota Kluger KX-R Auto AWD MY12","2022 Toyota Kluger Grande Auto AWD","2019 Toyota Kluger GX Auto 2WD","2010 Toyota Kluger KX-R Auto 2WD","2019 Toyota Kluger Grande Auto AWD","2008 Toyota Kluger KX-R Auto 2WD","2011 Toyota Kluger KX-R Auto AWD MY11","2019 Toyota Kluger Grande Auto AWD","2013 Toyota Kluger KX-R Auto 2WD","2010 Toyota Kluger Altitude Auto 2WD","2018 Toyota Kluger GXL Auto 2WD","2021 Toyota Kluger Grande Auto 2WD","2022 Toyota Kluger GXL Auto eFour","2012 Toyota Kluger KX-R Auto 2WD MY12","2017 Toyota Kluger GX Auto AWD","2013 Toyota Kluger Grande Auto AWD","2018 Toyota Kluger GXL Auto AWD","2012 Toyota Kluger KX-R Auto 2WD MY12","2015 Toyota Kluger GX Auto AWD","2015 Toyota Kluger GXL Auto 2WD"],"html":true,"align":"left","headerStyle":{"font-weight":"normal"}},{"id":"odometer","name":"odometer","type":"numeric","style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","cell":["95011","70000","118000","106854","86748","82112","49756","26000","90000","44","167850","64005","21415","120958","153000","224000","25079","31527","132274","68548","180000","225000","119000","19500","59803","75286","5544","144111","211524","90336","25000","62635","70100","209","83025","23749","67560","50339","95600","62950","60811","105413","99491","144534","54742","213000","27963","25546","11520","210500","49156","72631","79824","157713","244300","18878","62662","83000","97183","146724","115488","26863","245000","115531","200000","93943","70466","75757","290000","158900","55198","19068","123079","46430","59319","130484","156747","91327","107728","58057","70362","24000","84811","2800","28092","93903","60985","106250","5400","32402","56050","97006","137959","1946","210000","51324","176316","112345","68700","61531","154000","141555","167710","14986","14347","206675","103861","91607","20400","18","64650","31429","83836","142471","41680","92000","17642","209431","196","97309","78495","120490","146481","191500","20965","2051","102000","65083","56500","42934","47203","51970","23000","36057","120772","153338","133482","202000","45607","101000","69600","126474","52800","28000","196089","56500","20094","241710","208476","86865","110037","20000","43000","249000","18492","23000","19346","165828","50559","109021","14095","70412","144002","14957","80989","165633","19250","91497","41200","23500","51342","39000","52833","77000","13967","169000","24571","117317","143000","29793","215372","36255","34508","285005","79339","344122","183647","38448","131314","257852","72291","57376","32500","145771","108102","176716","55629","312995","101786","128613"],"html":true,"align":"right","headerStyle":{"font-weight":"normal"}},{"id":"body","name":"body","type":"character","style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","cell":["SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV","SUV"],"html":true,"align":"left","headerStyle":{"font-weight":"normal"}},{"id":"transmission","name":"transmission","type":"character","style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","cell":["Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic","Automatic"],"html":true,"align":"left","headerStyle":{"font-weight":"normal"}},{"id":"engine","name":"engine","type":"character","style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","cell":["6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","4cyl 2.4L Turbo Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.3L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.3L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","2.5i/184kW Hybrid","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol","6cyl 3.5L Petrol"],"html":true,"align":"left","headerStyle":{"font-weight":"normal"}},{"id":"odometer_Mm","name":"odometer_Mm","type":"numeric","style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","cell":["95.011","70.000","118.000","106.854","86.748","82.112","49.756","26.000","90.000","0.044","167.850","64.005","21.415","120.958","153.000","224.000","25.079","31.527","132.274","68.548","180.000","225.000","119.000","19.500","59.803","75.286","5.544","144.111","211.524","90.336","25.000","62.635","70.100","0.209","83.025","23.749","67.560","50.339","95.600","62.950","60.811","105.413","99.491","144.534","54.742","213.000","27.963","25.546","11.520","210.500","49.156","72.631","79.824","157.713","244.300","18.878","62.662","83.000","97.183","146.724","115.488","26.863","245.000","115.531","200.000","93.943","70.466","75.757","290.000","158.900","55.198","19.068","123.079","46.430","59.319","130.484","156.747","91.327","107.728","58.057","70.362","24.000","84.811","2.800","28.092","93.903","60.985","106.250","5.400","32.402","56.050","97.006","137.959","1.946","210.000","51.324","176.316","112.345","68.700","61.531","154.000","141.555","167.710","14.986","14.347","206.675","103.861","91.607","20.400","0.018","64.650","31.429","83.836","142.471","41.680","92.000","17.642","209.431","0.196","97.309","78.495","120.490","146.481","191.500","20.965","2.051","102.000","65.083","56.500","42.934","47.203","51.970","23.000","36.057","120.772","153.338","133.482","202.000","45.607","101.000","69.600","126.474","52.800","28.000","196.089","56.500","20.094","241.710","208.476","86.865","110.037","20.000","43.000","249.000","18.492","23.000","19.346","165.828","50.559","109.021","14.095","70.412","144.002","14.957","80.989","165.633","19.250","91.497","41.200","23.500","51.342","39.000","52.833","77.000","13.967","169.000","24.571","117.317","143.000","29.793","215.372","36.255","34.508","285.005","79.339","344.122","183.647","38.448","131.314","257.852","72.291","57.376","32.500","145.771","108.102","176.716","55.629","312.995","101.786","128.613"],"html":true,"align":"right","headerStyle":{"font-weight":"normal"}},{"id":"year","name":"year","type":"numeric","style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","cell":["2018","2018","2018","2017","2015","2019","2021","2021","2015","2023","2011","2018","2021","2015","2011","2009","2022","2021","2016","2019","2014","2008","2018","2022","2021","2019","2022","2014","2011","2015","2021","2018","2014","2022","2016","2022","2018","2018","2017","2018","2019","2018","2018","2008","2015","2008","2021","2021","2022","2014","2018","2021","2018","2014","2013","2021","2019","2018","2017","2016","2018","2021","2012","2015","2011","2019","2019","2019","2011","2015","2019","2021","2015","2019","2016","2017","2013","2017","2017","2019","2019","2021","2017","2022","2021","2018","2015","2019","2022","2019","2019","2019","2014","2023","2009","2019","2015","2017","2018","2021","2013","2014","2013","2021","2018","2015","2017","2019","2021","2022","2019","2021","2019","2013","2021","2018","2023","2004","2021","2018","2019","2015","2018","2010","2021","2022","2017","2016","2016","2021","2019","2019","2018","2021","2018","2012","2019","2009","2019","2015","2017","2018","2019","2019","2008","2017","2019","2005","2012","2019","2018","2021","2018","2011","2022","2021","2019","2016","2021","2017","2021","2009","2017","2021","2018","2016","2021","2018","2019","2019","2019","2019","2021","2015","2022","2010","2021","2018","2015","2022","2012","2022","2019","2010","2019","2008","2011","2019","2013","2010","2018","2021","2022","2012","2017","2013","2018","2012","2015","2015"],"html":true,"align":"right","headerStyle":{"font-weight":"normal"}},{"id":"drivetrain","name":"drivetrain","type":"character","style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","cell":["AWD","2WD","AWD","AWD","2WD","2WD","2WD","eFour","2WD","AWD","MY11","2WD","eFour","AWD","MY11","2WD","eFour","eFour","AWD","2WD","2WD","2WD","AWD","eFour","eFour","AWD","AWD","2WD","MY11","2WD","eFour","2WD","2WD","eFour","2WD","AWD","AWD","2WD","AWD","2WD","AWD","AWD","2WD","AWD","AWD","2WD","2WD","AWD","eFour","AWD","2WD","eFour","2WD","2WD","AWD","eFour","AWD","AWD","2WD","2WD","2WD","AWD","MY12","AWD","MY11","2WD","AWD","2WD","MY11","AWD","2WD","AWD","AWD","2WD","AWD","AWD","2WD","AWD","2WD","AWD","2WD","2WD","2WD","AWD","2WD","2WD","2WD","AWD","AWD","AWD","AWD","AWD","AWD","eFour","AWD","2WD","2WD","2WD","2WD","eFour","2WD","AWD","2WD","2WD","2WD","2WD","AWD","2WD","AWD","eFour","AWD","2WD","2WD","2WD","2WD","AWD","eFour","AWD","2WD","AWD","2WD","2WD","AWD","2WD","2WD","eFour","AWD","2WD","2WD","2WD","2WD","AWD","2WD","eFour","2WD","MY12","2WD","AWD","AWD","2WD","2WD","AWD","AWD","AWD","AWD","2WD","2WD","AWD","MY12","2WD","2WD","eFour","2WD","MY11","2WD","AWD","2WD","AWD","eFour","2WD","AWD","2WD","2WD","eFour","2WD","2WD","eFour","2WD","AWD","2WD","2WD","2WD","eFour","2WD","eFour","AWD","2WD","2WD","2WD","eFour","MY12","AWD","2WD","2WD","AWD","2WD","MY11","AWD","2WD","2WD","2WD","2WD","eFour","MY12","AWD","AWD","AWD","MY12","AWD","2WD"],"html":true,"align":"left","headerStyle":{"font-weight":"normal"}},{"id":"model","name":"model","type":"character","style":"function(rowInfo, colInfo) {\nconst rowIndex = rowInfo.index + 1\n}","cell":["GX","GXL","GX","Grande","GX","Black","GX","GX","Grande","GXL","KX-R","GX","GX","GXL","Grande","KX-R","Grande","Grande","Grande","GX","GX","KX-R","Grande","Grande","GX","GX","GXL","Grande","KX-R","GX","Grande","GXL","Grande","GX","GXL","Grande","GXL","GXL","Grande","GXL","GXL","GXL","GXL","Grande","GXL","KX-S","GX","Grande","Grande","GXL","GX","GX","GXL","Grande","KX-R","GXL","Black","GXL","GXL","GX","GXL","GX","KX-R","Grande","Grande","Black","GX","GXL","KX-R","Grande","GX","Grande","GXL","GX","Grande","GXL","KX-R","Grande","GX","Grande","GXL","GXL","GXL","Grande","Grande","GX","GXL","GXL","GX","Grande","GXL","GXL","GXL","GX","KX-S","Black","GXL","GX","GXL","GX","Altitude","GXL","KX-R","Grande","Grande","GX","Grande","GX","Grande","GXL","GX","Grande","GX","Grande","GX","Grande","GX","Grande","GXL","Grande","GX","GXL","GX","KX-R","GX","GXL","GX","GX","GX","GX","GX","GX","GX","GX","GXL","Altitude","GXL","KX-R","GX","GX","GX","GX","GXL","GXL","KX-S","Grande","GX","CVX","KX-S","GXL","GX","Grande","GXL","KX-R","GX","Grande","GXL","GX","GXL","Grande","GXL","KX-R","GXL","GX","GX","GX","Grande","GX","GXL","GX","GX","GXL","GXL","Grande","GXL","KX-R","GXL","GX","GX","GXL","KX-R","Grande","GX","KX-R","Grande","KX-R","KX-R","Grande","KX-R","Altitude","GXL","Grande","GXL","KX-R","GX","Grande","GXL","KX-R","GX","GXL"],"html":true,"align":"left","headerStyle":{"font-weight":"normal"}}],"defaultPageSize":10,"showPageSizeOptions":false,"pageSizeOptions":[10,25,50,100],"paginationType":"numbers","showPagination":true,"showPageInfo":true,"minRows":1,"showSortable":true,"height":"auto","theme":{"color":"#333333","backgroundColor":"#FFFFFF","stripedColor":"rgba(128,128,128,0.05)","style":{"fontFamily":"system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif"},"headerStyle":{"borderTopStyle":"solid","borderTopWidth":"2px","borderTopColor":"#D3D3D3","borderBottomStyle":"solid","borderBottomWidth":"2px","borderBottomColor":"#D3D3D3"}},"elementId":"sslhnmgzqr","dataKey":"dcad2c6768aba081006072ede096fc2a"},"children":[]},"class":"reactR_markup"},"evals":["tag.attribs.columns.0.style","tag.attribs.columns.1.style","tag.attribs.columns.2.style","tag.attribs.columns.3.style","tag.attribs.columns.4.style","tag.attribs.columns.5.style","tag.attribs.columns.6.style","tag.attribs.columns.7.style","tag.attribs.columns.8.style","tag.attribs.columns.9.style"],"jsHooks":[]}</script>
</div>

# Taking a Quick Look

Let’s visualise key features of the data. First up we’ll, how does the market price for a Kluger change as the odometers (in megametres):

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-12-1.png" width="672" />
The thing I notice is that looks suspiciously like there’s some sort of negative exponential relationship between the the odometer and price. What if we take a look at the odometer versus the log of the price?

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-13-1.png" width="672" />
This is great; with the log transform we’ve now got a linear relationship between the number odometer of the car and the price. We’re going to end up trying to fit a line to this data, and the log transform provides a nice interpretation for the slope of this line. You might recall that in general when you fit a line to x and y, the slope (\\beta\\) of that line is “the change in the y variable given a change of one unit of the x variable”. When you fit a line to to x and log(y) (called log-linear), for small \\\\, \\e^\\ is the percentage change in y for a one unit change of x.

Here’s the same view, but we split it out by model:

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-14-1.png" width="672" />

# Modelling

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-15-1.png" width="672" />
With our data in hand, what we want to do is create a model that helps us predict the sell price of a Toyota Kluger. In the interests of starting with a very simple model, we’re only going use the odometer reading as a single predictor variable. This means there’s likely a log of

``` r
kluger_model <- cmdstan_model(model_file_path)
kluger_model$print()
```

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
    Chain 1 Iteration:  500 / 2000 [ 25%]  (Warmup) 
    Chain 3 Iteration:  500 / 2000 [ 25%]  (Warmup) 
    Chain 4 Iteration:  500 / 2000 [ 25%]  (Warmup) 
    Chain 2 Iteration: 1000 / 2000 [ 50%]  (Warmup) 
    Chain 2 Iteration: 1001 / 2000 [ 50%]  (Sampling) 
    Chain 3 Iteration: 1000 / 2000 [ 50%]  (Warmup) 
    Chain 3 Iteration: 1001 / 2000 [ 50%]  (Sampling) 
    Chain 1 Iteration: 1000 / 2000 [ 50%]  (Warmup) 
    Chain 1 Iteration: 1001 / 2000 [ 50%]  (Sampling) 
    Chain 4 Iteration: 1000 / 2000 [ 50%]  (Warmup) 
    Chain 4 Iteration: 1001 / 2000 [ 50%]  (Sampling) 
    Chain 2 Iteration: 1500 / 2000 [ 75%]  (Sampling) 
    Chain 3 Iteration: 1500 / 2000 [ 75%]  (Sampling) 
    Chain 4 Iteration: 1500 / 2000 [ 75%]  (Sampling) 
    Chain 1 Iteration: 1500 / 2000 [ 75%]  (Sampling) 
    Chain 2 Iteration: 2000 / 2000 [100%]  (Sampling) 
    Chain 2 finished in 3.7 seconds.
    Chain 3 Iteration: 2000 / 2000 [100%]  (Sampling) 
    Chain 3 finished in 4.2 seconds.
    Chain 4 Iteration: 2000 / 2000 [100%]  (Sampling) 
    Chain 4 finished in 4.8 seconds.
    Chain 1 Iteration: 2000 / 2000 [100%]  (Sampling) 
    Chain 1 finished in 5.1 seconds.

    All 4 chains finished successfully.
    Mean chain execution time: 4.5 seconds.
    Total execution time: 5.2 seconds.

# Assessing the Model

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-19-1.png" width="672" />
<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-20-1.png" width="672" />

![](index_files/figure-html/unnamed-chunk-21-1.gif)<!-- -->

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-22-1.png" width="672" />

# Model Outcomes

<div id="cggyduflpv" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#cggyduflpv table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#cggyduflpv thead, #cggyduflpv tbody, #cggyduflpv tfoot, #cggyduflpv tr, #cggyduflpv td, #cggyduflpv th {
  border-style: none;
}
&#10;#cggyduflpv p {
  margin: 0;
  padding: 0;
}
&#10;#cggyduflpv .gt_table {
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
&#10;#cggyduflpv .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#cggyduflpv .gt_title {
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
&#10;#cggyduflpv .gt_subtitle {
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
&#10;#cggyduflpv .gt_heading {
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
&#10;#cggyduflpv .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#cggyduflpv .gt_col_headings {
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
&#10;#cggyduflpv .gt_col_heading {
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
&#10;#cggyduflpv .gt_column_spanner_outer {
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
&#10;#cggyduflpv .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#cggyduflpv .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#cggyduflpv .gt_column_spanner {
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
&#10;#cggyduflpv .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#cggyduflpv .gt_group_heading {
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
&#10;#cggyduflpv .gt_empty_group_heading {
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
&#10;#cggyduflpv .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#cggyduflpv .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#cggyduflpv .gt_row {
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
&#10;#cggyduflpv .gt_stub {
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
&#10;#cggyduflpv .gt_stub_row_group {
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
&#10;#cggyduflpv .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#cggyduflpv .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#cggyduflpv .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#cggyduflpv .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#cggyduflpv .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#cggyduflpv .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#cggyduflpv .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#cggyduflpv .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#cggyduflpv .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#cggyduflpv .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#cggyduflpv .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#cggyduflpv .gt_footnotes {
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
&#10;#cggyduflpv .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#cggyduflpv .gt_sourcenotes {
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
&#10;#cggyduflpv .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#cggyduflpv .gt_left {
  text-align: left;
}
&#10;#cggyduflpv .gt_center {
  text-align: center;
}
&#10;#cggyduflpv .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#cggyduflpv .gt_font_normal {
  font-weight: normal;
}
&#10;#cggyduflpv .gt_font_bold {
  font-weight: bold;
}
&#10;#cggyduflpv .gt_font_italic {
  font-style: italic;
}
&#10;#cggyduflpv .gt_super {
  font-size: 65%;
}
&#10;#cggyduflpv .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#cggyduflpv .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#cggyduflpv .gt_indent_1 {
  text-indent: 5px;
}
&#10;#cggyduflpv .gt_indent_2 {
  text-indent: 10px;
}
&#10;#cggyduflpv .gt_indent_3 {
  text-indent: 15px;
}
&#10;#cggyduflpv .gt_indent_4 {
  text-indent: 20px;
}
&#10;#cggyduflpv .gt_indent_5 {
  text-indent: 25px;
}
</style>
<table class="gt_table" data-quarto-disable-processing="false" data-quarto-bootstrap="false">
  <thead>
    &#10;    <tr class="gt_col_headings">
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="variable">variable</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="mean">mean</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="median">median</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="sd">sd</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr><td headers="variable" class="gt_row gt_left">a</td>
<td headers="mean" class="gt_row gt_right">11.136921050</td>
<td headers="median" class="gt_row gt_right">11.13700000</td>
<td headers="sd" class="gt_row gt_right">1.074327e-02</td></tr>
    <tr><td headers="variable" class="gt_row gt_left">b</td>
<td headers="mean" class="gt_row gt_right">-0.006262985</td>
<td headers="median" class="gt_row gt_right">-0.00626385</td>
<td headers="sd" class="gt_row gt_right">8.877914e-05</td></tr>
    <tr><td headers="variable" class="gt_row gt_left">sigma</td>
<td headers="mean" class="gt_row gt_right">0.205473454</td>
<td headers="median" class="gt_row gt_right">0.20533850</td>
<td headers="sd" class="gt_row gt_right">4.700010e-03</td></tr>
  </tbody>
  &#10;  
</table>
</div>

``` r
kluger_quantile <-
    kluger_fit |>
    spread_draws(price_pred) |>
    reframe(
        interval = c(.11, .89),
        value = quantile(price_pred, interval)
    ) |>
    spread(interval, value)

kluger_fit |>
    recover_types() |>
    spread_draws(price_pred) |>
    ggplot() +
    geom_histogram(aes(price_pred), bins = 200) +
    geom_vline(xintercept = kluger_quantile[['0.11']], color = 'blue', linewidth = 1, linetype = 'dotted') +
    geom_vline(xintercept = kluger_quantile[['0.89']], color = 'blue', linewidth = 1, linetype = 'dotted') +
    scale_x_continuous(labels = scales::dollar) +
    scale_y_continuous(labels = scales::comma) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) + 
    labs(
        x = "Count",
        y = "Predicted Price ($)",
        title = "Toyota Kluger Price Prediction",
        subtitle = "Distribution of Price Prediction at 60,000km"
    )
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-24-1.png" width="672" />

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-25-1.png" width="672" />

``` r
kluger_fit$summary()
```

    # A tibble: 1,018 × 10
       variable       mean   median      sd     mad       q5      q95  rhat ess_bulk
       <chr>         <num>    <num>   <num>   <num>    <num>    <num> <num>    <num>
     1 lp__     1097.       1.10e+3 1.20e+0 1.01e+0  1.09e+3  1.10e+3  1.00    1186.
     2 a          11.1      1.11e+1 1.07e-2 1.08e-2  1.11e+1  1.12e+1  1.00    1564.
     3 b          -0.00626 -6.26e-3 8.88e-5 8.73e-5 -6.41e-3 -6.12e-3  1.00    2056.
     4 sigma       0.205    2.05e-1 4.70e-3 4.84e-3  1.98e-1  2.13e-1  1.01    1548.
     5 y_s[1]     11.0      1.10e+1 2.03e-1 1.99e-1  1.06e+1  1.13e+1  1.00    3962.
     6 y_s[2]     10.7      1.07e+1 2.06e-1 2.03e-1  1.03e+1  1.10e+1  1.00    3913.
     7 y_s[3]     10.6      1.06e+1 2.04e-1 2.08e-1  1.03e+1  1.10e+1  1.00    4068.
     8 y_s[4]      9.86     9.86e+0 2.10e-1 2.15e-1  9.52e+0  1.02e+1  1.00    3967.
     9 y_s[5]     11.1      1.11e+1 2.06e-1 2.04e-1  1.08e+1  1.15e+1  1.00    3480.
    10 y_s[6]     11.1      1.11e+1 2.06e-1 2.05e-1  1.08e+1  1.14e+1  1.00    3747.
    # ℹ 1,008 more rows
    # ℹ 1 more variable: ess_tail <num>
