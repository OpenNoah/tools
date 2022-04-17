#!/bin/bash -ex
./build.sh

# Now, NP1501-specific stuff
./NoahSplit/mkpkg --create uImage-np1501.cfg upgrade_np1501.bin
cp upgrade_np1501.bin release/upgrade_np1501.bin
