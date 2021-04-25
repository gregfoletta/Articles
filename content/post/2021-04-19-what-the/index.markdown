---
title: 'What the #!'
author: Greg Foletta
date: '2021-04-19'
slug: []
categories: []
tags: []
images: []
---

Whenever you work with computers, you take an incredible amount of things for granted: your press of the keyboard will bubble up through the kernel to your terminal; the HTTP request will remain intact after travelling halfway across the globe; or the stream of a cat video will be decoded and rendered on your screen. Taking these things for granted isn't a negative, in fact quite the opposite. All of the abstractions and indirections that hide the internal details allow us to focus on other important aspects like aesthetics, speed or accuracy, rather than wondering how exactly how re-implement TCP.

But at the same time in can be a very unsatisfying feeling to not know how something is working, and you need to peek behind the curtains. For me that happened recently when writing a script and adding the obligatory "shebang" or "hashbang" (#!) to the first line. Of course I know that this specifies the interpreter that will run the rest of the file, but how does that work? Is it a user space or kernel space component that does this?  

So in this article we're going to answer the question:

> How is an interpreter caled when specified using a shebang in the first line of a script? 


```sh
uname -sor
```

```
## Linux 4.15.0-142-generic GNU/Linux
```


# Done In Userspace

Let's dive straight in - here's our simple Perl script that we're running.


```sh
cat data/foo.pl

chmod u+x data/foo.pl
```

```
## #!/usr/bin/perl
## 
## use strict;
## use warnings;
## use 5.010;
## 
## say "Foobar";
```

The first tool we go for is `strace`, which attaches itself to a process and intercepts system calls. In the below code snippet, we run strace with two arguments: the '-f' means that any child processes spawned by the original traced process are traced as well. The -e argument filters out specific system calls that we're interested in. I've done this for brevity within the article, but you'd likely want to look through the whole trace to get a firm idea about what the process is doing.

We spin up a bash process, then execute our script within that process.



```sh
strace -f -e trace=vfork,fork,clone,execve bash -c './data/foo.pl'
```

```
## execve("/bin/bash", ["bash", "-c", "./data/foo.pl"], 0x7ffd2edfde38 /* 100 vars */) = 0
## execve("./data/foo.pl", ["./data/foo.pl"], 0x562fbbb35880 /* 100 vars */) = 0
## Foobar
## +++ exited with 0 +++
```

The strace utility shows us two processes executions: the bash shell executing (which will have followed the `clone()` call from the original shell and not captured), then the path of our script being passed directly to the `execve()` system call. This is a system call that executes processes. It's prototype is:

```
int execve(const char *filename, char *const argv[], char *const envp[]);
```

with `*filename` containing the path to the program to run, `*argv[]` containing the command line arguements, and `*envp[]` containing the environment variables.

What does this tell us? It tells us that the scripts are passed directly this system call, and there's no userspace aspect to the parsing of the hash-bang line.

# A Quick Look in GLIBC

The bash process doesn't call the system call directly; the `execve()` function is part of the standard C library (on my machine it's glibc or GNU LibC), to which bash is dynamically linked. While it's unlikely that anything of significance is ocurring in the library, we'd better take a look.

We can use the `ldd` utility to print out the shared libraries required a program, and the paths to these shared libraries.


```bash
ldd $(which bash)
```

```
## 	linux-vdso.so.1 (0x00007fff4bcac000)
## 	libtinfo.so.5 => /lib/x86_64-linux-gnu/libtinfo.so.5 (0x00007f6931e2f000)
## 	libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007f6931c2b000)
## 	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f693183a000)
## 	/lib64/ld-linux-x86-64.so.2 (0x00007f6932373000)
```

We now use `objdump` to disassemble the shared library, and we extract out the section that's related to `execve()`.


```bash
objdump -d /lib/x86_64-linux-gnu/libc.so.6 | sed -n '/^[[:xdigit:]]\+ <execve/,/^$/p' 
```

```
## 00000000000e4c00 <execve@@GLIBC_2.2.5>:
##    e4c00:	b8 3b 00 00 00       	mov    $0x3b,%eax
##    e4c05:	0f 05                	syscall 
##    e4c07:	48 3d 01 f0 ff ff    	cmp    $0xfffffffffffff001,%rax
##    e4c0d:	73 01                	jae    e4c10 <execve@@GLIBC_2.2.5+0x10>
##    e4c0f:	c3                   	retq   
##    e4c10:	48 8b 0d 51 62 30 00 	mov    0x306251(%rip),%rcx        # 3eae68 <h_errlist@@GLIBC_2.2.5+0xdc8>
##    e4c17:	f7 d8                	neg    %eax
##    e4c19:	64 89 01             	mov    %eax,%fs:(%rcx)
##    e4c1c:	48 83 c8 ff          	or     $0xffffffffffffffff,%rax
##    e4c20:	c3                   	retq   
##    e4c21:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
##    e4c28:	00 00 00 
##    e4c2b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
```

