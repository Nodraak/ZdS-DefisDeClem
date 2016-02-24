#!/bin/bash

set -e

rm -f a.s.out a.c.out

# asm
nasm -f elf32 -g main.s
ld -melf_i386 -o a.s.out -g main.o
rm -f main.o  # clean after ourselves

# c
gcc -o a.c.out main.c
