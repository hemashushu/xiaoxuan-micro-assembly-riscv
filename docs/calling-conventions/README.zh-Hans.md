
```S
my_function:
    # Prologue
    addi    sp, sp, -32
    sd      ra, 0(sp)
    sd      a0, 8(sp)
    sd      s0, 16(sp)
    sd      s1, 24(sp)

    # Epilogue
    ld      ra, 0(sp)
    ld      a0, 8(sp)
    ld      s0, 16(sp)
    ld      s1, 24(sp)
    addi    sp, sp, 32
    ret
```

```S
.section .rodata
prompt: .asciz "Value of t0 = %ld and value of t1 = %ld\n"
.section .text
myfunc:
    # prologue
    addi    sp, sp, -8
    sd      ra, 0(sp)

    # Calling external function
    la      a0, prompt
    mv      a1, t0
    mv      a2, t1
    call    printf

    # epilogue
    ld      ra, 0(sp)
    addi    sp, sp, 8
    ret
```

## 静态链接和动态链接


Ref:
https://en.wikipedia.org/wiki/Global_Offset_Table
https://refspecs.linuxfoundation.org/ELF/zSeries/lzsabi0_zSeries/x2251.html
https://lwn.net/Articles/631631/
https://www.technovelty.org/linux/plt-and-got-the-key-to-code-sharing-and-dynamic-libraries.html
https://www.caichinger.com/elf.html

TODO