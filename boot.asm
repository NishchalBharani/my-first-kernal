; boot.asm - Bootloader that loads kernel from disk sector 2 and jumps to it

BITS 16
ORG 0x7C00

start:
    cli                    ; Disable interrupts
    mov ax, 0x0003         ; Text mode 80x25
    int 0x10               ; BIOS video

    ; Print bootloader message
    mov si, msg
print_loop:
    lodsb                  ; Load [SI] to AL, SI++
    cmp al, 0              ; Null?
    je load_kernel         ; Yes → load kernel
    mov ah, 0x0E           ; Teletype
    mov bx, 0x07           ; White on black
    int 0x10               ; Print
    jmp print_loop

load_kernel:
    ; Reset floppy (good practice)
    mov ah, 0x00           ; Reset function
    mov dl, 0              ; Drive 0
    int 0x13

    ; Set up for read: ES:BX = 0x07E0:0 (physical 0x7E00)
    mov ax, 0x07E0         ; No need for temp zero—direct
    mov es, ax             ; ES=0x07E0
    xor bx, bx             ; Offset=0

    ; BIOS disk read params (floppy drive 0)
    mov ah, 0x02           ; Read function
    mov al, 1              ; Sectors to read (1 = 512 bytes)
    mov ch, 0              ; Cylinder 0
    mov cl, 2              ; Sector 2 (1=boot, 2=kernel)
    mov dh, 0              ; Head 0
    mov dl, 0              ; Drive 0 (first floppy)
    int 0x13               ; Read from disk!

    jc disk_error          ; Carry set? Error!

    ; Jump to kernel (far: segment:offset)
    jmp 0x07E0:0

disk_error:
    mov si, err_msg        ; Print error
error_loop:
    lodsb
    cmp al, 0
    je halt_error
    mov ah, 0x0E
    mov bx, 0x07
    int 0x10
    jmp error_loop
halt_error:
    hlt                    ; Halt on error

    ; Infinite loop fallback (if jump fails)
    jmp $                  ; Never reached

msg db 'Booting Nishchal Kernel!', 0
err_msg db 'Disk Read Error!', 0

; Pad to 510 bytes + signature (data now before!)
times 510-($-$$) db 0
dw 0xAA55              ; Boot magic