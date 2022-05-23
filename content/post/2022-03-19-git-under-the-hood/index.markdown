---
title: Git Under the Hood
author: 'Greg Foletta'
date: '2022-05-23'
slug: git-under-the-hood
categories: [git]
---

<<<<<<< Updated upstream
While I use git all the time and think it's fantastic, there's no doubt that it can be [difficult to use](https://xkcd.com/1597/). Despite this complexity, under the hood git is quite simple and elegant. I believe that if you can get an understanding of the fundamental constructs that git uses then it becomes easier to use.

In this article we're going to take a look under the covers and investigate these constructs that git uses to store and track data. We'll start off with its storage model and take a look at blobs, trees and commits, using graphs to help visualize the connections between these objects. We'll look at how branches are implemented, and finally we'll unpack the git index file to understand what happens during the staging of a commit.

We're going to limit ourselves to five of the most common git commands: `git {init, add, commit, branch, checkout}`. The analysis be done using simple command line utilities operating on its files. By removing the as many abstractions as possible and focusing in on file operations, the elegance and simplicity of git becomes obvious, and (hopefully) makes it easier to understand.

=======
While my day-job is not a "programming" job per se, I use git all the time and find it a fantastic tool for source control and versioning of plain text files. But I don't think there's any doubt that it is [not the easiest tool to use](https://xkcd.com/1597/). Despite it's unintuitive user interface, under the hood git is quite simple and elegant. I believe that if you can understand the fundamental constructs git uses to store, track, and manage files, then the using git from the top down becomes easier.

In this article we're going to take a look under the covers and investigate these constructs. We'll start off with its storage model and take a look at blobs, trees and commits. We'll look at how branches are implemented, and finally we'll unpack the git index file to understand what happens during the staging of a commit. 

There's already [loads](https://jwiegley.github.io/git-from-the-bottom-up/) of [articles](https://medium.com/hackernoon/understanding-git-fcffd87c15a3) out there on git internals, so what's different about this one? 

First, we'll try to avoid the lower level 'plumbing' git commands and limit ourselves to the five most common 'porcelain' commands: `git {init, add, commit, branch, checkout}`. All other analysis will be done using standard command line utilities operating on git's internal files. By removing the as many abstractions as possible and focusing in on file operations, the simplicity of git should become obvious, and will (hopefully) make it easier to understand.

Second, using the R packages [git2r](https://github.com/ropensci/git2r) and [tidygraph](https://github.com/thomasp85/tidygraph), we'll dynamically build up a picture of the connections between git's fundamental objects and understand how they are tied together.

As always, the source code for this article is available up on [github](https://github.com/gregfoletta/articles.foletta.org/blob/production/content/post/2022-03-19-git-under-the-hood/index.Rmarkdown).
>>>>>>> Stashed changes












# Initialisation

<<<<<<< Updated upstream
We'll start by initialising an empty git repository. This creates a *.git* directory in the root directory of the repository. It's a root in that all subdirectories and files below this point will be considered part of the the repository. This is known as the **working tree**.

The initialisation creates a number of files that we don't need to worry about, so let's prune it back to the point where git only just considers it a valid repository.
=======
We'll start by initialising an empty git repository. This creates a *.git* directory in which git will hold all of the information git needs for source control, as well as other metadata. The intialisation process creates a number of files and directories, but we'll prune it back as far as we can while still maintaining it as git repository.
>>>>>>> Stashed changes


```zsh
# Initialise the repository (quietly)
git init --quiet

# Remove some of the created files and directories
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
# Create a file
echo "Root" > file_x

# Add it to the staging area
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

<<<<<<< Updated upstream
There's two new files - an index and an object. We'll get to the index later in the article, but for now let's focus on the object. It's path seems to be a hash, and the file is compressed data.
=======
There's two new files - an index and an object. We'll get to the index later in the article, but for now let's focus on the object. Checking it's format we find that it's compressed data:
>>>>>>> Stashed changes


```zsh
file .git/objects/93/39e13010d12194986b13e3a777ae5ec4f7c8a6
```

```
.git/objects/93/39e13010d12194986b13e3a777ae5ec4f7c8a6: zlib compressed data
```

<<<<<<< Updated upstream
Decompressing it and looking inside, the file is in a structured as a "type, length, value" or TLV. There type is 'blob', the length is the size of the of the data (in bytes), and the value is 'Hello'.
=======
Decompressing and looking inside, we see the file is in a structured as a "type, length, value" or TLV. The type is 'blob', the length is the size of the of the data (in bytes), and the value the contents of the file we created:
>>>>>>> Stashed changes


```zsh
pigz -cd .git/objects/93/39e13010d12194986b13e3a777ae5ec4f7c8a6 | hexdump -C
```

```
00000000  62 6c 6f 62 20 35 00 52  6f 6f 74 0a              |blob 5.Root.|
0000000c
```
<<<<<<< Updated upstream

How is the hash created? It's simply the SHA-1 hash of the blob itself:
=======
How is the path to the blob object created? It's simply the SHA1 hash of the blob itself. The first two hexadecimal digits are taken off and used as a folder, with the remaining digits used as the object file name. We can show this by recreating the object and taking the hash.
>>>>>>> Stashed changes


```zsh
# The hash matches the object's path
echo "blob 5\0Root" | shasum
```

```
9339e13010d12194986b13e3a777ae5ec4f7c8a6  -
```

We can therefore consider git to be a form of content addressable storage, with the location (path) of the file is based on its contents. Let's explore this further: we'll create a sub-directory and add two more files, one of which will have the same contents as our first file.


```zsh
# Cerate a subdir
mkdir subdir

# Add two files, one in the root, one in the subdir
echo "Root & Sub" > file_y
echo "Root & Sub" > subdir/file_z

# Add the files to the staging area
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

<<<<<<< Updated upstream
While we've added three files, there's only two objects. Blobs only contain raw data, nothing else. Even though there's three files, there's only two pieces of unique data, and thus two objects. The file/directory information is stored in tree objects which we will take a look at in the next section.
=======
While we've added three files, there's only two objects. Blobs only contain raw data, with no reference to files or directories. Even though there's three files, there's only two pieces of unique data, and thus two objects. The file/directory information is stored in tree objects which we will take a look at in the next section.
>>>>>>> Stashed changes

Over the course of the article we'll build up a graph of the objects in the git repository to gain a visual representation of the structure. Here's out starting point: two blobs, the first four characters of their hash, and their contents.

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-11-1.png" width="672" />

# Tree

So where is the file and directory information stored? This is the role of the tree object. If we use the analogy of a disk filesystem and the blob object is the raw data on storage, then the tree object is similar to the inode. It holds the metadata of the file, as well as a pointer to the blob object.

Let's perform our first commit and see what's changed in the repository.


```zsh
git commit --quiet -m "First Commit"

tree .git
```

```
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
│   ├── 4e
│   │   └── eafbc980bb5cc210392fa9712eeca32ded0f7d
│   ├── 67
│   │   └── 21ae08f27ae139ec833f8ab14e3361c38d07bd
│   ├── 93
│   │   └── 39e13010d12194986b13e3a777ae5ec4f7c8a6
│   ├── a3
│   │   └── 9cc2a7cc32a8d99abf483a3d530ab8b4f75871
│   └── cc
│       └── 23f67bb60997d9628f4fd1e9e84f92fd49780e
└── refs
    └── heads
        └── master

11 directories, 11 files
```

<<<<<<< Updated upstream
There's a lot to take in! If we focus in again on the objects where we there's an additional three on top of the two blob objects. I've done the hard work of determining which is which, so let's take a look at the first of the tree objects. As they contain some binary encoded information (as opposed to UTF-8 strings), I'll unpack it into a string format.
=======
A lot has changed here, and it's a bit much to takwe in, but focus in on the objects subdirectory. There's an additional three objects on top of the two blob objects we saw before. 


```zsh
# Please forgive me...
find .git/objects -type f -exec sh -c \
"echo -n '{} -> ' && pigz -cd {} | perl -0777 -nE 'say unpack qw(Z*)'" \;
```

```
.git/objects/cc/23f67bb60997d9628f4fd1e9e84f92fd49780e -> blob 11
.git/objects/4e/eafbc980bb5cc210392fa9712eeca32ded0f7d -> tree 101
.git/objects/67/21ae08f27ae139ec833f8ab14e3361c38d07bd -> tree 34
.git/objects/93/39e13010d12194986b13e3a777ae5ec4f7c8a6 -> blob 5
.git/objects/a3/9cc2a7cc32a8d99abf483a3d530ab8b4f75871 -> commit 175
```

Let's look at the first of the tree objects. As they contain some binary encoded information (as opposed to UTF-8 strings), I'll unpack it into a string format.
>>>>>>> Stashed changes


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
author Greg Foletta <greg@foletta.org> 1653347712 +1000
committer Greg Foletta <greg@foletta.org> 1653347712 +1000

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
parent a39cc2a7cc32a8d99abf483a3d530ab8b4f75871
author Greg Foletta <greg@foletta.org> 1653347713 +1000
committer Greg Foletta <greg@foletta.org> 1653347713 +1000

Second Commit
```

We see an additional *parent* line in the commit, which references the hash of the commit that came before it. We can place this on our graph

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-20-1.png" width="672" />

This is the core of git. Three objects types resulting in content-addressable storage. THe commits represent 'snapshots' of the repository at a point int time, which point to a parent commit, and the root of a tree. The tree has nodes that represent directories, holding metadata about files, and point towards blobs of data. The data itself is just that: data. Git doesn't calculate any differences between file changes: a one byte change to a file, this results in a new hash and this a completely new blob object that will be pointed to. In terms of the [space-time trade-off](https://en.wikipedia.org/wiki/Space%E2%80%93time_tradeoff), git chooses space over time, resulting in a simple model of data changes over time.

Working with 160 bit hashes is all well and good for a machine, but not human friendly. This is where branches come in.

# Branches and HEAD

Branches are relatively simple: they are a named pointer to a commit hash. This pointer is updated whenever a commit occurs. The default branch was master, but in git versions 2.28 and higher this is now configurable.

Local branches are stored in the *.git/refs/heads* directory.


```zsh
cat .git/refs/heads/master
```

```
6efd66798a3eaf0e1c0030bd42a284409c930d7e
```

```r
odb_objects()
```

```
                                       sha   type len
1 cc23f67bb60997d9628f4fd1e9e84f92fd49780e   blob  11
2 4eeafbc980bb5cc210392fa9712eeca32ded0f7d   tree 101
3 33459b8faaeaf56a97f7ecba0ae2b1b4511c87e8   blob  13
4 6721ae08f27ae139ec833f8ab14e3361c38d07bd   tree  34
5 9339e13010d12194986b13e3a777ae5ec4f7c8a6   blob   5
6 6efd66798a3eaf0e1c0030bd42a284409c930d7e commit 224
7 6e09d0dbb13d342d66580c40a49dd1583958ccc8   tree 101
8 a39cc2a7cc32a8d99abf483a3d530ab8b4f75871 commit 175
```

If we create a new branch, it will point to the same spot as our current HEAD:


```zsh
git branch new_branch

sed -s 1F .git/refs/heads/*
```

```
.git/refs/heads/master
6efd66798a3eaf0e1c0030bd42a284409c930d7e
.git/refs/heads/new_branch
6efd66798a3eaf0e1c0030bd42a284409c930d7e
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
6efd66798a3eaf0e1c0030bd42a284409c930d7e
.git/refs/heads/new_branch
c43b7e81a45dda7b6566966038e4c4f718bf8f1f
```



If change a file and and commit, we'll see the hash that the branch points to change.


```zsh
git checkout new_branch
echo $RANDOM > file_x
git commit -q -am "Third Commit"
git checkout master
echo $RANDOM > subdir/file_y
git commit -q -am "Fourth Commit"


sed -s 1F .git/refs/heads/*
```

```
Already on 'new_branch'
Switched to branch 'master'
On branch master
Untracked files:
  (use "git add <file>..." to include in what will be committed)
	index.Rmarkdown
	index.Rmarkdown.lock~
	index.knit.md~
	index.markdown
	index_files/
	subdir/file_y

nothing added to commit but untracked files present (use "git add" to track)
.git/refs/heads/master
6efd66798a3eaf0e1c0030bd42a284409c930d7e
.git/refs/heads/new_branch
11499b94ef5c926dad3113bf2eb9a673272c3b9a
```


```r
repo = '.'

commit_parents <-
    odb_objects(repo = repo) %>% 
    filter(type == 'commit') %>% 
    mutate(parent_commit = map(sha, ~ {
        lookup(repo, .x) %>% parents() %>% as.data.frame() %>% magrittr::extract2('sha')
    })) %>% 
    unnest(parent_commit) %>%
    select(from = sha, to = parent_commit) 

branch_edges <-
    tibble(branches = branches()) %>% 
    transmute(
        from = map_chr(branches, ~pluck(.x, 'name')),
        to = map_chr(branches, ~branch_target(.x))
    ) 

commit_nodes <-
    commit_parents %>% 
    pivot_longer(c(from, to)) %>% 
    distinct(value) %>%
    mutate(type = 'commit') %>% 
    rename(name = value)

branch_nodes <-
    branch_edges %>% 
    mutate(type = 'branch') %>% 
    select(-to, name = from)

    tbl_graph(
        nodes = bind_rows(
            commit_nodes,
            branch_nodes
        ),
        edges = bind_rows(
            commit_parents,
            branch_edges
        )
    ) %>% 
    git_graph_branches()
```

```
Warning: Ignoring unknown aesthetics: repel
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-27-1.png" width="672" />

# Index

The final file we're going to look at is the index. While it has a few different roles, we'll be focusing on it's main role as the 'staging area'. Let's crack it open and have a look at the structure:


```zsh
perl -0777 -nE '
# Extract out each file in the index
my @index = unpack("A4 H8 N (N4 N2 n B16 N N N H40 B16 Z*)");

say "Index Header: " . join " ", @index[0..2];
say "lstat() info: " . join " ", @index[3..12];
say "Object & Filepath: " . join " ", @index[13..16];
' .git/index
```

```
Index Header: DIRC 00000002 3
lstat() info: 1653347713 781207746 1653347713 781207746 64769 7999093 0 1000000110100100 1000 1000
Object & Filepath: 13 33459b8faaeaf56a97f7ecba0ae2b1b4511c87e8 0000000000000110 file_x
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
ctime, mtime: 00000002 1653347714
object, filepath: db12d29ef25db0f954787c6d620f1f6e9ce3c778 file_x
```
The `lstat()` values have changed, and so has the object that *file_x* points to. If a `git commit` is issued, this next commit will represent the current state of the index. In our example, a new tree object will be created with *file_x* pointing towards the object that's in the index (as well as pointing to the current, unchanged tree representing the sub-directory). As this is the root tree object, the new commit will point to this.

# Conclusion

In this article we dived in to the internals of git. We first looked at git's data model and learned about the raw blobs of data, the trees that hold the filesystem information, and the commits that point the root of the tree and hold information about the author, time, and a description of the commit. We also saw how these commits point to other parent commits, giving us a graph that allows you to trace any the changed in the repository back to the first embryonic commit. 

We needed a human readable way to track commits and learned about branches, which are simple files that point to commit hashes.

Finally we looked at the index which acts as the staging area for a commit and helps to speed up file comparison operations.

It's a sorry state of affairs when you have to understand the internals of something in order to use it. This could be bad design, the inherent complexity of the problem domain, or perhaps a litle bit of both. Nevertheless it's a piece of software that's incredibly powerful and investing some time to understand it will pay dividends down the line when you're trying to manage configuration, code, almost any other type of text-based content.


