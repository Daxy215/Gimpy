#!/bin/bash

echo "Building"

nasm -f elf64 -g -F dwarf game.asm -o game.o
gcc -g -no-pie game.o -o game -lX11

./game

