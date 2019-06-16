#!/bin/bash -ex
# Compile kernel and update rootfs

top=$HOME/mips/OpenNoah
ARCH=mips make -j8 modules

rm -rf $top/initramfs/lib/modules
ARCH=mips make -j8 modules_install INSTALL_MOD_PATH=/home/zhiyb/mips/OpenNoah/initramfs
# Remove non-essential modules
rm -rf $top/initramfs/lib/modules/*/kernel/net
rm -rf $top/initramfs/lib/modules/*/kernel/fs

rm -rf $top/rootfs/lib/modules
ARCH=mips make -j8 modules_install INSTALL_MOD_PATH=/home/zhiyb/mips/OpenNoah/rootfs

ARCH=mips make -j8 uImage "KCFLAGS=-Wno-attribute-alias"
