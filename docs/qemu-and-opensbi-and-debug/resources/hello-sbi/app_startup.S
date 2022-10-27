.section .text.entry
.globl _start

_start:
    la sp, stack_top
    call bare_main

_loop:
    nop
    j _loop
