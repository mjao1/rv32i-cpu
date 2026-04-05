/* RV32I bare-metal: code at 0x0 (instruction memory), RAM at 0x80000000 (data memory) */

ENTRY(_start)

MEMORY {
  rom (rx) : ORIGIN = 0x00000000, LENGTH = 16K
  ram (rw) : ORIGIN = 0x80000000, LENGTH = 4K
}

SECTIONS {
  .text : {
    KEEP(*(.text.init))
    *(.text .text.*)
  } > rom

  .data : {
    *(.data .data.*)
  } > ram

  .bss : {
    *(.bss .bss.*)
    *(COMMON)
  } > ram

  _stack_top = ORIGIN(ram) + LENGTH(ram);
}
