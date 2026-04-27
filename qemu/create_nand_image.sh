#!/bin/bash -x
src=$1 #upgrade.bin
pkg=upgrade.pkg
nand=nand_image.bin
qcow2=nand_image.qcow2

# Extract data sections from upgrade.bin
[ -f $pkg ] || ./mkpkg --type=np1000 --extract $src $pkg

# Create NAND image
# Ignore errors as it does not support ubifs file system format yet
rm -f $nand
./create_nand_image.py -s $((2*1024*1024*1024)) -p 4096 -o 128 $pkg $nand

# (Optional) Write fake serial number
./write_serial.py -p 4096 -o 128 0x00201000 "QEMU $(date -Iseconds)" $nand

# (Optional) Convert NAND image to qcow2 format
qemu-img convert -f raw -O qcow2 $nand $qcow2
