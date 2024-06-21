---
title: TCP Analysis
author: ''
date: '2024-04-07'
slug: []
categories: []
tags: []
images: []
---



I currently work for a [network & security vendor](https://fortinet.com) whos main product is a firewall. When sizing firewalls there's a two main things to consider: the throughput, and the conncurrent connections. Sizing based on throughput is relatively easy: what's the aggregate bandwidth connected to the device. But concurrent connections is a little harder. Imagine a head office with 200 people, how many concurrent connections would you expect? Also, what's our certainty about this?

In this article we're going to try and answer this question by taking Bayesian perspective. We'll do this by using real packet capture data from my laptop, and using this as an input to a STAN program. THe STAN program estimate the parameters for the probability distributions for the connections per second, and the connection duration. We'll then simulate connections by pulling values from these probability distributions.

The result is an idea of the probable concurrent connections that we can use to size our firewall.

# Caveats Firsts

Let's be up-front in where the flaws are with this. The first is that it's predicated on everyone else's behaviour looking like mine. For an office scenario I don't think this is too far fetched: my data was taken during a normal work day, so it's got Microsoft Teams, web-browsing, Outlook; the standard worker fare. But we need to be aware that not everyones traffic profile looks like this.

The second is that in real life, concurrent connections rise and fall like the tide based on people's behaviour.


# Traffic Data

I used `tshark` to capture my wlan0 interface over the course of the day, piping this in to `jq` to filter out the fields I didn't need to reduce the size. The commandline looked like this:

```
tshark -Tjson -J 'frame eth ip tcp udp' -iwlan0 | jq --stream --from-file pcap_stream_filter.jq > 20240417_pcap.json
```


```json
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

- Filter out the TCP traffic






```r
pcap <-
    pcap |>
    separate(
        frame.protocols,
        into = paste0('frame.protocols.', c('l1', 'l2', 'l3', 'l4', 'l5', 'remain')), sep = ':',
        extra = 'merge',
        remove = FALSE 
    )
```

```r
pcap |>
    ggplot() +
    geom_bar(aes(frame.protocols.l4)) +
    scale_y_log10() +
    labs(
        x = "Protocol",
        y = "Count (Log 10 Scale)"
    )
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-3-1.png" width="672" />

```r
pcap |>
    filter(frame.protocols.l4 == 'udp') |>
    ggplot() +
    geom_bar(aes(frame.protocols.l5)) +
    scale_y_log10()
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-4-1.png" width="672" />



```r
pcap_reduced <-
    pcap |>
    # Filter out TCP and UDP
    filter(!is.na(udp.stream) | !is.na(tcp.stream)) |>
    unnest(tcp.flags_tree) |> 
    mutate(
        time = as.double(frame.time_epoch),
        id = as.double(frame.number)
    ) |> 
    mutate(time  = as.POSIXct(time)) |> 
    select(c(time, frame.time_relative, id, eth.src, eth.dst, tcp.stream, udp.stream, tcp.srcport, tcp.dstport, tcp.flags.syn, tcp.flags.ack, tcp.flags.fin, tcp.flags.reset, flags_string = tcp.flags.str)) |>
    mutate(across(c( starts_with('tcp.'), udp.stream ), as.integer)) |>
    mutate(frame.time_relative = as.double(frame.time_relative))



# Split out TCP and UDP
tcp_segments <- pcap_reduced |> filter(!is.na(tcp.stream)) |> arrange(time)
udp_datagrams <- pcap_reduced |> filter(!is.na(udp.stream)) |> select(-starts_with('tcp')) |> filter(!str_detect(eth.dst, '^(33:33|01:00|ff:ff)')) |>  arrange(time)
```



# Connections Per Second


```r
# UDP connections based simply on first datagram per stream seen
udp_connections <-
    udp_datagrams |>
    mutate(time = as.integer(time)) |> 
    group_by(udp.stream) |>
    filter(n() > 1 & row_number() == 1) |>
    ungroup() |>
    count(time, name = 'cps') |> 
    full_join(
        tibble(
            time = as.integer( first(udp_datagrams$time):last(udp_datagrams$time) ),
        ),
        by = 'time'
    ) |> 
    arrange(time) |> 
    mutate(cps = if_else(is.na(cps), 0, cps))

# TCP connections are based on the the first SYN seen
tcp_connections <-
    tcp_segments |>
    mutate(time = as.integer(time)) |> 
    group_by(tcp.stream) |> 
    # Filter out any where by haven't seen the initial SYN
    filter(any(tcp.flags.syn == 1 & tcp.flags.ack == 0)) |>
    # Filter out any where we've ONLY seen the initial SYN
    filter(!all(tcp.flags.syn == 1)) |>   group_by(tcp.stream) |> 
    ungroup() |> 
    group_by(time) |>
    summarise(cps = sum(tcp.flags.syn)) |> 
    full_join(
        tibble(
            time = as.integer( first(tcp_segments$time):last(tcp_segments$time) ),
        ),
        by = 'time'
    ) |>
    arrange(time) |>
    mutate(cps = if_else(is.na(cps), 0, cps))


# Merge TCP and UDP back together
connections_per_second <- tcp_connections
    #bind_rows(tcp_connections, udp_connections) |>
    #group_by(time) |>
    #summarise(cps = sum(cps))
```


```r
connections_per_second |>
    ggplot() +
    geom_histogram(aes(cps), binwidth = 1)
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-5-1.png" width="672" />

# Connection Length


```r
# UDP session length
udp_session_length <-
    udp_datagrams |>
    group_by(udp.stream) |>
    filter(n() != 1) |>
    summarise(duration = last(frame.time_relative) - first(frame.time_relative))

######
# This needs to be more accurate
tcp_session_length <-
    tcp_segments |>
    group_by(tcp.stream) |>
    # Remove streams where we haven't seen the initial SYN
    filter(first(tcp.flags.syn) == 1 & first(tcp.flags.ack == 0) ) |>
    # Remove streams with no ACKs
    filter(any(tcp.flags.ack)) |>
    # Remove streams with no RST or FIN
    filter(!any(tcp.flags.fin) | !any(tcp.flags.reset)) |> 
    summarise(duration = last(frame.time_relative) - first(frame.time_relative)) 

session_length <- tcp_session_length
    #bind_rows(tcp_session_length, udp_session_length) |>
    #pivot_longer(cols = ends_with('stream'), names_to = 'protocol', values_to = 'stream', values_drop_na = TRUE) |>
    #arrange(stream)
```



```r
session_length |> 
    ggplot() +
    geom_histogram(aes(duration), bins = 256) +
    scale_x_continuous(limits = c(10, 600))
```

```
Warning: Removed 423 rows containing non-finite outside the scale range
(`stat_bin()`).
```

```
Warning: Removed 2 rows containing missing values or values outside the scale range
(`geom_bar()`).
```

<img src="{{< blogdown/postref >}}index_files/figure-html/session_histogram-1.png" width="672" />




# Modelling


```r
tcp_model <- cmdstan_model('tcp_user_model.stan')

tcp_fit <- tcp_model$sample(
    data = compose_data(
        cps = select(connections_per_second, cps),
        duration = select(session_length, duration)
    ),
    seed = 1234,
    chains = 4,
    parallel_chains = 4,
    refresh = 1000,
)
```

```
Running MCMC with 4 parallel chains...

Chain 1 Iteration:    1 / 2000 [  0%]  (Warmup) 
```

```
Chain 1 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
```

```
Chain 1 Exception: neg_binomial_lpmf: Inverse scale parameter is 0, but must be positive finite! (in '/tmp/RtmpTVFVHd/model-42172520e4c80.stan', line 30, column 4 to column 42)
```

```
Chain 1 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
```

```
Chain 1 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
```

```
Chain 1 
```

```
Chain 1 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
```

```
Chain 1 Exception: neg_binomial_lpmf: Inverse scale parameter is 0, but must be positive finite! (in '/tmp/RtmpTVFVHd/model-42172520e4c80.stan', line 30, column 4 to column 42)
```

```
Chain 1 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
```

```
Chain 1 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
```

```
Chain 1 
```

```
Chain 1 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
```

```
Chain 1 Exception: gamma_lpdf: Inverse scale parameter is 0, but must be positive finite! (in '/tmp/RtmpTVFVHd/model-42172520e4c80.stan', line 31, column 4 to column 38)
```

```
Chain 1 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
```

```
Chain 1 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
```

```
Chain 1 
```

```
Chain 1 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
```

```
Chain 1 Exception: gamma_lpdf: Inverse scale parameter is 0, but must be positive finite! (in '/tmp/RtmpTVFVHd/model-42172520e4c80.stan', line 31, column 4 to column 38)
```

```
Chain 1 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
```

```
Chain 1 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
```

```
Chain 1 
```

```
Chain 1 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
```

```
Chain 1 Exception: gamma_lpdf: Inverse scale parameter is 0, but must be positive finite! (in '/tmp/RtmpTVFVHd/model-42172520e4c80.stan', line 31, column 4 to column 38)
```

```
Chain 1 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
```

```
Chain 1 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
```

```
Chain 1 
```

```
Chain 1 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
```

```
Chain 1 Exception: neg_binomial_lpmf: Shape parameter is inf, but must be positive finite! (in '/tmp/RtmpTVFVHd/model-42172520e4c80.stan', line 30, column 4 to column 42)
```

```
Chain 1 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
```

```
Chain 1 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
```

```
Chain 1 
```

```
Chain 1 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
```

```
Chain 1 Exception: neg_binomial_lpmf: Shape parameter is inf, but must be positive finite! (in '/tmp/RtmpTVFVHd/model-42172520e4c80.stan', line 30, column 4 to column 42)
```

```
Chain 1 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
```

```
Chain 1 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
```

```
Chain 1 
```

```
Chain 1 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
```

```
Chain 1 Exception: gamma_lpdf: Inverse scale parameter is 0, but must be positive finite! (in '/tmp/RtmpTVFVHd/model-42172520e4c80.stan', line 31, column 4 to column 38)
```

```
Chain 1 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
```

```
Chain 1 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
```

```
Chain 1 
```

```
Chain 2 Iteration:    1 / 2000 [  0%]  (Warmup) 
```

```
Chain 2 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
```

```
Chain 2 Exception: neg_binomial_lpmf: Inverse scale parameter is 0, but must be positive finite! (in '/tmp/RtmpTVFVHd/model-42172520e4c80.stan', line 30, column 4 to column 42)
```

```
Chain 2 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
```

```
Chain 2 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
```

```
Chain 2 
```

```
Chain 2 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
```

```
Chain 2 Exception: neg_binomial_lpmf: Inverse scale parameter is 0, but must be positive finite! (in '/tmp/RtmpTVFVHd/model-42172520e4c80.stan', line 30, column 4 to column 42)
```

```
Chain 2 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
```

```
Chain 2 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
```

```
Chain 2 
```

```
Chain 2 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
```

```
Chain 2 Exception: gamma_lpdf: Inverse scale parameter is 0, but must be positive finite! (in '/tmp/RtmpTVFVHd/model-42172520e4c80.stan', line 31, column 4 to column 38)
```

```
Chain 2 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
```

```
Chain 2 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
```

```
Chain 2 
```

```
Chain 2 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
```

```
Chain 2 Exception: gamma_lpdf: Inverse scale parameter is 0, but must be positive finite! (in '/tmp/RtmpTVFVHd/model-42172520e4c80.stan', line 31, column 4 to column 38)
```

```
Chain 2 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
```

```
Chain 2 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
```

```
Chain 2 
```

```
Chain 2 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
```

```
Chain 2 Exception: gamma_lpdf: Inverse scale parameter is 0, but must be positive finite! (in '/tmp/RtmpTVFVHd/model-42172520e4c80.stan', line 31, column 4 to column 38)
```

```
Chain 2 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
```

```
Chain 2 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
```

```
Chain 2 
```

```
Chain 2 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
```

```
Chain 2 Exception: gamma_lpdf: Inverse scale parameter is 0, but must be positive finite! (in '/tmp/RtmpTVFVHd/model-42172520e4c80.stan', line 31, column 4 to column 38)
```

```
Chain 2 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
```

```
Chain 2 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
```

```
Chain 2 
```

```
Chain 2 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
```

```
Chain 2 Exception: neg_binomial_lpmf: Shape parameter is inf, but must be positive finite! (in '/tmp/RtmpTVFVHd/model-42172520e4c80.stan', line 30, column 4 to column 42)
```

```
Chain 2 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
```

```
Chain 2 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
```

```
Chain 2 
```

```
Chain 2 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
```

```
Chain 2 Exception: neg_binomial_lpmf: Shape parameter is inf, but must be positive finite! (in '/tmp/RtmpTVFVHd/model-42172520e4c80.stan', line 30, column 4 to column 42)
```

```
Chain 2 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
```

```
Chain 2 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
```

```
Chain 2 
```

```
Chain 2 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
```

```
Chain 2 Exception: gamma_lpdf: Inverse scale parameter is 0, but must be positive finite! (in '/tmp/RtmpTVFVHd/model-42172520e4c80.stan', line 31, column 4 to column 38)
```

```
Chain 2 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
```

```
Chain 2 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
```

```
Chain 2 
```

```
Chain 3 Iteration:    1 / 2000 [  0%]  (Warmup) 
```

```
Chain 3 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
```

```
Chain 3 Exception: neg_binomial_lpmf: Shape parameter is 0, but must be positive finite! (in '/tmp/RtmpTVFVHd/model-42172520e4c80.stan', line 30, column 4 to column 42)
```

```
Chain 3 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
```

```
Chain 3 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
```

```
Chain 3 
```

```
Chain 3 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
```

```
Chain 3 Exception: neg_binomial_lpmf: Shape parameter is 0, but must be positive finite! (in '/tmp/RtmpTVFVHd/model-42172520e4c80.stan', line 30, column 4 to column 42)
```

```
Chain 3 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
```

```
Chain 3 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
```

```
Chain 3 
```

```
Chain 3 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
```

```
Chain 3 Exception: gamma_lpdf: Inverse scale parameter is 0, but must be positive finite! (in '/tmp/RtmpTVFVHd/model-42172520e4c80.stan', line 31, column 4 to column 38)
```

```
Chain 3 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
```

```
Chain 3 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
```

```
Chain 3 
```

```
Chain 3 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
```

```
Chain 3 Exception: neg_binomial_lpmf: Shape parameter is 0, but must be positive finite! (in '/tmp/RtmpTVFVHd/model-42172520e4c80.stan', line 30, column 4 to column 42)
```

```
Chain 3 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
```

```
Chain 3 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
```

```
Chain 3 
```

```
Chain 3 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
```

```
Chain 3 Exception: neg_binomial_lpmf: Shape parameter is 0, but must be positive finite! (in '/tmp/RtmpTVFVHd/model-42172520e4c80.stan', line 30, column 4 to column 42)
```

```
Chain 3 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
```

```
Chain 3 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
```

```
Chain 3 
```

```
Chain 4 Iteration:    1 / 2000 [  0%]  (Warmup) 
```

```
Chain 4 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
```

```
Chain 4 Exception: neg_binomial_lpmf: Inverse scale parameter is 0, but must be positive finite! (in '/tmp/RtmpTVFVHd/model-42172520e4c80.stan', line 30, column 4 to column 42)
```

```
Chain 4 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
```

```
Chain 4 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
```

```
Chain 4 
```

```
Chain 4 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
```

```
Chain 4 Exception: neg_binomial_lpmf: Inverse scale parameter is 0, but must be positive finite! (in '/tmp/RtmpTVFVHd/model-42172520e4c80.stan', line 30, column 4 to column 42)
```

```
Chain 4 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
```

```
Chain 4 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
```

```
Chain 4 
```

```
Chain 4 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
```

```
Chain 4 Exception: gamma_lpdf: Inverse scale parameter is 0, but must be positive finite! (in '/tmp/RtmpTVFVHd/model-42172520e4c80.stan', line 31, column 4 to column 38)
```

```
Chain 4 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
```

```
Chain 4 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
```

```
Chain 4 
```

```
Chain 4 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
```

```
Chain 4 Exception: gamma_lpdf: Inverse scale parameter is 0, but must be positive finite! (in '/tmp/RtmpTVFVHd/model-42172520e4c80.stan', line 31, column 4 to column 38)
```

```
Chain 4 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
```

```
Chain 4 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
```

```
Chain 4 
```

```
Chain 4 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
```

```
Chain 4 Exception: gamma_lpdf: Inverse scale parameter is 0, but must be positive finite! (in '/tmp/RtmpTVFVHd/model-42172520e4c80.stan', line 31, column 4 to column 38)
```

```
Chain 4 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
```

```
Chain 4 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
```

```
Chain 4 
```

```
Chain 4 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
```

```
Chain 4 Exception: gamma_lpdf: Inverse scale parameter is 0, but must be positive finite! (in '/tmp/RtmpTVFVHd/model-42172520e4c80.stan', line 31, column 4 to column 38)
```

```
Chain 4 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
```

```
Chain 4 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
```

```
Chain 4 
```

```
Chain 4 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
```

```
Chain 4 Exception: neg_binomial_lpmf: Shape parameter is inf, but must be positive finite! (in '/tmp/RtmpTVFVHd/model-42172520e4c80.stan', line 30, column 4 to column 42)
```

```
Chain 4 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
```

```
Chain 4 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
```

```
Chain 4 
```

```
Chain 4 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
```

```
Chain 4 Exception: neg_binomial_lpmf: Shape parameter is inf, but must be positive finite! (in '/tmp/RtmpTVFVHd/model-42172520e4c80.stan', line 30, column 4 to column 42)
```

```
Chain 4 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
```

```
Chain 4 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
```

```
Chain 4 
```

```
Chain 1 Iteration: 1000 / 2000 [ 50%]  (Warmup) 
Chain 1 Iteration: 1001 / 2000 [ 50%]  (Sampling) 
Chain 2 Iteration: 1000 / 2000 [ 50%]  (Warmup) 
Chain 2 Iteration: 1001 / 2000 [ 50%]  (Sampling) 
Chain 3 Iteration: 1000 / 2000 [ 50%]  (Warmup) 
Chain 3 Iteration: 1001 / 2000 [ 50%]  (Sampling) 
Chain 4 Iteration: 1000 / 2000 [ 50%]  (Warmup) 
Chain 4 Iteration: 1001 / 2000 [ 50%]  (Sampling) 
Chain 1 Iteration: 2000 / 2000 [100%]  (Sampling) 
Chain 2 Iteration: 2000 / 2000 [100%]  (Sampling) 
Chain 1 finished in 2.9 seconds.
Chain 2 finished in 2.8 seconds.
Chain 3 Iteration: 2000 / 2000 [100%]  (Sampling) 
Chain 4 Iteration: 2000 / 2000 [100%]  (Sampling) 
Chain 3 finished in 3.0 seconds.
Chain 4 finished in 2.7 seconds.

All 4 chains finished successfully.
Mean chain execution time: 2.9 seconds.
Total execution time: 3.5 seconds.
```



```r
tcp_fit |> 
    gather_draws(nb_alpha, nb_beta, g_alpha, g_beta) |>
    recover_types() |> 
    ggplot() +
    geom_line(aes(.iteration, .value, colour = as_factor(.chain)), alpha = .8) +
    facet_grid(vars(.variable), scales = 'free_y')
```

<img src="{{< blogdown/postref >}}index_files/figure-html/assess_chains-1.png" width="672" />

```r
tcp_fit |> 
    gather_draws(nb_alpha, nb_beta, g_alpha, g_beta) |>
    recover_types() |> 
    ggplot() +
    geom_histogram(aes(.value, fill = as.factor(.chain)), bins = 100) +
    facet_wrap(vars(.variable), scales = 'free')
```

<img src="{{< blogdown/postref >}}index_files/figure-html/assess_chains-2.png" width="672" />

```r
tcp_fit |>
    recover_types() |>
    spread_draws(cps_sim[i]) |>
    bind_rows(tcp_connections,) |>
    pivot_longer(c(cps, cps_sim), values_drop_na = TRUE) |>
    ggplot() +
    geom_histogram(aes(value, after_stat(density), fill = name), binwidth = 1, position = position_dodge()) +
    scale_x_continuous(limits = c(-1, 10)) 
```

```
Warning: Removed 19739 rows containing non-finite outside the scale range
(`stat_bin()`).
```

```
Warning: Removed 2 rows containing missing values or values outside the scale range
(`geom_bar()`).
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-6-1.png" width="672" />

```r
tcp_fit |>
    recover_types() |>
    spread_draws(duration_sim[i]) |>
    transmute(duration = duration_sim) |> 
    bind_rows(session_length, .id = 'set') |> 
    ggplot() +
    geom_histogram(aes(duration, after_stat(density), fill = set), binwidth = 1) +
    scale_x_continuous(limits = c(-1, 25)) +
    facet_wrap(~set)
```

```
Warning: Removed 1783014 rows containing non-finite outside the scale range
(`stat_bin()`).
```

```
Warning: Removed 4 rows containing missing values or values outside the scale range
(`geom_bar()`).
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-7-1.png" width="672" />

# Simulating Users


```r
posterior_distros <-
    tcp_fit |>
    recover_types() |>
    spread_draws(cps_sim[i], duration_sim[i])
```


```r
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


```r
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


```r
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
        duration = map(cps, ~{ sample(tcp_session_length$duration, size = .x, replace = TRUE) })
    ) |> 
    group_by(time) |>
    summarise(duration = list(unlist(duration)) ) |>  
    mutate(
        connections = connections(duration),
        concurrent_connections = cumsum(connections)
    ) |>
    select(time, concurrent_connections)
```



```r
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

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-11-1.png" width="672" />

```r
connection_datasets |> 
    mutate(set  = case_when(dataset == 1 ~ 'real', dataset == 2 ~ 'simulated_synthetic', dataset == 3 ~ 'simulated_real')) |>
    ggplot() +
    geom_histogram(aes(concurrent_connections, after_stat(density), group = set, fill = set), binwidth = 1, alpha = .5) +
    facet_grid(~set)
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-11-2.png" width="672" />




```r
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

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-12-1.png" width="672" />

```r
    #geom_boxplot(aes(users, concurrent_connections, group = users))
```

