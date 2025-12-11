#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#include "multiboot2.h"
#include "print.h"
#include "utilities.h"
#include "vga.h"

// Every function needs to be declared before this one
// Useful link for C functions: https://wiki.osdev.org/Meaty_Skeleton#libc/string/strlen.c
void main(void *multiboot2)
{
    // To initialize the serial port for debugging
    init_serial();

    // Now in order to have memory allocation, the first step is to parse the content given by multiboot2

    // First we verify if the reference is not null
    if (multiboot2 == NULL)
    {
        print("Multiboot2 structure is null");
        halt();
    }

    // Since it's not null we can start parsing the header
    get_multiboot2_header(multiboot2);
    
    write_string(4,"Hello World\n\n\n\n\n\n\n\n\n\n\n");

    // Can't end on a return, since there is no place to return
    while (1);
}
