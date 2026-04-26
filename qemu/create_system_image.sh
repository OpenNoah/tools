#!/bin/bash -x
src=$1 #upgrade.bin
pkg=upgrade.pkg
image=image.bin
qcow2=image.qcow2

# Extract data sections from upgrade.bin
[ -f $pkg ] || ./mkpkg --type=np1000 --extract $src $pkg

# Create NP6800 system image
# Ignore errors as it does not support ext3 file system format yet
rm -f $image
./create_system_image.py -s $((8*1024*1024*1024)) $pkg $image

# (Optional) Convert NAND image to qcow2 format
qemu-img convert -f raw -O qcow2 $image $qcow2
