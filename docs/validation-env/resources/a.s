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
