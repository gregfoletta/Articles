---
title: Git Under the Hood
author: 'Greg Foletta'
date: '2022-03-19'
slug: git-under-the-hood
categories: [git]
---


```zsh
touch file_x
rm -rf .git file_* subdir
```


```r
library(tidyverse)
```

```
## ── Attaching packages ─────────────────────────────────────── tidyverse 1.3.1 ──
```

```
## ✓ ggplot2 3.3.5     ✓ purrr   0.3.4
## ✓ tibble  3.1.6     ✓ dplyr   1.0.8
## ✓ tidyr   1.2.0     ✓ stringr 1.4.0
## ✓ readr   2.1.2     ✓ forcats 0.5.1
```

```
## ── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
## x dplyr::filter() masks stats::filter()
## x dplyr::lag()    masks stats::lag()
```

```r
library(tidygraph)
```

```
## 
## Attaching package: 'tidygraph'
```

```
## The following object is masked from 'package:stats':
## 
##     filter
```

```r
library(ggraph)
library(git2r)
```

```
## 
## Attaching package: 'git2r'
```

```
## The following object is masked from 'package:tidygraph':
## 
##     pull
```

```
## The following object is masked from 'package:dplyr':
## 
##     pull
```

```
## The following objects are masked from 'package:purrr':
## 
##     is_empty, when
```

```r
library(stringr)
library(glue)
```

# Init and Cleaning


```zsh
git init -q
rm -rf .git/{hooks,info,config,branches,description}
rm -rf .git/objects/{info,pack}
rm -rf .git/refs/{heads,tags}

tree -n .git
```

```
## [01;34m.git[00m
## ├── HEAD
## ├── [01;34mobjects[00m
## └── [01;34mrefs[00m
## 
## 2 directories, 1 file
```


# Blobs


```zsh
echo "Hello" > file_x
git add file_x

tree -n .git
```

```
## [01;34m.git[00m
## ├── HEAD
## ├── index
## ├── [01;34mobjects[00m
## │   └── [01;34me9[00m
## │       └── 65047ad7c57865823c7d992b1d046ea66edf78
## └── [01;34mrefs[00m
## 
## 3 directories, 3 files
```


```zsh
pigz -cd .git/objects/e9/65047ad7c57865823c7d992b1d046ea66edf78 | hexdump -C
```

```
## 00000000  62 6c 6f 62 20 36 00 48  65 6c 6c 6f 0a           |blob 6.Hello.|
## 0000000d
```


```zsh
echo "blob 6\0Hello" | shasum
```

```
## e965047ad7c57865823c7d992b1d046ea66edf78  -
```


```zsh
mkdir subdir

echo "Hello Again" > subdir/file_y
echo "Hello" > subdir/file_z

git add subdir

tree -n .git
```

```
## [01;34m.git[00m
## ├── HEAD
## ├── index
## ├── [01;34mobjects[00m
## │   ├── [01;34m90[00m
## │   │   └── 9789960b67d38f5e7fa0bb51238079cf041c6a
## │   └── [01;34me9[00m
## │       └── 65047ad7c57865823c7d992b1d046ea66edf78
## └── [01;34mrefs[00m
## 
## 4 directories, 4 files
```

```r
tbl_graph(
    nodes = odb_objects() %>% select(sha),
    edges = tibble(to = c(1,2), from = c(1,2))
) %>%
    mutate(x = c(-1, 1), y = c(0, 0))
```

```
## # A tbl_graph: 2 nodes and 2 edges
## #
## # A directed multigraph with 2 components
## #
## # Node Data: 2 × 3 (active)
##   sha                                          x     y
##   <chr>                                    <dbl> <dbl>
## 1 e965047ad7c57865823c7d992b1d046ea66edf78    -1     0
## 2 909789960b67d38f5e7fa0bb51238079cf041c6a     1     0
## #
## # Edge Data: 2 × 2
##    from    to
##   <int> <int>
## 1     1     1
## 2     2     2
```


```r
tbl_graph(
    nodes = odb_objects() %>% select(sha),
    edges = tibble(to = c(1,2), from = c(1,2))
) %>%
    mutate(x = c(-1, 1), y = c(0, 0)) %>% 
    ggraph(x = x, y = y) +
    geom_node_point(size = 30, colour = 'steelblue') +
    geom_node_text(aes(label = str_sub(sha, end = 8)), colour = 'white') +
    labs(
        title = 'Blob Objects'
    ) +
    xlim(-4, 4) +
    ylim(-4, 4)
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-9-1.png" width="672" />

```r
    #ggraph() +
    #geom_node_point(size = 40, colour = 'steelblue') +
    #geom_node_label(aes(label = sha))
```

# Tree


```zsh
git commit -m "Initial Commit"

