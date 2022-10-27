#!/bin/bash

# build

riscv64-elf-as -g -o app.o app.S
riscv64-elf-ld -T app.lds -o app.out app.o
riscv64-elf-objcopy -S -O binary app.out app.bin

# run by using ELF

qemu-system-riscv64 \
    -machine virt \
    -nographic \
    -bios none \
    -kernel app.out

# qemu-system-riscv64 \
#     -machine virt \
#     -nographic \
#     -bios app.out
#
# qemu-system-riscv64 \
#     -machine virt \
#     -nographic \
#     -bios none \
#     -device loader,file=app.out


# run by using BIN
#
# qemu-system-riscv64 \
#     -machine virt \
#     -nographic \
#     -bios none \
#     -kernel app.bin
#
# qemu-system-riscv64 \
#     -machine virt \
#     -nographic \
#     -bios app.bin
#
# qemu-system-riscv64 \
#     -machine virt \
#     -nographic \
#     -bios none \
#     -device loader,file=app.bin,addr=0x80000000