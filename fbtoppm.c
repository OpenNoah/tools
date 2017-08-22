#include <stdio.h>
#include <stdint.h>

int main()
{
	const int w = 320, h = 240;
	long i;
	printf("P6 %d %d 255\n", w, h);
	for (i = 0; i != w * h; i++) {
		uint8_t c[4];
		int i;
		for (i = 0; i != 4; i++)
			c[i] = getchar();
		putchar(c[2]);
		putchar(c[1]);
		putchar(c[0]);
	}
	fflush(stdout);
	return 0;
}
