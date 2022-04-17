#!/bin/bash -ex
./build.sh

# Now, NP1500-specific stuff
./NoahSplit/mkpkg --create uImage-np1500.cfg upgrade_np1500.bin
cp upgrade_np1500.bin release/upgrade_np1500.bin
