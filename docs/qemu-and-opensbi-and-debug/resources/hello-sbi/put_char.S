.equ VIRT_UART0, 0x10000000

.section .text.put_char

.globl put_char

put_char:
    li s1, VIRT_UART0
    mv s2, a0
    sb s2, 0(s1)
    ret
