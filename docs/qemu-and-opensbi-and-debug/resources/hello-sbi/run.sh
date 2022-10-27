#!/bin/bash
riscv64-elf-as -o app_startup.o app_startup.S
riscv64-elf-gcc -I . -Wall -fPIC -c -g -o app.o app.c
riscv64-elf-as -o sbi-base.o sbi-base.S
riscv64-elf-gcc -I . -Wall -fPIC -c -g -o libprint.o libprint.c
riscv64-elf-as -o put_char.o put_char.S

riscv64-elf-ld -T app.lds -o app.out app_startup.o app.o sbi-base.o libprint.o put_char.o

qemu-system-riscv64 \
    -machine virt \
    -nographic \
    -bios default \
    -kernel app.out