tree -n .git
```

```
## [master (root-commit) a4b8375] Initial Commit
##  3 files changed, 3 insertions(+)
##  create mode 100644 file_x
##  create mode 100644 subdir/file_y
##  create mode 100644 subdir/file_z
## [01;34m.git[00m
## ├── COMMIT_EDITMSG
## ├── HEAD
## ├── index
## ├── [01;34mlogs[00m
## │   ├── HEAD
## │   └── [01;34mrefs[00m
## │       └── [01;34mheads[00m
## │           └── master
## ├── [01;34mobjects[00m
## │   ├── [01;34m2b[00m
## │   │   └── 04fd32b556e89dfa44b332f0cc59541879189a
## │   ├── [01;34m44[00m
## │   │   └── 9a4c7ba21764840c8abc1eb9698596fdf33f3d
## │   ├── [01;34m90[00m
## │   │   └── 9789960b67d38f5e7fa0bb51238079cf041c6a
## │   ├── [01;34ma4[00m
## │   │   └── b837510a2a48ab9d9701548ab2ff6db35237ef
## │   └── [01;34me9[00m
## │       └── 65047ad7c57865823c7d992b1d046ea66edf78
## └── [01;34mrefs[00m
##     └── [01;34mheads[00m
##         └── master
## 
## 11 directories, 11 files
```


```zsh
pigz -cd .git/objects/2b/04fd32b556e89dfa44b332f0cc59541879189a | hexdump -C
```

```
## 00000000  74 72 65 65 20 36 37 00  31 30 30 36 34 34 20 66  |tree 67.100644 f|
## 00000010  69 6c 65 5f 78 00 e9 65  04 7a d7 c5 78 65 82 3c  |ile_x..e.z..xe.<|
## 00000020  7d 99 2b 1d 04 6e a6 6e  df 78 34 30 30 30 30 20  |}.+..n.n.x40000 |
## 00000030  73 75 62 64 69 72 00 44  9a 4c 7b a2 17 64 84 0c  |subdir.D.L{..d..|
## 00000040  8a bc 1e b9 69 85 96 fd  f3 3f 3d                 |....i....?=|
## 0000004b
```


```zsh
cat .git/objects/2b/04fd32b556e89dfa44b332f0cc59541879189a |\
pigz -d |\
perl -nE 'print join "\n", unpack("Z*(Z*H40)*")'
```

```
## tree 67
## 100644 file_x
## e965047ad7c57865823c7d992b1d046ea66edf78
## 40000 subdir
## 449a4c7ba21764840c8abc1eb9698596fdf33f3d
```


```zsh
pigz -cd .git/objects/44/9a4c7ba21764840c8abc1eb9698596fdf33f3d |\
perl -nE 'print join "\n", unpack("Z*(Z*H40)*")'
```

```
## tree 68
## 100644 file_y
## 909789960b67d38f5e7fa0bb51238079cf041c6a
## 100644 file_z
## e965047ad7c57865823c7d992b1d046ea66edf78
```


```r
odb_blobs()
```

```
##                                        sha   path   name len
## 1 e965047ad7c57865823c7d992b1d046ea66edf78        file_x   6
## 2 909789960b67d38f5e7fa0bb51238079cf041c6a subdir file_y  12
## 3 e965047ad7c57865823c7d992b1d046ea66edf78 subdir file_z   6
##                                     commit       author                when
## 1 a4b837510a2a48ab9d9701548ab2ff6db35237ef Greg Foletta 2022-04-25 22:31:34
## 2 a4b837510a2a48ab9d9701548ab2ff6db35237ef Greg Foletta 2022-04-25 22:31:34
## 3 a4b837510a2a48ab9d9701548ab2ff6db35237ef Greg Foletta 2022-04-25 22:31:34
```

```r
odb_objects() %>% 
left_join(odb_blobs()) %>%
select(sha, type, name) %>%
filter(type != 'commit')
```

```
## Joining, by = c("sha", "len")
```

```
##                                        sha type   name
## 1 2b04fd32b556e89dfa44b332f0cc59541879189a tree   <NA>
## 2 449a4c7ba21764840c8abc1eb9698596fdf33f3d tree   <NA>
## 3 e965047ad7c57865823c7d992b1d046ea66edf78 blob file_x
## 4 e965047ad7c57865823c7d992b1d046ea66edf78 blob file_z
## 5 909789960b67d38f5e7fa0bb51238079cf041c6a blob file_y
```



```r
# All git objects
one_commit_nodes <- 
    odb_objects() 

# Add in the blob content
one_commit_nodes <-
    one_commit_nodes %>% 
    filter(type == 'blob') %>%
    select(-c(type, len)) %>% 
    mutate(content = map(sha, ~content(lookup('.', sha = .x)))) %>% 
    right_join(one_commit_nodes, by = 'sha')


