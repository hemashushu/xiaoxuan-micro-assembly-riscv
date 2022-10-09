#!/bin/bash
riscv64-elf-as -o app-loader.o app-loader.S
riscv64-elf-as -o put_char.o put_char.S
riscv64-elf-gcc -I . -Wall -fPIC -c -o libprint.o libprint.c
riscv64-elf-gcc -I . -Wall -fPIC -c -o liba.o liba.c
riscv64-elf-gcc -I . -Wall -fPIC -c -o libb.o libb.c
riscv64-elf-gcc -I . -Wall -fPIC -c -o app.o app.c
riscv64-elf-ld -T app.lds -o app.out app-loader.o app.o liba.o libb.o libprint.o put_char.o
qemu-system-riscv64 \
    -machine virt \
    -nographic \
    -bios none \
    -kernel app.out