#!/bin/bash -x
src=upgrade.bin
pkg=upgrade.pkg
nand=nand_dump_oob.bin
qcow2=nand_dump_oob.qcow2

# Extract data sections from upgrade.bin
[ -f $pkg ] || ./mkpkg --type=np1000 --extract $src $pkg

# Create NAND image
# Ignore errors as it does not support ubifs file system format yet
./create_nand_dump.py -s $((2*1024*1024*1024)) -p 4096 -o 128 $pkg $nand

# (Optional) Convert NAND image to qcow2 format
qemu-img convert -f raw -O qcow2 $nand $qcow2
