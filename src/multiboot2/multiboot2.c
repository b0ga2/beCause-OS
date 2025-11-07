#include <stdint.h>
#include "print.h"

/*
Multiboot2 header and tag structure, according to https://www.gnu.org/software/grub/manual/multiboot2/multiboot.html

Boot information consists of fixed part and a series of tags. Its start is 8-bytes aligned. Fixed part is as following:

        +-------------------+
u32     | total_size        |
u32     | reserved          |
        +-------------------+
‘total_size’ contains the total size of boot information including this field and terminating tag in bytes

‘reserved’ is always set to zero and must be ignored by OS image

Every tag begins with following fields:

        +-------------------+
u32     | type              |
u32     | size              |
        +-------------------+
*/

// TODO: Read https://www.gnu.org/software/grub/manual/multiboot2/multiboot.html#Header-tags (Section 3.6)
struct multiboot2_tag
{
    uint32_t type;
    uint32_t size;
};

struct multiboot2_header
{
    uint32_t total_size;
    uint32_t reserved;

    /*
     * Since the memory is already there, and its passed by the 
     * grub we know that imediatly after the checksum there will be a flag
     * so there is no need to declare the tag structure here, besides we dont know
     * how many flags there are
     */
    
};

void get_multiboot2_header(void *multiboot2)
{
    // Convert the multiboot2 pointer to a pointer to the multiboot2_header struct
    // we have to create another variable since we can't change the type of multiboot2
    struct multiboot2_header * multiboot2_aux = (struct multiboot2_header *) multiboot2;

    print("\n teste\n");
    // Now we have to parse the content
    print_int(multiboot2_aux->total_size);
    print("\n");
    print_int(multiboot2_aux->reserved);

    print("\n após teste");

}