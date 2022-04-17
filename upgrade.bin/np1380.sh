#!/bin/bash -ex
./build.sh

# Now, NP1380-specific stuff
./NoahSplit/mkpkg --create uImage-np1380.cfg upgrade_np1380.bin
cp upgrade_np1380.bin release/upgrade_np1380.bin
