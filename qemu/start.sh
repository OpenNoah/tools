#!/bin/bash -ex
prefix=
monitor=vc

if (($# != 0)); then
	# Specify -S to start debugging
	prefix="gdb -ex run --args"
	monitor=stdio
fi

# Create overlay qcow2 files as snapshot
qemu-img create -f qcow2 -F qcow2 -b nand_dump_oob_base.qcow2 nand_overlay.qcow2
qemu-img create -f qcow2 -F qcow2 -b mmc_base.qcow2 mmc_overlay.qcow2

# Start QEMU
eval $prefix ./qemu-system-mipsel \
	-M noah_np1380 -cpu JZ4740 \
	-d guest_errors,unimp \
	-bios bootrom.bin \
	-parallel null \
	-serial tcp:localhost:7645 \
	-monitor $monitor \
	-blockdev driver=file,node-name=nand_qcow2,filename=nand_overlay.qcow2 \
	-blockdev qcow2,node-name=nand,file=nand_qcow2 \
	-global ingenic-emc-nand.drive=nand \
	-blockdev driver=file,node-name=mmc_qcow2,filename=mmc_overlay.qcow2 \
	-blockdev qcow2,node-name=mmc,file=mmc_qcow2 \
	-device sd-card,spec_version=3,drive=mmc \
	-display vnc=:10 \
	"$@"
