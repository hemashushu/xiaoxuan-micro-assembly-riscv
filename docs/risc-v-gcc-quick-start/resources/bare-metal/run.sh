#!/bin/bash
riscv64-elf-as -o app_startup.o app_startup.S
riscv64-elf-gcc -I . -Wall -fPIC -c -g -o app.o app.c
riscv64-elf-gcc -I . -Wall -fPIC -c -g -o liba.o liba.c
riscv64-elf-gcc -I . -Wall -fPIC -c -g -o libb.o libb.c
riscv64-elf-gcc -I . -Wall -fPIC -c -g -o libprint.o libprint.c
riscv64-elf-as -o put_char.o put_char.S

riscv64-elf-ar -crs libmath.a liba.o libb.o

riscv64-elf-ld -T app.lds -o app.out app_startup.o app.o libmath.a libprint.o put_char.o

qemu-system-riscv64 \
    -machine virt \
    -nographic \
    -bios none \
    -kernel app.out