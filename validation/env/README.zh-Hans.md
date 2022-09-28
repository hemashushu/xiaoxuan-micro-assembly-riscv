# 配置验证的环境

安装 [QEMU](https://www.qemu.org/) 和 [RISC-V toolchains](https://github.com/riscv-collab/riscv-gnu-toolchain)

## 测试环境

### 构建目标文件

当前目录里已存在一个简单的汇编文件 `a.s`，内容如下：

```s
.globl _start
.globl _somefunc

_start:
    li s1, 0x10000000   # set s1 = 0x1000_0000
    li s2, 0x41         # set s2 = 0x41
    sb s2, 0(s1)        # store s2 (as byte) to memory[s1+0]

_somefunc:
    nop                 # do nothing
```

使用 GCC 汇编器 `riscv64-elf-as`（注意名称也可能是 `riscv64-unknown-elf-as`）生成目标文件：

`$ riscv64-elf-as -g -o a.o a.s`

- 参数 `-g` 表示同时生成调试信息。
- 参数 `-o a.o` 用于指定输出文件的名称。
- 参数 `a.s` 表示源文件的名称路径。

然后将会得到文件 `a.o`，接下来我们查看它的内容。

### 查看导出的符号列表

`符号` 是一个固定的名词，可以理解为各个函数或者全局变量等的名称。

`$ riscv64-elf-nm a.o`

输出的内容如下：

```text
000000000000000c T _haha
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
0000000000000000 <_start>:
   0:   100004b7                lui     s1,0x10000
   4:   04100913                li      s2,65
   8:   01248023                sb      s2,0(s1) # 10000000 <_haha+0xffffff4>

000000000000000c <_haha>:
   c:   00000013                nop
```

注意参数 `-d` 仅反汇编 `.text` 段，如果你想查看所有段的内容，可以使用 `-D` 参数代替 `-d`，不过一般我们不用关心其它段的内容（数据段除外）。

### 链接

TODO::
