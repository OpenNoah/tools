#!/bin/bash
# This file is just a note for setting up a minimal rootfs
# Use as a reference only

# Cross compiler variables
. ../vars
export ARCH=mips
jobs=-j8

cd ..
top=$PWD
rootfs=$top/rootfs
prefix=$top/toolchain/mipsel-linux
sysroot=$top/toolchain/mipsel-linux/mipsel-linux
export PKG_CONFIG_PATH=$prefix/lib/pkgconfig
export PKG_CONFIG_LIBDIR=$PKG_CONFIG_PATH

# https://github.com/OpenNoah/linux-new
cd $top/linux-new/
make $jobs modules_install INSTALL_MOD_PATH=$rootfs

# https://busybox.net/downloads/busybox-1.31.0.tar.bz2
cd $top/build/busybox-1.31.0/
make $jobs
make install

# https://ftp.gnu.org/gnu/glibc/glibc-2.29.tar.xz
cd $top/build/glibc-2.29/
mkdir -p build
cd build
../configure --host=mipsel-linux --prefix=/
make $jobs
make $jobs install DESTDIR=$rootfs

# https://www.freedesktop.org/software/libevdev/libevdev-1.7.0.tar.xz
true || {	# Not needed
cd $top/build/libevdev-1.7.0/
mkdir -p build
cd build
../configure --host=mipsel-linux --disable-static
make $jobs
make $jobs install DESTDIR=$rootfs
# Build again for cross-compiler
rm -rf *
../configure --host=mipsel-linux --disable-static --prefix=$prefix --with-sysroot=$sysroot
make $jobs
make $jobs install
}

# https://github.com/libts/tslib/releases/download/1.20/tslib-1.20.tar.xz
cd $top/build/tslib-1.20/
mkdir -p build
cd build
../configure --host=mipsel-linux --sysconfdir=/etc #--enable-input-evdev
make $jobs
make $jobs install DESTDIR=$rootfs
rm -rf *
../configure --host=mipsel-linux --disable-static --prefix=$prefix --with-sysroot=$sysroot
make $jobs
make $jobs install

# https://github.com/OpenNoah/mtd-utils
cd $top/mtd-utils/ubi-utils/new-utils/
make $jobs
make $jobs install DESTDIR=$rootfs

# https://github.com/libexpat/libexpat/releases/download/R_2_2_6/expat-2.2.6.tar.bz2
cd $top/build/expat-2.2.6/
mkdir -p build
cd build
../configure --host=mipsel-linux --disable-static
make $jobs
make $jobs install DESTDIR=$rootfs
rm -rf *
../configure --host=mipsel-linux --disable-static --prefix=$sysroot
make $jobs
make $jobs install

# https://download.savannah.gnu.org/releases/freetype/freetype-2.10.0.tar.bz2
cd $top/build/freetype-2.10.0/
mkdir -p build
cd build
../configure --host=mipsel-linux --disable-static
make $jobs
make $jobs install DESTDIR=$rootfs
rm -rf *
../configure --host=mipsel-linux --disable-static --prefix=$prefix --with-sysroot=$sysroot
make $jobs
make $jobs install

# https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.13.91.tar.xz
cd $top/build/fontconfig-2.13.91/
mkdir -p build
cd build
../configure --host=mipsel-linux --disable-static
make $jobs
make $jobs install DESTDIR=$rootfs
rm -rf *
../configure --host=mipsel-linux --disable-static --prefix=$prefix
make $jobs
make $jobs install

# https://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.lz
cd $top/build/flex-2.6.4/
mkdir -p build
cd build
../configure --host=mipsel-linux --disable-static
make $jobs
make $jobs install DESTDIR=$rootfs
rm -rf *
../configure --host=mipsel-linux --disable-static --prefix=$prefix --disable-bootstrap
make $jobs
make $jobs install

# https://download.qt.io/archive/qt/5.12/5.12.4/single/qt-everywhere-src-5.12.4.tar.xz
cd $top/build/qt-everywhere-src-5.12.4/
mkdir -p build
cd build
../configure -release -device linux-mipsel-noah-g++ -confirm-license -opensource -no-opengl -device-option CROSS_COMPILE=mipsel-linux- -tslib -linuxfb -skip qtmultimedia -I $prefix/include -L $prefix/lib -prefix /usr/local/Qt-5.12.4 -hostprefix /host -fontconfig -system-freetype -pkg-config
make $jobs
make $jobs install INSTALL_ROOT=$rootfs
mv $rootfs/host .

# https://github.com/LibVNC/libvncserver/archive/LibVNCServer-0.9.12.tar.gz
cd $top/build/libvncserver-LibVNCServer-0.9.12/
mkdir -p build
cd build
cmake .. -DCMAKE_C_COMPILER=mipsel-linux-gcc -DCMAKE_BUILD_TYPE=Release
make $jobs
make $jibs install DESTDIR=$rootfs

# https://github.com/ponty/framebuffer-vncserver
cd $top/build/framebuffer-vncserver/src
mipsel-linux-gcc *.c -o fbvncd -I $rootfs/usr/local/include -L $rootfs/usr/local/lib/ -lvncserver -O3
cp -a fbvncd $rootfs/usr/local/bin

# https://zlib.net/zlib-1.2.11.tar.xz
cd $top/build/zlib-1.2.11/
mkdir build
cd build
CHOST=mipsel-linux ../configure --shared
make $jobs
make $jibs install DESTDIR=$rootfs

# http://download.qt-project.org/archive/qt/2/qt-embedded-2.3.10-free.tar.gz
# Needs multiple patches...
cd $top/build/qt-2.3.10.host/
export QTDIR=$PWD
./configure -release -platform linux-generic-g++ -thread -no-qvfb -depths 32 -system-jpeg -gif -no-opengl
cd tools/designer
make $jobs

cd $top/build/qt-2.3.10/
export QTDIR=$PWD
export QWS_MOUSE_PROTO='TPanel:/dev/input/event0 USB'
./configure -release -xplatform linux-mips-g++ -thread -tslib -no-xft -I$rootfs/usr/local/include -L$rootfs/usr/local/lib -no-qvfb -depths 32 -vnc
make $jobs
cp ../qt-2.3.10.host/bin/* bin/

# https://sourceforge.net/projects/linux-diag/files/sysfsutils/2.1.0/sysfsutils-2.1.0.tar.gz
cd $top/build/sysfsutils-2.1.0/
./configure --host=mipsel-linux --disable-static
make $jobs
make $jobs install DESTDIR=$rootfs
make distclean
./configure --host=mipsel-linux --disable-static --prefix=$prefix
make $jobs
make $jobs install DESTDIR=$rootfs

# https://github.com/opieproject/opie
mkdir -p build/tmp/staging/i686-linux/bin
cp ../qt-2.3.10.host/bin/* build/tmp/staging/i686-linux/bin/
