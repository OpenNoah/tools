.PHONY: all
all: fbtoppm reg jzmon

CFLAGS	= -O3 -s

fbtoppm: fbtoppm.c

reg jzmon: %: %.c
	mipsel-linux-gcc $< -o $@ $(CFLAGS)