# Pull out tree objects, run ls_tree to list what they
# point to which becomes out edges
tree_to_blob_edges <-
    odb_objects() %>% 
    filter(type == 'tree') %>% 
    mutate(blobs = map(sha, ~ls_tree(.x, recursive = FALSE))) %>%
    unnest(blobs, names_repair = 'universal') %>%
    select(
        from = sha...1,
        to = sha...6,
    )
```

```
## New names:
## * sha -> sha...1
## * type -> type...2
## * len -> len...3
## * type -> type...5
## * sha -> sha...6
## * ...
```

```r
# Pull out the commits and get what they point to
commit_to_tree_edges <-
    odb_objects() %>% 
    filter(type == 'commit') %>% 
    mutate(tree = map_chr(sha, ~{ lookup('.', .x) %>% tree() %>% .$sha })) %>%
    select(
        from = sha,
        to = tree
    )

one_commit_edges <-
    bind_rows(
        tree_to_blob_edges,
        commit_to_tree_edges
    )
    

# Create the graph, filtering out the commit
tbl_graph(
    nodes = one_commit_nodes,
    edges = one_commit_edges
) %>%
    #filter(type != 'commit') %>% 
    ggraph() +
    geom_node_point(aes(colour = type), size = 10) +
    geom_edge_link(arrow = arrow(type = 'closed', length = unit(4, units = 'mm'))) +
    geom_node_label(aes(filter = type != 'blob', label = glue("{ str_sub(sha, end = 8)}")), repel = TRUE) +
    geom_node_label(aes(filter = type == 'blob', label = glue("{ str_sub(sha, end = 8)}\n'{ content }'")), repel = TRUE) +
    labs(
        title = 'Git Object Structure',
        subtitle = 'Tree and Blob Objects'
    )
```

```
## Using `sugiyama` as default layout
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-15-1.png" width="672" />

# Commit


```zsh
COMMIT_DIR=$(git show HEAD --pretty=format:"%H" --no-patch | cut -c 1-2)
COMMIT_OBJ=$(git show HEAD --pretty=format:"%H" --no-patch | cut -c 3-)

pigz -cd .git/objects/$COMMIT_DIR/$COMMIT_OBJ |
perl -0777 -nE 'print join "\n", unpack("Z*A*")'
```

```
## commit 177
## tree 2b04fd32b556e89dfa44b332f0cc59541879189a
## author Greg Foletta <greg@foletta.org> 1650925894 +1000
## committer Greg Foletta <greg@foletta.org> 1650925894 +1000
## 
## Initial Commit
```


```r
odb_objects()
```

```
##                                        sha   type len
## 1 2b04fd32b556e89dfa44b332f0cc59541879189a   tree  67
## 2 449a4c7ba21764840c8abc1eb9698596fdf33f3d   tree  68
## 3 e965047ad7c57865823c7d992b1d046ea66edf78   blob   6
## 4 909789960b67d38f5e7fa0bb51238079cf041c6a   blob  12
## 5 a4b837510a2a48ab9d9701548ab2ff6db35237ef commit 177
```

```r
# Create the graph
tbl_graph(
    nodes = one_commit_nodes,
    edges = one_commit_edges
) %>%
    ggraph() +
    geom_node_point(aes(colour = type), size = 10) +
    geom_edge_link(arrow = arrow(type = 'closed', length = unit(4, units = 'mm'))) +
    geom_node_label(aes(label = glue("{type}\n{str_sub(sha, end = 8)}")), nudge_y = -.14)
```

```
## Using `sugiyama` as default layout
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-17-1.png" width="672" />



# Branch


```zsh
cat .git/HEAD
cat .git/refs/heads/master

```

```
## ref: refs/heads/master
## a4b837510a2a48ab9d9701548ab2ff6db35237ef
```

# Index

```zsh
perl -MData::Dumper -0777 -nE '
my @index = unpack("A4 H8 N/(N4 N2 B16 B16 N N N H40 B8 W/A B16 x![4])");
say join(" ", @index[ ($_ * 15) + 2 ..  ($_ * 15) + 17])  foreach (0 .. (scalar (@index - 2) / 15) - 1)
' .git/index
```

```
## 1650925894 63280793 1650925894 63280793 64769 7999817 0000000000000000 1000000110100100 1000 1000 6 e965047ad7c57865823c7d992b1d046ea66edf78 00000000 file_x 0000000000000000 1650925894
## 1650925894 103279498 1650925894 103279498 64769 9046848 0000000000000000 1000000110100100 1000 1000 12 909789960b67d38f5e7fa0bb51238079cf041c6a 00000000 subdir/file_y 0000000000000000 1650925894
## 1650925894 103279498 1650925894 103279498 64769 9046849 0000000000000000 1000000110100100 1000 1000 6 e965047ad7c57865823c7d992b1d046ea66edf78 00000000 subdir/file_z 0000000000000000
```





