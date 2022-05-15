---
title: Git Under the Hood
author: 'Greg Foletta'
date: '2022-03-19'
slug: git-under-the-hood
categories: [git]
---

While I use git all the time and think it's fantastic, there's no doubt that it can be [difficult to use](https://xkcd.com/1597/). Despite this complexity, under the hood git is quite simple and elegant. I believe that if you can get an understanding of the fundamental constructs that git uses then it becomes easier to use.

In this article we're going to take a look under the covers and investigate these constructs that git uses to store and track data. We'll start off with its storage model and take a look at blobs, trees and commits, using graphs to help visualize the connections between these objects. We'll look at how branches are implemented, and finally we'll unpack the git index file to understand what happens during the staging of a commit.

We're going to limit ourselves to five of the most common git commands: `git {init, add, commit, branch, checkout}`. The analysis be done using simple command line utilities operating on its files. By removing the as many abstractions as possible and focusing in on file operations, the elegance and simplicity of git becomes obvious, and (hopefully) makes it easier to understand.














# Initialisation

We'll start by initialising an empty git repository. This creates a *.git* directory in the root directory of the repository. It's a root in that all subdirectories and files below this point will be considered part of the the repository. This is known as the **working tree**.

The initialisation creates a number of files that we don't need to worry about, so let's prune it back to the point where git only just considers it a valid repository.


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

The first fundamental git object we'll look at is the *blob*. We create a file, add it to the staging area, and see what this has done in our .git directory.


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

There's two new files - an index and an object. We'll get to the index later in the article, but for now let's focus on the object. It's path seems to be a hash, and the file is compressed data.


```zsh
file .git/objects/93/39e13010d12194986b13e3a777ae5ec4f7c8a6
```

```
.git/objects/93/39e13010d12194986b13e3a777ae5ec4f7c8a6: zlib compressed data
```

Decompressing it and looking inside, the file is in a structured as a "type, length, value" or TLV. There type is 'blob', the length is the size of the of the data (in bytes), and the value is 'Hello'.


```zsh
pigz -cd .git/objects/93/39e13010d12194986b13e3a777ae5ec4f7c8a6 | hexdump -C
```

```
00000000  62 6c 6f 62 20 35 00 52  6f 6f 74 0a              |blob 5.Root.|
0000000c
```

How is the hash created? It's simply the SHA-1 hash of the blob itself:


```zsh
echo "blob 5\0Root" | shasum
```

```
9339e13010d12194986b13e3a777ae5ec4f7c8a6  -
```

We can therefore consider git to be a form of content addressable storage, with the location (path) of the file is based on its contents. Let's explore this further: we'll create a sub-directory and add two more files, one of which will have the same contents as our first file.


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

While we've added three files, there's only two objects. Blobs only contain raw data, nothing else. Even though there's three files, there's only two pieces of unique data, and thus two objects. The file/directory information is stored in tree objects which we will take a look at in the next section.

Over the course of the article we'll build up a graph of the objects in the git repository to gain a visual representation of the structure. Here's out starting point: two blobs, the first four characters of their hash, and their contents.

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-11-1.png" width="672" />

# Tree

So where is the file and directory information stored? This is the role of the tree object. If we use the analogy of a disk filesystem and the blob object is the raw data on storage, then the tree object is similar to the inode. It holds the metadata of the file, as well as a pointer to the blob object.

Let's perform our first commit and see what's changed in the repository.


```zsh
git commit -m "First Commit"

tree .git
```

```
[master (root-commit) 1408351] First Commit
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
│   ├── 14
│   │   └── 08351779b0b651f11d13be9108408ca0dc2734
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

There's a lot to take in! If we focus in again on the objects where we there's an additional three on top of the two blob objects. I've done the hard work of determining which is which, so let's take a look at the first of the tree objects. As they contain some binary encoded information (as opposed to UTF-8 strings), I'll unpack it into a string format.


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

Let's place this on our graph:

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-15-1.png" width="672" />
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
author Greg Foletta <greg@foletta.org> 1652648676 +1000
committer Greg Foletta <greg@foletta.org> 1652648676 +1000

First Commit
```

Again, like the blob and the tree, we have our type an length of the object. We've then got a few different pieces of information:

The first is reference to a tree object. This is the tree objects that represents the root directory of the repository. The next is the author of the commit, with their name, email address, commit time and the UTC offset. The person who authored the commit doesn't have to be the same person who commited it to the repository, so there's also a line for the commiter. Following this is the commit message, which is free text input at the time of commit which (should) discuss the changes contained in the commit.

Placing this on our graph and we can see the full structure:

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-17-1.png" width="672" />
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
parent 1408351779b0b651f11d13be9108408ca0dc2734
author Greg Foletta <greg@foletta.org> 1652648677 +1000
committer Greg Foletta <greg@foletta.org> 1652648677 +1000

Second Commit
```

We see an additional *parent* line in the commit, which references the hash of the commit that came before it. We can place this on our graph

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-19-1.png" width="672" />

This is the core of git. Three objects types resulting in content-addressable storage. THe commits represent 'snapshots' of the repository at a point int time, which point to a parent commit, and the root of a tree. The tree has nodes that represent directories, holding metadata about files, and point towards blobs of data. The data itself is just that: data. Git doesn't calculate any differences between file changes: a one byte change to a file, this results in a new hash and this a completely new blob object that will be pointed to. In terms of the [space-time trade-off](https://en.wikipedia.org/wiki/Space%E2%80%93time_tradeoff), git chooses space over time, resulting in a simple model of data changes over time.

Working with 160 bit hashes is all well and good for a machine, but not human friendly. This is where branches come in.

# Branches and HEAD

Branches are relatively simple: they are a named pointer to a commit hash. This pointer is updated whenever a commit occurs. The default branch was master, but in git versions 2.28 and higher this is now configurable.

Local branches are stored in the *.git/refs/heads* directory.


```zsh
cat .git/refs/heads/master
```

```
0d6dec5564f4b4d70767efdb51d9f21fd49a0254
```

```r
odb_objects()
```

```
                                       sha   type len
1 cc23f67bb60997d9628f4fd1e9e84f92fd49780e   blob  11
2 0d6dec5564f4b4d70767efdb51d9f21fd49a0254 commit 224
3 4eeafbc980bb5cc210392fa9712eeca32ded0f7d   tree 101
4 33459b8faaeaf56a97f7ecba0ae2b1b4511c87e8   blob  13
5 6721ae08f27ae139ec833f8ab14e3361c38d07bd   tree  34
6 9339e13010d12194986b13e3a777ae5ec4f7c8a6   blob   5
7 6e09d0dbb13d342d66580c40a49dd1583958ccc8   tree 101
8 1408351779b0b651f11d13be9108408ca0dc2734 commit 175
```

If we create a new branch, it will point to the same spot as our current HEAD:


```zsh
git branch new_branch

sed -s 1F .git/refs/heads/*
```

```
.git/refs/heads/master
0d6dec5564f4b4d70767efdb51d9f21fd49a0254
.git/refs/heads/new_branch
0d6dec5564f4b4d70767efdb51d9f21fd49a0254
```

If change a file and and commit, we'll see the hash that the branch points to change.


```zsh
git checkout new_branch
echo $RANDOM > file_x
git commit -q -am "Third Commit"

sed -s 1F .git/refs/heads/*
```

```
Switched to branch 'new_branch'
.git/refs/heads/master
0d6dec5564f4b4d70767efdb51d9f21fd49a0254
.git/refs/heads/new_branch
1199aebadef27218b562178775abeaf6457efd98
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
lstat() info: 1652648678 119894484 1652648678 119894484 64769 7999053 0 1000000110100100 1000 1000
Object & Filepath: 5 524996e759e76449c32315190aa1d64edd4b9039 0000000000000110 file_x
<9d>|m<a1><b0>IE<86>ea<ea>9<ba>wa
g!<ae><f2>z<e1>9<ec><83>?<8a><b1>N3aÍ<bd><86><dd>kۯN<f0>Bg<cc><e1>{L\<8b><89><eb><84>=<a4>
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
ctime, mtime: 00000002 1652648678
object, filepath: db12d29ef25db0f954787c6d620f1f6e9ce3c778 file_x
subdir
g!<ae><f2>z<e1>9<ec><83>?<8a><b1>N3aÍ<bd><cf>Y<99>د<b3>b<ce>*<a2>U<9e><f0> <aa><d5>
```

The `lstat()` values have changed, and so has the object that *file_x* points to. If a `git commit` is issued, this next commit will represent the current state of the index. In our example, a new tree object will be created with *file_x* pointing towards the object that's in the index (as well as pointing to the current, unchanged tree representing the sub-directory). As this is the root tree object, the new commit will point to this.

# Summary

In this article we dived in to the internals of git. We first looked at git's data model and learned about the raw blobs of data, the trees that hold the filesystem information, and the commits that point the root of the tree and hold information about the author, time, and a description of the commit. We also saw how these commits point to other parent commits, giving us a graph that allows you to trace any the changed in the repository back to the first embryonic commit. 

We needed a human readable way to track commits and learned about branches, which are simple files that point to commit hashes.

Finally we looked at the index which acts as the staging area for a commit and helps to speed up file comparison operations.

It's a sorry state of affairs when you have to understand the internals of something in order to use it. This could be bad design, the inherent complexity of the problem domain, or perhaps a litle bit of both. Nevertheless it's a piece of software that's incredibly powerful and investing some time to understand it will pay dividends down the line when you're trying to manage configuration, code, almost any other type of text-based content.


