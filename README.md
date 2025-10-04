# Nishchal Kernel - interactive demo

Build:
  make clean
  make

Run:
  make run
  # or:
  qemu-system-i386 -m 512 -cdrom os.iso -boot d -no-reboot -serial stdio

Features:
- Green VGA text
- Blinking cursor at bottom
- Typing works (Shift, Backspace)
- Shift+Enter -> go to line 2
- Enter -> execute command
- "sysinfo" prints: "I am an OS built by Nishchal..."
