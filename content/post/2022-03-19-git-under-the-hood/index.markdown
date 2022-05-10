---
title: Git Under the Hood
author: 'Greg Foletta'
date: '2022-03-19'
slug: git-under-the-hood
categories: [git]
---

---intro---

In this article we're going to take a look under the covers and investigate the fundamental constructs that git uses. We'll start off with its storage model and take a look at blobs, trees and commits, using graphs to help visualize the connections between these objects. We'll look at how branches are implemented, and we'll unpack the git index file to understand what happens during the staging of a commit.

All the way through we'll limit ourselves to five simple git commands:

- git init
- git add
- git commit
- git branch
- git checkout

Our actual invesitgation of git's internals will be done using simple command line utilities operating on files. The reason is simple: by removing the abstractions and focusing in on file operations, the elegance and simplicity of git becomes obvious, and (hopefully) makes it easier to understand.














# Initialisation

We'll start by initialising an empty git repository. This creates a *.git* directory in the root directory of the repository. It's a root in that all subdirectories and files below this point will be considered part of the the repository. This is known as the **working tree**.

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
echo "Root" > file_x
git add file_x

tree .git
```

```
.git
├── HEAD
├── index
├── objects
│   └── 93
│       └── 39e13010d12194986b13e3a777ae5ec4f7c8a6
└── refs

3 directories, 3 files
```

We can see two new files - an index and an object. We'll get to the index later in the article, for now let's focus on the object. It appears to be names with some sort of hash value, and the file is compressed data.


```zsh
file .git/objects/93/39e13010d12194986b13e3a777ae5ec4f7c8a6
```

```
.git/objects/93/39e13010d12194986b13e3a777ae5ec4f7c8a6: zlib compressed data
```

If we decompress and look inside, we can see the file is in a "type, length, value" or TLV format, with the type being a blob, the length of the value being 6 bytes, and the value being "Hello".


```zsh
pigz -cd .git/objects/93/39e13010d12194986b13e3a777ae5ec4f7c8a6 | hexdump -C
```

```
00000000  62 6c 6f 62 20 35 00 52  6f 6f 74 0a              |blob 5.Root.|
0000000c
```

All data in git is stored in this manner. So what we can say is that git is an object store for data, where the objects are addressed by a hash. 

A key point to note at this stage is that there's no information about the file contained in these blobs: no path or file name, no permissions. It's only the contents of the file. 

How is this hash calculated? It's simply the SHA hash of the TLV. 


```zsh
echo "blob 5\0Root" | shasum
```

```
9339e13010d12194986b13e3a777ae5ec4f7c8a6  -
```

Let's explore this further. We'll create a subdirectory and add two more files, one of which will have the same contents as our first file.


```zsh
mkdir subdir
echo "Root & Sub" > file_y
echo "Root & Sub" > subdir/file_z

git add file_y subdir 

tree .git
```

```
.git
├── HEAD
├── index
├── objects
│   ├── 93
│   │   └── 39e13010d12194986b13e3a777ae5ec4f7c8a6
│   └── cc
│       └── 23f67bb60997d9628f4fd1e9e84f92fd49780e
└── refs

4 directories, 4 files
```

Two things that stand out here. First is that while we have a total of three files, there's only two objects. This is because blobls are only concerned with the contents of the files, and we have only two unique pieces of content.

The second is that, like the filenames, theres no reference to the subdirectory here either. We'll see in the next section where this information is stored.

Over the course of the article we'll build up a graph of the objects in the git repository. Here's out starting point: two blobs, the first four characters of their hash, and their contents.

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-11-1.png" width="672" />

# Tree

So where is the file system information stored? This is the role of the tree object. If we use the analogy of a disk filesystem and the blob is the raw data on the disk, then the tree object is similar to the inode. It holds the metadata of the file, as well as a pointer to the blob object.

Let's perform our first commit and see what's changed in the repository.


```zsh
git commit -m "First Commit"

tree .git
```

```
[master (root-commit) 3845332] First Commit
 3 files changed, 3 insertions(+)
 create mode 100644 file_x
 create mode 100644 file_y
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
│   ├── 38
│   │   └── 45332f28d78db53ac300cad361dcda4312300e
│   ├── 4e
│   │   └── eafbc980bb5cc210392fa9712eeca32ded0f7d
│   ├── 67
│   │   └── 21ae08f27ae139ec833f8ab14e3361c38d07bd
│   ├── 93
│   │   └── 39e13010d12194986b13e3a777ae5ec4f7c8a6
│   └── cc
│       └── 23f67bb60997d9628f4fd1e9e84f92fd49780e
└── refs
    └── heads
        └── master

