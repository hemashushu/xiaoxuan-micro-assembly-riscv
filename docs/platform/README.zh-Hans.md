
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