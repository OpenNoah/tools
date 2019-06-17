// Monitor JZ peripherals (polling)

#include <stdio.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <stdint.h>
#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include "escape.h"

#define _I	const volatile
#define _O	volatile
#define _IO	volatile

#define APB_BASE	0x10000000
#define GPIO_BASE	0x10010000

#pragma packed(push, 1)
struct gpio_t {
	union {
		struct {
			struct gpio_port_t {
				_I uint32_t D;
				_O uint32_t S;
				_O uint32_t C;
				   uint32_t _RESV;
			} PIN, DAT, IM, PE, FUN, SEL, DIR, TRG, FLG;
		};
		struct gpio_port_t RAW[0];
	};
};
#pragma packed(pop)

// Mask out known GPIO ports
uint32_t gpio_mask[4] = {
	0b00000000000000000000000000000000,
	0b01110000000001100000000000000000,
	0b00001000111000111111111100000000,
	//0b11010001110000111100000011111111,
	0b11010001110000010100000001110000,	// Matrix keyboard masked
};

int dump_bin(char *pstr, uint32_t v, uint32_t mask)
{
	if (mask == 0)
		return sprintf(pstr, ESC_BRIGHT_BLACK "----");
	char *_pstr = pstr;
	for (uint32_t i = 0; i < 32; i++, v <<= 1, mask <<= 1) {
		if ((i % 8 == 0) && i != 0)
			pstr += sprintf(pstr, ESC_RESET ESC_UNDERLINE " " ESC_RESET);
		if (!(mask & 0x80000000)) {
			pstr += sprintf(pstr, ESC_BRIGHT_BLACK "-");
			continue;
		}
		pstr += sprintf(pstr, (v & 0x80000000) ? ESC_BRIGHT_WHITE "1"
							: ESC_BRIGHT_BLACK "0");
	}
	return pstr - _pstr;
}

int dump_func(char *pstr, uint32_t fun, uint32_t sel, uint32_t dir, uint32_t mask)
{
	if (mask == 0)
		return sprintf(pstr, ESC_BRIGHT_BLACK "----");
	char *_pstr = pstr;
	for (uint32_t i = 0; i < 32; i++, fun <<= 1, sel <<= 1, dir <<= 1, mask <<= 1) {
		if ((i % 8 == 0) && i != 0)
			pstr += sprintf(pstr, ESC_RESET ESC_UNDERLINE " " ESC_RESET);
		if (!(mask & 0x80000000)) {
			pstr += sprintf(pstr, ESC_BRIGHT_BLACK "-");
			continue;
		}

		const char *s;
		switch (  !!(fun & 0x80000000) * 4
			+ !!(sel & 0x80000000) * 2
			+ !!(dir & 0x80000000)) {
		// GPIO, GPIO, IN
		case 0b000:	s = ESC_BRIGHT_GREEN  "I"; break;
		// GPIO, GPIO, OUT
		case 0b001:	s = ESC_BRIGHT_RED    "O"; break;
		// GPIO,  INT, LOW
		case 0b010:	s = ESC_BRIGHT_BLUE   "v"; break;
		// GPIO,  INT, HIGH
		case 0b011:	s = ESC_BRIGHT_YELLOW "^"; break;
		//   AF,  AF0, -
		case 0b100:
		case 0b101:	s = ESC_BRIGHT_CYAN   "f"; break;
		//   AF,  AF1, -
		case 0b110:
		case 0b111:	s = ESC_BRIGHT_CYAN   "F"; break;
		}
		pstr += sprintf(pstr, s);
	}
	return pstr - _pstr;
}

int gpio_reg_scan(char *pstr, void *apb, uint32_t reg)
{
	char *_pstr = pstr;
	for (uint32_t ip = 0; ip < 4; ip++) {
		struct gpio_t *p = apb + GPIO_BASE - APB_BASE + 0x100 * ip;
		if (ip)
			pstr += sprintf(pstr, ESC_RESET ESC_UNDERLINE "," ESC_RESET);
		pstr += dump_bin(pstr, p->RAW[reg].D, gpio_mask[ip]);
	}
	*pstr++ = '\n';
	return pstr - _pstr;
}

void gpio_scan(void *apb)
{
	static char buf[4096];
	int first = 1;
	for (;;) {
		char *pstr = &buf[0];
		pstr += sprintf(pstr, ESC_RESET "FUNC: ");
		for (uint32_t ip = 0; ip < 4; ip++) {
			struct gpio_t *p = apb + GPIO_BASE - APB_BASE + 0x100 * ip;
			if (ip)
				pstr += sprintf(pstr, ESC_RESET ESC_UNDERLINE "," ESC_RESET);
			pstr += dump_func(pstr, p->FUN.D, p->SEL.D, p->DIR.D, gpio_mask[ip]);
		}
		*pstr++ = '\n';
		struct gpio_t *p = 0;
		pstr += sprintf(pstr, ESC_RESET "PINV: ");
		pstr += gpio_reg_scan(pstr, apb, &p->PIN - &p->RAW[0]);
		printf("%s", first ? "" : ESC_CURSOR_UP(2));
		printf("%s", buf);
		first = 0;
		//usleep(10 * 1000);
	}
}

int main(int argc, char *argv[])
{
        // Open /dev/mem
        int mem = open("/dev/mem", O_RDWR | O_SYNC);
        if (mem == -1) {
                perror("open");
		return 1;
	}

	// APB block from 0x1000_0000 to 0x1100_0000
        void *apb = mmap(0, 0x01000000, PROT_READ | PROT_WRITE, MAP_SHARED, mem, 0x10000000);
        if (apb == (void *)-1) {
                perror("APB");
		return 1;
	}

	printf("\033[?25l");
	gpio_scan(apb);

        munmap(apb, 0x01000000);
        close(mem);
        return 0;
}
