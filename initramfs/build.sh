#!/bin/bash -ex
busybox_url="https://busybox.net/downloads/busybox-1.35.0.tar.bz2"
jobs=12

if [ ! -e busybox ]; then
	curl "$busybox_url" | tar jxvf -
	ln -sfr busybox-* busybox
	cat defconfig > busybox/.config
fi

if [ ! -f rootfs/bin/busybox ]; then
	mkdir -p rootfs

	pushd busybox
	make -j$jobs
	make install CONFIG_PREFIX=$PWD/../rootfs
	popd

	# Shared libraries for busybox
	mkdir -p rootfs/lib
	cp -a ../../toolchain/mipsel-linux/mipsel-linux/lib/libc.so* \
	      ../../toolchain/mipsel-linux/mipsel-linux/lib/libm.so* \
	      ../../toolchain/mipsel-linux/mipsel-linux/lib/libresolv.so* \
	      rootfs/lib/
	mipsel-linux-strip rootfs/lib/*.so.*

	# Init script
	cp init rootfs/
	chmod a+x rootfs/init
	ln -sf init rootfs/linuxrc
fi