As expected, the standard library doesn't do much. It places 0x3b (decimal 59) into the `eax` register, which is the [execve system call number](https://elixir.bootlin.com/linux/latest/source/arch/x86/entry/syscalls/syscall_64.tbl#L70) and calls the [fast system call x86 instruction](https://www.felixcloutier.com/x86/syscall). 

I could write another whole article on the process of jumping from user space into the kernel through a system call. You'll find a brief description of the steps in the appendix at the bottom of this article.



# Delving into the kernel

Come in to [SYSCALL_DEFINE3(execve)](https://elixir.bootlin.com/linux/latest/source/include/linux/syscalls.h#L222), which then calls [do_execve](https://elixir.bootlin.com/linux/latest/source/fs/exec.c#L1981), which calls [do_exexveat_common](https://elixir.bootlin.com/linux/latest/C/ident/do_execveat_common).

Important thing that happens here is the allocation of a [linux_binprom](https://elixir.bootlin.com/linux/latest/source/include/linux/binfmts.h#L17) structure. Argument and environment counts and strings are copied into this structure. [bprm_execve](https://elixir.bootlin.com/linux/latest/source/fs/exec.c#L1792) is then called, which then calls [exec_binprm](https://elixir.bootlin.com/linux/latest/source/fs/exec.c#L1744).

# Binary Handler Search

Within `exec_binrpm()` there is a call to [search_binary_handler](https://github.com/torvalds/linux/blob/29c395c77a9a514c5857c45ceae2665e9bd99ac7/fs/exec.c#L1698). 


The key pieces of code are here:

```c
static int search_binary_handler(struct linux_binprm *bprm)
{
	struct linux_binfmt *fmt;
	int retval;

	retval = prepare_binprm(bprm);
	...
	
	list_for_each_entry(fmt, &formats, lh) {
	    ...
		retval = fmt->load_binary(bprm);
		...
		if (bprm->point_of_no_return || (retval != -ENOEXEC)) {
			return retval;
		}
	}	
    ...
	return retval;
}
```

The `prepare_binprm()` function zeros out and then copies `BINPRM_BUF_SIZE` (current 256 bytes) of the file to be executed into the `bprm->buf`. It then iterates across a linked list of supported binary executable formats and calls the `load_binary()` function pointer for each format. It's the responsibility of each binary handler's `load_binary()` function to use the first 256 bytes to determine whether or not it can execute the file. If it can't it returns `-ENOXEC` and the search continues.

The binary handlers are registered using the [register_binfmt()](https://elixir.bootlin.com/linux/latest/C/ident/register_binfmt) function. They can be dynamically added at runtime using kernel modules, but there are some that are built in to the kernel. These include the common ELF format, the older a.out format, but the one we are most interested in is the 'script' format.

===============
Then iterate across `&formats` and `retval = fmt->load_binary(bprm)`. For scripts, load_binary is a pointer to `load_script()`. This is registered as a format by `init_script_binfmt()`, which is registered as a `core_initcall()`. The core initcalls are called in `do_initcalls()` which is called during `do_basic_setup()`, `kernel_init_freeable(void)`, `kernel_init(void *unused)` -> `rest_init()` ->

# Loading the Script

In the script binary format, the `load_binary` function pointer points to the [load_script()](https://elixir.bootlin.com/linux/latest/source/fs/binfmt_script.c#L34) function. Let's go through this and see how it works.

It's first task is to determine whether it is the appropriate handler for the file that's being executed. It looks at the first two bytes and checks whether they are the hash-bang. If not then it returns `-ENOEXEC`.

```c
static int load_script(struct linux_binprm *bprm)
{
	const char *i_name, *i_sep, *i_arg, *i_end, *buf_end;
	struct file *file;
	int retval;

	/* Not ours to exec if we don't start with "#!". */
	if ((bprm->buf[0] != '#') || (bprm->buf[1] != '!'))
		return -ENOEXEC;
```

If there is a hash-bang, it needs to parse the first line to pull out the interpreter to run, and any arguments to pass to it.






# Appendix - System Calls

It's out of scope to go deep on the system call entry, but at a high level:

- The `syscall` instruction:
    - Saves the address of the following instruction to the `rcx` register
    - Loads a new instruction pointer from the `IA32_LSTAR` model specific register.
    - Jumps to the new instruction at a ring 0 privilege level.
- The `IA32_LSTAR` register holds the address if [entry_SYSCALL_64](https://elixir.bootlin.com/linux/latest/source/arch/x86/entry/entry_64.S#L87)
    - This is set at boot time in [syscall_init()](https://elixir.bootlin.com/linux/latest/source/arch/x86/kernel/cpu/common.c#L1752)
- 