11 directories, 11 files
```

Ok, there's a lot there, but let's focus in again on the objects where we have an additional three. I've done the hard work of determining which is which, so let's take a look at the first of the tree objects.


```zsh
pigz -cd .git/objects/4e/eafbc980bb5cc210392fa9712eeca32ded0f7d | hexdump -C
```

```
00000000  74 72 65 65 20 31 30 31  00 31 30 30 36 34 34 20  |tree 101.100644 |
00000010  66 69 6c 65 5f 78 00 93  39 e1 30 10 d1 21 94 98  |file_x..9.0..!..|
00000020  6b 13 e3 a7 77 ae 5e c4  f7 c8 a6 31 30 30 36 34  |k...w.^....10064|
00000030  34 20 66 69 6c 65 5f 79  00 cc 23 f6 7b b6 09 97  |4 file_y..#.{...|
00000040  d9 62 8f 4f d1 e9 e8 4f  92 fd 49 78 0e 34 30 30  |.b.O...O..Ix.400|
00000050  30 30 20 73 75 62 64 69  72 00 67 21 ae 08 f2 7a  |00 subdir.g!...z|
00000060  e1 39 ec 83 3f 8a b1 4e  33 61 c3 8d 07 bd        |.9..?..N3a....|
0000006e
```

This is a little harder to interpret as some of the information is in a binary representation. Again I've done the hard to work to determine the structure, so we can unpack it into a friendlier, plain-text representation:


```zsh
pigz -cd .git/objects/4e/eafbc980bb5cc210392fa9712eeca32ded0f7d |\
perl -nE 'print join "\n", unpack("Z*(Z*H40)*")'
```

```
tree 101
100644 file_x
9339e13010d12194986b13e3a777ae5ec4f7c8a6
100644 file_y
cc23f67bb60997d9628f4fd1e9e84f92fd49780e
40000 subdir
6721ae08f27ae139ec833f8ab14e3361c38d07bd
```
Again we have the type of object, then the of the tree object. Then we have an entry for each of the filesystem objects in the root of our git repository. The first is the *file_x* file, with its permnissions, it's filename, and a pointer to the blob object of its contents.

**Add note on limited permissions**.

The second is the subdir directory, but instead of pointing to a blob object, this points to another tree object. Taking a look inside that:


```zsh
pigz -cd .git/objects/67/21ae08f27ae139ec833f8ab14e3361c38d07bd |\
perl -nE 'print join "\n", unpack("Z*(Z*H40)*")'
```

```
tree 34
100644 file_z
cc23f67bb60997d9628f4fd1e9e84f92fd49780e
```
This object point to the two files within that subdirectory. Keen eyes may notice that both *file_x* in the root and *file_z* point to the same hash, as those files have the same contents. 

We can visualise this as a graph:
    
<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-16-1.png" width="672" />
The hash value of the tree objects is directly dependent on the name of the file/directory, and its permissions. But it's indirectly dependent on the contents of the files: if that changes, the hash of the blob changes, and so the hash of the tree changes.

# Commit

Our third and most visible object is the commit. Let's take a look inside. Because the hash of the commit is based on time, and I generate this article dynamically, I have to calculate the hash and thus the path to the commit. We'll talk about branches later, but this will give you an idea about how they work.


```zsh
# Get the commit object 
COMMIT_DIR=$(cat .git/refs/heads/master | cut -c 1-2)
COMMIT_OBJ=$(cat .git/refs/heads/master | cut -c 3-)

pigz -cd .git/objects/$COMMIT_DIR/$COMMIT_OBJ |\
perl -0777 -nE 'print join "\n", unpack("Z*A*")'
```

```
commit 175
tree 4eeafbc980bb5cc210392fa9712eeca32ded0f7d
author Greg Foletta <greg@foletta.org> 1652303788 +1000
committer Greg Foletta <greg@foletta.org> 1652303788 +1000

First Commit
```

Again, like the blob and the tree, we have our type an length of the object. We've then got a few different pieces of information:

The first is reference to a tree object. This is the tree objects that represents the root directory of the repository. The next is the author of the commit, with their name, email address, commit time and the UTC offset. The person who authored the commit doesn't have to be the same person who commited it to the repository, so there's also a line for the commiter. Following this is the commit message, which is free text input at the time of commit which (should) discuss the changes contained in the commit.

Placing this on our graph and we can see the full structure:

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-18-1.png" width="672" />
If the value of any one of the fields changes in the commit, it will be references by a new hash. If a file changes downstream, this will result in one or more changes to tree objects, culminating in a change to hash of the tree object that represents the root directory of the repository. The value of the 'tree' field in the commit changes, and theremore the hash of the commit changes.

This first commit is actually a special commit as it has no parents. Every other commit from this point on - no matter what the branch - will be a descendant of this commit. So from any point, we can trace back the history of the changes to the files in the repository all the way back to this nascent state. If we change the contents of *file_z*, add it to the staging area, and create a second commit we can see how this is represented.


```zsh
# Change the contents, add, and create a second commit
echo "Root Changed" > file_x
git add file_x
git commit -q -m "Second Commit"

# Determine the path to the second commit object
COMMIT_DIR=$(cat .git/refs/heads/master | cut -c 1-2)
COMMIT_OBJ=$(cat .git/refs/heads/master | cut -c 3-)

