#!/bin/bash

# TODO: Since I'm trying to have organized code in the repo i should check a goos structure for a C proj and how to do globbing
# ref: https://www.lucavall.in/blog/how-to-structure-c-projects-my-experience-best-practices

# This allows to print every command that is currently running and stops in the first
# command that returns an error
set -xe

mkdir -p build

# To assemble the assembly with gcc
gcc -ffreestanding -O2 -nostdlib -c boot.s -o build/boot.o

# To compile the main.c
# TODO: Look for more compiling warnings options
gcc -c src/main.c -o build/main.o --freestanding -O2 -Wall -Wextra

# gcc - Linking using the gcc, 
# --freestanding - Tells the compiler that the environment is freestanding (no standard library or OS)
# -03 - enables aggressive optimizations for performance.
# -nostdlib - Prevents linking against the standard libraries
# currently only linking the boot.o 
# -lgcc means using the linker from gcc
# TODO: Verify what is linking
gcc -T linker.ld -o build/myos.bin -ffreestanding -O2 -nostdlib build/boot.o build/main.o -lgcc

mkdir -p isodir/boot/grub

cp build/myos.bin isodir/boot/myos.bin

cp grub.cfg isodir/boot/grub/grub.cfg

# grub2-mkrescue - A tool that creates a bootable ISO image using GRUB2 as the bootloader
# isodir - Directory containing the bootable files
grub2-mkrescue -o build/myos.iso isodir

# qemu-system-x86_64 - Launches QEMU for emulating a 64-bit x86 system.
# -enable-kvm - Enables KVM (Kernel-based Virtual Machine) for performance
# myos.iso - Tells QEMU to use myos.iso as the CD-ROM (bootable ISO) image.
# The -serial stdio argument used above instructs QEMU to redirect the serial input and output to the host system's stdio stream. This is particularly useful for debugging purposes. 
qemu-system-x86_64 -enable-kvm -serial stdio -cdrom build/myos.iso


