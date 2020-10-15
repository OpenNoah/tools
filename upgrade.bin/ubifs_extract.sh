#!/bin/bash -ex
file="$1"
base="$(basename "$1" .bin)"

./tools/unubirefimg $file $base.img
./tools/ubirefimg $base.img new-$base.bin
diff $file new-$base.bin

rm new-$base.bin
#exit 0

mkdir -p $base/raw
sudo python ./ubidump/ubidump.py --savedir $base -p $base.img

mv $base/raw .
rmdir $base
mv raw $base
sudo chown root:root $base
