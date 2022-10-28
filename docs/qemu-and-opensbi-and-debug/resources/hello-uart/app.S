.equ VIRT_UART0, 0x10000000

.section .text.entry
.globl _start

_start:
    la      sp, stack_top
    call    uart_main

_loop:
    nop
    j       _loop

uart_main:
    # prologue
    addi    sp, sp, -8
    sd      ra, 0(sp)

    la      a0, hello
    call    put_string

    # epilogue
    ld      ra, 0(sp)
    addi    sp, sp, 8
    ret

put_string:
    # prologue
    addi    sp, sp, -8
    sd      ra, 0(sp)

    mv      t1, x0          # let t1 = 0  (i.e. index)
    mv      t2, a0          # let t2 = a0 (i.e. *buf)
1:
    add     t3, t1, t2      # let t3 = t1 + t2
    ld      a0, 0(t3)       # let a0 = memory[t3]
    beqz    a0, 2f          # if a0 == 0 then goto 2f
    call    put_char
    addi    t1,t1,1         # t1++
    j       1b              # goto 1b
2:
    # epilogue
    ld      ra, 0(sp)
    addi    sp, sp, 8
    ret

put_char:
    li      s1, VIRT_UART0
    mv      s2, a0
    sb      s2, 0(s1)
    ret

.section .rodata
hello:
#    .string "Hello UART!\n"        # prefer `.asciz` directive
#    .ascii "Hello UART!\n\0"       # no automatic trailing zero
    .asciz "Hello UART!\n"          # automatic trailing zero
