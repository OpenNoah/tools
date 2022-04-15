#!/bin/bash -ex
# Compile kernel and update rootfs

top=$HOME/mips/OpenNoah
cd $top/linux-new

ARCH=mips make -j12 uImage
ARCH=mips make -j12 modules

#rm -rf $top/initramfs/lib/modules
#ARCH=mips make -j12 modules_install INSTALL_MOD_PATH=/home/zhiyb/mips/OpenNoah/initramfs

# Remove non-essential modules
#rm -rf $top/initramfs/lib/modules/*/kernel/net
#rm -rf $top/initramfs/lib/modules/*/kernel/fs
#rm -rf $top/initramfs/lib/modules/*/kernel/crypto
#rm -rf $top/initramfs/lib/modules/*/kernel/drivers/usb/host
#rm -rf $top/initramfs/lib/modules/*/kernel/drivers/hid
#rm -rf $top/initramfs/lib/modules/*/kernel/drivers/power

#rm -rf $top/rootfs/lib/modules
#ARCH=mips make -j12 modules_install INSTALL_MOD_PATH=/home/zhiyb/mips/OpenNoah/rootfs

#ARCH=mips make -j12 uImage #"KCFLAGS=-Wno-attribute-alias"
