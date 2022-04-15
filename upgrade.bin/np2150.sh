#!/bin/bash -ex
./build.sh

# Now, NP2150-specific stuff
./NoahSplit/mkpkg --create uImage-np2150.cfg upgrade_np2150.bin
cp upgrade_np2150.bin release/upgrade_np2150.bin
