.section .text.init
.global _start

_start:
  la sp, _stack_top
  andi sp, sp, -16
  call main
.Lhang:
  j .Lhang
