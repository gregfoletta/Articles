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

```{bash}
Cloning into 'whitespacer'...
```


```bash
curl -O --silent https://gregfoletta.s3.ap-southeast-2.amazonaws.com/articles-data/sample_text.txt
cat sample_text.txt
```

```{bash}
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
```


```bash
./ws < sample_text.txt | head -n8
```

```{bash}
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

```{bash}
256+0 records in
256+0 records out
256000000 bytes (256 MB, 244 MiB) copied, 7.69295 s, 33.3 MB/s
filename size	total pages	cached pages	cached size	cached percentage
urandom 256000000 62500 62500 256000000 100.000000
[ 192MiB/s]
[ 198MiB/s]
cdb2600d0b785358b10c7db0c89874a4  urandom
cdb2600d0b785358b10c7db0c89874a4  urandom.transfer
```


```sh
nc -l 8080 | ./ws -d & 
cat sample_text.txt | ./ws | nc -N localhost 8080
```

```
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
```

![Wireshark TCP Follow](tcp_follow.png)


# The Code

## Encoding

```
Foo Bar
```


```C
//Lookup table for each of the 2-bit values
char ws_lookup[] = {'\b', '\t', '\n', '\v'};

//Encode each 2 bits of the byte into whitespace
int ws_encode(const unsigned char *bytes_in, unsigned char *ws_out, const ssize_t bytes) {
    int x;

    for (x = 0; x < bytes; x++) {
    ¦   *ws_out++ = (bytes_in[x] & 0x03) + ws_lookup[0];
    ¦   *ws_out++ = (bytes_in[x] >> 2 & 0x03) + ws_lookup[0];
    ¦   *ws_out++ = (bytes_in[x] >> 4 & 0x03) + ws_lookup[0];
    ¦   *ws_out++ = (bytes_in[x] >> 6 & 0x03) + ws_lookup[0];
    }

    return x * 4;
}

```

## Read Loop

```C
ssize_t bytes_read = 0, total_bytes_read = 0, num_bytes_write = 0;
unsigned char *bytes_in, *bytes_out;

int decoding = is_decoder(argc, argv);

bytes_in = malloc(READ_BUFFER * sizeof(*bytes_in));
bytes_out = malloc(OUTPUT_BUFFER * sizeof(*bytes_out));

```

```C
unsigned char *buffer_pos = bytes_in;

while ( (bytes_read = read(STDIN, buffer_pos, READ_BUFFER - total_bytes_read)) ) {
¦   if (bytes_read < 0) {
¦   ¦   fprintf(stderr, "- read() error\n");
¦   ¦   return -1;
¦   }

¦   total_bytes_read += bytes_read;

¦   if (decoding) {
¦   ¦   //If decoding we need a multiple of four bytes.
¦   ¦   if (!total_bytes_read & 4) {
¦   ¦   ¦   fprintf(stderr, "%ld\n", total_bytes_read);
¦   ¦   ¦   //Move our buffer along
¦   ¦   ¦   buffer_pos += bytes_read;
¦   ¦   ¦   continue;
¦   ¦   }

¦   ¦   num_bytes_write = ws_decode(bytes_in, bytes_out, total_bytes_read);
¦   } else {
¦   ¦   num_bytes_write = ws_encode(bytes_in, bytes_out, total_bytes_read);
¦   }

¦   //Write out to stdout
¦   if ( write(STDOUT, bytes_out, num_bytes_write) < 0 ) {
¦   ¦   fprintf(stderr, "- write() error\n");
¦   ¦   return -1;
¦   }

¦   //Reset buffer position and total bytes read.
¦   buffer_pos = bytes_in;
¦   total_bytes_read = 0;
}
```




