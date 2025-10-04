# Makefile - final stable build (polling keyboard, no IRQs)
CROSS ?=
ASM = nasm
CC  = $(CROSS)gcc
LD  = $(CROSS)ld
GRUBMKRESCUE = grub-mkrescue
OBJCOPY = $(CROSS)objcopy)

ASMFLAGS = -f elf32

CFLAGS = -m32 -ffreestanding -O2 -fno-builtin -nostdlib -Wall -Wextra \
	-fno-exceptions -fno-unwind-tables -fno-asynchronous-unwind-tables \
	-ffunction-sections -fdata-sections

LDFLAGS = -m elf_i386 -T linker.ld

all: os.iso

boot.o: boot.s
	$(ASM) $(ASMFLAGS) boot.s -o boot.o

kernel.o: kernel.c
	$(CC) $(CFLAGS) -c kernel.c -o kernel.o

kernel.elf: boot.o kernel.o linker.ld
	$(LD) $(LDFLAGS) -o kernel.elf boot.o kernel.o
	-$(OBJCOPY) --remove-section .note.gnu.build-id kernel.elf 2>/dev/null || true

iso/boot/grub/grub.cfg:
	mkdir -p iso/boot/grub
	cp grub.cfg iso/boot/grub/grub.cfg

os.iso: kernel.elf iso/boot/grub/grub.cfg
	mkdir -p iso/boot
	cp kernel.elf iso/boot/kernel.elf
	$(GRUBMKRESCUE) -o os.iso iso

run: os.iso
	qemu-system-i386 -m 512 -cdrom os.iso -boot d -no-reboot -serial stdio

clean:
	rm -f *.o kernel.elf os.iso
	rm -rf iso

.PHONY: all run clean
