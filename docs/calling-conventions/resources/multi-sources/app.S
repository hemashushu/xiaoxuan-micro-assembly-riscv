.equ VIRT_UART0, 0x10000000

.section .text

print_new_line:
    li s1, VIRT_UART0   # set s1 = 0x1000_0000
    li s2, 0xa          # '\n'
    sb s2, 0(s1)
    ret

.section .text.entry

.globl _start

_start:
    la sp, stack_top
    call print_m
    call print_new_line
    call print_n
    call print_new_line
    call print_mn
    call print_new_line
_loop:
    nop
    j _loop
