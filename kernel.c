/* kernel.c - interactive kernel: green text, blinking cursor, polling keyboard
   Features:
   - Green text on VGA
   - Cursor blinking (software toggle)
   - Polling PS/2 keyboard (no IRQs)
   - Shift support, Backspace, Enter, Shift+Enter (go to line 2)
   - Command 'sysinfo' prints details
*/

typedef unsigned char  uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int   uint32_t;
typedef unsigned long  uint64_t;
typedef unsigned int   size_t;

#define VGA_ADDR 0xB8000
#define VGA_COLS 80
#define VGA_ROWS 25
#define VGA_ATTR 0x02 /* green on black */

volatile uint16_t* const vga = (volatile uint16_t*)VGA_ADDR;

/* cursor position */
static size_t cursor_x = 0;
static size_t cursor_y = VGA_ROWS - 1; /* bottom line */

/* input buffer */
static char input_buffer[128];
static size_t input_len = 0;
static int shift_pressed = 0;

/* I/O port helpers */
static inline void outb(uint16_t port, uint8_t value) {
    asm volatile ("outb %0, %1" : : "a"(value), "Nd"(port));
}
static inline uint8_t inb(uint16_t port) {
    uint8_t val;
    asm volatile ("inb %1, %0" : "=a"(val) : "Nd"(port));
    return val;
}

/* update hw cursor */
static void update_cursor(void) {
    uint16_t pos = (uint16_t)(cursor_y * VGA_COLS + cursor_x);
    outb(0x3D4, 0x0F);
    outb(0x3D5, (uint8_t)(pos & 0xFF));
    outb(0x3D4, 0x0E);
    outb(0x3D5, (uint8_t)((pos >> 8) & 0xFF));
}

/* clear screen, set prompt on bottom */
static void clear_screen(void) {
    uint16_t blank = (uint16_t)(' ') | ((uint16_t)VGA_ATTR << 8);
    for (size_t i = 0; i < VGA_ROWS * VGA_COLS; ++i) vga[i] = blank;
    cursor_x = 0;
    cursor_y = VGA_ROWS - 1;
    update_cursor();
}

/* scroll up one line (move rows up) */
static void scroll_up(void) {
    for (size_t r = 1; r < VGA_ROWS; ++r) {
        for (size_t c = 0; c < VGA_COLS; ++c) {
            vga[(r - 1) * VGA_COLS + c] = vga[r * VGA_COLS + c];
        }
    }
    uint16_t blank = (uint16_t)(' ') | ((uint16_t)VGA_ATTR << 8);
    for (size_t c = 0; c < VGA_COLS; ++c) vga[(VGA_ROWS - 1) * VGA_COLS + c] = blank;
    cursor_y = VGA_ROWS - 1;
}

/* put a character at cursor */
static void putch(char ch) {
    if (ch == '\n') {
        cursor_x = 0;
        cursor_y++;
        if (cursor_y >= VGA_ROWS) scroll_up();
        update_cursor();
        return;
    }
    vga[cursor_y * VGA_COLS + cursor_x] = (uint16_t)ch | ((uint16_t)VGA_ATTR << 8);
    cursor_x++;
    if (cursor_x >= VGA_COLS) {
        cursor_x = 0;
        cursor_y++;
        if (cursor_y >= VGA_ROWS) scroll_up();
    }
    update_cursor();
}

/* print string */
static void kprint(const char* s) {
    while (*s) putch(*s++);
}

/* simple strcmp (no libc) */
static int kstrcmp(const char* a, const char* b) {
    while (*a && (*a == *b)) { a++; b++; }
    return (int)(uint8_t)*a - (int)(uint8_t)*b;
}

/* keyboard maps (scancode -> char) */
static const char keymap[128] = {
    0,27,'1','2','3','4','5','6','7','8','9','0','-','=', '\b',
    '\t','q','w','e','r','t','y','u','i','o','p','[',']','\n', 0,
    'a','s','d','f','g','h','j','k','l',';','\'','`',   0,'\\',
    'z','x','c','v','b','n','m',',','.','/',   0,'*',   0,' ',
};
static const char keymap_shift[128] = {
    0,27,'!','@','#','$','%','^','&','*','(',')','_','+', '\b',
    '\t','Q','W','E','R','T','Y','U','I','O','P','{','}','\n', 0,
    'A','S','D','F','G','H','J','K','L',':','"','~',   0,'|',
    'Z','X','C','V','B','N','M','<','>','?',   0,'*',   0,' ',
};

