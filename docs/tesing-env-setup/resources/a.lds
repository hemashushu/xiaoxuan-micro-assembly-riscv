OUTPUT_ARCH(riscv)
ENTRY(_start)
BASE_ADDRESS = 0x80000000;

SECTIONS
{
  . = BASE_ADDRESS;

  .text : {
    *(.text.entry)
    *(.text .text.*)
  }

  .rodata : {
    *(.rodata .rodata.*)
  }

  .data : {
    . = ALIGN(4096);
    *(.sdata .sdata.*)
    *(.data .data.*)
  }

  .bss :{
    *(.sbss .sbss.*)
    *(.bss .bss.*)
  }
}
