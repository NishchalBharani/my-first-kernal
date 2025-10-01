# Makefile for simple kernel (ASM bootloader + ASM kernel)
NASM = nasm
QEMU = qemu-system-i386

all: build

build: boot.bin

# Assemble bootloader
bootloader.bin: boot.asm
	$(NASM) -f bin boot.asm -o bootloader.bin

# Assemble kernel (16-bit flat binary)
kernel.bin: kernel.asm
	$(NASM) -f bin kernel.asm -o kernel.bin

# Pad kernel to 512 bytes
pad_kernel: kernel.bin
	dd if=/dev/zero of=kernel_padded.bin bs=512 count=1 2>/dev/null
	dd if=kernel.bin of=kernel_padded.bin conv=notrunc 2>/dev/null
	mv kernel_padded.bin kernel.bin
	rm -f kernel.bin.orig  # Backup if needed

# Combine: bootloader + kernel
boot.bin: bootloader.bin kernel.bin
	cat bootloader.bin kernel.bin > boot.bin

run: build
	$(QEMU) -drive file=boot.bin,index=0,if=floppy,format=raw

clean:
	rm -f *.bin *.elf *.o

.PHONY: all build run clean