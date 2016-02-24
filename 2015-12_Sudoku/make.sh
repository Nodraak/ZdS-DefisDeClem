#!/bin/bash

set -e

rm -f main.o a.s.out
nasm -f elf32 -g main.s
ld -melf_i386 -o a.s.out -g main.o

rm -f main.o a.c.out
gcc -o a.c.out main.c
