#!/usr/bin/env python3
import os
import argparse
from pprint import pprint
import helper

def copy_to_dump(fout, pkg_data):
    if not pkg_data["include"]:
        return
    if pkg_data["dev"] == "/dev/null":
        return

    if pkg_data["fstype"] == "raw":
        dev,offset = pkg_data["dev"].split(",", 1)
        if dev != "/dev/mmcblk0":
            raise NotImplementedError(f"Unknown device {dev}")
        offset = int(offset, 0)
        print(f"Writing {pkg_data['file']} type {pkg_data['fstype']} to {offset:#010x}")
        fout.seek(offset, os.SEEK_SET)
        with open(pkg_data["file"], "rb") as fin:
            fout.write(fin.read())

    else:
        pprint(pkg_data)
        raise NotImplementedError(f"Unknown fstype: {pkg_data['fstype']}")

def main():
    parser = argparse.ArgumentParser(prog='create_image',
                                     description='Create system image from upgrade package')
    parser.add_argument('-s', '--image_size', type=int, default=4*1024*1024*1024, help="Image size")
    parser.add_argument('pkg_file', help="upgrade.pkg")
    parser.add_argument('image_file', help="image.bin")
    args = parser.parse_args()

    with open(args.image_file, "wb") as fout:
        fout.truncate(args.image_size)

        # Parse package info from upgrade.bin
        pkg_info = helper.read_ini(args.pkg_file)
        # pprint(pkg_info)

        for pkg_data in pkg_info["pkg"]:
            copy_to_dump(fout, pkg_data)

if __name__ == '__main__':
    main()
