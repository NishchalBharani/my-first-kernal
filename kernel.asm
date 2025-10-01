; kernel.asm - Simple 16-bit kernel stub (VGA print + halt)
; Loaded at 0x7E00, prints on row 1

BITS 16                    ; 16-bit real mode
ORG 0                      ; Code starts at offset 0 (physical 0x7E00 from boot)

kernel_start:
    ; Set DS = CS for data access (string in code segment)
    mov ax, cs               ; AX = current code segment (0x07E0)
    mov ds, ax               ; DS = 0x07E0 (now [bx] points correctly)

    ; Set ES for VGA segment (0xB800 << 4 = 0xB8000 physical)
    mov ax, 0xB800           ; Segment for VGA text buffer
    mov es, ax               ; ES = 0xB800

    ; Set up VGA write: Row 1 (offset 160 bytes = 80 chars * 2 bytes/char)
    mov di, 160              ; DI = index in buffer (row 1 col 0)
    mov bx, msg              ; BX = string pointer (now correct via DS)
    mov ah, 0x07             ; AH = attr (white on black)

print_loop:
    mov al, [bx]             ; AL = next char (from correct memory!)
    cmp al, 0                ; Null?
    je done_print            ; Yes → done
    mov [es:di], ax          ; Write AX as word: attr high + char low (VGA format!)
    inc bx                   ; Next char
    add di, 2                ; Next buffer slot (char + attr = 2 bytes)
    jmp print_loop

done_print:
    hlt_loop:
    hlt                      ; Halt
    jmp hlt_loop             ; Loop forever

msg db 'Hello Nishchal from C Kernel!', 0  ; Null-terminated (reuse your string)

; Pad to 512 bytes (dd will handle, but explicit for clarity)
times 512-($-$$) db 0