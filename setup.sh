#!/bin/bash

# This allows to print every command that is currently running and stops in the first
# command that returns an error
set -xe

# To assemble the assembly with gcc
gcc -ffreestanding -O3 -nostdlib -c boot.s -o boot.o

# Linking using the gcc, generating the file myos.bin using freestading,
# 03 is optimization, nostdlib means no standard libs,
# currently only linking the boot.o 
# -lgcc means using the linker from gcc
gcc -T linker.ld -o myos.bin -ffreestanding -O3 -nostdlib boot.o -lgcc

mkdir -p isodir/boot/grub

cp myos.bin isodir/boot/myos.bin

cp grub.cfg isodir/boot/grub/grub.cfg

#
grub2-mkrescue -o myos.iso isodir

qemu-system-x86_64 -enable-kvm -cdrom myos.iso