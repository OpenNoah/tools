#!/usr/bin/env python3
import argparse
from pprint import pprint
import helper

page_size = 0
oob_size = 0
erase_size = 0
block_size = 0

def write_page(fout, offset, data):

    def write_fout_page(fout, page_ofs, data):
        fout.seek(page_ofs * block_size)
        fout.write(data)

    # Special consideration for the first 8 pages (16k / 2048)
    page_ofs = offset // page_size
    if page_ofs < 8:
        # JZ4740 can only boot assuming page size = 2048, oob size = 64
        # Fill the first 8 pages with fake page size
        page_ratio = page_size // 2048
        if page_ofs >= 8 // page_ratio:
            # Ignore extra pages
            return
        for page in range(page_ratio):
            outdata = data[2048*page : 2048*(page+1)]
            # Page is valid if one of these three bytes is zero
            outdata += b'\xff\xff\x00\x00\x00\xff'
            # Fake ECC data
            outdata += bytes([0x5a] * (2048 // 512 * 9))
            # Padding to output page+oob size
            outdata += bytes([0xff] * (block_size - len(outdata)))
            # Write to output file
            write_fout_page(fout, page_ofs * page_ratio + page, outdata)
        return

    # Skip empty pages, they have already been erased
    empty = True
    for v in data:
        if v != 0xff:
            empty = False
            break
    if empty:
        return

    # Construct page+oob data
    # Padding to page size
    data += bytes([0xff] * (page_size - len(data)))
    # MTD header
    data += b'\xff\xff\x00\x00\x00\xff'
    # Fake ECC data
    data += bytes([0x5a] * (page_size // 512 * 9))
    # Padding to page+oob size
    data += bytes([0xff] * (block_size - len(data)))
    # Write to output file
    write_fout_page(fout, page_ofs, data);

def copy_to_dump(fout, pkg_data):
    if not pkg_data["include"]:
        return
    if pkg_data["dev"] == "/dev/null":
        return

    if pkg_data["fstype"] == "nor":
        offset = int(pkg_data["dev"], 0)
        print(f"Write {pkg_data['file']} type {pkg_data['fstype']} to {offset:#010x}")
        with open(pkg_data["file"], "rb") as fin:
            while True:
                data = fin.read(page_size)
                if not data:
                    break
                write_page(fout, offset, data)
                offset += page_size

    else:
        pprint(pkg_data)
        raise Exception(f"Unknown fstype: {pkg_data['fstype']}")

def main():
    parser = argparse.ArgumentParser(prog='create_nand_dump',
                                     description='Create NAND dump from upgrade package')
    parser.add_argument('-s', '--nand_size', type=int, default=2*1024*1024*1024, help="NAND size")
    parser.add_argument('-p', '--page_size', type=int, default=4096, help="page size")
    parser.add_argument('-o', '--oob_size', type=int, default=128, help="oob size")
    parser.add_argument('-e', '--erase_pages', type=int, default=128, help="pages in erase block")
    parser.add_argument('pkg_file', help="upgrade.pkg")
    parser.add_argument('nand_file', help="nand_dump.bin")
    args = parser.parse_args()

    global page_size, oob_size, block_size
    page_size = args.page_size
    oob_size = args.oob_size
    erase_size = args.erase_pages * page_size
    block_size = page_size + oob_size
    block_size = (block_size + 3) // 4 * 4

    with open(args.nand_file, "wb") as fout:
        fout.truncate(args.nand_size // page_size * block_size)

        # Erase NAND first
        fout.seek(0)
        data = bytes([0xff] * (page_size + oob_size))
        for _ in range(args.nand_size // page_size):
            fout.write(data)

        # Parse package info from upgrade.bin
        pkg_info = helper.read_ini(args.pkg_file)
        #pprint(pkg_info)

        for pkg_data in pkg_info["pkg"]:
            copy_to_dump(fout, pkg_data)

if __name__ == '__main__':
    main()
