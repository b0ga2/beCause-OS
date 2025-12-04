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

There are several tags, that are identified by the type, the one with the type 0 is the end
*/



// TODO: Read https://www.gnu.org/software/grub/manual/multiboot2/multiboot.html#Header-tags (Section 3.6)
struct multiboot2_tag
{
    uint32_t type;
    uint32_t size;
};

// Tag with the type 1
struct multiboot2_boot_command_line
{
    uint32_t type;
    uint32_t size;
    // It has a third member that is a uint_8t char array
};

// Tag with the type 2
struct multiboot2_boot_loader_name
{
    uint32_t type;
    uint32_t size;
    // It has a third member that is a uint_8t char array
};

// Tag with the type 4
struct multiboot2_basic_memory_information
{
    uint32_t type;
    uint32_t size;
    uint32_t mem_lower;
    uint32_t mem_upper;
};

// Tag with the type 5
struct multiboot2_bios_boot_device
{
    uint32_t type;
    uint32_t size;
    uint32_t biosdev;
    uint32_t partition;
    uint32_t sub_partition;
};

//Used in the tag of type 6
struct entry
{
    uint64_t base_addr;
    uint64_t lenght;
    uint32_t type;
    uint32_t reserved;
};

// Tag with the type 6
struct multiboot2_memory_map
{
    uint32_t type;
    uint32_t size;
    uint32_t entry_size;
    uint32_t entry_version;
    // It has a fifth member which is the entries, but like the tags we dont know
};


// Tag with the type 8
struct multiboot2_framebuffer_info
{
    uint32_t type;
    uint32_t size;
    uint64_t framebuffer_addr;
    uint32_t framebuffer_pitch;
    uint32_t framebuffer_widht;
    uint32_t framebuffer_height;
    uint8_t framebuffer_bpp;
    uint8_t framebuffer_type;
    uint8_t reserved;
    // TODO: Finish this structure
    
};

// Interesting reading: https://refspecs.linuxbase.org/elf/gabi4+/ch4.sheader.html
// Tag with the type 9
struct multiboot2_elf_symbols
{
    uint32_t type;
    uint32_t size;
    uint16_t num;
    uint16_t entsize;
    uint16_t shndx;
    uint16_t reserved;
    // It has a seventh member which is the section header more info see the interesting reading above
};


// Tag with the type 10
struct multiboot2_apm_table
{
    uint32_t type;
    uint32_t size;
    uint16_t version;
    uint16_t cseg;
    uint32_t offset;
    uint16_t cseg_16;
    uint16_t flags;
    uint16_t cseg_len;
    uint16_t cseg_16_len;
    uint16_t dseg_len;

};

// Tag with the type 21
struct multiboot2_tag_image_load_base_physical_address
{
    uint32_t type;
    uint32_t size;
    uint32_t load_base_addr;
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

    // This is a way to parse the first tag, by telling C we are now pointing to this structure
    struct multiboot2_tag * multiboot2_tag = (struct multiboot2_tag *) multiboot2;

    while(multiboot2_tag->type != 0){

        print("\nType of tag to be parsed:");
        print_int(multiboot2_tag->type);
        print("\n");

        // Based on the type of the tag we parse accordingly
        switch (multiboot2_tag->type)
        {

        case 1:
            struct multiboot2_boot_command_line * multiboot2_tag_1 = (struct multiboot2_boot_command_line *) multiboot2_tag;     
            
            // This is a way to go to the string value that is passed through the kernel
            // print((char *)(multiboot2_tag_1 + 1));
            
            print("Tag of type 1 parsed succefully\n\n");
            break;  
           
        case 2:
            struct multiboot2_boot_loader_name * multiboot2_tag_2 = (struct multiboot2_boot_loader_name *) multiboot2_tag;     
            
            // This is a way to go to the string value that is passed from grub
            print((char *)(multiboot2_tag_2 + 1));

            print("Tag of type 2 parsed succefully\n\n");
            break; 

        case 4:
            struct multiboot2_basic_memory_information * multiboot2_tag_4 = (struct multiboot2_basic_memory_information *) multiboot2_tag;     

            print("Tag of type 4 parsed succefully\n\n");
            break; 

        case 5:
            struct multiboot2_bios_boot_device * multiboot2_tag_5 = (struct multiboot2_bios_boot_device *) multiboot2_tag;     

            print("Tag of type 5 parsed succefully\n\n");
            break; 

        case 6:
            struct multiboot2_memory_map * multiboot2_tag_6 = (struct multiboot2_memory_map *) multiboot2_tag;     

            print("Tag of type 6 parsed succefully\n\n");
            break;  
            
        case 8:
            struct multiboot2_memory_map * multiboot2_tag_8 = (struct multiboot2_memory_map *) multiboot2_tag;     

            print("Tag of type 8 parsed succefully\n\n");
            break;

        case 9:
            struct multiboot2_elf_symbols * multiboot2_tag_9 = (struct multiboot2_elf_symbols *) multiboot2_tag;     

            print("Tag of type 9 parsed succefully\n\n");
            break;  

        case 10:
            struct multiboot2_apm_table * multiboot2_tag_10 = (struct multiboot2_apm_table *) multiboot2_tag;     

            print("Tag of type 10 parsed succefully\n\n");
            break;

        case 14:
            //struct multiboot2_apm_table * multiboot2_tag_14 = (struct multiboot2_apm_table *) multiboot2_tag;

            print("Tag of type 14 parsed wasnt parsed due to it being legacy\n\n");
            break;

        case 21:
            struct multiboot2_tag_image_load_base_physical_address * multiboot2_tag_21 = (struct multiboot2_tag_image_load_base_physical_address *) multiboot2_tag;     
            print("Tag of type 21 parsed succefully\n\n");
            break;
        
        default:
            break;
        }

        // We can't just parse the next tag, due to the aligment
        multiboot2_tag = ((void *)multiboot2_tag) + ((multiboot2_tag->size + 7) & ~7);
    }

    // Now we have to parse the content
    print_int(multiboot2_aux->total_size);
    print("\n");
    print_int(multiboot2_aux->reserved);

}