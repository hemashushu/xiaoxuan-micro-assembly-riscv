# QEMU

## QEMU 启动流程

virt 物理内存的起始地址为 0x80000000 ，物理内存的默认大小为 128MiB（可以通过 -m 选项进行配置）

QEMU 启动流程有 2 个阶段

1. 固化在 QEMU 内的一段程序

地址 0x1000，TODO

2. bootloader

地址 0x80000000，TODO & 加载内核

## 关于 `-bios` 参数

1. 当启动 QEMU 省略 `-bios` 参数时，或者 `-bios default`
   QEMU 会使用内置的 OpenSBI，然后内核程序使用 `-kernel` 指定。

2. `-bios none`
   有用户自己指定加载任意程序

3. `-bios path/to/bootloader`
   指定自己的 bootloader 程序

详细 https://www.qemu.org/docs/master/system/target-riscv.html#risc-v-cpu-firmware

## virt 平台

- Up to 8 generic RV32GC/RV64GC cores, with optional extensions
- CFI parallel NOR flash memory
- 1 NS16550 compatible UART

```
[VIRT_MROM] =         {     0x1000,        0xf000 },
[VIRT_UART0] =        { 0x10000000,         0x100 },
[VIRT_FLASH] =        { 0x20000000,     0x4000000 },
[VIRT_DRAM] =         { 0x80000000,           0x0 },
```

https://github.com/qemu/qemu/blob/master/hw/riscv/virt.c

跟配置有关的启动参数：

- The number of subnodes of the /cpus node should match QEMU’s -smp option
- The /memory reg size should match QEMU’s selected ram_size via -m

详细 https://www.qemu.org/docs/master/system/riscv/virt.html

测试 UART

```c
#define VIRT_UART0 0x10000000

volatile unsigned int *const UART_PTR = (unsigned int *)VIRT_UART0;

void print(const char *str)
{
    while (*str != '\0')
    {
        *UART_PTR = (unsigned int)(*str);
        str++;
    }
}

void main()
{
    print("Hello, World!\n");
}
```

编译、链接、执行：

```bash
$ riscv64-elf-as hello-uart-loader.S -o hello-uart-loader.o
$ riscv64-elf-gcc -c -fPIC hello-uart-app.c -o hello-uart-app.o
$ riscv64-elf-ld -T hello-uart.lds hello-uart-loader.o hello-uart-app.o -o hello-uart.out
$ qemu-system-riscv64 \
    -machine virt \
    -nographic \
    -bios none \
    -kernel hello-uart.out
```

注意编译 `hello-uart-app.c` 时需要加上参数 `-c` 和 `-fPIC`，前者用于指定仅编译而不链接，后者指定生成位置无关代码（PIC，因为有待后续的链接）。

运行后应该能看到 "Hello, World!" 输出，按 `Ctrl+a, x` 退出 QEMU。

## TODO

QEMU 可以直接加载 ELF 文件，如果要在程序里（比如我们自己写的 bootload 程序）手动加载另一个 ELF 文件，可以把目标 ELF 的元数据都丢弃（即只保留 `.text`, `.rodata`, `.data`, `.bss` 等必须段）：

```bash
$ riscv64-elf-objcopy --strip-all a.out -O binary a.bin
$ qemu-system-riscv64 \
      -machine virt \
      -nographic \
      -bios my-bootloader.bin \
      -device loader,file=a.bin,addr=0x80200000
```

## 调试

TODO::