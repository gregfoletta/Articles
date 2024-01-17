---
title: 'A Day in the Life: The BGP Table'
author: Greg Foletta
date: '2024-01-08'
slug: []
categories: []
tags: []
images: []
---




# Let the Yak SHaving Begin


# Updates, Not Routes

```json
{
  "recv_time": 1704483075,
  "id": 12349,
  "type": "UPDATE",
  "nlri": [ "38.43.124.0/23" ],
  "withdrawn_routes": [],
  "path_attributes": [
    {
      "type": "ORIGIN", "type_code": 1,
      "flags": [ well-known", "transitive", "complete", "standard" ],
      "origin": "IGP"
    },
    {
      "type": "AS_PATH", "type_code": 2,
      "flags": ["well-known", "transitive", "complete", "standard"],
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
      "flags": ["well-known", "transitive", "complete", "standard"],
      "next_hop": "61.245.147.114"
    },
    {
      "type": "AS4_PATH", "type_code": 17,
      "flags": ["optional", "non-transitive","partial","extended" ],
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








# Initial Graph





# Initial Send, Number of v4 and v6 Paths


# Updated Over Time




# Longest AS_PATHS







# IP Address Space




## Prefix Length Distribution




# Path Attributes








