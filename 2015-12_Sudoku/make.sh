#!/bin/bash

rm -f main.o a.out

nasm -f elf32 -g main.s
ld -melf_i386 -g main.o
