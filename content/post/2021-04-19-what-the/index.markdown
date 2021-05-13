---
title: 'What the #!'
author: Greg Foletta
date: '2021-05-11'
slug: [what-the-hashbang]
categories: [Linux, Kernel]
description: "How do hashbangs work?"
---




Working with computers, you take a lot for granted: your press of the keyboard will bubble up through the kernel to your terminal, the HTTP request will remain intact after travelling halfway across the globe; or the stream of a cat video will be decoded and rendered on your screen. This isn't a negtive, in fact quite the opposite. The countless abstractions and indirections that hide the internal details allow us to focus on other important aspects like aesthetics, speed, and accuracy.

But at the same time in can be a very unsatisfying feeling to not know how something is working, and a feeling that you need to peek behind the curtains. That happened recently when writing a script and adding the obligatory hashbang '#!' to the first line. I've done this hundreds of times, and know that this specifies the interpreter (and optional arguments) that will run the rest of the file, but how does that work? Is it a user space or kernel space component that does this?  

In this article we're going to answer the question:

> How is an interpreter caled when specified using a hashbang in the first line of a script? 

There are some kernel components to consider in this article, and I'll be focusing on the version running on my laptop:


```sh
uname -sor
```

```
Linux 4.15.0-142-generic GNU/Linux
```


# Done In Userspace

Let's dive straight in - here's our simple Perl script that we're running.


```sh
cat data/foo.pl

chmod u+x data/foo.pl
```

```
#!/usr/bin/perl

use strict;
use warnings;
use 5.010;
use Data::Dumper;

print Dumper [@ARGV];
```

The first tool we go for is `strace`, which attaches itself to a process and intercepts system calls. In the below code snippet, we run strace with the -e argument to focus on the system calls we're interested in. I've done this for brevity within the article, but you'd likely want to look through the whole trace to get a firm idea about what the process is doing.

We spin up a bash process, then execute our script within that process.


```sh
strace -e trace=vfork,fork,clone,execve bash -c './data/foo.pl argument_1'
```

```
execve("/bin/bash", ["bash", "-c", "./data/foo.pl argument_1"], 0x7ffe171f6c90 /* 100 vars */) = 0
execve("./data/foo.pl", ["./data/foo.pl", "argument_1"], 0x564830ed1890 /* 100 vars */) = 0
$VAR1 = [
          'argument_1'
        ];
+++ exited with 0 +++
```

The strace utility shows us two processes executions: the bash shell executing (which will have followed the `clone()` call from the original shell and not captured), then the path of our script being passed directly to the `execve()` system call. This is a system call that executes processes. It's prototype is:

```c
int execve(
    const char *filename,
    char *const argv[],
    char *const envp[]
);
```

with `*filename` containing the path to the program to run, `*argv[]` containing the command line arguments, and `*envp[]` containing the environment variables.

What does this tell us? It tells us that the scripts are passed directly this system call, and there's no userspace aspect to the parsing of the hash-bang line.

# A Quick Look in glibc 

The bash process doesn't call the system call directly; the `execve()` function is part of the standard C library (on my machine it's glibc), to which bash is dynamically linked. While it's unlikely that anything of significance is occurring in the library, let's be rigorous and take a look.

We can use the `ldd` utility to print out the dynamic libraries linked at runtime by the dynamic linker:


```bash
ldd $(which bash)
```

```
	linux-vdso.so.1 (0x00007ffd1bffa000)
	libtinfo.so.5 => /lib/x86_64-linux-gnu/libtinfo.so.5 (0x00007f07ce59b000)
	libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007f07ce397000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f07cdfa6000)
	/lib64/ld-linux-x86-64.so.2 (0x00007f07ceadf000)
```

We can see that libc on my machine is located at */lib/x86_64-linux-gnu/libc.so.6*. Using `objdump` we can disassemble the shared library, and we extract out the section that's related to `execve()`.


```bash
objdump -d /lib/x86_64-linux-gnu/libc.so.6 | sed -n '/^[[:xdigit:]]\+ <execve/,/^$/p' 
```

