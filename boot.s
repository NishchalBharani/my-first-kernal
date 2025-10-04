; boot.s - Multiboot header + tiny entry
; Assemble: nasm -f elf32 boot.s -o boot.o

BITS 32

section .multiboot
    align 4
    dd 0x1BADB002              ; multiboot magic
    dd 0x00000000              ; flags = 0
    dd -(0x1BADB002 + 0x00000000) ; checksum

section .text
    global _start
    extern kernel_main

_start:
    cli
    mov  esp, 0x00200000       ; safe stack at 2 MiB
    call kernel_main
.hang:
    hlt
    jmp .hang
