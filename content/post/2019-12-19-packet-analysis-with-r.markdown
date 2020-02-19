---
title: Packet Analysis with R (Part 1)
author: ~
date: '2019-11-20'
slug: packet-analysis-with-r-part-1
categories: [R, Perl]
tags: [R Perl PCAP Networking]
description: ''
output: md_document
always_allow_html: yes
---

In this article I am going to be look at some of the ways you can analyse packet captures with R. It is broken in to three mainI am a network and security consultant by trade,
but recently I have become enamoured with [R]() and the R community.  Network engineer, learning more about data science and statistical modeling.

The joy of learning something that is outside your normal field is when you start to see intersections between it and what you've always been doing.
For me this happened when reading the chapter of Hadley Wickham's [R for Data Science](https://vita.had.co.nz/papers/tidy-data.pdf) on [tidy data](https://vita.had.co.nz/papers/tidy-data.pdf).

To summarise, tidy data has three key elements:

1. Each variable must have its own column.
1. Each observation must have its own row.
1. Each value must have its own cell.

What hit me was that this perfectly described a packet capture. Each captured packet is an observation in a row, and the values the dissectors return
are the columns containin the variables. I started to imagine the kinds of data analysis and visualisations that could be performed on the packet data.

In this article I want to show how valuable it is to perform packet analysis using the R language. It's broken into two sections: converting packet capture files
into a format appropraite for ingestion into R (in this case it's comma separated values), and then performing some initial 
[exploratory data analysis](https://en.wikipedia.org/wiki/Exploratory_data_analysis) on the capture to describe and visualise it's main characteristics.

# Removing the False Dichotomy

Before moving on, I want to be clear that I don't think that this is a replacement for packet analysis in Wireshark. Rather, I see it as a complimentary tool
that with both strengths and weaknesses. I think of Wireshark as a bottom-up tool: you open a packet capture an immediately you're thrust amongst the packets,
barraged with details. This is perfect if you know what you're looking for and can filter out the noise to concentrate on your problem. But if you don't have
a clear view of what's in the packet capture or where the problem may lie, taking a step back and removing yourself from the details can be difficult.

Analysing packet captures with R is a top-down aproach. You load your packet capture and you're presented with nothing. But what you have at your disposal is 
a richer set of tools to summarise and visualise the packets and get a broader sense of what is happening across the entire capture, and at any point in the 
protocol layers: data-link, network, transport, or application.

# PCAP to CSV Transformation

The first step is to convert the packet capture file into a format that R can ingest. I chose the comma separate values format (CSV) as it is human readable. [SQLLite](https://www.sqlite.org/index.html) and [Parquet](https://parquet.apache.org/) are other viable options. In this article the packet captures I am transoforming are < 100Mb, so CSV works fine. CSV may (read: will likely) have issues for packet capture files larger than this, but for the moment [good enough is good enough](https://en.wikipedia.org/wiki/Principle_of_good_enough).

In the code below, we download a sample packet capture file and the PCAP to CSV conversion script.


```r
packet_capture <- './sample.pcap'
pcap_to_csv <- './pcap_to_csv'
```


```r
# Download the sample packet capture
if (!file.exists(packet_capture)) {
    download.file(
        url = 'https://s3.amazonaws.com/tcpreplay-pcap-files/smallFlows.pcap',
        destfile = packet_capture
    )
}

# Download the PCAP to CSV script to the CWD.
download.file(
    url = 'https://raw.githubusercontent.com/gregfoletta/PCAP_to_CSV/master/pcap_to_csv.pl',
    destfile = pcap_to_csv
)
```

We then run the script across the sample packet capture we've downloaded to convert it into a CSV. At a high level the script:

- Takes a list of dissectors.
    - The default dissectors are those beginning with frame|eth|ip|arp|tcp|udp|icmp|dns|ssl|http|smb.
- Spawns a `tshark` process which runs over the packet catpure, outputting the specifed fields in JSON format to STDOUT.
- Reads the JSON from STDOUT and flattens the data structure.
    - e.g. `{ http.cookie_pair => [ 'a=1', 'b=2' ] }` becomes `{ http.cookie_pair.0 => 'a=1', http.cookie_pair.1 => 'b=2' }`
- Outputs all of the fields as CSV.

Spawning the tshark process and reading from STDOUT is not the cleanest of inplementations, but it does the job we need it to do.


```zsh
perl pcap_to_csv sample.pcap

# What's the size differential?
ls -lh sample.pcap*
```

```
## Gathering dissectors...
## Extracting packets...
## Decoding JSON...
## Flattening packets...
## Creating sample.pcap.csv
## -rw-rw-r-- 1 puglet puglet 9.1M Feb 19 12:39 sample.pcap
## -rw-rw-r-- 1 puglet puglet 101M Feb 19 12:39 sample.pcap.csv
```

We see there's about a 10:1 size ratio between the CSV and the original packet capture.

We now ingest the CSV file into R and perform some mutations to the data:

1. We remove the '.0' from the end of variable names. This allows us to refer directly to variables that are only in a frame once, e.g. `pcap['tcp.dstport']` instead of `pcap['tcp.dstport.0']`.
1. The `frame.time` field is changed to a `POSIXct` date-time class rather than a simple character string.

We then take a look at the first 10 rows of some selected fields.


```r
library(glue)
library(tidyverse)
library(kableExtra)

# Ingest the packet capture
pcap <- 
    glue(packet_capture, ".csv") %>%
    read_csv(guess_max = 100000)

# Remove the ':0' from the column names
names(pcap) <- names(pcap) %>% str_remove('\\.0$')

# Update the frame.time column
pcap <-
    pcap %>%
    mutate(frame.time = as.POSIXct(
        frame.time_epoch,
        tz = 'UTC',
        origin = '1970-01-01 00:00.00 UTC'
    ))

# Take a look at some of the columns in the first 10 rows
pcap %>%
    select(
        frame.time,
        ip.src, ip.dst, 
        tcp.dstport, tcp.stream
    ) %>%
    slice(1:5)
```

```
## # A tibble: 5 x 5
##   frame.time          ip.src        ip.dst        tcp.dstport tcp.stream
##   <dttm>              <chr>         <chr>               <dbl>      <dbl>
## 1 2011-01-25 18:52:22 192.168.3.131 72.14.213.138          80          0
## 2 2011-01-25 18:52:22 72.14.213.138 192.168.3.131       57011          0
## 3 2011-01-25 18:52:22 192.168.3.131 72.14.213.102          80          1
## 4 2011-01-25 18:52:22 192.168.3.131 72.14.213.138          80          0
## 5 2011-01-25 18:52:22 72.14.213.102 192.168.3.131       55950          1
```


# Wireshark Analogies

Now that we've got our data in to R, let's explore it. To start we're going to create some of the graphs and other analysis out puts you would find in Wireshark.

## IO Graph

This is the default graph you would find by going to [Statistics -> I/O Graph] in Wireshark.
We round the each frame's time to the nearest second and group by this value. We then tally up
the number of frames occurring within each of these seconds and graph is as a line graph.


```r
pcap %>%
    group_by(t = round(frame.time_relative)) %>%
    tally() %>%
    ggplot() +
    geom_line(aes(t, n)) +
    labs(x = 'Seconds Since Start of Capture', y = 'Frame Count')
```

<img src="/post/2019-12-19-packet-analysis-with-r_files/figure-html/packets_per_second-1.png" width="672" />

## IP Conversations

This is similar to the output you would get by going to [Statistics -> Conversations -> IP]. We group by 
each source and destination IP address and count the number of packets and the number of kiobytes in each
of these *unidirectional* IP conversations. 


```r
pcap %>%
    group_by(ip.src, ip.dst) %>%
    summarise(
        packets = n(),
        kbytes = sum(frame.len)/1000
    ) %>%
    arrange(desc(packets)) %>%
    head() %>%
    kable() %>%
    kable_styling()
```

<table class="table" style="margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> ip.src </th>
   <th style="text-align:left;"> ip.dst </th>
   <th style="text-align:right;"> packets </th>
   <th style="text-align:right;"> kbytes </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 65.54.95.68 </td>
   <td style="text-align:left;"> 192.168.3.131 </td>
   <td style="text-align:right;"> 1275 </td>
   <td style="text-align:right;"> 1718.702 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 204.14.234.85 </td>
   <td style="text-align:left;"> 192.168.3.131 </td>
   <td style="text-align:right;"> 1036 </td>
   <td style="text-align:right;"> 956.946 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 65.54.95.75 </td>
   <td style="text-align:left;"> 192.168.3.131 </td>
   <td style="text-align:right;"> 766 </td>
   <td style="text-align:right;"> 878.941 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 192.168.3.131 </td>
   <td style="text-align:left;"> 204.14.234.85 </td>
   <td style="text-align:right;"> 740 </td>
   <td style="text-align:right;"> 478.420 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 192.168.3.131 </td>
   <td style="text-align:left;"> 65.54.95.68 </td>
   <td style="text-align:right;"> 664 </td>
   <td style="text-align:right;"> 66.932 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 65.54.95.140 </td>
   <td style="text-align:left;"> 192.168.3.131 </td>
   <td style="text-align:right;"> 658 </td>
   <td style="text-align:right;"> 762.505 </td>
  </tr>
</tbody>
</table>

## Protocols

In this graph we're trying to emulate [Statistics -> Protocol Hierarchy]. The `frame.protocols` field lists the dissectors used in the frame separated by a colon. A regex is used to extract out the first four dissectors and create a new variable. This variable is grouped variable and count the number of frames for each one.

We graph the output slightly differently, first flipping the coordinates to that the x-axis runs top to bottom and y-axis runs left to right, then scaling the x-axis logarithmically.

No surprises that TCP traffic accounts for the most packets, followed by SSL (TLS) and HTTP.


```r
pcap %>%
    mutate(first_4_proto = str_extract(frame.protocols, '(\\w+)(:\\w+){0,4}')) %>%
    count(first_4_proto) %>%
    ggplot() +
    geom_col(aes(fct_reorder(first_4_proto, n), n)) +
    coord_flip() +
    scale_y_log10() +
    labs(x = 'First Four Dissectors', y = 'Total Frames (Log Scale)')
```

<img src="/post/2019-12-19-packet-analysis-with-r_files/figure-html/protocols-1.png" width="672" />

## Packet Lengths

This graph is a visual representation of [Statistics -> Packet Lengths]. The axis is broken up into bins of 50 bytes, and the height of each bar represents the log of the number of packets seen with a size within that range. The bars are also colourised based on whether the packet is a TCP acknowledgement or not.


```r
pcap %>%
    ggplot() +
    geom_histogram(aes(frame.len, fill = !is.na(tcp.analysis.acks_frame)), binwidth = 50) +
    labs(x = 'Number of Frames', y = 'Frame Size - Log(Bytes)', fill = 'Is ACK Segment?') +
    scale_y_log10()
```

<img src="/post/2019-12-19-packet-analysis-with-r_files/figure-html/packet_lengths-1.png" width="672" />


# Eploratory

We've emulated (to an extent) some of the Wireshark statistical information, let's dig a little deeper and see what else we can discover about this particular packet capture.

## HTTP Hosts

Let's explore what HTTP hosts requests are being made to. We filter out all packets without the `http.host` field, which contains the value of the [Host header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Host), and count the number of occurences of each distinct value. This could is represented as a column

We see an MSN address topping the list, however interestingly a broadcast address is second.


```r
    pcap %>%
    dplyr::filter(!is.na(http.host)) %>%
    count(http.host) %>%
    top_n(20, n) %>%
    ggplot() +
    geom_col(aes(fct_reorder(http.host, n), n)) +
    coord_flip() +
    labs(x = 'Host', y = 'Number of HTTP requests')
```

<img src="/post/2019-12-19-packet-analysis-with-r_files/figure-html/unnamed-chunk-2-1.png" width="672" />

Let's dive a little deeper on this - what are the protocols of these multicast HTTP packets?


```r
pcap %>% 
    dplyr::filter(http.host == '239.255.255.250:1900') %>% 
    select(frame.protocols) %>%
    distinct()
```

```
## # A tibble: 2 x 1
##   frame.protocols                  
##   <chr>                            
## 1 eth:ethertype:ip:udp:ssdp        
## 2 eth:ethertype:ip:icmp:ip:udp:ssdp
```

We see that it's [SSDP](https://en.wikipedia.org/wiki/Simple_Service_Discovery_Protocol) broadcasting out, as well as other hosts responding with ICMP messgaes. What are the ICMP messages?


```r
pcap %>%
    dplyr::filter(frame.protocols == 'eth:ethertype:ip:icmp:ip:udp:ssdp') %>%
    select(icmp.type, icmp.code)
```

```
## # A tibble: 20 x 2
##    icmp.type icmp.code
##        <dbl>     <dbl>
##  1        11         0
##  2        11         0
##  3        11         0
##  4        11         0
##  5        11         0
##  6        11         0
##  7        11         0
##  8        11         0
##  9        11         0
## 10        11         0
## 11        11         0
## 12        11         0
## 13        11         0
## 14        11         0
## 15        11         0
## 16        11         0
## 17        11         0
## 18        11         0
## 19        11         0
## 20        11         0
```

Type 11 (time exceeded) code 0 (time to tive exceeded in transit) messages.

## TLS Versions and Ciphers

Taking more of a security bent on our analysis, we'll take a look at the SSL/TLS versions and ciphers being used.

During the TLS handshake, the ClientHello message has two versions: the record version which indicates which version of the ClientHello is being sent, and the handshake version which indicates the version of the protocol the client/server wishes to communicate on during the session. We're concerned with the handshake version:


```r
pcap %>%
    dplyr::filter(!is.na(ssl.handshake.version)) %>%
    count(ssl.handshake.version)
```

```
## # A tibble: 2 x 2
##   ssl.handshake.version     n
##   <chr>                 <int>
## 1 0x00000300               10
## 2 0x00000301              126
```

The predominant verison is TLS 1.1 (0x0301), with some TLS 1.0 (0x0300).

What about the ciphers being used? By filtering out


```r
pcap %>%
    dplyr::filter(!is.na(ssl.handshake.ciphersuite)) %>%
    select(ssl.handshake.ciphersuite)
```

```
## # A tibble: 122 x 1
##    ssl.handshake.ciphersuite
##                        <dbl>
##  1                     49162
##  2                         5
##  3                     49162
##  4                     49162
##  5                     49162
##  6                     49162
##  7                     49162
##  8                     49162
##  9                         5
## 10                         5
## # … with 112 more rows
```

We don't get the ciphersuite in a human readable format, instead we get the the decimal version of the two-byte identification number. This makes it's difficult to make a security judgement on these ciphers.

Let's translate these into a human readable format. The [website](http://realtimelogic.com/ba/doc/en/C/shark/group__SharkSslCiphers.html) that has a translation table and also - thankfully - has a CSS element that we can use to pull out the values.

The `rvest` library is used to download the page, pull out the table entries, and convert them to text. Each entry is a string with the ciphersuite name and hex separated by spaces, so those are split, and finally the columns are given sensible names.


```r
library(rvest)

cipher_mappings <-
    xml2::read_html('http://realtimelogic.com/ba/doc/en/C/shark/group__SharkSslCiphers.html') %>%
    html_nodes('.memItemRight') %>%
    html_text() %>%
    str_split_fixed("\\s+", n = 2) %>%
    as_tibble(.name_repair = ~{ c('ciphersuite', 'hex_value') }) %>%
    mutate(hex_value = as.hexmode(hex_value))

head(cipher_mappings)
```

```
## # A tibble: 6 x 2
##   ciphersuite              hex_value
##   <chr>                    <hexmode>
## 1 TLS_NULL_WITH_NULL_NULL  0        
## 2 TLS_RSA_WITH_NULL_MD5    1        
## 3 TLS_RSA_WITH_NULL_SHA    2        
## 4 TLS_RSA_WITH_RC4_128_MD5 4        
## 5 TLS_RSA_WITH_RC4_128_SHA 5        
## 6 TLS_RSA_WITH_DES_CBC_SHA 9
```

We're only concerned with the ciphersuite the ServerHello responds with, because this is the one that is ultimately used. Thus other records are filtered out, the number of discrete ciphersuites is counted, and the values converted to hex.

A left join by the hex values is performed which adds the `ciphersuite` column to the data. The data is presented as a bar graph, the height of the bar representing the number of times each ciphersuite was used in an TLS connection.



```r
pcap %>%
    dplyr::filter(ssl.handshake.type == 2) %>%
    count(ssl.handshake.ciphersuite) %>%
    mutate(ssl.handshake.ciphersuite = as.hexmode(ssl.handshake.ciphersuite)) %>%
    left_join(cipher_mappings, by = c('ssl.handshake.ciphersuite' = 'hex_value')) %>%
    ggplot() +
    geom_col(aes(ciphersuite, n)) +
    coord_flip() +
    labs(x = 'TLS Ciphersuite', y = 'Total TLS Sessions')
```

<img src="/post/2019-12-19-packet-analysis-with-r_files/figure-html/tls_ciphers-1.png" width="672" />

## DNS Response Times

In this section we'll be looking at DNS response times. First off let's find out what DNS servers hosts are using, and what the average response times are:

```{r 


```r
pcap %>%
    dplyr::filter(dns.flags.response == 1) %>%
    group_by(dns.qry.name, dns.resp.type) %>%
    summarise(mean_resp = mean(dns.time)) %>%
    ggplot() +
    geom_col(aes(fct_reorder(dns.qry.name, mean_resp), mean_resp, fill = as.factor(dns.resp.type))) +
    coord_flip() +
    labs(x = 'DNS Query Name', y = 'Mean Response Time (ms)', fill = 'DNS Response Type')
```

<img src="/post/2019-12-19-packet-analysis-with-r_files/figure-html/unnamed-chunk-3-1.png" width="672" />



