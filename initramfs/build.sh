#!/bin/bash -ex
busybox_url="https://busybox.net/downloads/busybox-1.35.0.tar.bz2"
jobs=12

if [ ! -e busybox ]; then
	curl "$busybox_url" | tar jxvf -
	ln -sfr busybox-* busybox
	cat files/defconfig > busybox/.config
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
	      ../../toolchain/mipsel-linux/mipsel-linux/lib/ld.so* \
	      rootfs/lib/
	mipsel-linux-strip rootfs/lib/*.so.*

	# Essential directories and files
	pushd rootfs
	mkdir -p etc dev sys proc tmp mnt/mmc mnt/root
	popd
	cp files/fstab rootfs/etc/

	sudo mknod rootfs/dev/console c 5 1
	sudo mknod rootfs/dev/null c 1 3
fi

# Init script
cp files/init rootfs/
chmod a+x rootfs/init
ln -sf /init rootfs/sbin/init
