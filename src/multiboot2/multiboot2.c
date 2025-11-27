#include <stdint.h>
#include "print.h"

// Interesting reading: https://wiki.osdev.org/Multiboot

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

There are several tags, that are identified by the type
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
    // Verify if the address is aligned with 8 bytes, with an AND with the value 7 (0b111 verifies that)
    // a pointer in x86_64 is always 64 bits
    if((uint64_t)multiboot2 & 7)
    {
        print("The pointer address is not aligned");
        return;
    }

    // Convert the multiboot2 pointer to a pointer to the multiboot2_header struct
    // we have to create another variable since we can't change the type of multiboot2
    struct multiboot2_header * multiboot2_aux = (struct multiboot2_header *) multiboot2;

    // Now we have to start parsing tha multiboot tags, so what we do is add to the pointer the size of the
    // multiboot header, since after the header comes the flags
    multiboot2 += sizeof(struct multiboot2_header);

    struct multiboot2_tag * multiboot2_tag = (struct multiboot2_tag *) multiboot2;

    print_int(multiboot2_tag->type);


    // Now we have to parse the content
    print_int(multiboot2_aux->total_size);
    print("\n");
    print_int(multiboot2_aux->reserved);

}