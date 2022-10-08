# 配置用于验证的环境

<!-- @import "[TOC]" {cmd="toc" depthFrom=2 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [安装必要软件](#安装必要软件)
- [汇编](#汇编)
  - [构建目标文件](#构建目标文件)
  - [查看导出的符号列表](#查看导出的符号列表)
  - [查看文件的段信息](#查看文件的段信息)
  - [查看各段的大小](#查看各段的大小)
  - [反汇编](#反汇编)
- [链接](#链接)
  - [链接单个目标文件](#链接单个目标文件)
  - [运行可执行文件](#运行可执行文件)
  - [链接多个目标文件](#链接多个目标文件)

<!-- /code_chunk_output -->

## 安装必要软件

为了方便测试和验证汇编和链接的结果，XiaoXuan Assembly 使用虚拟机 [QEMU](https://www.qemu.org/) 以及编译工具链 [RISC-V Toolchains](https://github.com/riscv-collab/riscv-gnu-toolchain)，开发者在 Linux 环境里只需使用各发行版自己的 _包管理器_ 来安装这两个软件即可。

> 虚拟机使用 [Spike RISC-V ISA Simulator](https://github.com/riscv-software-src/riscv-isa-sim)，编译工具链使用 [LLVM](https://llvm.org/) 也是可以的。

下面章节既是对这两个软件的测试，同时也是有关汇编原理的简短教程。

## 汇编

### 构建目标文件

在目录 [resources](./resources/) 里有一个简单的汇编文件 `a.S`，内容如下：

```s
.section .text.entry

.globl _start
.globl _print_a

_start:
    call _print_a
_loop:
    nop
    j _loop

_print_a:
    li s1, 0x10000000   # set s1 = 0x1000_0000
    li s2, 0x41         # set s2 = 0x41
    sb s2, 0(s1)        # store s2 (as byte) to memory[s1+0]
                        # the 0x1000_0000 is mapped to UART0
                        # see QEMU source https://github.com/qemu/qemu/blob/master/hw/riscv/virt.c
    ret
```

该程序的功能是向串口打印一个大写的字母 "A"。下面简单讲解一下：

1. 程序的第 1 行用于指定汇编的结果放在目标文件的哪个段里；
2. 接下来的两句 `.globl` 用于声明两个将会导出的符号（在这里也就是函数的名称，最后导出的是函数的地址）；
3. `_start` 可以看作是一个函数，函数里调用了另一个函数 `_print_a`，然后进入无限循环（汇编语言实际上没有函数概念，也就是说结构之间没有边界，为了防止 `_start` 函数往下执行，所以在函数的末尾处设定了一个无限循环）；
4. `_print_a` 也可以看作是另外一个函数，作用是把 byte 类型的整数 `0x41`（即大写字母 `A` 对应的 ASCII 号码）写入内存地址 `0x1000_0000`，这个内存地址被映射到 UART 端口（类似串口控制台 Serial Console），QEMU 的 UART 被重定向到我们的虚拟终端，所以实际上就是向我们的虚拟终端输出了一个大写字母 `A`，`_print_a` 函数的最后一句是 `ret` 指令，也就是返回到调用函数指令的下一条指令。

下面使用 RISC-V GCC 汇编器 `riscv64-elf-as` 生成目标文件：

`$ riscv64-elf-as a.S -g -o a.o`

- 参数 `a.S` 表示源文件的名称路径。
- 参数 `-g` 表示同时生成调试信息。
- 参数 `-o a.o` 用于指定输出文件的名称。

> 因 Linux 发行版的不同，RISC-V GCC 工具链当中的各个工具的名称前缀可能会有所不同，比如 `riscv64-elf-*` 会被命名为 `riscv64-unknown-elf-*`。
> 另外注意区分 `riscv64-elf-*` 和 `riscv64-linux-gnu-*`，前者用于编译 "裸机" 程序，即程序运行于 "无操作系统" 的环境中，比如嵌入式环境，或者用于编译内核。后者用于编译在 Linux 环境中运行的程序。

然后将会得到文件 `a.o`，我们先查看它的文件类型：

`$ file a.o`

输出内容如下：

```text
a.o: ELF 64-bit LSB relocatable, UCB RISC-V, double-float ABI, version 1 (SYSV), with debug_info, not stripped
```

可见汇编器输出的是一个 ELF 格式的文件，同时可以大致推断出 RISC-V GCC 默认的编译架构（即参数 `-march`）是 `rv64imafd`，ABI （即编译参数 `-mabi`）是 `lp64d`。

有关目标架构和 ABI 详细请参阅本项目的另一篇文章 [平台架构和 ABI](../platform/README.zh-Hans.md)。

### 查看导出的符号列表

`符号` 是一个专用的名词，可以理解为各个函数或者全局变量等的名称。使用工具 `riscv64-elf-nm` 可以查看目标文件的导出符号列表：

`$ riscv64-elf-nm a.o`

输出的内容如下：

```text
0000000000000008 t _loop
0000000000000010 T _print_a
0000000000000000 T _start
```

左边一列是各个符号的虚拟地址，右边一列是符号的名称，中间一列是符号类型的代号，部分代号的含义如下：

- A: Global absolute symbol.
- a: Local absolute symbol.
- B: Global bss symbol.
- b: Local bss symbol.
- D: Global data symbol.
- d: Local data symbol.
- T: Global text symbol.
- t: Local text symbol.
- U: Undefined symbol.

符号类型代号当中，大写的表示是导出的（供外部使用的），小写的表示局部的（供内部使用的）。详细的列表可参阅 [GNU Binary Utilities Document](https://sourceware.org/binutils/docs/binutils/index.html) 当中的 [nm](https://sourceware.org/binutils/docs/binutils/nm.html) 一章。

类型 `U` 比较特殊，表示未定义的符号。比如在一个源代码文件里，调用了一个外部函数，那么这个外部函数的名称就是一个未定义的符号。可见这里的 "未定义" 是相对当前源代码文件而言的。

### 查看文件的段信息

文件 `a` 是一个 ELF 格式的文件，ELF 格式的文件的内容被划分为多个段。

`$ riscv64-elf-objdump -h a.o`

输出的部分内容如下：

```text
Idx Name          Size      VMA               LMA               File off  Algn
  0 .text         00000020  0000000000000000  0000000000000000  00000040  2**2
                  CONTENTS, ALLOC, LOAD, RELOC, READONLY, CODE
  1 .data         00000000  0000000000000000  0000000000000000  00000060  2**0
                  CONTENTS, ALLOC, LOAD, DATA
  2 .bss          00000000  0000000000000000  0000000000000000  00000060  2**0
                  ALLOC
```

`.text`, `.data` 和 `.bss` 是段的名称，`VMA` 和 `LMA` 分别表示虚拟内存地址和加载地址，`ALLOC, LOAD, READONLY, CODE` 等是段的标记，程序加载器会根据该标记来决定处理该段的方式。

比如 `ALLOC` 表示程序加载器需要分配空间给该段，`LOAD` 表示该段需要从文件加载进内存，`READONLY` 表示该段的内容不能被子进程修改，`CODE` 表示该段是可执行代码，`DATA` 表示该段是数据段。完整的标记列表可以参阅 [GDB - section-flag](https://sourceware.org/gdb/onlinedocs/gdb/Files.html)。

> 如果使用 `-x` 参数，将会看到所有的段，包括调试信息的段，不过一般我们不需要关心这些段的内容。

ELF 的段（section）有两个视图：一个是从汇编器和链接器等工具看到的 section 视图（上面我们看到的都是这种视图），另一个是从程序加载器看到的 program 视图。

section 视图在 "section headers" 里列出，program 视图在 "program header" 里列出；section 视图基本上跟 section 一一对应，而 program 视图则存在一对多的映射关系，比如 `.text` 和 `.data` 段常常对被映射到同一个 program header。

使用命令 `riscv64-elf-readelf -l a.o` 即可列出 program header，不过由于目前的 `a.o` 还不是可执行文件，所以它的 program header 是空的。完整的 ELF 文件的结构信息可以参阅 [ELF Format wiki](https://en.wikipedia.org/wiki/Executable_and_Linkable_Format)。

### 查看各段的大小

使用 `riscv64-elf-size` 可以查看各个段的大小：

`$ riscv64-elf-size a.o`

输出的结果如下：

```text
   text    data     bss     dec     hex filename
     32       0       0      32      20 a.o
```

### 反汇编

对目标文件进行 _反汇编_ 将会得到汇编文本，同时还能得到指令的机器码（二进制）以及各个指令的地址，另外我们手写汇编源代码时，偶尔会写一些 `伪指令`（即由多个真实指令组成的虚拟指令），通过反汇编能得到真实的指令。

`$ riscv64-elf-objdump -d a.o`

输出的结果如下：

```text
Disassembly of section .text:

0000000000000000 <_start>:
   0:   00000097                auipc   ra,0x0
   4:   000080e7                jalr    ra # 0 <_start>

0000000000000008 <_loop>:
   8:   00000013                nop
   c:   ffdff06f                j       8 <_loop>

0000000000000010 <_print_a>:
  10:   100004b7                lui     s1,0x10000
  14:   04100913                li      s2,65
  18:   01248023                sb      s2,0(s1) # 10000000 <_print_a+0xffffff0>
  1c:   00008067                ret
```

注意参数 `-d` 仅反汇编 `.text` 段，如果你想查看所有段的内容，可以使用 `-D` 参数代替 `-d`，不过一般我们不用关心其它段的内容。

下面分析其中的第 2 个指令 `0000_80e7`：

```text
000000000000  00001 000 00001 1100111
____________  _____     _____ _______
|offset[11:0] rs=1      rd=1  jalr
```

解码得出：`jalr ra, 0(ra)`，结合上一条指令 `auipc ra,0x0` 来看，这两条指令并不能实现跳转到 `_print_a` 函数，所以这里仅是一个占位符。尽管我们现阶段就已经知道 `_print_a` 函数的地址，但仍然使用地址 `0` 来代替，等到链接的时候才会统一被替换为真实地址。

## 链接

链接器主要有两个目标：

1. 将多个（汇编器产生的）目标文件合并成为一个可执行文件。

目标文件里往往存在多个 “段”，在合并时默认会将相同类型（或者说相同名称）的段合并成一个段。

比如假设现有两个目标文件 `a.o` 和 `b.o`。在链接时，`a.o` 的 `.text` 段将会和 `b.o` 的 `.text` 段合并，`a.o` 的 `.data` 段和 `b.o` 的 `.data` 段合并，最后再将合并后的各个段连接起来。

具体的合并方案是由一个链接器的脚本控制的，这个默认脚本可以通过命令 `$ riscv64-elf-ld --verbose` 查看，脚本的具体含义可以参考 [LD 的文档](https://sourceware.org/binutils/docs/ld/index.html) 当中的 [3 Linker Scripts](https://sourceware.org/binutils/docs/ld/Scripts.html) 一章，这里有一个 [中文翻译版](https://blog.csdn.net/m0_47799526/article/details/108765403) 也可以参考一下。

有时目标文件可能是第三方提供的库，比如 C 的数学库 `/usr/lib/libm.so`，所以链接时又有静态链接和动态链接之分，详细的请参阅本项目的另一篇文章 [函数的调用与链接](../calling-conventions/README.zh-Hans.md)。

2. 将指令中用到的符号（可以粗略理解为函数或者公共变量的地址）的真实地址填补上。

### 链接单个目标文件

下面先链接上一节构建的 `a.o`，然后观察链接前后目标文件的不同。

`$ riscv64-elf-ld a.o -o a.out`

上面程序运行之后得到文件 `a.out`，先查看文件的类型：

`$ file a.out`

输出如下信息：

```text
a.out: ELF 64-bit LSB executable, UCB RISC-V, double-float ABI, version 1 (SYSV), statically linked, with debug_info, not stripped
```

对比 `a.o` 的输出信息：

```text
a.o: ELF 64-bit LSB relocatable, UCB RISC-V, double-float ABI, version 1 (SYSV), with debug_info, not stripped
```

发现除了多了 `statically linked` 其余是一样的。为了进一步分析它们的异同，可以用 `riscv64-elf-readelf` 命令查看文件头：

```bash
$ riscv64-elf-readelf -h a.o
$ riscv64-elf-readelf -h a.out
```

输出的结果如下：

```text
< Type:                              REL (Relocatable file)
< Entry point address:               0x0
< Start of program headers:          0 (bytes into file)
< Number of program headers:         0

> Type:                              EXEC (Executable file)
> Entry point address:               0x100b0
> Start of program headers:          64 (bytes into file)
> Number of program headers:         2
```

可见 `a.o` 是一个 `Relocatable` 文件，里面没有 _program header_，无法被执行；而 `a.out` 是一个可执行文件，且有 _program header_。

然后再看看导出符号表：

`$ riscv64-elf-nm a.out`

输出的内容如下：

```text
00000000000110d0 T __BSS_END__
00000000000110cc T __bss_start
00000000000110cc T __DATA_BEGIN__
00000000000110cc T _edata
00000000000110d0 T _end
00000000000118cc A __global_pointer$
00000000000100b4 t _loop
00000000000100bc T _print_a
00000000000110cc T __SDATA_BEGIN__
00000000000100b0 T _start
```

发现多出了几个符号，比如 `__DATA_BEGIN`，`__bss_start` 等，这些符号来自链接脚本。

然后再看段信息：

`$ riscv64-elf-objdump -h a.out`

输出的内容如下：

```text
Idx Name          Size      VMA               LMA               File off  Algn
  0 .text         0000001c  00000000000100b0  00000000000100b0  000000b0  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, CODE
```

发现 `.data` 和 `.bss` 段不见了（因为它们原本就是无内容的，长度为 0，所以在最后输出文件里被去除了），然后 `.text` 的长度不变，而 `VMA` （虚拟内存地址）和 `LMA` （加载内存地址）的值都变为 `0x1_00b0`。

因为 `a.out` 已经是可执行文件，所以现在可以查看 program header 了：

`$ riscv64-elf-readelf -l a.out`

输出的结果如下：

```text
Elf file type is EXEC (Executable file)
Entry point 0x100b0
There are 2 program headers, starting at offset 64

Program Headers:
  Type           Offset             VirtAddr           PhysAddr
                 FileSiz            MemSiz              Flags  Align
  RISCV_ATTRIBUT 0x00000000000000cc 0x0000000000000000 0x0000000000000000
                 0x0000000000000043 0x0000000000000000  R      0x1
  LOAD           0x0000000000000000 0x0000000000010000 0x0000000000010000
                 0x00000000000000cc 0x00000000000000cc  R E    0x1000

 Section to Segment mapping:
  Segment Sections...
   00     .riscv.attributes
   01     .text
```

program header 主要用于指示程序加载器如何加载程序（到内存），由上面的结果可见程序会被加载到 `0x1_0000`，总共加载 `0xcc` 个字节。又因为程序的入口位于地址 `0x1_00b0`，所以实际指令的大小为 `0xcc - 0xb0 = 0x1c`，这个大小跟 section header 列出的 `.text` 段的大小是一致的。

然后再次查看各个段的大小：

`$ riscv64-elf-size a.out`

输出的内容如下：

```text
   text    data     bss     dec     hex filename
     28       0       0      28      1c a.out
```

对比链接之前的 `a.o`，发现代码段居然减少了 4 个字节，我们反汇编便知道其中的原因：

`$ riscv64-elf-objdump -d a.out`

输出的结果如下：

```text
Disassembly of section .text:

00000000000100b0 <_start>:
   100b0:       00c000ef                jal     ra,100bc <_print_a>

00000000000100b4 <_loop>:
   100b4:       00000013                nop
   100b8:       ffdff06f                j       100b4 <_loop>

00000000000100bc <_print_a>:
   100bc:       100004b7                lui     s1,0x10000
   100c0:       04100913                li      s2,65
   100c4:       01248023                sb      s2,0(s1) # 10000000 <__global_pointer$+0xffee734>
   100c8:       00008067                ret
```

从反汇编的结果发现两处不同：

1. 指令的地址从 0x1_00b0 开始，原先从 0 开始；
2. `call _print_a` 语句由 2 个指令 `auipc` 和 `jalr` 转换为 1 个指令 `jal`，且目标地址被填上真实的地址，RISC-V 一条指令（不管是 32 位还是 64 位）的长度为 4 个字节，所以少了一条指令刚好就少了 4 个字节。

现在分析指令 `00c000ef`：

```text

0    0000000110 0    00000000 00001 1101111
---- ---------- ---- -------- ----- -------
[20] [10:1]     [11] [19:12]  rd=1  jal

```

解码得出：`jal ra, 0b1100`，其中 `0b1100` 是地址偏移值，我们来算算它表示的绝对地址：当前指令地址为 `0x1_00b0`，即在运行时，`PC` 寄存器的值为 `0x1_00b0`，加上偏移值 `0b1100` 得出 `0x100bc`，这正好是函数 `_print_a` 的地址。

> 在数字电路里 PC 的值主要有 3 个来源：一个是指令被获取（即 fetch）之后，PC 的当前值加上了数值 `4`；另一个是当前的 PC 值加上跳转指令当中的立即数；最后一个是（jalr 指令）当前 PC 值加上跳转指令的立即数，再加上目标寄存器的值。PC 的下一个值会根据指令的不同而由 _复用器_ 采用这 3 个来源当中的一个。对于上面的 `jal` 指令，采用的是第 2 种来源。

### 运行可执行文件

上一步我们得到 `a.out` 是一个 ELF 格式的可执行文件，不过如果你当前操作的计算机是 x86（包括 AMD x86-64） 或者 ARM 架构的，是无法直接执行这个文件的，因为这个可执行文件的目标平台是 RISC-V 架构。河马蜀黍当前的计算机是 x86 架构的，直接执行之后出现了如下提示信息：

```text
$ ./a.out
Segmentation fault (core dumped)
```

显然我们的 x86 CPU 无法正确理解 RISC-V 的指令，经过一番挣扎之后直接抛出 _段失败_ 错误。

下面我们使用模拟器 QEMU 来运行可执行文件 `a.out`，

```bash
$ qemu-system-riscv64 \
    -machine virt \
    -nographic \
    -bios none \
    -kernel a.out
```

这次不会显示 _段失败_ 错误了，但是等了半天都没等到程序结束，也没看到大写字母 “A”，显然我们的程序并没有被正确执行。

> 按 `Ctrl+a, x`（即先按下 `Ctrl+a`，然后再单独按下 `x` 键）可结束 QEMU，这个组合键显然会跟第一次退出 VIM 一样，让人手忙脚乱一阵子。

通过 GDB 调试可知，QEMU RISC-V virt 会假设内核程序的开始位置在内存的 `0x8000_0000`，而我们的程序被加载到 `0x0001_00b0`，因此我们的程序根本没有被执行。

这里的 `0x8000_0000` 是一个映射地址，并不是说我们的虚拟机有很大的内存（实际上默认只有 128MB），这个地址被映射到内存 RAM 的开始位置，我们可以从 [QEMU 的源代码](https://github.com/qemu/qemu/blob/master/hw/riscv/virt.c) 找到映射关系：

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

> 有关 qemu-system-riscv64 的使用及程序调试方法，请参阅本项目的另一篇文章 [QEMU RISC-V 的使用及调试](../qemu-risc-v/README.zh-Hans.md)

那么我们怎样才能把程序加载到指定的位置呢？除了更改 `qemu-system-riscv64` 程序本身，还有更简单的方法，就是使用自己的链接脚本，让链接器指定程序的加载到内存后的位置。

目录 [resources](./resources/) 里有一个链接器脚本文件 `a.lds`，其内容如下：

```lds
OUTPUT_ARCH(riscv)
ENTRY(_start)
BASE_ADDRESS = 0x80000000;

SECTIONS
{
  . = BASE_ADDRESS;

  .text : {
    *(.text.entry)
    *(.text .text.*)
  }

  .rodata : {
    *(.rodata .rodata.*)
  }

  .data : {
    . = ALIGN(4096);
    *(.sdata .sdata.*)
    *(.data .data.*)
  }

  .bss :{
    *(.sbss .sbss.*)
    *(.bss .bss.*)
  }
}
```

然后我们在链接时指定链接脚本：

`$ riscv64-elf-ld a.o -T a.lds -o a.qemu.out`

其中参数 `-T a.lds` 用于指定链接脚本，命令执行之后将会得到文件 `a.qemu.out`，使用命令 `$ riscv64-elf-objdump -h a.qemu.out` 查看段信息，输出内容如下：

```text
Idx Name          Size      VMA               LMA               File off  Algn
  0 .text         0000001c  0000000080000000  0000000080000000  00001000  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, CODE
  1 .data         00000fe4  000000008000001c  000000008000001c  0000101c  2**0
                  CONTENTS, ALLOC, LOAD, DATA
```

可见代码段 `.text` 的加载地址已经变为 `0x8000_0000`，另外数据段 `.data` 也有 0xfe4（即 4068）字节，这是因为我们的链接脚本当中 `ALIGN(4096)` 迫使 `.data` 段进行 4kB 对齐，其实里面并没有内容，使用命令 `$ riscv64-elf-objdump -s -j .data a.qemu.out` 可以查看 `.data` 段的内容，输出的结果如下：

```text
Contents of section .data:
 8000001c 00000000 00000000 00000000 00000000  ................
 8000002c 00000000 00000000 00000000 00000000  ................
 ...
 80000fec 00000000 00000000 00000000 00000000  ................
 80000ffc 00000000                             ....
```

可见内容全是数字 0。

> 使用 `riscv64-elf-objdump` 查看 `.bss` 段的内容将看不到任何数据，因为 `.bss` 是由程序加载器在内存里分配空间，并填充数字 0，因此在 ELF 文件里没必要存放一堆数字 0。

我们再看看 program header：

```text
$ riscv64-elf-readelf -l a.qemu.out

Elf file type is EXEC (Executable file)
Entry point 0x80000000
There are 2 program headers, starting at offset 64

Program Headers:
  Type           Offset             VirtAddr           PhysAddr
                 FileSiz            MemSiz              Flags  Align
  RISCV_ATTRIBUT 0x0000000000002000 0x0000000000000000 0x0000000000000000
                 0x0000000000000043 0x0000000000000000  R      0x1
  LOAD           0x0000000000001000 0x0000000080000000 0x0000000080000000
                 0x0000000000001000 0x0000000000001000  RWE    0x1000

 Section to Segment mapping:
  Segment Sections...
   00     .riscv.attributes
   01     .text .data
```

可见它把 `.text` 和 `.data` 一次加载到内存里，而且内存的位置也是 `0x8000_0000`，加载的大小为 `0x1000` 字节，刚好是 `.text` 和 `.data` 的大小之和。

下面让我们执行新生成的可执行文件 `a.qemu.out`：

```bash
$ qemu-system-riscv64 \
    -machine virt \
    -nographic \
    -bios none \
    -kernel a.qemu.out
```

如无意外，应该可以看到在终端输出大写字母 “A”。再友情提示一下，按 `Ctrl+x, a` 终止 QEMU。

### 链接多个目标文件

下面我们查看链接器是如何链接多个目标文件的。

在目录 [resource](./resources/) 里有 3 个汇编源代码文件 `app.S`, `libm.S` 以及 `libn.S`。

- `libn.S` 提供函数 `print_n`；
- `libm.S` 提供函数 `print_m` 和函数 `print_mn`，后者的功能为依次调用 `print_m` 和 `print_n`；
- `app.S` 在入口 `_start` 里依次调用了 `print_m`、`print_n` 和 `print_mn`。

它们的依赖关系如下：

```text
        |------------|
app.S --|            |-- libn.S
        |-- libm.S --|
```

下面先汇编这 3 个源文件：

```bash
$ riscv64-elf-as app.S -o app.o
$ riscv64-elf-as libm.S -o libm.o
$ riscv64-elf-as libn.S -o libn.o
```

汇编之后得 3 个目标文件 `app.o`, `libm.o` 和 `libn.o`。

如果一个软件项目（比如用 C 语言编写的软件项目）包含多个源文件，即使各个文件存在依赖关系，但在编译时却是分开单独编译的，而且编译的次序也不重要，甚至可以同时并行编译，下面我们分析这是如何做到的。首先查看各个目标文件的符号表：

```text
$ riscv64-elf-nm libn.o
0000000000000000 T print_n

$ riscv64-elf-nm libm.o
0000000000000024 T print_m
0000000000000000 T print_mn
                 U print_n

$ riscv64-elf-nm app.o
0000000000000038 t _loop
                 U print_m
                 U print_mn
                 U print_n
0000000000000000 t print_new_line
                 U stack_top
0000000000000000 T _start
```

可见对于外部的符号，全部被标记为 `U`，也就是未定义的意思。进一步查看 `app.o` 的函数调用指令：

`$ riscv64-elf-objdump -d app.o`

输出的结果（部分）如下：

```text
0000000000000000 <_start>:
   0:   00000117                auipc   sp,0x0
   4:   00010113                mv      sp,sp
   8:   00000097                auipc   ra,0x0
   c:   000080e7                jalr    ra # 8 <_start+0x8>
  10:   00000097                auipc   ra,0x0
  14:   000080e7                jalr    ra # 10 <_start+0x10>
  18:   00000097                auipc   ra,0x0
  1c:   000080e7                jalr    ra # 18 <_start+0x18>
  20:   00000097                auipc   ra,0x0
  24:   000080e7                jalr    ra # 20 <_start+0x20>
  28:   00000097                auipc   ra,0x0
  2c:   000080e7                jalr    ra # 28 <_start+0x28>
  30:   00000097                auipc   ra,0x0
  34:   000080e7                jalr    ra # 30 <_start+0x30>
```

正如前面章节分析的那样，对于尚未链接的目标文件，函数调用的目标地址都用数字 `0` 占位，仅当链接之后才会被实际的函数地址替换。

接下来看看链接器之后的符号列表：

```text
$ riscv64-elf-ld -T app.lds libm.o libn.o app.o -o app.out
$ riscv64-elf-nm app.out
0000000080000000 A BASE_ADDRESS
0000000080000020 t _loop
0000000080000044 T print_m
0000000080000028 T print_mn
0000000080000054 T print_n
0000000080000064 t print_new_line
0000000080001000 D stack_bottom
0000000080002000 D stack_top
0000000080000000 T _start
```

链接器根据符号的名称，把未定义的符号全都解决了，我们可以通过反汇编来查看是否所有 _外部_ 函数的地址都正确地重新定位：

```text
$ riscv64-elf-objdump -d app.out

app.out:     file format elf64-littleriscv
Disassembly of section .text:

0000000080000000 <_start>:
    80000000:   00002117                auipc   sp,0x2
    80000004:   00010113                mv      sp,sp
    80000008:   03c000ef                jal     ra,80000044 <print_m>
    8000000c:   058000ef                jal     ra,80000064 <print_new_line>
    80000010:   044000ef                jal     ra,80000054 <print_n>
    80000014:   050000ef                jal     ra,80000064 <print_new_line>
    80000018:   010000ef                jal     ra,80000028 <print_mn>
    8000001c:   048000ef                jal     ra,80000064 <print_new_line>

0000000080000020 <_loop>:
    80000020:   00000013                nop
    80000024:   ffdff06f                j       80000020 <_loop>

0000000080000028 <print_mn>:
    80000028:   ff810113                addi    sp,sp,-8 # 80001ff8 <stack_bottom+0xff8>
    8000002c:   00113023                sd      ra,0(sp)
    80000030:   014000ef                jal     ra,80000044 <print_m>
    80000034:   020000ef                jal     ra,80000054 <print_n>
    80000038:   00013083                ld      ra,0(sp)
    8000003c:   00810113                addi    sp,sp,8
    80000040:   00008067                ret

0000000080000044 <print_m>:
    80000044:   100004b7                lui     s1,0x10000
    80000048:   06d00913                li      s2,109
    8000004c:   01248023                sb      s2,0(s1) # 10000000 <_start-0x70000000>
    80000050:   00008067                ret

0000000080000054 <print_n>:
    80000054:   100004b7                lui     s1,0x10000
    80000058:   06e00913                li      s2,110
    8000005c:   01248023                sb      s2,0(s1) # 10000000 <_start-0x70000000>
    80000060:   00008067                ret

0000000080000064 <print_new_line>:
    80000064:   100004b7                lui     s1,0x10000
    80000068:   00a00913                li      s2,10
    8000006c:   01248023                sb      s2,0(s1) # 10000000 <_start-0x70000000>
    80000070:   00008067                ret
```

检查 `jal ra, ...` 指令，可见全部函数的地址都是正确的。

有一点需要说明的，就是在链接时 `$ riscv64-elf-ld -T app.lds libm.o libn.o app.o -o app.out` 我们把 `app.o` 放在 3 个源目标文件的最后，而 `app.o` 里的函数 `print_new_line` 也确实被链接到可执行文件的末尾，那么为什么函数 `_start` 和 `_loop` 却在文件的开头呢？

这是因为 `app.S` 里有如下的语句指定了这两个函数的段名：

```S
.section .text.entry
_start:
    ...
_loop:
    ...
```

然后在链接脚本 `app.lds` 里有如下一段：

```lds
  .text : {
    *(.text.entry)
    *(.text .text.*)
  }
```

可见在链接脚本里指定了生成 `.text` 段的方法是：先链接各个源目标文件里的 `.text.entry` 段（假如存在的话），再链接剩余的段（即 `.text.*`）。在 3 个源目标文件里，只有 `app.S` 里存在 `.text.entry` 段，所以就先被链接了。

最后我们运行这个可执行文件：

```bash
$ qemu-system-riscv64 \
    -machine virt \
    -nographic \
    -bios none \
    -kernel app.out
```

如无意外，应该会输出：

```text
m
n
mn
```

另外，在源代码文件 `libm.S` 里，函数 `print_mn` 里有如下的结构：

```S
print_mn:
    # prologue
    addi    sp, sp, -8
    sd      ra, 0(sp)

    # ...

    # epilogue
    ld      ra, 0(sp)
    addi    sp, sp, 8
    ret
```

它们的作用是保存和恢复寄存器 `ra` 的值，这是大部分函数的样板代码（也就是说大部分函数都有类似的开头和结尾），至于为什么需要这样做，可以参阅本项目的另一篇文章 [函数的调用与链接](../calling-conventions/README.zh-Hans.md)。
