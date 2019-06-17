.PHONY: all
all: fbtoppm reg jzmon gpio

CFLAGS	= -O3 -s

fbtoppm: %: %.c

reg jzmon gpio: %: %.c
	mipsel-linux-gcc $< -o $@ $(CFLAGS)