```
00000000000e4c00 <execve@@GLIBC_2.2.5>:
   e4c00:	b8 3b 00 00 00       	mov    $0x3b,%eax
   e4c05:	0f 05                	syscall 
   e4c07:	48 3d 01 f0 ff ff    	cmp    $0xfffffffffffff001,%rax
   e4c0d:	73 01                	jae    e4c10 <execve@@GLIBC_2.2.5+0x10>
   e4c0f:	c3                   	retq   
   e4c10:	48 8b 0d 51 62 30 00 	mov    0x306251(%rip),%rcx        # 3eae68 <h_errlist@@GLIBC_2.2.5+0xdc8>
   e4c17:	f7 d8                	neg    %eax
   e4c19:	64 89 01             	mov    %eax,%fs:(%rcx)
   e4c1c:	48 83 c8 ff          	or     $0xffffffffffffffff,%rax
   e4c20:	c3                   	retq   
   e4c21:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
   e4c28:	00 00 00 
   e4c2b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
```

As expected, the standard library doesn't do much. It places 0x3b (decimal 59) into the `eax` register, which is the [execve system call number](https://elixir.bootlin.com/linux/latest/source/arch/x86/entry/syscalls/syscall_64.tbl#L70) and calls the [fast system call x86 instruction](https://www.felixcloutier.com/x86/syscall). 

I could write another whole article on the process of jumping from user space into the kernel through a system call. I've provided a brief overview in an appendix at the bottom of this article.

# Delving into the kernel