/* process a completed command */
/* process a completed command */
static void handle_command(void) {
    if (input_len == 0) {
        kprint("\n> ");
        return;
    }
    input_buffer[input_len] = 0;

    if (kstrcmp(input_buffer, "sysinfo") == 0) {
        kprint("\n--- Kernel Info ---\n");
        kprint("Nishchal OS Kernel v0.2\n");
        kprint("I am an OS built by Nishchal.\n");
        kprint("I can do small tasks like text display & input.\n");
        kprint("Architecture: i386 (32-bit)\n");
        kprint("-------------------\n");
    } else if (kstrcmp(input_buffer, "clear") == 0) {
        clear_screen();
        kprint("> ");
    } else if (kstrcmp(input_buffer, "help") == 0) {
        kprint("\nAvailable commands:\n");
        kprint("  sysinfo - Show kernel info\n");
        kprint("  clear   - Clear the screen\n");
        kprint("  help    - Show this help menu\n");
        kprint("  time    - Show a fake system time\n");
        kprint("  echo X  - Print X\n");
        kprint("  reboot  - Restart the machine\n");
    } else if (kstrcmp(input_buffer, "time") == 0) {
        static unsigned ticks = 0;
        ticks++;
        kprint("\nSystem uptime (fake): ");
        char buf[16];
        int n = 0;
        unsigned t = ticks;
        if (t == 0) buf[n++] = '0';
        else {
            char tmp[16];
            int m = 0;
            while (t > 0) { tmp[m++] = '0' + (t % 10); t /= 10; }
            while (m--) buf[n++] = tmp[m];
        }
        buf[n] = 0;
        kprint(buf);
        kprint(" seconds\n");
    } else if (input_buffer[0] == 'e' && input_buffer[1] == 'c' &&
               input_buffer[2] == 'h' && input_buffer[3] == 'o' &&
               (input_buffer[4] == ' ' || input_buffer[4] == 0)) {
        kprint("\n");
        if (input_buffer[4] == ' ') kprint(input_buffer + 5);
        kprint("\n");
    } else if (kstrcmp(input_buffer, "reboot") == 0) {
        kprint("\nRebooting...\n");
        outb(0x64, 0xFE); /* reset command */
    } else {
        kprint("\nUnknown command: ");
        kprint(input_buffer);
        kprint("\nType 'help' for list.\n");
    }

    input_len = 0;
    kprint("> ");
}


/* polling keyboard loop:
   - we read from PS/2 data port 0x60 when status port 0x64 has bit 0 set.
   - we detect Shift press/release scancodes.
   - no IRQs; this is stable in QEMU and won't crash.
*/
static void keyboard_loop(void) {
    uint32_t blink = 0;
    for (;;) {
        /* software blink (toggle attr bit occasionally) */
        blink++;
        if ((blink & 0x1FFFF) == 0) {
            size_t pos = cursor_y * VGA_COLS + cursor_x;
            uint16_t cell = vga[pos];
            uint8_t ch = (uint8_t)(cell & 0x00FF);
            uint8_t attr = (uint8_t)((cell >> 8) & 0xFF);
            attr ^= 0x08; /* toggle bright bit */
            vga[pos] = (uint16_t)ch | ((uint16_t)attr << 8);
        }

        /* poll PS/2 status */
        if (inb(0x64) & 1) {
            uint8_t sc = inb(0x60);

            /* Shift down: 0x2A or 0x36; Shift up: 0xAA or 0xB6 */
            if (sc == 0x2A || sc == 0x36) { shift_pressed = 1; continue; }
            if (sc == 0xAA || sc == 0xB6) { shift_pressed = 0; continue; }

            if (sc & 0x80) continue; /* ignore key release events */

            char c = shift_pressed ? keymap_shift[sc] : keymap[sc];
            if (!c) continue;

            if (c == '\n') {
                if (shift_pressed) {
                    /* Shift+Enter: move to line 2 (row index 1) */
                    cursor_x = 0;
                    cursor_y = 1;
                    update_cursor();
                } else {
                    putch('\n');
                    handle_command();
                }
                continue;
            }
            if (c == '\b') {
                if (input_len > 0) {
                    if (cursor_x > 0) cursor_x--;
                    else if (cursor_y > 0) { cursor_y--; cursor_x = VGA_COLS - 1; }
                    vga[cursor_y * VGA_COLS + cursor_x] = (uint16_t)(' ') | ((uint16_t)VGA_ATTR << 8);
                    if (input_len > 0) input_len--;
                    update_cursor();
                }
                continue;
            }
            /* normal character */
            if (input_len < sizeof(input_buffer) - 1) {
                putch(c);
                input_buffer[input_len++] = c;
            }
        } /* end if status */
    } /* forever */
}

/* entry */
void kernel_main(void) {
    clear_screen();
    kprint("Hello Nishchal Kernel in C!\n");
    kprint("Multiboot header kept and visible. Kernel loaded.\n");
    kprint("> ");
    update_cursor();
    keyboard_loop();
}
