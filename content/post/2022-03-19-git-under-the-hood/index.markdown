---
title: Git Under the Hood
author: 'Greg Foletta'
date: '2022-03-19'
slug: git-under-the-hood
categories: [git]
---









# Initialisation

We'll start by initialising an empty git repository. This creates a *.git* directory in the root directory of the repository. It's a root in that all subdirectories and files below this point will be considered part of the the repository.

There's a bunch of stuff that's created, but we'll prune it back to the absolute bare minimum of what git considers a git repository.


```zsh
git init -q
rm -rf .git/{hooks,info,config,branches,description}
rm -rf .git/objects/{info,pack}
rm -rf .git/refs/{heads,tags}

tree .git
```

```
.git
├── HEAD
├── objects
└── refs

2 directories, 1 file
```


# Blobs

The first fundamental git object we'll look at is the *blob*. Let's create a file and use the `git add` command to add it to the staging area and see what this has done in our .git directory.


```zsh
echo "Hello" > file_x
git add file_x

tree .git
```

```
.git
├── HEAD
├── index
├── objects
│   └── e9
│       └── 65047ad7c57865823c7d992b1d046ea66edf78
└── refs

3 directories, 3 files
```

We see that a new object has been created in what looks like some sort of hash value. The file is compressed data.


```zsh
file .git/objects/e9/65047ad7c57865823c7d992b1d046ea66edf78
```

```
.git/objects/e9/65047ad7c57865823c7d992b1d046ea66edf78: zlib compressed data
```

If we decompress and look inside, we can see the file is in a "type, length, value" or TLV format, with the type being a blob, the length of the value being 6 bytes, and the value being "Hello".



```zsh
pigz -cd .git/objects/e9/65047ad7c57865823c7d992b1d046ea66edf78 | hexdump -C
```

```
00000000  62 6c 6f 62 20 36 00 48  65 6c 6c 6f 0a           |blob 6.Hello.|
0000000d
```


All data in git is stored in this manner. So what we can say is that git is an object store for data, where the objects are addressed by a hash. 

A key point to note at this stage is that there's no information about the file contained in these blobs: no path or file name, no permissions. It's only the contents of the file. 

How is this hash calculated? It's simply the SHA2 hash of the TLV. 


```zsh
echo "blob 6\0Hello" | shasum
```

```
e965047ad7c57865823c7d992b1d046ea66edf78  -
```

Let's explore this further. We'll create a subdirectory and add two more files, one of which will have the same contents as our first file.


```zsh
mkdir subdir

echo "Hello" > subdir/file_z
echo "Hello Again" > subdir/file_y

git add subdir

tree .git
```

```
.git
├── HEAD
├── index
├── objects
│   ├── 90
│   │   └── 9789960b67d38f5e7fa0bb51238079cf041c6a
│   └── e9
│       └── 65047ad7c57865823c7d992b1d046ea66edf78
└── refs

4 directories, 4 files
```

Two things that stand out here. First is that while we have a total of three files, there's only two objects. This is because blobls are only concerned with the contents of the files, and we have only two unique pieces of content.

The second is that, like the filenames, theres no reference to the subdirectory here either. We'll see in the next section where this information is stored.

Over the course of the article we'll build up a graph of the objects in the git repository. Here's out starting point: two blobs, the first four characters of their hash, and their contents.

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-10-1.png" width="672" />


# Tree

So where is the file system information stored? This is the role of the tree object. If we use the analogy of a disk filesystem and the blob is the raw data on the disk, then the tree object is similar to the inode. It holds the metadata of the file, as well as a pointer to the blob object.

Let's perform our first commit and see what's changed in the repository.


```zsh
git commit -m "First Commit"

tree .git
```

```
[master (root-commit) 60d5e40] First Commit
 3 files changed, 3 insertions(+)
 create mode 100644 file_x
 create mode 100644 subdir/file_y
 create mode 100644 subdir/file_z
.git
├── COMMIT_EDITMSG
├── HEAD
├── index
├── logs
│   ├── HEAD
│   └── refs
│       └── heads
│           └── master
├── objects
│   ├── 2b
│   │   └── 04fd32b556e89dfa44b332f0cc59541879189a
│   ├── 44
│   │   └── 9a4c7ba21764840c8abc1eb9698596fdf33f3d
│   ├── 60
│   │   └── d5e4008ed97d76deafcef9dde9c3325a376127
│   ├── 90
│   │   └── 9789960b67d38f5e7fa0bb51238079cf041c6a
│   └── e9
│       └── 65047ad7c57865823c7d992b1d046ea66edf78
└── refs
    └── heads
        └── master

11 directories, 11 files
```

Ok, there's a lot there, but let's focus in again on the objects where we have an additional three. I've done the hard work of determining which is which, so let's take a look at the first of the tree objects.


```zsh
pigz -cd .git/objects/2b/04fd32b556e89dfa44b332f0cc59541879189a | hexdump -C
```