Skipping over the kernel system call handler, we start our journey in the kernel at at [SYSCALL_DEFINE3(execve)](https://elixir.bootlin.com/linux/v4.15/source/fs/exec.c#L1923). This calls [do_execve()](https://elixir.bootlin.com/linux/v4.15/source/fs/exec.c#L1841), which calls [do_execveat_common()](https://elixir.bootlin.com/linux/v4.15/source/fs/exec.c#L1694). This is where we start to see some items of interest. This function allocates the [linux_binprm](https://elixir.bootlin.com/linux/v4.15/source/include/linux/binfmts.h#L17) structure, which is the primary structure we'll be concerned with in this article. The members we're focused on are:

- `char buf[BINPRM_BUF_SIZE]` - holds first 128 bytes of the file being executed.
- `unsigned long p` - current top of the processes memory.
- `int argc, envc` - our command line argument and environment counts
- `const char * filename` - the name of the binary that's seen by the 'ps' utility. 
- `const char * interp` - name of the binary that was really executed.
- `unsigned int recursion_depth`, which tracks how far deep our binary handler search goes.


Both the `filename` and `interp` members are set to the path of the file to be executed. A temporary stack is allocated, and the `p` member is set to the top of it. The `argc` and `envc` members are set to the respective counts. The `buf` member is then zeroed out and the first `BINPRM_BUF_SIZE` bytes (which is 128 in this version of the kernel) of the file is copied into it.

At this stage, the `argv` and `envp` pointers still point to the stack of calling process. These strings are copied across into the new stack that has been allocated. 

The [exec_binprm](https://elixir.bootlin.com/linux/v4.15/source/fs/exec.c#L1669) function is then called. The main responsibility of this function is to call [search_binary_handler](https://elixir.bootlin.com/linux/v4.15/source/fs/exec.c#L1616). This is where things get interesting.

# Binary Handler Search

The binary handler is responsible for iterating through the list of supported binary formats, and dispatching the `load_binary()` function of each one. I've included the code below, minus some tangential items like locking and security checks:

```c
int search_binary_handler(struct linux_binprm *bprm)
{
	struct linux_binfmt *fmt;
	int retval;
	...
	/* This allows 4 levels of binfmt rewrites before failing hard. */
	if (bprm->recursion_depth > 5)
		return -ELOOP;
	...

	list_for_each_entry(fmt, &formats, lh) {
	    ...
		bprm->recursion_depth++;
		retval = fmt->load_binary(bprm);
		bprm->recursion_depth--;
		...
	}
	...
	return retval;
}
```

The `formats` is a linked list of [linux_binfmt](https://elixir.bootlin.com/linux/v4.15/source/include/linux/binfmts.h#L92) structures. Some of these are defined in the kernel, but they can also be loaded via loadable kernel modules. These are registered using the [register_binfmt()](https://elixir.bootlin.com/linux/v4.15/C/ident/register_binfmt) function. The built-in These include the common ELF format, the older a.out format, but the one we are most interested in is the 'script' format.

Here's the structure and the code code that registers the script format:

```c
static struct linux_binfmt script_format = {
	.module		= THIS_MODULE,
	.load_binary	= load_script,
};

static int __init init_script_binfmt(void)
{
	register_binfmt(&script_format);
	return 0;
}
```

We can see that the `load_binary` function pointer that the `search_binary_handler()` function will dispatch is the [load_script()](https://elixir.bootlin.com/linux/v4.15/source/fs/binfmt_script.c#L17) function. Let's now turn our attention to this.


# Script Binary Format

The `load_script()` function must first determine whether it is the appropriate handler for the file that's being executed. The `binprm` structure has the first 128 bytes of the file to be executed in the `buf` member. It looks at the first two bytes and checks whether they are the hash-bang. If not then it returns `-ENOEXEC`.

```c
static int load_script(struct linux_binprm *bprm)
{
	const char *i_arg, *i_name;
	char *cp;
	struct file *file;
	int retval;

	if ((bprm->buf[0] != '#') || (bprm->buf[1] != '!'))
		return -ENOEXEC;
```

The rest of the function can be broken down into three parts:

1. Parsing the interpreter and arguments
1. Splitting the interpreter and arguments
1. Updating the command line arguments
1. Recalling binary handler


## Parsing the Interpreter & Arguments

At this point the function knows it's a script, so now it has to extract the interpreter and any arguments out of the 128 byte buffer. I've commented each line of this processes below:

```c
//Add a NUL to the end so the string is NUL terminated.
bprm->buf[BINPRM_BUF_SIZE - 1] = '\0';

//The end of the string is either:
// a) A newline character, or
// b) The end of the buffer
	if ((cp = strchr(bprm->buf, '\n')) == NULL)
		cp = bprm->buf+BINPRM_BUF_SIZE-1;
		
	//For a) above, replaces the newline with a NUL.
	//If it was b) above, it redundantly replaces a NUL
	//with another NUL
	*cp = '\0';
	
	//Work our way backwards through the buffer
	while (cp > bprm->buf) {
		cp--;
		//If the character is whitespace, replace it with
		//a NUL
		if ((*cp == ' ') || (*cp == '\t'))
			*cp = '\0';
		//Otherwise, we've found the end of the interpreter
		//string
		else
			break;
	}
	

    //After the hashbang (the buf + 2), remove any whitespace
	for (cp = bprm->buf+2; (*cp == ' ') || (*cp == '\t'); cp++);
	//If we hit a NUL, the line only contains a hashbang
	//with no interpreter
	if (*cp == '\0')
		return -ENOEXEC; /* No interpreter name found */
	//i_name (and cp) points to the start of the interpreter string
	i_name = cp;
```

At the end of this process, `i_name` points to the first character of a NUL terminated string containing the path to the interpreter and arguments, with whitespace before and after being removed.

```
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+----+
| / | u | s | r | / | b | i | n | / | e | n | v |   | p | e | r | l | \0 |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+----+
  ^
  |
+------+
|i_name|         
+------+ 
```

## Splitting the Interpreter and Arguments

The string now needs to be split into its components: the path to the interpreter, and any arguments to that interpreter:

```c
i_arg = NULL;
//cp still points to the start of the interpreter string,
//exlcluding any whitespace.
//
//Move along the string until we either hit
// a) A NUL character, or
// b) A space or a tab
for ( ; *cp && (*cp != ' ') && (*cp != '\t'); cp++)
    /* nothing */ ;
//If there is whitespace, replace it with a NUL character
while ((*cp == ' ') || (*cp == '\t'))
    *cp++ = '\0';
//If there are bytes after the whitespace, these become
//the arguments to the interpreter.
if (*cp)
    i_arg = cp;
```

Again, taking our example script, the pointers now point to the following pieces of memory:

```
+---+---+---+---+---+---+---+---+---+---+---+---+----+---+---+---+---+----+
| / | u | s | r | / | b | i | n | / | e | n | v | \0 | p | e | r | l | \0 |
+---+---+---+---+---+---+---+---+---+---+---+---+----+---+---+---+---+----+
  ^                                                    ^
  |                                                    |
+------+                                             +-----+
|i_name|                                             |i_arg|          
+------+                                             +-----+
```

One of the main implications of this code is that you cannot have whitespace in the interpreter path, as anything after the whitespace is considered arguments to the interpreter.

## Updating the Arguments

The arguments and argument counts now need to be updated. If we ran our script as `./foo.pl foo_arg`, and the hashbang line was `#!/usr/bin/perl perl_arg`, the new command line arguments need to be `./usr/bin/perl perl_arg ./foo.pl foo_arg`. Because of the way the stack is laid out, this is done in reverse order. 

```c
//The current argv[0] (the filename of our script) is removed
//from the temporary stack
retval = remove_arg_zero(bprm);
...
//Add in the filename of the script being executed.
retval = copy_strings_kernel(1, &bprm->interp, bprm);
...
bprm->argc++;
if (i_arg) {
//If the interpreter line has arguments, add these in to the stack.
	retval = copy_strings_kernel(1, &i_arg, bprm);
	...
	bprm->argc++;
}
//Finallly, add the interpreter, which becomes arg[0].
retval = copy_strings_kernel(1, &i_name, bprm);
...
bprm->argc++;
//Update the 'interp` bprm member, which will now
//be difference to the 'filename' member.
retval = bprm_change_interp(i_name, bprm);
```

Now that the the interpreter has been parsed and the bprm structure updated, the interpreter is opened as a file, and the `search_binary_hander()` is called again. Except this time it will be searching for a binary handler for our interpreter.

```c
file = open_exec(i_name);
	if (IS_ERR(file))
		return PTR_ERR(file);

	bprm->file = file;
	retval = prepare_binprm(bprm);
	if (retval < 0)
		return retval;
	return search_binary_handler(bprm);
```
The interpreter is of this type:


```sh
file /usr/bin/perl
```

```
/usr/bin/perl: ELF 64-bit LSB shared object, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 3.2.0, BuildID[sha1]=e865d791bb4b89f4ab5e7ec1217e38ff6c31f3ed, stripped
```

Thus the ELF binary handler will be called, doing what it needs to do to load the binary and add it to the kernel scheduler, eventually running the process.

# Summary

We started this article out with a question: how is an interpreter called when used in a hashbang line of script. We used some tools to determine whether it was performed in userspace, but found that it was the kernel that performed this task.

We went through the kernel, starting at the `execve()` system call, working our way down to the binary handlers. We then went through the 'script' binary handler, which matches files that have '#!' as their first two bytes. We could see how this handler parsed the interpreter line, extracting the interpreter path and optional arguments, and updating the binary to be called by the kernel. 

This is an example of an elegant and generalised solution by the Linux kernel.

# Appendix - System Calls

When we started delving into the kernel, we skipped over the `syscall` instruction and the system call handler in the kernel; this appendix summarises what happens between. There's a number of different variables that change the code path (page table isolation, slow and fast paths), so it's a simplification.

As with the rest of this article, we only consider an x86_64 processor architecture, and I'm also going to ignore the *page table isolation* feature introduced to mitigate against the [Meltdown](https://meltdownattack.com/) vulnerability.

- The `syscall` instruction:
    - Saves the address of the following instruction to the `rcx` register
    - Loads a new instruction pointer from the `IA32_LSTAR` model specific register.
    - Jumps to the new instruction at a ring 0 privilege level.
- The `IA32_LSTAR` register holds the address if [entry_SYSCALL_64](https://elixir.bootlin.com/linux/v4.15/source/arch/x86/entry/entry_64.S#L206), which is our system call handler.
    - This is set (per-CPU) at boot time in [syscall_init()](https://elixir.bootlin.com/linux/v4.15/source/arch/x86/kernel/cpu/common.c#L1373).
- The `entry_SYSCALL_64` handler performs re-organisation required to transition from userspace to kernel space.
    - Main task is to push all the current registers on to some new stack space.
    - There's loads of other things, but let's consider them out of scope for this summarisation.
- The system call is then called using its number (in the `rax` register) as an index into the [sys_call_table](https://elixir.bootlin.com/linux/v4.15/source/arch/x86/entry/syscall_64.c#L21) array.
    - This is an array of function pointers to each of the system calls.
    - The file in the `#include <asm/syscalls_64.h>` line is generated dynamically.
- It's generated from the [syscall table file](https://elixir.bootlin.com/linux/v4.15/source/arch/x86/entry/syscalls/syscall_64.tbl).
- This is converted into a header via a simple [shell script](https://elixir.bootlin.com/linux/v4.15/source/arch/x86/entry/syscalls/syscallhdr.sh).
