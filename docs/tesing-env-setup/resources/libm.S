.section .text

.globl print_mn
.globl print_m

print_mn:
    # prologue
    addi    sp, sp, -8
    sd      ra, 0(sp)

    # call other functions
    call print_m
    call print_n

    # epilogue
    ld      ra, 0(sp)
    addi    sp, sp, 8
    ret

print_m:
    li s1, 0x10000000
    li s2, 0x6d         # 'm'
    sb s2, 0(s1)
    ret
