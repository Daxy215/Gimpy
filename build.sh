#!/bin/bash
set -e

echo "Building"

for module in game display window graphics events; do
    nasm -f elf64 -g -F dwarf $module.asm -o $module.o
done
gcc -g -no-pie game.o display.o window.o graphics.o events.o -o game -lX11

./game
