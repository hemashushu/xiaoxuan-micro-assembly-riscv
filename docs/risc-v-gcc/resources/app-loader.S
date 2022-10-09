.section .text.entry
.globl _start

_start:
    la sp, stack_top
    call mymain

_loop:
    nop
    j _loop
