# RISC-V GCC

XiaoXuan Assembly 使用编译工具 [RISC-V GCC](https://github.com/riscv-collab/riscv-gnu-toolchain) 来对比编译、汇编和链接的结果，下面简单介绍 RISC-V GCC 的使用方法。

<!-- @import "[TOC]" {cmd="toc" depthFrom=2 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [RISC-V 的编译工具](#risc-v-的编译工具)
- [QEMU 的工作模式](#qemu-的工作模式)
- [Hello world! 程序](#hello-world-程序)
  - [编译](#编译)
  - [可执行文件的主要内容](#可执行文件的主要内容)
  - [运行](#运行)
  - [分阶段编译](#分阶段编译)
  - [常用的参数](#常用的参数)
- ["裸机" 程序](#裸机-程序)
  - [打印单个字符的函数](#打印单个字符的函数)

<!-- /code_chunk_output -->

## RISC-V 的编译工具

假设我们工作的平台是 x86_64 Linux，现在需要把程序编译成可以在 RISC-V 平台上运行的可执行文件，这种编译叫做 _交叉编译_。相对地，平常 _普通的编译_ 是在当前的平台里编译出给当前平台运行的软件。交叉编译本质上是生成 "可以在目标平台里顺利运行的二进制文件"，为了实现这个目标，编译器在生成二进制文件时，有几个基本的要素必须跟目标平台一致：指令集、内核（系统调用）、各种库的所在位置等。

RISC-V GCC 是一个常用的交叉编译工具，在大部分 Linux 发行版里，都可以通过包管理器安装。

注意在安装 RISC-V GCC 的时候，有可能会发现有两套名称相近的工具，比如在 Arch Linux 里，有 `riscv64-elf-*` 和 `riscv64-linux-gnu-*` 两套程序。前者用于编译 "裸机" 程序，即在 "无操作系统" 的环境里运行的程序，比如开发内核或者嵌入式程序。后者用于编译在 Linux 环境中运行的程序，也就是我们平常所接触到的程序。条件允许的话，建议两套工具都安装。技术来说，后者只不过会链接 C 的标准库，除此之外并没有太大的不同。因此有些环境不区分这两套程序，统一叫做 `riscv64-unknown-elf-*`。

## QEMU 的工作模式

对于裸机程序，我们使用 `qemu-system-riscv64` 来运行，这时 QEMU 会工作在 "全系统模拟" 模式中，它模拟了一个完整的计算机系统，包括 CPU、内存、磁盘等硬件，我们可以在这种模式下执行所有 CPU 指令。

对于 Linux 程序，因为这种程序一般包含系统调用等的代码，所以无法直接使用 `qemu-system-riscv64` 来运行，除非你把引导程序、内核、虚拟磁盘等通通都配置好了，它才能顺利运行。当然还有一个简单的方法，使用 QEMU 的 _用户模式模拟_ 程序 `qemu-riscv64` 来运行，这种模式会把你的程序转换为主机平台支持的程序（当然 _系统调用_ 也一起被转换），所以如果你写了一个向控制台打印 "Hello world" 的 RISC-V 程序，想让它跑起来的最简单的方法是使用 `riscv64-linux-gnu-gcc` 编译，然后使用 `qemu-riscv64` 来运行。

## Hello world! 程序

下面先从最简单的程序开始了解 RISC-V GCC。

### 编译

目录 [resources](./resources/) 里有一个 "Hello world!" 程序 `hello.c`，内容如下：

```c
#include <stdio.h>

int main() {
    printf("Hello world!\n");
    return 0;
}
```

因为这不是 "裸机" 程序，因此需要使用 `riscv64-linux-gnu-gcc` 来编译：

`$ riscv64-linux-gnu-gcc -g -Wall -o hello.out hello.c`

- 参数 `-g` 用于生成供 GDB 使用的额外调试信息；
- 参数 `-Wall` 用于报告编译过程中的所有警告和错误信息；
- 参数 `-o hello.out` 用于指定输出的文件的名称，如果缺省这个参数，默认的输出文件名为 `a.out`，因为我们后续还有其它程序需要编译，所以为了避免混淆，这里需要指定输出文件名。

编译完成后得到文件 `hello.out`，使用 `file` 命令可以查看该文件的格式：

`$ file hello.out`

输出结果如下：

```text
hello.out: ELF 64-bit LSB pie executable, UCB RISC-V, RVC, double-float ABI, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-riscv64-lp64d.so.1, BuildID[sha1]=156ee22d4c2f19bf333101d38249ce86c6a19d49, for GNU/Linux 4.15.0, with debug_info, not stripped
```

### 可执行文件的主要内容

我们重复上一章 [测试环境的安装和配置](../tesing-env-setup/README.zh-Hans.md) 所掌握的工具，首先查看程序的大小：

`$ riscv64-linux-gnu-size hello.out`

输出结果如下：

```text
   text    data     bss     dec     hex filename
   1123     584       8    1715     6b3 hello.out
```

根据上面的数值可知，编译器在我们的程序里额外塞入了不少信息，下面查看该 ELF 文件的详细信息：

`$ riscv64-linux-gnu-readelf -l hello.out`

输出的（部分）结果如下：

```text
Elf file type is DYN (Position-Independent Executable file)
Entry point 0x5b0
There are 10 program headers, starting at offset 64

Program Headers:
  Type           Offset             VirtAddr           PhysAddr
                 FileSiz            MemSiz              Flags  Align
  LOAD           0x0000000000000000 0x0000000000000000 0x0000000000000000
                 0x00000000000006e4 0x00000000000006e4  R E    0x1000
  LOAD           0x0000000000000e08 0x0000000000001e08 0x0000000000001e08
                 0x0000000000000248 0x0000000000000250  RW     0x1000

 Section to Segment mapping:
  Segment Sections...
   03     .interp .note.gnu.build-id .note.ABI-tag .gnu.hash .dynsym .dynstr .gnu.version .gnu.version_r .rela.dyn .rela.plt .plt .text .rodata .eh_frame_hdr .eh_frame
   04     .preinit_array .init_array .fini_array .dynamic .data .got .bss
```

可见有两个 program header 将会被加载进内存，其中第一段具有 "read, execute" 标记，第二段有 "read, write" 标记，同时得知程序的入口位于 `0x5b0`。

下面再反汇编其中的代码段，查看位置 `0x5b0` 的内容：

`$ riscv64-linux-gnu-objdump -d hello.out`

输出（部分）结果如下：

```text
Disassembly of section .text:

...
00000000000005b0 <_start>:
 5b0:   022000ef                jal     ra,5d2 <load_gp>
 5b4:   87aa                    mv      a5,a0
 5b6:   00002517                auipc   a0,0x2
 5ba:   a8253503                ld      a0,-1406(a0) # 2038 <_GLOBAL_OFFSET_TABLE_+0x10>
 5be:   6582                    ld      a1,0(sp)
 5c0:   0030                    addi    a2,sp,8
 5c2:   ff017113                andi    sp,sp,-16
 5c6:   4681                    li      a3,0
 5c8:   4701                    li      a4,0
 5ca:   880a                    mv      a6,sp
 5cc:   fc5ff0ef                jal     ra,590 <__libc_start_main@plt>
 5d0:   9002                    ebreak
```

跟我们预想不同的是，程序的入口并不是 `main` 函数，而是一个名为 `_start` 的过程，该过程会设置 `global pointer` 寄存器的值，然后调用 `__libc_start_main@plt` 对 `GLOBAL_OFFSET_TABLE` 等进行一系列初始化工作。

> 关于 GOT（`GLOBAL_OFFSET_TABLE`）的详细信息请参阅本项目的另一篇文章 [动态调用](../dynamic-linking/README.zh-Hans.md)

而 `main` 函数的内容如下：

```text
0000000000000668 <main>:
 668:   1141                    addi    sp,sp,-16
 66a:   e406                    sd      ra,8(sp)
 66c:   e022                    sd      s0,0(sp)
 66e:   0800                    addi    s0,sp,16
 670:   00000517                auipc   a0,0x0
 674:   02050513                addi    a0,a0,32 # 690 <_IO_stdin_used+0x8>
 678:   f29ff0ef                jal     ra,5a0 <puts@plt>
 67c:   0001                    nop
 67e:   60a2                    ld      ra,8(sp)
 680:   6402                    ld      s0,0(sp)
 682:   0141                    addi    sp,sp,16
 684:   8082                    ret
```

可见它是一个普通的函数，有 _开场白_ 和 _收场白_ 模板代码，然后中间是对函数 `puts` 的调用。

### 运行

因为 `hello.out` 不是 "裸机" 程序，它依赖操作系统（系统调用）才能运行，所以我们可以使用 _用户模式_ 的 QEMU 模拟器 `qemu-riscv64` 来运行：

`$ qemu-riscv64 hello.out`

运行的结果是：

```text
qemu-riscv64: Could not open '/lib/ld-linux-riscv64-lp64d.so.1': No such file or directory
```

这是因为我们程序调用了 `printf` 函数，而这个函数实际上是调用了标准库的 `puts`，RISC-V GCC 默认使用了动态链接，所以在运行时会尝试寻找该函数所在的库文件（以及函数的地址）。不过 `qemu-riscv64` 有时并不能准确定位库文件的路径（虽然 _动态链接技术_ 对操作系统来说是不错的主意，但对于普通用户来说，应用程序因动态链接引起的问题实在令人头痛），河马蜀黍粗略地试了几种方法均未成功解决该问题，因此下面我们尝试使用静态链接。

> 注意有些环境里的 RISC-V GCC 编译器默认使用静态链接。

我们可以在编译时传入 `-static` 参数，用于指示 GCC 使用静态链接，也就是说，把调用的外部函数的代码复制进我们的可执行文件里：

`$ riscv64-linux-gnu-gcc -static -o hello.static.out hello.c`

先看看文件格式：

`$ file hello.static.out`

输出结果：

```text
hello.static.out: ELF 64-bit LSB executable, UCB RISC-V, RVC, double-float ABI, version 1 (SYSV), statically linked, BuildID[sha1]=e5483614d4b600c22bdada95913a953eae577965, for GNU/Linux 4.15.0, with debug_info, not stripped
```

原先的 "dynamically linked" 已经变为 "statically linked"。再看看文件的大小：

`$ riscv64-linux-gnu-size hello.static.out`

输出结果如下：

```text
   text    data     bss     dec     hex filename
 387532   22024   21760  431316   694d4 hello.static.out
```

代码段的大小从 1KB 多增长到近 400KB，这是因为链接器把所用到的（位于标准库里头的）函数的代码都复制过来了，如果反汇编 `hello.static.out` 将会得到超长的文本，因此这里就略过了，下面我们运行这个静态链接的可执行文件：

`$ qemu-riscv64 hello.static.out`

这次得到我们预期的结果了：

```text
Hello world!
```

### 分阶段编译

当我们执行命令 `riscv64-linux-gnu-gcc` 将一个 C 源文件编译为一个可执行文件时，实际上 GCC 在背后是分 4 个阶段来完成的：

![GCC compile stages](../images/gcc-compile-stage.png)

1. 预处理
   将源代码里的 `include` 文件包含进来，解析其中的条件编译指令（`#ifdef`），展开宏（`macro`）等各种预处理指令。相当于如下命令：

   `$ riscv64-linux-gnu-cpp hello.c > hello.i`

2. 编译
   将 C 代码编译为汇编代码，相当于如下命令：

   `$ riscv64-linux-gnu-gcc -S hello.i`

3. 汇编
   将汇编代码转换为机器指令，并生成目标文件，相当于如下命令：

   `$ riscv64-linux-gnu-as -o hello.o hello.s`

   第 1 到第 3 步也可以一步完成：`$ riscv64-linux-gnu-gcc -c -o hello.o hello.c`，参数 `-c` 表示只编译（包括汇编）但不链接。

4. 链接
   将多个目标文件（假如有的话）链接起来，并重新定位其中的函数地址，最后生成 ELF 格式的可执行文件，相当于命令：

   `$ riscv64-linux-gnu-ld -o hello.stage.out -e main -lc -static hello.o`

   其中参数 `-e main` 用来指定入口函数，参数 `-lc` 表明需要链接 `libc`，参数 `-static` 表示静态链接。

最后我们得到可执行文件 `hello.stage.out`，不过上面的命令在河马蜀黍的机器上生成的却是动态链接（暂时不知道原因），改用命令 `$ riscv64-linux-gnu-gcc -o hello.stage.out -static hello.o` 可以得到预期的 `hello.stage.out`。

运行该可执行文件：

`$ qemu-riscv64 hello.stage.out`

输出了正确的结果 "Hello world!"。

### 常用的参数

- `-I` 用于指定头文件的路径
  有时头文件分布在多个位置，这时可以用参数 `-I` 把额外的头文件路径包含进来，比如当前的路径为 `/home/yang/hello-world/hello.c`，假如有额外的头文件位于 `/home/yang/include`，则可以这样传入参数：

  `$ riscv64-linux-gnu-gcc -I /home/yang/include hello.c`

- `-L` 和 `-l` 用于指定额外库的路径和名称
  接着上一个例子，如果我们的程序需要使用到库 `/home/yang/lib/libmymath.a`，则可以这样传入参数：

  `$ riscv64-linux-gnu-gcc -L /home/yang/lib -lmymath hello.c`

  其中参数 `-lmymath` 的 `-l` 是参数名称，`mymath` 是参数值。这个参数表示编译过程会使用到库文件 `libmymath.a`。注意库名称 `mymath` 必须去除了前缀 `lib` 和后缀 `.a`（或者 `.so`），比如 `libm.so` 的库名是单独一个字母 `m`，`libpthread.so` 的库名是 `pthread`。

GCC 的编译过程是松散的，它由上一节所述的 4 个相对独立的过程组成，显然头文件是在预处理阶段使用，而库文件则是在链接阶段使用。另外每个源代码文件都是单独编译，只有在链接阶段才被合并在一起，理解这些概念有助于解决在编译过程遇到的各种问题。

## "裸机" 程序

"裸机" 程序虽然运行在 "无操作系统" 的环境中，但数值计算、流程控制、程序的结构等跟普通应用程序是一样的，只是在进行 I/O 操作时，需要直接跟硬件打交道。

幸好跟硬件打交道也不算太复杂：有些硬件在电路里被映射到某段内存地址，比如串口控制台、键盘、VGA 文本等，你只需把它们当作内存的数据来读写，即可获取这些硬件的状态数据或者更改它们的状态；另外有些硬件有专门的 CPU 指令来操作，我们只需编写相应的汇编代码即可。

下面是一个 "裸机" 版的 "Hello world!" 程序，该程序实现 3 个功能：

1. 向串口控制台打印一行 "Hello world!" 文本；
2. 计算两个整数的和并显示其结果；
3. 计算一个整数加上 10 之后的值，并显示其结果；

因为没有操作系统的支持，显然我们无法直接使用 `printf` 函数，但我们可以编写一个功能相近的简单函数。

### 打印单个字符的函数

我们的程序准备在虚拟机 QEMU RISC-V virt 中运行，通过查看 [QEMU RISC-V virt 的源代码](https://github.com/qemu/qemu/blob/master/hw/riscv/virt.c) 可以找到一些基本硬件的内存映射关系：

```c
static const MemMapEntry virt_memmap[] = {
    [VIRT_MROM] =         {     0x1000,        0xf000 },
    ...
    [VIRT_UART0] =        { 0x10000000,         0x100 },
    ...
    [VIRT_FLASH] =        { 0x20000000,     0x4000000 },
    ...
    [VIRT_DRAM] =         { 0x80000000,           0x0 },
};
```

其中串口通信 UART 被映射到 `0x1000_0000`，只需向该内存地址写入一个 byte 类型整数，该 ASCII 字符就会被重定向到我们的虚拟终端。所以打印单个字符的函数是很简单的，在目录 [resources](./resources/) 有源代码 `put_char.S`，其内容如下：

```S
.section .text.put_char

.globl put_char

put_char:
    li s1, 0x10000000
    mv s2, a0
    sb s2, 0(s1)
    ret
```

```bash
$ riscv64-elf-as -o app-loader.o app-loader.S
$ riscv64-elf-as -o put_char.o put_char.S
$ riscv64-elf-gcc -I . -Wall -fPIC -c -o libprint.o libprint.c
$ riscv64-elf-gcc -I . -Wall -fPIC -c -o liba.o liba.c
$ riscv64-elf-gcc -I . -Wall -fPIC -c -o libb.o libb.c
$ riscv64-elf-gcc -I . -Wall -fPIC -c -o app.o app.c
$ riscv64-elf-ld -T app.lds -o app.out app-loader.o app.o liba.o libb.o libprint.o put_char.o
$ qemu-system-riscv64 \
    -machine virt \
    -nographic \
    -bios none \
    -kernel app.out
```