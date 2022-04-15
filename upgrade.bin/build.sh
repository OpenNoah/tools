#!/bin/bash -ex
# Script for updating initramfs, kernel and upgrade.bin

top=$HOME/mips/OpenNoah
jobs=12
kargs="ARCH=mips CROSS_COMPILE=mipsel-linux-"

pushd ../initramfs
./build.sh
rootfs=$PWD/rootfs
rm -rf $rootfs/lib/modules
popd

pushd $top/linux-new
sed -i "s/CONFIG_INITRAMFS_SOURCE=.*/CONFIG_INITRAMFS_SOURCE=\"${rootfs//\//\\\/}\"/" .config
make -j$jobs $kargs modules
make -j$jobs $kargs modules_install INSTALL_MOD_PATH=$rootfs
popd

pushd ../initramfs
./build.sh
popd

pushd $top/linux-new
make -j$jobs $kargs uImage
popd

cp $top/linux-new/arch/mips/boot/uImage.bin uImage

if [ ! -f NoahSplit/mkpkg ]; then
	pushd NoahSplit
	make -j$jobs
	popd
fi
