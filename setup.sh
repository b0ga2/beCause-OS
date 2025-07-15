#!/bin/bash

# This allows to print every command that is currently running and stops in the first
# command that returns an error
set -xe

# To assemble the assembly with gcc
gcc -ffreestanding -O3 -nostdlib -c boot.s -o boot.o

# gcc - Linking using the gcc, 
# --freestanding - Tells the compiler that the environment is freestanding (no standard library or OS)
# -03 - enables aggressive optimizations for performance.
# -nostdlib - Prevents linking against the standard libraries
# currently only linking the boot.o 
# -lgcc means using the linker from gcc
gcc -T linker.ld -o myos.bin -ffreestanding -O3 -nostdlib boot.o -lgcc

mkdir -p isodir/boot/grub

cp myos.bin isodir/boot/myos.bin

cp grub.cfg isodir/boot/grub/grub.cfg

# grub2-mkrescue - A tool that creates a bootable ISO image using GRUB2 as the bootloader
# isodir - Directory containing the bootable files
grub2-mkrescue -o myos.iso isodir

# qemu-system-x86_64 - Launches QEMU for emulating a 64-bit x86 system.
# -enable-kvm - Enables KVM (Kernel-based Virtual Machine) for performance
# myos.iso - Tells QEMU to use myos.iso as the CD-ROM (bootable ISO) image.
qemu-system-x86_64 -enable-kvm -cdrom myos.iso