```
00000000  74 72 65 65 20 36 37 00  31 30 30 36 34 34 20 66  |tree 67.100644 f|
00000010  69 6c 65 5f 78 00 e9 65  04 7a d7 c5 78 65 82 3c  |ile_x..e.z..xe.<|
00000020  7d 99 2b 1d 04 6e a6 6e  df 78 34 30 30 30 30 20  |}.+..n.n.x40000 |
00000030  73 75 62 64 69 72 00 44  9a 4c 7b a2 17 64 84 0c  |subdir.D.L{..d..|
00000040  8a bc 1e b9 69 85 96 fd  f3 3f 3d                 |....i....?=|
0000004b
```

This is a little harder to interpret as some of the information is in a binary representation. Again I've done the hard to work to determine the structure, so we can unpack it into a friendlier, plain-text representation:


```zsh
pigz -cd .git/objects/2b/04fd32b556e89dfa44b332f0cc59541879189a |\
perl -nE 'print join "\n", unpack("Z*(Z*H40)*")'
```

```
tree 67
100644 file_x
e965047ad7c57865823c7d992b1d046ea66edf78
40000 subdir
449a4c7ba21764840c8abc1eb9698596fdf33f3d
```
Again we have the type of object, then the of the tree object. Then we have an entry for each of the filesystem objects in the root of our git repository. The first is the *file_x* file, with its permnissions, it's filename, and a pointer to the blob object of its contents.

**Add note on limited permissions**.

The second is the subdir directory, but instead of pointing to a blob object, this points to another tree object. Taking a look inside that:


```zsh
pigz -cd .git/objects/44/9a4c7ba21764840c8abc1eb9698596fdf33f3d |\
perl -nE 'print join "\n", unpack("Z*(Z*H40)*")'
```

```
tree 68
100644 file_y
909789960b67d38f5e7fa0bb51238079cf041c6a
100644 file_z
e965047ad7c57865823c7d992b1d046ea66edf78
```
This object point to the two files within that subdirectory. Keen eyes may notice that both *file_x* in the root and *file_z* point to the same hash, as those files have the same contents. 

We can visualise this as a graph:
    
<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-15-1.png" width="672" />
The hash value of the tree objects is directly dependent on the name of the file/directory, and its permissions. But it's indirectly dependent on the contents of the files: if that changes, the hash of the blob changes, and so the hash of the tree changes.

# Commit


```zsh
COMMIT_DIR=$(git show HEAD --pretty=format:"%H" --no-patch | cut -c 1-2)
COMMIT_OBJ=$(git show HEAD --pretty=format:"%H" --no-patch | cut -c 3-)

pigz -cd .git/objects/$COMMIT_DIR/$COMMIT_OBJ |
perl -0777 -nE 'print join "\n", unpack("Z*A*")'
```

```
commit 175
tree 2b04fd32b556e89dfa44b332f0cc59541879189a
author Greg Foletta <greg@foletta.org> 1651352382 +1000
committer Greg Foletta <greg@foletta.org> 1651352382 +1000

First Commit
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-17-1.png" width="672" />


```zsh
echo "Hello Root" > subdir/file_z
git add subdir/file_z
git commit -m "Second Commit"
```

```
[master 4dcc348] Second Commit
 1 file changed, 1 insertion(+), 1 deletion(-)
```


```zsh
COMMIT_DIR=$(git show HEAD --pretty=format:"%H" --no-patch | cut -c 1-2)
COMMIT_OBJ=$(git show HEAD --pretty=format:"%H" --no-patch | cut -c 3-)

pigz -cd .git/objects/$COMMIT_DIR/$COMMIT_OBJ |
perl -0777 -nE 'print join "\n", unpack("Z*A*")'
```

```
commit 224
tree 0aa029179697fb5370fe682371d582ca75db0c1f
parent 60d5e4008ed97d76deafcef9dde9c3325a376127
author Greg Foletta <greg@foletta.org> 1651352383 +1000
committer Greg Foletta <greg@foletta.org> 1651352383 +1000

Second Commit
```
<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-20-1.png" width="672" />


# Branches


```zsh
cat .git/HEAD
cat .git/refs/heads/master
```

```
ref: refs/heads/master
4dcc3489d11e7e09776fe847e85d89c4579e356f
```

# Index

```zsh
perl -MData::Dumper -0777 -nE '
my @index = unpack("A4 H8 N/(N4 N2 B16 B16 N N N H40 B8 W/A B16 x![4])");
say join(" ", @index[ ($_ * 15) + 2 ..  ($_ * 15) + 17])  foreach (0 .. (scalar (@index - 2) / 15) - 1)
' .git/index
```

```
1651352381 812135539 1651352381 812135539 64769 7997635 0000000000000000 1000000110100100 1000 1000 6 e965047ad7c57865823c7d992b1d046ea66edf78 00000000 file_x 0000000000000000 1651352381
1651352381 848136019 1651352381 848136019 64769 8265364 0000000000000000 1000000110100100 1000 1000 12 909789960b67d38f5e7fa0bb51238079cf041c6a 00000000 subdir/file_y 0000000000000000 1651352383
1651352383 284154981 1651352383 284154981 64769 8265363 0000000000000000 1000000110100100 1000 1000 11 ff8bc6b592ef09b667207e90e5cf51c369358627 00000000 subdir/file_z 0000000000000000 
```





