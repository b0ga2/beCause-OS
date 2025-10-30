#include <stdint.h>

/*
Multiboot2 header and tag structure, according to https://www.gnu.org/software/grub/manual/multiboot2/multiboot.html

Offset	Type    Field Name	    Note
0	    u32	    magic	        required
4	    u32	    architecture	required
8	    u32	    header_length	required
12	    u32	    checksum	    required
16-XX		    tags	        required

                +-------------------+
        u16     | type              |
        u16     | flags             |
        u32     | size              |
                +-------------------+
*/
struct multiboot2_tag
{
    uint16_t type;
    uint16_t flag;
    uint32_t size;

};

struct multiboot2_header
{
    uint32_t magic;
    uint32_t architecture;
    uint32_t header_lenght;
    uint32_t checksum;
};

void get_multiboot2_header(void *multiboot2)
{
}