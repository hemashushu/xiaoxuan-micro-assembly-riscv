.section .text

.globl print_n

print_n:
    li s1, 0x10000000
    li s2, 0x6e         # 'n'
    sb s2, 0(s1)
    ret
