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


```bash
git clone https://github.com/gregfoletta/whitespacer

gcc -O3 -Wpedantic -o ws whitespacer/whitespacer.c
```

```{.bash}
Cloning into 'whitespacer'...
```


```bash
curl -O --silent https://gregfoletta.s3.ap-southeast-2.amazonaws.com/articles-data/sample_text.txt
cat sample_text.txt
```

```{bash}
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
```


```sh
./ws < sample_text.txt | head -n8
```

```
	
	
			
		
	
	

							
```


```bash
# Create a 1Gb file full of random data
dd if=/dev/urandom of=urandom bs=1MB count=256

# Is the file in the cache?
fincore --pages=false urandom

# What's our throughput
cat urandom | ./ws | ./ws -d | pv -fa > urandom.transfer

# Are the two files the same?
md5sum urandom*

```

```{.bash}
256+0 records in
256+0 records out
256000000 bytes (256 MB, 244 MiB) copied, 7.28328 s, 35.1 MB/s
filename size	total pages	cached pages	cached size	cached percentage
urandom 256000000 62500 62500 256000000 100.000000
[ 276MiB/s]
a29502929634e600a3c71a065b5d0c56  urandom
a29502929634e600a3c71a065b5d0c56  urandom.transfer
```


```sh
nc -l 8080 | ./ws -d & 
cat sample_text.txt | ./ws | nc -N localhost 8080
```

```
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
```



# The Code









