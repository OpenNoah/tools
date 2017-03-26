/*
 * Check/modify memory addresses (registers) using memmap() and /dev/mem
 * Author: Yubo Zhi (normanzyb@gmail.com)
 */

#include <stdio.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>

int main(int argc, char *argv[])
{
        if (argc != 2 && argc != 3)
                return 1;

        static const unsigned int block = 8192u;
        void *ptr = (void *)strtol(argv[1], NULL, 16);
        unsigned int base = (unsigned int)ptr & ~(block - 1u);
        unsigned int offset = (unsigned int)ptr & (block - 1u);

        /* Open /dev/mem */
        int mem = open("/dev/mem", O_RDWR | O_SYNC);
        if (mem == -1)
                perror("open");

        //printf("map: %u@%p\n", block, (void *)base);
        void *p = mmap(0, block, PROT_READ | PROT_WRITE, MAP_SHARED, mem, base);
        if (p == (void *)-1)
                perror("mmap");

        unsigned int *value = (unsigned int *)(p + offset);
        printf("*%p = 0x%08x (%u)\n", ptr, *value, *value);

        if (argc == 3) {
                *value = (unsigned int)strtol(argv[2], NULL, 16);
                printf("*%p = 0x%08x (%u)\n", ptr, *value, *value);
        }

        munmap(p, block);
        close(mem);
        return 0;
}
