#!/bin/bash -ex
# Script for uploading upgrade_NP1380.bin to NP1380
cat upgrade_NP1380.bin | ncat -l -p 1234 --send-only -i 5 &
expect <<EOF | strings
spawn telnet -E NP1380
set timeout 30
expect -ex "#"
send "nc 192.168.2.1 1234 > /mnt/mmc/upgrade.bin < /dev/null\r"
expect -ex "#"
send "sync\r"
expect -ex "#"
set timeout 10
send "umount -l /mnt/mmc\r"
expect -ex "#"
send "reboot\r"
expect -ex "#"
send "exit\r"
expect eof
EOF
wait
