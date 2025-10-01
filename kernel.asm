; kernel.asm - 16-bit kernel shell (loop echo keys until 'q')
; Loaded at 0x7E00, prints "Hello...", sets cursor row 2 col 0, loops key echo

BITS 16                    ; 16-bit real mode
ORG 0                      ; Code starts at offset 0 (physical 0x7E00 from boot)

kernel_start:
    ; Set DS = CS for data access (string in code segment)
    mov ax, cs               ; AX = current code segment (0x07E0)
    mov ds, ax               ; DS = 0x07E0

    ; Set ES for VGA segment (0xB800 << 4 = 0xB8000 physical)
    mov ax, 0xB800           ; Segment for VGA text buffer
    mov es, ax               ; ES = 0xB800

    ; Print "Hello..." on row 1
    mov di, 160              ; DI = row 1 start
    mov bx, hello_msg        ; BX = string ptr
    mov ah, 0x07             ; AH = attr
print_hello:
    mov al, [bx]
    cmp al, 0
    je set_cursor            ; Done print → set cursor
    mov [es:di], ax
    inc bx
    add di, 2
    jmp print_hello

set_cursor:
    ; Set cursor to row 2 col 0 (BIOS int 0x10 ah=0x02)
    mov ah, 0x02             ; Set cursor function
    mov bh, 0                ; Page 0
    mov dh, 2                ; Row 2
    mov dl, 0                ; Col 0
    int 0x10                 ; Update cursor

shell_loop:
    ; Get cursor pos to check room (BIOS int 0x10 ah=0x03)
    mov ah, 0x03             ; Get cursor
    mov bh, 0                ; Page 0
    int 0x10                 ; DX = row:col
    cmp dh, 23               ; Row <24?
    jge halt_loop            ; No → halt

    ; Wait for key
    mov ah, 0x00
    int 0x16                 ; AL=char
    cmp al, 'q'              ; Quit?
    je halt_loop             ; Yes → halt

    ; Echo char at cursor (int 0x10 ah=0x0E teletype)
    mov ah, 0x0E             ; Teletype
    mov bx, 0x07             ; Page/attr
    int 0x10                 ; Prints AL, advances cursor

    jmp shell_loop           ; Next

halt_loop:
    hlt
    jmp halt_loop

hello_msg db 'Hello Nishchal from Kernel! Type keys (q=quit):', 0

; Pad to 512 bytes
times 512-($-$$) db 0