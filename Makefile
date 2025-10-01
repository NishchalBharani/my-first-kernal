# Makefile for simple kernel
# Usage: make build (assembles to boot.bin) or make run (builds + QEMU)

NASM = nasm
QEMU = qemu-system-i386

# Default target: build
all: build

# Rule to assemble bootloader
build: boot.bin

boot.bin: boot.asm
	$(NASM) -f bin boot.asm -o boot.bin

# Run in QEMU
run: build
	$(QEMU) -fda boot.bin

# Clean build files
clean:
	rm -f boot.bin

.PHONY: all build run clean