#include "utilities.h"

size_t strlen(char * string)
{
    size_t count = 0;

    // First verify if is not null
    if (string == NULL)
    {
        return 0;
    }

    //Iterate until we find the null byte
    while (string[count] != '\0')
    {
        count++;
    }
    
    return count;
    
}

// I will use this when an "error" or something that isnt supposed to happen, happens :')
// this way the system will stop and its easier to find the little bastard
void halt(void ){
    __asm__ ("hlt");
}