.equ VIRT_UART0, 0x10000000

.section .text

.globl print_n

print_n:
    li s1, VIRT_UART0   # set s1 = 0x1000_0000
    li s2, 0x6e         # 'n'
    sb s2, 0(s1)
    ret
