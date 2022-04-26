---
title: Git Under the Hood
author: 'Greg Foletta'
date: '2022-03-19'
slug: git-under-the-hood
categories: [git]
---









# Init and Cleaning


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


```zsh
pigz -cd .git/objects/e9/65047ad7c57865823c7d992b1d046ea66edf78 | hexdump -C
```

```
00000000  62 6c 6f 62 20 36 00 48  65 6c 6c 6f 0a           |blob 6.Hello.|
0000000d
```


```zsh
echo "blob 6\0Hello" | shasum
```

```
e965047ad7c57865823c7d992b1d046ea66edf78  -
```


```zsh
mkdir subdir

echo "Hello Again" > subdir/file_y
echo "Hello" > subdir/file_z

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

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-9-1.png" width="672" />


# Tree


```zsh
git commit -m "First Commit"

tree .git
```

```
[master (root-commit) bac4189] First Commit
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
│   ├── 90
│   │   └── 9789960b67d38f5e7fa0bb51238079cf041c6a
│   ├── ba
│   │   └── c41898130ada9ce9c75d9d2336dd8e4b73e1cb
│   └── e9
│       └── 65047ad7c57865823c7d992b1d046ea66edf78
└── refs
    └── heads
        └── master

11 directories, 11 files
```


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


```zsh
cat .git/objects/2b/04fd32b556e89dfa44b332f0cc59541879189a |\
pigz -d |\
perl -nE 'print join "\n", unpack("Z*(Z*H40)*")'
```

```
tree 67
100644 file_x
e965047ad7c57865823c7d992b1d046ea66edf78
40000 subdir
449a4c7ba21764840c8abc1eb9698596fdf33f3d
```


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



    
<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-14-1.png" width="672" />

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
author Greg Foletta <greg@foletta.org> 1651020478 +1000
committer Greg Foletta <greg@foletta.org> 1651020478 +1000

First Commit
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-16-1.png" width="672" />


```zsh
echo "Hello Root" > file_x
git add file_x
git commit -m "Second Commit"
```

```
[master 0fd8db4] Second Commit
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
tree 8b14e7318562df2b0e9880ad5028a00805307f33
parent bac41898130ada9ce9c75d9d2336dd8e4b73e1cb
author Greg Foletta <greg@foletta.org> 1651020479 +1000
committer Greg Foletta <greg@foletta.org> 1651020479 +1000

Second Commit
```
<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-19-1.png" width="672" />


# Branches


```zsh
cat .git/HEAD
cat .git/refs/heads/master
```

```
ref: refs/heads/master
0fd8db46a88f9107974d5eb1f37bdf4fc065d974
```

# Index

```zsh
perl -MData::Dumper -0777 -nE '
my @index = unpack("A4 H8 N/(N4 N2 B16 B16 N N N H40 B8 W/A B16 x![4])");
say join(" ", @index[ ($_ * 15) + 2 ..  ($_ * 15) + 17])  foreach (0 .. (scalar (@index - 2) / 15) - 1)
' .git/index
```

```
1651020479 156550954 1651020479 156550954 64769 8000733 0000000000000000 1000000110100100 1000 1000 11 ff8bc6b592ef09b667207e90e5cf51c369358627 00000000 file_x 0000000000000000 1651020477
1651020477 628771373 1651020477 628771373 64769 8917842 0000000000000000 1000000110100100 1000 1000 12 909789960b67d38f5e7fa0bb51238079cf041c6a 00000000 subdir/file_y 0000000000000000 1651020477
1651020477 628771373 1651020477 628771373 64769 8917843 0000000000000000 1000000110100100 1000 1000 6 e965047ad7c57865823c7d992b1d046ea66edf78 00000000 subdir/file_z 0000000000000000 
```





