# 配置验证的环境

<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [配置验证的环境](#配置验证的环境)
  - [配置环境](#配置环境)
  - [测试汇编](#测试汇编)
    - [构建目标文件](#构建目标文件)
    - [查看导出的符号列表](#查看导出的符号列表)
    - [查看文件的段信息](#查看文件的段信息)
    - [反汇编](#反汇编)
  - [测试链接](#测试链接)
    - [链接单个目标文件](#链接单个目标文件)

<!-- /code_chunk_output -->

## 配置环境

安装 [QEMU](https://www.qemu.org/) 和 [RISC-V toolchains](https://github.com/riscv-collab/riscv-gnu-toolchain)

## 测试汇编

### 构建目标文件

目录 `resources` 里有一个简单的汇编文件 `a.s`，内容如下：

```s
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

使用 RISC-V GCC 汇编器 `riscv64-elf-as`（注意名称也可能是 `riscv64-unknown-elf-as`）生成目标文件：

`$ riscv64-elf-as a.s -g -o a.o`

- 参数 `a.s` 表示源文件的名称路径。
- 参数 `-g` 表示同时生成调试信息。
- 参数 `-o a.o` 用于指定输出文件的名称。

然后将会得到文件 `a.o`，我们先查看它的文件类型：

`$ file a.o`

输出内容如下：

```text
a.o: ELF 64-bit LSB relocatable, UCB RISC-V, double-float ABI, version 1 (SYSV), with debug_info, not stripped
```

可见汇编器输出的是一个 ELF 格式的文件，同时可以大致推断出 RISC-V GCC 默认的编译架构（即参数 `-march`）是 `rv64imafd`，ABI （即编译参数 `-mabi`）是 `lp64d`。

有关目标架构和 ABI 详细请参阅 [平台架构和 ABI](../platform/README.zh-Hans.md)。

### 查看导出的符号列表

`符号` 是一个固定的名词，可以理解为各个函数或者全局变量等的名称。

`$ riscv64-elf-nm a.o`

输出的内容如下：

```text
0000000000000008 t _loop
0000000000000010 T _print_a
0000000000000000 T _start
```

左边一列是各个符号的虚拟地址，右边一列是符号的名称，中间一列是符号类型的代号，部分符号类型代号的含义如下：

- A: Global absolute symbol.
- a: Local absolute symbol.
- B: Global bss symbol.
- b: Local bss symbol.
- D: Global data symbol.
- d: Local data symbol.
- T: Global text symbol.
- t: Local text symbol.
- U: Undefined symbol.

符号类型代号当中大写的表示是导出的（外部的），小写的表示局部的，类型 `U` 比较特殊，表示未定义的符号。详细的列表可参阅 [GNU Binary Utilities Document](https://sourceware.org/binutils/docs/binutils/index.html) 当中的 [nm](https://sourceware.org/binutils/docs/binutils/nm.html) 一章。

### 查看文件的段信息

文件 `a` 是一个 ELF 格式的文件，文件的内容被划分为多个段。

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

完整的 ELF 文件的结构可以参阅 [ELF](https://wiki.osdev.org/ELF) 、[ELF wiki](https://en.wikipedia.org/wiki/Executable_and_Linkable_Format) 以及 。

注意如果使用 `-x` 参数将会看到所有的段，包括调试信息的段，不过一般我们不需要关心这些段的内容。

### 查看各段的大小

使用 `riscv64-elf-size` 可以查看各个段的大小：

`$ riscv64-elf-size a.o`

输出的结果如下：

```text
   text    data     bss     dec     hex filename
     32       0       0      32      20 a.o
```

### 反汇编

反汇编目标文件将会得到汇编文本，同时还能得到指令的机器码（二进制）以及各个指令的地址，另外对于由多个指令组成的 `伪指令`，通过反汇编也能得到真实的指令。

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

注意参数 `-d` 仅反汇编 `.text` 段，如果你想查看所有段的内容，可以使用 `-D` 参数代替 `-d`，不过一般我们不用关心其它段的内容（数据段除外）。

下面分析其中的第 2 个指令 `0000_80e7`：

```text
000000000000  00001 000 00001 1100111
____________  _____     _____ _______
|offset[11:0] rs=1      rd=1  jalr
```

解码得出：`jalr ra, 0(ra)`，结合上一条指令 `auipc ra,0x0` 来看，这两条指令并不能实现跳转到 `_print_a` 函数，所以这里仅是一个占位符，等到链接的时候才会被替换为目标函数的真实地址。

## 测试链接

本项目除了实现了一个汇编器，同时也实现了一个链接器，所以对于链接的结果也需要进行验证。

链接器主要实现两个目的：

1. 将多个（汇编器产生的）目标文件合并成为一个文件。因为目标文件里存在多个 “段”，在合并时默认会将相同类型的段合并成一个段。

比如假设现有两个输出文件 `a.o` 和 `b.o`，在链接时，`a.o` 的 `.text` 段将会和 `b.o` 的 `.text` 段合并，`a.o` 的 `.data` 段和 `b.o` 的 `.data` 段合并，最后再将合并后的各个段连接起来。具体的合并方案是由一个链接器的脚本控制的，这个默认脚本可以通过命令 `$ riscv64-elf-ld --verbose` 查看，脚本的具体含义可以参考 [LD 的文档](https://sourceware.org/binutils/docs/ld/index.html) 当中的 [3 Linker Scripts](https://sourceware.org/binutils/docs/ld/Scripts.html) 一章。

另外源目标文件也可能是第三方提供的库，比如 C 的数学库 `/usr/lib/libm.so`，链接时又有静态链接和动态链接之分，这里不展开叙述。

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

发现除了多了 `statically linked` 其余都是一样的，然后再看看导出符号表：

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

发现多出了好几个符号，比如 `__SDATA_BEGIN` 表示静态数据段的开始，`__DATA_BEGIN` 表示数据段的开始，`__bss_start` 表示未初始化的数据（即值为 0 的全局变量或者尚未初始化的变量）的开始，另外一般程序还会有 `__rodata_start` 表示只读数据（即全局常量）的开始等等。

然后再看段信息：

`$ riscv64-elf-objdump -h a.out`

输出的内容如下：

```text
Idx Name          Size      VMA               LMA               File off  Algn
  0 .text         0000001c  00000000000100b0  00000000000100b0  000000b0  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, CODE
```

发现 `.data` 和 `.bss` 段不见了（因为它们原本就是无内容的，长度为 0，所以在最后输出文件里被去除了），然后 `.text` 的长度不变，而 `VMA` （虚拟内存地址）和 `LMA` （加载内存地址）的值都变为 `0x1_00b0`。

然后再次查看各个段的大小：

`$ riscv64-elf-size a.out`

输出的内容如下：

```text
   text    data     bss     dec     hex filename
     28       0       0      28      1c a.out
```

发现代码段居然减少了 4 个字节，我们反汇编便知道其中的原因：

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

发现除了指令的地址从 0x1_00b0 开始（原先从 0 开始），以及 `call _print_a` 语句由 2 个指令 `auipc` 和 `jalr` 转换为 1 个指令 `jal`，且目标地址被填上真实的地址，其余的内容则保持不变。

现在分析指令 `00c000ef`：

```text

0    0000000110 0    00000000 00001 1101111
---- ---------- ---- -------- ----- -------
[20] [10:1]     [11] [19:12]  rd=1  jal

```

解码得出：`jal ra, 0b1100`，其中 `0b1100` 是地址偏移值，我们来算算它表示的绝对地址：当前指令地址为 `0x1_00b0`，加上偏移值 `0b1100` 得出 `0x100bc`，这正好是函数 `_print_a` 的地址。



TODO::
$ riscv64-elf-ld a.o -T a.lds -o a.out

```bash
$ qemu-system-riscv64 \
    -machine virt \
    -nographic \
    -bios none \
    -kernel a.out
```