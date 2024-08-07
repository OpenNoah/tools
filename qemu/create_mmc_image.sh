#!/bin/bash -ex
in=upgrade.bin
out=mmc.bin
out_qcow2=mmc.qcow2

# Create sparse image file
rm -f $out
touch $out
truncate -s 4G $out

# Create partition table
sfdisk $out <<SFDISK
label: dos
start=2048, size=8386560, type=0c
SFDISK

# Format drive
lo=$(losetup -f --show $out -o $((512*2048)))
mkfs.vfat -F 32 $lo
mkdir -p mnt
mount -t vfat $lo mnt

# Copy files to mmc
cp $in mnt/upgrade.bin

# Done, clean up
df -h mnt
umount mnt
rmdir mnt
/sbin/losetup -d $lo

# (Optional) Convert to qcow2
qemu-img convert -f raw -O qcow2 $out $out_qcow2
