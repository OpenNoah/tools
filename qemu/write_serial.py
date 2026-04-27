#!/usr/bin/env python3
import argparse
from pprint import pprint

page_size = 0
oob_size = 0
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

def main():
    parser = argparse.ArgumentParser(prog='write_serial.py',
                                     description='Write serial number at specified offset')
    parser.add_argument('-p', '--page_size', type=int, default=4096, help="page size")
    parser.add_argument('-o', '--oob_size', type=int, default=128, help="oob size")
    parser.add_argument('offset', help="Serial number data offset")
    parser.add_argument('serial', help="Serial number string")
    parser.add_argument('image_file', help="image.bin")
    args = parser.parse_args()

    global page_size, oob_size, block_size
    page_size = args.page_size
    oob_size = args.oob_size
    block_size = page_size + oob_size
    block_size = (block_size + 3) // 4 * 4

    with open(args.image_file, "r+b") as fout:
        write_page(fout, int(args.offset, 0), args.serial.encode("GBK") + b'\0')

if __name__ == '__main__':
    main()
