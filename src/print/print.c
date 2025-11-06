#include <stddef.h>
#include <stdint.h>
#include <string.h>


#define PORT 0x3f8 // COM1

// TODO: Read https://wiki.osdev.org/Bare_Bones#Writing_a_kernel_in_C
// https://wiki.osdev.org/Inline_Assembly/Examples
static inline void outb(uint16_t port, uint8_t val)
{
    __asm__ volatile("outb %b0, %w1" : : "a"(val), "Nd"(port) : "memory");
    /* There's an outb %al, $imm8 encoding, for compile-time constant port numbers that fit in 8b. (N constraint).
     * Wider immediate constants would be truncated at assemble-time (e.g. "i" constraint).
     * The  outb  %al, %dx  encoding is the only option for all other cases.
     * %1 expands to %dx because  port  is a uint16_t.  %w1 could be used if we had the port number a wider C type */
}

static inline uint8_t inb(uint16_t port)
{
    uint8_t ret;
    __asm__ volatile("inb %w1, %b0"
                     : "=a"(ret)
                     : "Nd"(port)
                     : "memory");
    return ret;
}

// Has to be before the in and out commands since it uses
int init_serial()
{
    outb(PORT + 1, 0x00); // Disable all interrupts
    outb(PORT + 3, 0x80); // Enable DLAB (set baud rate divisor)
    outb(PORT + 0, 0x03); // Set divisor to 3 (lo byte) 38400 baud
    outb(PORT + 1, 0x00); //                  (hi byte)
    outb(PORT + 3, 0x03); // 8 bits, no parity, one stop bit
    outb(PORT + 2, 0xC7); // Enable FIFO, clear them, with 14-byte threshold
    outb(PORT + 4, 0x0B); // Interrup Requets enabled, RTS/DSR set

    outb(PORT + 4, 0x1E); // Set in loopback mode, test the serial chip
    outb(PORT + 0, 0xAE); // Test serial chip (send byte 0xAE and check if serial returns same byte)

    // Check if serial is faulty (i.e: not same byte as sent)
    if (inb(PORT + 0) != 0xAE)
    {
        return 1;
    }

    // If serial is not faulty set it in normal operation mode
    // (not-loopback with IRQs enabled and OUT#1 and OUT#2 bits enabled)
    outb(PORT + 4, 0x0F);
    return 0;
}

// To verify if the serial port is busy
int serial_received()
{
    return inb(PORT + 5) & 1;
}

// Self-explanatory
char read_serial()
{
    while (serial_received() == 0);

    return inb(PORT);
}

// To verify if there is anything to print
int is_transmit_empty()
{
    return inb(PORT + 5) & 0x20;
}

// Self-explanatory
void write_serial(char a)
{
    while (is_transmit_empty() == 0);

    outb(PORT, a);
}


void print_char(char character)
{
    outb(PORT,character);
}

// TODO: Read https://wiki.osdev.org/Formatted_Printing
void print(char * string)
{
    //Writes this value in static memory (stays inside the executable)
    // it points to the first char of my string
    // char * string = "stringTest";

    for (size_t i = 0; i < strlen(string); i++)
    {
       print_char(string[i]);
    }
}



// For now it can be for unsigned
void print_int (uint64_t integer)
{
    char buffer[12];
    int i = 0;

    // Verify if the value is not zero
    if (integer == 0) {
        print("0");
        return;
    }
    
    // We write the buffer backwards
    while (integer > 0) {
        // Get the last digit of the number.
        // Example: if integer = 1234, then integer % 10 = 4
        buffer[i++] = '0' + (integer % 10);

        // Remove the last digit from the number.
        // Example: integer = 1234 / 10 = 123
        integer /= 10;
    }
    
    // Since the buffer is written backwards we read it backwards
    while (i > 0)
    {
        print_char(buffer[--i]);
    }
    
}