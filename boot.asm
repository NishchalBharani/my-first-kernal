; boot.asm - Simple bootloader for x86
; Assembles to flat binary with NASM

BITS 16          ; We're in 16-bit real mode (old BIOS style)
ORG 0x7C00       ; BIOS loads us at 0x7C00 in memory

start:
    cli          ; Disable interrupts (no distractions)
    mov ax, 0x0003 ; Set text mode 80x25
    int 0x10     ; BIOS video interrupt

    ; Print message
    mov si, msg  ; SI = pointer to string
print_loop:
    lodsb        ; Load byte from [SI] into AL, increment SI
    cmp al, 0    ; End of string?
    je done_print
    mov ah, 0x0E ; Teletype function
    mov bx, 0x07 ; Page 0, white on black
    int 0x10     ; Print char
    jmp print_loop
done_print:

    hlt          ; Halt CPU (wait forever)

msg db 'Booting Nishchal Kernel!', 0 ; Null-terminated string

times 510-($-$$) db 0  ; Pad to 510 bytes
dw 0xAA55              ; Boot signature (magic number for BIOS)