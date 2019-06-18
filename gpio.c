// JZ4740 GPIO control

#include <stdio.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <stdint.h>
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
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

int main(int argc, char *argv[])
{
	// Process arguments
	enum {FNone, FInput, FOutput, FInt, FAF} func = FNone;
	int port = -1;
	char v = -1, help = 0;

	char **pv = &argv[0];
	while (argc && --argc) {
		++pv;
		if (strlen(*pv) >= 3 && (*pv)[0] == 'P')
			port = ((*pv)[1] - 'A') * 32 + atoi(*pv + 2);
		else if (strcmp(*pv, "input") == 0)
			func = FInput;
		else if (strcmp(*pv, "output") == 0)
			func = FOutput;
		else if (strcmp(*pv, "int") == 0)
			func = FInt;
		else if (strcmp(*pv, "af") == 0)
			func = FAF;
		else if (strcmp(*pv, "0") == 0)
			v = 0;
		else if (strcmp(*pv, "1") == 0)
			v = 1;
		else
			help = 1;
	}

	// Check for PA0 - PD31
	if (port < 0) {
		help = 1;
	} else if (port >= 4 * 32) {
		printf("Unsupport port specified\n");
		help = 1;
	}

	if (help) {
		printf("Usage: %s"
			" PA0-PD31"
			" [input|output|int|af]"
			" [0|1]\n", argv[0]);
		return 1;
	}

	// Check for operation
	if (func == FNone && v < 0)
		goto op;

	printf("Set P%c%d to ", 'A' + port / 32, port % 32);
	if (func != FNone)
		printf("%s",	func == FInput  ? "input"     :
				func == FOutput ? "output"    :
				func == FInt    ? "interrupt" :
				func == FAF     ? "function"  :
				"Error!");
	if (v >= 0) {
		v = !!v;
		printf(	func == FNone   ? "= %u\n"  :
			func == FInput  ? "\n"      :
			func == FOutput ? " = %u\n" :
			func == FInt    ? " %u\n"   :
			func == FAF     ? " %u\n"   :
			" = %u\n", v);
	} else {
		putchar('\n');
	}

op:	;
        // Open /dev/mem
        int mem = open("/dev/mem", O_RDWR | O_SYNC);
        if (mem == -1) {
                perror("open");
		return 1;
	}

	// APB block from 0x1000_0000 to 0x1100_0000
        void *apb = mmap(0, 0x01000000, PROT_READ | PROT_WRITE, MAP_SHARED, mem, 0x10000000);
        if (apb == (void *)-1) {
                perror("APB mmap");
		return 1;
	}

	struct gpio_t *p = apb + GPIO_BASE - APB_BASE + 0x100 * (port / 32);
	printf("Port %c is now:\n", 'A' + port / 32);
	port = port % 32;

	switch (func) {
	case FNone:
		if (v == 0)
			p->DAT.C = 1ul << port;
		else if (v == 1)
			p->DAT.S = 1ul << port;
		break;
	case FInput:
		p->FUN.C = 1ul << port;
		p->SEL.C = 1ul << port;
		p->DIR.C = 1ul << port;
		break;
	case FOutput:
		if (v == 0)
			p->DAT.C = 1ul << port;
		else if (v == 1)
			p->DAT.S = 1ul << port;
		p->FUN.C = 1ul << port;
		p->SEL.C = 1ul << port;
		p->DIR.S = 1ul << port;
		break;
	case FInt:
		p->FUN.C = 1ul << port;
		p->SEL.S = 1ul << port;
		if (v == 0)
			p->DIR.C = 1ul << port;
		else if (v == 1)
			p->DIR.S = 1ul << port;
		break;
	case FAF:
		p->FUN.S = 1ul << port;
		if (v == 0)
			p->SEL.C = 1ul << port;
		else if (v == 1)
			p->SEL.S = 1ul << port;
		break;
	}

	char buf[2][256] = {0};
	dump_func(buf[0], p->FUN.D, p->SEL.D, p->DIR.D, 0xffffffff);
	dump_bin(buf[1], p->PIN.D, 0xffffffff);
	printf(	ESC_RESET "FUNC: %s" ESC_RESET "\n"
		ESC_RESET "PINV: %s" ESC_RESET "\n", buf[0], buf[1]);

        munmap(apb, 0x01000000);
        close(mem);
        return 0;
}
