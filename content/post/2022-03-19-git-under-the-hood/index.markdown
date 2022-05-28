---
title: Git Under the Hood
author: 'Greg Foletta'
date: '2022-05-23'
slug: git-under-the-hood
categories: [git]
---

While my day-job is not a "programming" job per se, I use git all the time and find it a fantastic tool for source control and versioning of plain text files. But I don't think there's any doubt that it is [not the easiest tool to use](https://xkcd.com/1597/). Despite it's unintuitive user interface, under the hood git is quite simple and elegant. I believe that if you can understand the fundamental constructs git uses to store, track, and manage files, then the using git from the top down becomes easier.

In this article we're going to take a look under the covers and investigate these constructs. We'll start off with its storage model and take a look at blobs, trees and commits. We'll look at how branches are implemented, and finally we'll unpack the git index file to understand what happens during the staging of a commit. 

There's already [loads](https://jwiegley.github.io/git-from-the-bottom-up/) of [articles](https://medium.com/hackernoon/understanding-git-fcffd87c15a3) out there on git internals, so what's different about this one? 

First, we'll try to avoid the lower level 'plumbing' git commands and limit ourselves to the five most common 'porcelain' commands: `git {init, add, commit, branch, checkout}`. All other analysis will be done using standard command line utilities operating on git's internal files. By removing the as many abstractions as possible and focusing in on file operations, the simplicity of git should become obvious, and will (hopefully) make it easier to understand.

Second, using the R packages [git2r](https://github.com/ropensci/git2r) and [tidygraph](https://github.com/thomasp85/tidygraph), we'll dynamically build up a picture of the connections between git's fundamental objects and understand how they are tied together.

As always, the source code for this article is available up on [github](https://github.com/gregfoletta/articles.foletta.org/blob/production/content/post/2022-03-19-git-under-the-hood/index.Rmarkdown).










```r
repo_branch_commit <- function(repo = '.') {
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
        transmute(from = map_chr(branches, ~ pluck(.x, 'name')),
                  to = map_chr(branches, ~ branch_target(.x)))
    
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
        nodes = bind_rows(commit_nodes, branch_nodes) %>%
            mutate(type = fct_expand(
                type, c('blob', 'tree', 'commit', 'branch')
            ),
            type = fct_relevel(
                type, c('blob', 'tree', 'commit', 'branch')
            )),
        edges = bind_rows(commit_parents,
                          branch_edges)
    )
}
```



# Initialisation

We'll start by initialising an empty git repository. This creates a *.git* directory in which git will hold all of the information git needs for source control, as well as other metadata. The intialisation process creates a number of files and directories, but we'll prune it back as far as we can while still maintaining it as git repository.


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

There's two new files - an index and an object. We'll get to the index later in the article, but for now let's focus on the object. Checking it's format we find that it's compressed data:


```zsh
file .git/objects/93/39e13010d12194986b13e3a777ae5ec4f7c8a6
```

```
.git/objects/93/39e13010d12194986b13e3a777ae5ec4f7c8a6: zlib compressed data
```

Decompressing and looking inside, we see the file is in a structured as a "type, length, value" or TLV. The type is 'blob', the length is the size of the of the data (excluding the type), and the value the contents of the file we created:


```zsh
pigz -cd .git/objects/93/39e13010d12194986b13e3a777ae5ec4f7c8a6 | hexdump -C
```

```
00000000  62 6c 6f 62 20 35 00 52  6f 6f 74 0a              |blob 5.Root.|
0000000c
```

How is the path to the blob object created? It's simply the SHA1 hash of the blob itself. The first two hexadecimal digits are used as a folder, with the remaining digits used as the object file name. We can show this by recreating the object and taking the hash.


```zsh
# The hash matches the object's path
echo "blob 5\0Root" | shasum
```

```
9339e13010d12194986b13e3a777ae5ec4f7c8a6  -
```

What this means is that git uses content addressable storage, with the location of the file is based on its contents. Let's explore this further: we'll add two files with the same contents, one in the root directory and one in a subdirectory. 


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

While we've added three files, there's only two objects. Blobs only contain raw data, with no reference to files or directories. Even though there's three files, there's only two pieces of unique data, and thus two objects. The file/directory information is stored in tree objects which we will take a look at in the next section.

Over the course of the article we'll build up a graph of the objects in the git repository to gain a visual representation of the structure. Here's our starting point: two blobs, the first four characters of their hash, and their contents.

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-12-1.png" width="672" />

The two little blobs of data look pretty lonely out there. What they need is some context, and this is where the tree object comes in.
# Tree

As we've seen, there's no file or directory information in the blob object. The storage of this information is the role of the tree object. If we use the analogy of a disk filesystem and the blob object is the raw data on storage, then the tree object is similar to the inode. It holds the metadata of the file, as well as a pointer to the blob object.

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
│   ├── 61
│   │   └── bdbd436ba0cc99fc54c46e5c0dda00b6238e0b
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

A lot has changed here, and at first glance it may be a bit overwhelming, but focus in on the objects subdirectory. There's an additional three objects on top of the two blob objects we saw before. What are they? If you'll forgive me, I'll use a pretty ugly set of commands to pull out the type and length from each of the objects:


```zsh
# May god have mercy on my soul
find .git/objects -type f -exec sh -c \
"echo -n '{} -> ' && pigz -cd {} | perl -0777 -nE 'say unpack qw(Z*)'" \;
```

```
.git/objects/cc/23f67bb60997d9628f4fd1e9e84f92fd49780e -> blob 11
.git/objects/61/bdbd436ba0cc99fc54c46e5c0dda00b6238e0b -> commit 175
.git/objects/4e/eafbc980bb5cc210392fa9712eeca32ded0f7d -> tree 101
.git/objects/67/21ae08f27ae139ec833f8ab14e3361c38d07bd -> tree 34
.git/objects/93/39e13010d12194986b13e3a777ae5ec4f7c8a6 -> blob 5
```
So in addition to our two blobs, we've got two trees and a commit. Our starting point for will be the first of the tree objects. Unlike the others, trees contain some binary information rather than UTF-8 strings. I'll use Perl's `unpack()` function so decode this into hex:


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
Like the blob we have the type and length of the object. Following this there's an entry for two files and subdirectory that reside in the root directory. The digits preceding the filename are the *mode*, capturing the type of filesystem object (regular file/symbolic link/directory) and it's permissions. Git doesn't track all combinations of permissions, only whether the file is user executable or not.    

The two files point to the hashes of the blob objects, but you might have noticed that the subdirectory points to the hash of the other tree object. Looking inside of that:


```zsh
pigz -cd .git/objects/67/21ae08f27ae139ec833f8ab14e3361c38d07bd |\
perl -nE 'print join "\n", unpack("Z*(Z*H40)*")'
```

```
tree 34
100644 file_z
cc23f67bb60997d9628f4fd1e9e84f92fd49780e
```
This tree object points to the hash of the blob for the file in the subdirectory. Adding the tree objects to our graph should make things a little clearer.

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-17-1.png" width="672" />
At the top is the root of the tree, with its pointers to two blobs and a subdirectory. The second tree is the subdirectory, with a single pointer to a blob. The root and subdirectory trees both point to the same blob, because both files have the same contents.

With blobs and trees we've built up a pseudo-filesystem, but how does this help us with source control? The object that ties all of this together is the commit.

# Commit

Our third object - and the one most visible to the end user - is the commit. As we'll see soon, the hash of the commit (and thus the path to the object) is based on the time it was generated. As I generate this article dynamically, there's a little bit of overhead to get the commit object.


```zsh
# Get the commit object 
COMMIT_DIR=$(cat .git/refs/heads/master | cut -c 1-2)
COMMIT_OBJ=$(cat .git/refs/heads/master | cut -c 3-)

# Open it up
pigz -cd .git/objects/$COMMIT_DIR/$COMMIT_OBJ |\
perl -0777 -nE 'print join "\n", unpack("Z*A*")'
```

```
commit 175
tree 4eeafbc980bb5cc210392fa9712eeca32ded0f7d
author Greg Foletta <greg@foletta.org> 1653778033 +1000
committer Greg Foletta <greg@foletta.org> 1653778033 +1000

First Commit
```

Again we have the type and length of the object, then there's a few different pieces of information.

The first is reference to a tree object. This is the tree object that represents the root directory of the repository. The next is the author of the commit, with their name, email address, commit time and the UTC offset. As the person who authored the commit doesn't necessarily have to be the person who committed it to the repository, there's also a line for the committer. Following this is the commit message, which is free text input entered at the time of the commit.

Let's place this on our graph:

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-19-1.png" width="672" />
So a commit points to the tree object representing the root directory. But there's something missing here, as this first commit is a special commit: as it has no parents. Every other commit from this point on will be a descendant of this commit. From any point, history of the changes to the files in the repository can be traced back all the way back to this nascent state. 

Changing the contents of *file_z*, staging, and creating a second commit, will allow us to see this additional information in the commit object:


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
parent 61bdbd436ba0cc99fc54c46e5c0dda00b6238e0b
author Greg Foletta <greg@foletta.org> 1653778034 +1000
committer Greg Foletta <greg@foletta.org> 1653778034 +1000

Second Commit
```

We see an additional *parent* line in the commit, which references the hash of the commit that came before it. A commit can have multiple parents: two or more "branches" can be merged together, resulting in commits having multiple parents. We're not going to cover any merging in this article.

Putting all the work we've done together, we place the second commit onto our graph, sans the link back to the parent (we'll get to that in the next section):

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-21-1.png" width="672" />
What we see here represents the core of how git stores data. The commits represent 'snapshots' of the state of the files and directories in the repository. The commits point to different root tree objects, each of which point to a different object representing the *file_x* in the root (the file we changed in the second commit). But they share the same tree object representing the subdirectory and the blob representing *file_y*. 

There's no 'diffs' calculated between commits; if one byte of a file changes, this results in a new blob, resulting in a new tree (or trees), resulting in a new commit. In terms of the [space-time trade-off](https://en.wikipedia.org/wiki/Space%E2%80%93time_tradeoff), git chooses space over time, resulting in a simple model of data changes over time.

The problem is, our commits are still addressed via a 160 bit hash. This is all well and good for a computer, but we'd like something a bit more human friendly. This is the role of branches.

# Branches and HEAD

Branches are relatively simple: they are a human-friendly, named pointer to a commit hash. Local branches are stored in *.git/reds/heads/*, and we see the current master[^1] branch points to the hash of our second commit:

[^1]: the default branch, which is now configurable in git version 2.28 and above


```zsh
cat .git/refs/heads/master
```

```
ebf4de1b8fe8ee55e7ad07794df6788fc2135cd0
```
If we create a new branch, it will point to the same spot:


```zsh
# Create a new branch
git branch branch_2

# List the branches and the hashes they point to
find .git/refs/heads/* -type f -exec sh -c 'echo -n "{} -> " && cat {}' \;
```

```
.git/refs/heads/branch_2 -> ebf4de1b8fe8ee55e7ad07794df6788fc2135cd0
.git/refs/heads/master -> ebf4de1b8fe8ee55e7ad07794df6788fc2135cd0
```

The branches are updated when a new commit occurs.


```zsh
# Commit on the new branch
git checkout -q branch_2
echo $RANDOM > file_x
git commit -q -am "Third Commit (new_branch)"

# The 'new_branch' branch now points to a different commit.
find .git/refs/heads/* -type f -exec sh -c 'echo -n "{} -> " && cat {}' \;
```

```
.git/refs/heads/branch_2 -> c206b4809f0d4499aa9d9a98404cf18fe7554b2d
.git/refs/heads/master -> ebf4de1b8fe8ee55e7ad07794df6788fc2135cd0
```

Going back to master branch and creating a new commit allows us to visualise how the two branches have diverged:


```zsh
# Commit back on  the master branch
git checkout -q master 
echo $RANDOM > file_x
git commit -q -am "Fourth Commit (master)"
```


<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-26-1.png" width="672" />

The third and fourth commits are both descendants of the third commit. Adding in our branches we see they point to the tip of this graph:

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-27-1.png" width="672" />
There's nothing stopping us from creating more branches, even if they point to the same location:


```zsh
# Create new branches
git branch branch_3 
git branch branch_4 
git branch branch_5 
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-29-1.png" width="672" />

Branches make the underlying structure of git navigable by a human.

# Index

The final file we're going to look at is the index. While it has a few different roles, we'll be focusing on it's main role as the 'staging area'. The index will have entry for


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
lstat() info: 1653778035 148739955 1653778035 148739955 64769 7999136 0 1000000110100100 1000 1000
Object & Filepath: 6 bf3a1f34302301d165c8c9b52eaef52499a055ad 0000000000000110 file_x
```
The first line shows the the four byte 'DIRC' signature (which stands for 'directory cache'), the version number, and the number of entries (files in the index). We'll be unpacking only one of the entries. 

The first fields contain information from the `lstat()` function: last changed and modified time, the device and inode, permissions, uid and gid, and file size. These values allow git to quickly determine if files in the working tree have been modified.

We next have the hash of the object, a flags field (including the length of path), and the path of the object.

If we recall back in the *Blobs* section, when we added a file to the staging are via `git add`, the index was created. Let's modify *file_x* and add it to the staging area:


```zsh
echo "Index Modification" > file_x
git add file_x
```

Now we'll re-take a look at the index:


```
ctime, mtime: 00000002 1653778036
object, filepath: db12d29ef25db0f954787c6d620f1f6e9ce3c778 file_x
```

The `lstat()` values have changed, and so has the object that *file_x* points to. If a `git commit` is issued, this next commit will represent the current state of the index. In our example, a new tree object will be created with *file_x* pointing towards the object that's in the index (as well as pointing to the current, unchanged tree representing the sub-directory). As this is the root tree object, the new commit will point to this.

# Conclusion

In this article we dived in to the internals of git. We first looked at git's data model and learned about the raw blobs of data, the trees that hold the filesystem information, and the commits that point the root of the tree and hold information about the author, time, and a description of the commit. We also saw how these commits point to other parent commits, giving us a graph that allows you to trace any the changed in the repository back to the first embryonic commit. 

We needed a human readable way to track commits and learned about branches, which are simple files that point to commit hashes.

Finally we looked at the index which acts as the staging area for a commit and helps to speed up file comparison operations.

It's perhaps a sad indictment when you have to understand the internals of something in order to use it. This could be bad design, the inherent complexity of the problem domain, or perhaps a litle bit of both. Nevertheless it's a piece of software that's incredibly powerful and investing some time to understand it will pay dividends down the line when you're trying to manage configuration, code, almost any other type of text-based content.