# Unpack the contents of the commit
pigz -cd .git/objects/$COMMIT_DIR/$COMMIT_OBJ |
perl -0777 -nE 'print join "\n", unpack("Z*A*")'
```

```
commit 224
tree 6e09d0dbb13d342d66580c40a49dd1583958ccc8
parent 3845332f28d78db53ac300cad361dcda4312300e
author Greg Foletta <greg@foletta.org> 1652303789 +1000
committer Greg Foletta <greg@foletta.org> 1652303789 +1000

Second Commit
```

We see an additional *parent* line in the commit, which references the hash of the commit that came before it. We can place this on our graph

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-20-1.png" width="672" />

This is the core of git. Three objects types resulting in content-addressable storage. THe commits represent 'snapshots' of the repository at a point int time, which point to a parent commit, and the root of a tree. The tree has nodes that represent directories, holding metadata about files, and point towards blobs of data. The data itself is just that: data. Git doesn't calculate any differences between file changes: a one byte change to a file, this results in a new hash and this a completely new blob object that will be pointed to. In terms of the [space-time trade-off](https://en.wikipedia.org/wiki/Space%E2%80%93time_tradeoff), git chooses space over time, resulting in a simple model of data changes over time.

Working with 160 bit hashes is all well and good for a machine, but not human friendly. This is where branches come in.

# Branches

Branches are relatively simple: they are a named pointer to a commit hash. This pointer is updated whenever a commit occurs. The default branch was master, but in git versions 2.28 and higher this is now configurable.

Local branches are stored in the *.git/refs/heads* directory.


```zsh
cat .git/refs/heads/master
```

```
1366250731dc508085ac22f1d06d03d2e5325cc2
```

If we create a new branch, it will point to the same spot as our current HEAD:


```zsh
git branch new_branch

sed -s 1F .git/refs/heads/*
```

```
.git/refs/heads/master
1366250731dc508085ac22f1d06d03d2e5325cc2
.git/refs/heads/new_branch
1366250731dc508085ac22f1d06d03d2e5325cc2
```

If change a file and and commit, we'll see the hash that the branch points to change.


```zsh
echo "Branch Change" > file_x
git add file_x
git commit -q -m "Third Commit"

sed -s 1F .git/refs/heads/*

```

```
.git/refs/heads/master
6129793d80983cdb70d57dcefb489c3273981b21
.git/refs/heads/new_branch
1366250731dc508085ac22f1d06d03d2e5325cc2
```


# Index

The final file we're going to look at is the index. While it has a few different roles, we'll be focusing on it's main role as the 'staging area'. Let's crack it open and have a look at the structure:


```zsh
perl -0777 -nE '
# Extract out each file in the index
my @index = unpack("A4 H8 N (N4 N2 n B16 N N N H40 B16 A*)");

say "Index Header: " . join " ", @index[0..2];
say "lstat() info: " . join " ", @index[3..12];
say "Object & Filepath: " . join " ", @index[13..16];

' .git/index
```

```
Index Header: DIRC 00000002 3
lstat() info: 1652303790 131180542 1652303790 131180542 64769 7998325 0 1000000110100100 1000 1000
Object & Filepath: 14 fc3b51e93ad662d0bcf4df7e5253acbf4d14e53a 0000000000000110 file_x
t)(<99><da><c9>Ґ<df><f9>e<cb><fc><b4><8c><f5><ad><f5><c3>subdir
g!<ae><f2>z<e1>9<ec><83>?<8a><b1>N3aÍ<bd><89><de>ZM<bc>=<9e><d9>l<93>V<ec><bb>u
```
The first line shows the the four byte 'DIRC' signature (which stands for 'directory cache'), the version number, and the number of entries (files in the index). We'll be unpacking only one of the entries. 

The first fields contain information from the `lstat()` function: last changed and modified time, the device and inode, permissions, uid and gid, and file size. These values allow git to quickly determine if files in the working tree have been modified.

We next have the hash of the object, a flags field (including the length of path), and the path of the object.

If we recall back in the *Blobs* section, when we added a file to the staging are via `git add`, the index was created. Let's modify *file_x* and add it to the staging area:


```zsh
echo "Index Modification" > file_x
git add file_x
```

And we'll re-take a look at the index:


```
ctime, mtime: 00000002 1652303790
object, filepath: db12d29ef25db0f954787c6d620f1f6e9ce3c778 file_x
subdir
g!<ae><f2>z<e1>9<ec><83>?<8a><b1>N3aÍ<bd>,_w<b0>X6T<db>{i<fc>px-<ab>9#<b2>
```

The `lstat()` values have changed, and so has the object that *file_x* points to. If a `git commit` is issued, this next commit will represent the current state of the index. In our example, a new tree object will be created with *file_x* pointing towards the object that's in the index (as well as pointing to the current, unchanged tree representing the sub-directory). As this is the root tree object, the new commit will point to this.

# Summary

In this article we dived in to the internals of git. We first looked at gits data model.

We then looked at branches.

Finally we looked at the index.

---outro---



