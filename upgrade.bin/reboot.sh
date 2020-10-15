#!/bin/bash -ex
# Script for reboot
expect <<EOF | strings
spawn ncat zhiyb-rpi4 1383
set timeout 30
expect -ex "#"
send "sync\r"
expect -ex "#"
send "umount -l /mnt/mmc\r"
expect -ex "#"
set timeout 2
send "reboot\r"
expect eof
EOF
wait
