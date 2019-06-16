#!/bin/bash -ex
# Script for updating initramfs, kernel and upgrade.bin
. ../../vars
#cd ../busybox-1.31.0-static/
#ARCH=mips make -j8
#ARCH=mips make -j8 install
#cd -
cd ../../linux-new/
./compile.sh
cd -
./mkpkg --create uImage-NP1380.cfg upgrade_NP1380.bin
./mkpkg --create uImage-NP1500.cfg upgrade_NP1500.bin
sync
./mkpkg --create rootfs.cfg upgrade.bin
./upload.sh upgrade_NP1380.bin
mv upgrade.bin /mnt/nas/Linux/Noah/upgrade.bin/mainline/upgrade.bin
cp upgrade_NP1380.bin /mnt/nas/Linux/Noah/upgrade.bin/mainline/upgrade_NP1380.bin
cp upgrade_NP1500.bin /mnt/nas/Linux/Noah/upgrade.bin/mainline/upgrade_NP1500.bin
