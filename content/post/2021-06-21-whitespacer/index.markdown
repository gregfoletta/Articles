---
title: Whitespacer
author: Greg Foletta
date: '2021-06-20'
slug: [whitespacer]
categories: []
tags:
  - C
images: []
---




Intro paragraph


# The Program


```sh
git clone https://github.com/gregfoletta/whitespacer

gcc -O3 -Wpedantic -o ws whitespacer/whitespacer.c
```

```{.sh}
Cloning into 'whitespacer'...
```


```sh
curl -O --silent https://gregfoletta.s3.ap-southeast-2.amazonaws.com/articles-data/sample_text.txt
cat sample_text.txt
```

```{.sh}
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
```


```sh
./ws < sample_text.txt | head -n8
```

```{.sh}
	
	
			
		
	
	

							
```


```sh
# Create a 1Gb file full of random data
dd if=/dev/urandom of=urandom bs=1MB count=256

# Is the file in the cache?
fincore --pages=false urandom

# What's our throughput
cat urandom | ./ws | ./ws -d | pv -fa > urandom.transfer

# Are the two files the same?
md5sum urandom*

```

```{.sh}
256+0 records in
256+0 records out
256000000 bytes (256 MB, 244 MiB) copied, 7.38176 s, 34.7 MB/s
filename size	total pages	cached pages	cached size	cached percentage
urandom 256000000 62500 62500 256000000 100.000000
[ 259MiB/s]
75ee4d0b1e3d4622ab0567993057b17b  urandom
75ee4d0b1e3d4622ab0567993057b17b  urandom.transfer
```


```sh
nc -l 8080 | ./ws -d & 
cat sample_text.txt | ./ws | nc -N localhost 8080
```

```{.sh}
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
```



# The Code









