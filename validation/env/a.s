.globl _start
.globl _somefunc

_start:
    li s1, 0x10000000   # set s1 = 0x1000_0000
    li s2, 0x41         # set s2 = 0x41
    sb s2, 0(s1)        # store s2 (as byte) to memory[s1+0]

_somefunc:
    nop                 # do nothing
