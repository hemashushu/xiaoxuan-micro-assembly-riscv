# 配置验证的环境

<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [配置验证的环境](#配置验证的环境)
  - [配置环境](#配置环境)
  - [测试环境](#测试环境)
    - [构建目标文件](#构建目标文件)
    - [查看导出的符号列表](#查看导出的符号列表)
    - [查看文件的段信息](#查看文件的段信息)
    - [反汇编](#反汇编)
    - [链接](#链接)
  - [附录 A](#附录-a)
    - [指令集架构（ISA）](#指令集架构isa)
    - [应用程序二进制接口（ABI）](#应用程序二进制接口abi)

<!-- /code_chunk_output -->

## 配置环境

安装 [QEMU](https://www.qemu.org/) 和 [RISC-V toolchains](https://github.com/riscv-collab/riscv-gnu-toolchain)

## 测试环境

### 构建目标文件

目录 `resources` 里有一个简单的汇编文件 `a.s`，内容如下：

```s
.globl _start
.globl _somefunc

_start:
    li s1, 0x10000000   # set s1 = 0x1000_0000
    li s2, 0x41         # set s2 = 0x41
    sb s2, 0(s1)        # store s2 (as byte) to memory[s1+0]
                        # the 0x1000_0000 is mapped to UART0
                        # see QEMU source https://github.com/qemu/qemu/blob/master/hw/riscv/virt.c

_somefunc:
    nop                 # do nothing
```

使用 GCC 汇编器 `riscv64-elf-as`（注意名称也可能是 `riscv64-unknown-elf-as`）生成目标文件：

`$ riscv64-elf-as -g -o a.o a.s`

- 参数 `-g` 表示同时生成调试信息。
- 参数 `-o a.o` 用于指定输出文件的名称。
- 参数 `a.s` 表示源文件的名称路径。

然后将会得到文件 `a.o`，我们先查看它的文件类型：

`$ file a.o`

输出内容如下：

```text
a.o: ELF 64-bit LSB relocatable, UCB RISC-V, double-float ABI, version 1 (SYSV), with debug_info, not stripped
```

可见汇编器输出的是一个 ELF 格式的文件，同时可以大致推断出编译架构（即参数 `-march`）是 `rv64ifd`，ABI （即编译参数 `-mabi`）是 `lp64d`。

有关目标架构和 ABI 详细请参阅附录 A。

### 查看导出的符号列表

`符号` 是一个固定的名词，可以理解为各个函数或者全局变量等的名称。

`$ riscv64-elf-nm a.o`

输出的内容如下：

```text
000000000000000c T _somefunc
0000000000000000 T _start
```

左侧是各个符号的地址，右侧是符号的名称。

### 查看文件的段信息

文件 `a` 是一个 ELF 格式的文件，文件的内容被划分为多个段。

`$ riscv64-elf-objdump -h a.o`

输出的部分内容如下：

```text
Idx Name          Size      VMA               LMA               File off  Algn
  0 .text         00000010  0000000000000000  0000000000000000  00000040  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, CODE
  1 .data         00000000  0000000000000000  0000000000000000  00000050  2**0
                  CONTENTS, ALLOC, LOAD, DATA
  2 .bss          00000000  0000000000000000  0000000000000000  00000050  2**0
                  ALLOC
```

`.text`, `.data` 和 `.bss` 是段的名称，`VMA` 和 `LMA` 分别表示虚拟内存地址和加载地址，`ALLOC, LOAD, READONLY, CODE` 表示程序加载器应该如何处理该段的内容。具体的含义请查阅相关的资料。

注意如果使用 `-x` 参数将会看到所有的段，包括调试信息的段，不过一般我们不需要关心这些段的内容。

### 反汇编

反汇编目标文件将会得到汇编文本，同时还能得到指令的机器码（二进制）以及各个指令的地址，另外对于由多个指令组成的 `伪指令`，通过反汇编也能得到真实的指令。

`$ riscv64-elf-objdump -d a.o`

输出的结果如下：

```text
Disassembly of section .text:

0000000000000000 <_start>:
   0:   100004b7                lui     s1,0x10000
   4:   04100913                li      s2,65
   8:   01248023                sb      s2,0(s1) # 10000000 <_somefunc+0xffffff4>

000000000000000c <_somefunc>:
   c:   00000013                nop
```

注意参数 `-d` 仅反汇编 `.text` 段，如果你想查看所有段的内容，可以使用 `-D` 参数代替 `-d`，不过一般我们不用关心其它段的内容（数据段除外）。

### 链接

本项目除了实现了一个汇编器，同时也实现了一个链接器，所以对于链接的结果也需要进行验证。


TODO::

## 附录 A

### 指令集架构（ISA）

RISC-V 64 最小的指令集是 rv64i，其中 `i` 表示 integer，即目标平台/处理器只支持整数的加减以及逻辑运算。在此基础之上，还有其它几个扩展指令集：

- `m`：整数的乘除运算
- `a`：原子操作
- `f`：单精度浮点运算
- `d`：双精度浮点运算

在使用 GCC（RISC-V） 编译时，可以通过 `-march` 指定目标平台支持的指令集，比如对于 C 程序：

```c
int my_int_mul(int a, int b) {
    return a * b;
}
```

先尝试使用 `-march rv64imd -mabi=lp64d` 编译：

`$ riscv64-elf-gcc arch.c -march=rv64imd -mabi=lp64d -S -O3 -o /dev/stdout`

输出的内容如下（已去除不相关的内容）：

```s
my_int_mul:
        mulw    a0,a0,a1
        ret
```

由此乘法运算使用了目标平台支持的指令 `mulw` 实现，现在把编译平台参数改为 `-march=rv64id`（即去除了 `m` 字母）：

`$ riscv64-elf-gcc arch.c -march=rv64id -mabi=lp64d -S -O3 -o /dev/stdout`

得输出的函数 `my_int_mul` 指令如下：

```s
my_int_mul:
        addi    sp,sp,-16
        sd      ra,8(sp)
        call    __muldi3
        ld      ra,8(sp)
        sext.w  a0,a0
        addi    sp,sp,16
        jr      ra
```

可见指令 `mulw` 被替换为函数调用 `call __muldi3`，注意其中指令 `call` 是伪指令，对应的实际指令是 `jal ra, ADDR`。

我们可以通过链接然后再反汇编：

```bash
riscv64-elf-gcc arch.c -march=rv64id -mabi=lp64d -O3 -o arch.out
riscv64-elf-objdump -d arch.out
```

可以看到 `__muldi3` 的内容如下：

```s
0000000000010200 <__muldi3>:
   10200:       862a                    mv      a2,a0
   10202:       4501                    li      a0,0
   10204:       0015f693                andi    a3,a1,1
   10208:       c291                    beqz    a3,1020c <__muldi3+0xc>
   1020a:       9532                    add     a0,a0,a2
   1020c:       8185                    srli    a1,a1,0x1
   1020e:       0606                    slli    a2,a2,0x1
   10210:       f9f5                    bnez    a1,10204 <__muldi3+0x4>
   10212:       8082                    ret
```

由此可见，当目标平台不支持乘法运算时，编译器会使用一个实现了乘法的函数代替 `mulw` 指令。注意 `ret` 也是一个伪指令，对应的实际指令是 `jalr zero,0(ra)`，如果希望反汇编时不要显示伪指令，可以添加 `-M no-aliases` 参数，比如：

`$ riscv64-elf-objdump -M no-aliases -d arch.out`

### 应用程序二进制接口（ABI）

“应用程序二进制接口” 可以粗略地理解为在汇编语言层面的 ”应用程序接口（API）”，GCC（RISC-V）支持 `ilp32`, `ilp32f`, `ilp32d`, `lp64`, `lp64f` 和 `lp64d` 几种规范。

`ilp32` 表示 `integer` 和 `long` 和 `pointer` 都是 32 bit，且不支持 `float` 或者 `double float` 作为参数传递给寄存器。我们很容易推断 `lp64d` 表示 `long` 和 `pointer` 是 64 bit，且支持 `double float` 作为参数传递给寄存器，至于那个没有提及的 `i` 则保留 32 bit。



 Ref:
 RISC-V Calling Conventions
 https://github.com/riscv-non-isa/riscv-elf-psabi-doc/blob/master/riscv-cc.adoc