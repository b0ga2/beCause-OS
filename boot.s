.code32 # To define the assembly file as a 32 bit

# TODO: Comment what each section is

# Multiboot2 - It's a protocol between GRUB and the kernel that defines 
# how the kernel is loaded, what memory layout GRUB passes to it, etc.

/* Declare constants for the multiboot2 header. */
.set HEADER_LENGHT, header_end - header_start  				/* Little smart way to use labels to know the size of the multiboot header */
.set ARCHITECTURE,  0<<0			              		    /* specifies the endianness ISAs */
.set MAGIC,         0xE85250D6                 				/* 'magic number' lets bootloader find the header */
.set CHECKSUM,      -(HEADER_LENGHT + MAGIC + ARCHITECTURE) /* checksum of above, to prove we are multiboot2 */

/*Declare the constants for verifying the CPUID*/
.set CPUID_EXTENSIONS, 0x80000000 # returns the maximum extended requests for cpuid
.set CPUID_EXT_FEATURES,  0x80000001 # returns flags containing long mode support among 

/* 
Declare a multiboot2 header that marks the program as a kernel. These are magic
values that are documented in the multiboot2 standard. The bootloader will
search for this signature in the first 8 KiB of the kernel file, aligned at a
32-bit boundary. The signature is in its own section so the header can be
forced to be within the first 8 KiB of the kernel file.
*/
.section .multiboot2
header_start: 
.align 4
/*Has to be in the specific order of the specification*/
.long MAGIC
.long ARCHITECTURE
.long HEADER_LENGHT
.long CHECKSUM
# Tags has to be 8-bytes aligned address
# and since we dont need a tag we just declared the end flag (tag of type ‘0’ and size ‘8’)
.word 0 # Represents the TYPE of the struct TAG
.word 0 # Represents the FLAGS of the struct TAG
.long 8 # Represents the FLAGS of the struct TAG (32 bits -> 4 bytes)
header_end:

/*
The multiboot2 standard does not define the value of the stack pointer register
(esp) and it is up to the kernel to provide a stack. This allocates room for a
small stack by creating a symbol at the bottom of it, then allocating 16384
bytes for it, and finally creating a symbol at the top. The stack grows
downwards on x86. The stack is in its own section so it can be marked nobits,
which means the kernel file is smaller because it does not contain an
uninitialized stack. The stack on x86 must be 16-byte aligned according to the
System V ABI standard and de-facto extensions. The compiler will assume the
stack is properly aligned and failure to align the stack will result in
undefined behavior.
*/
.section .bss
.align 16
stack_bottom:
.skip 16384 # 16 KiB
stack_top:
page_table4:
.skip 4096
page_table3:
.skip 4096
page_table2:
.skip 4096
page_table1:
.skip 4096 * 256

/*
The linker script specifies _start as the entry point to the kernel and the
bootloader will jump to this position once the kernel has been loaded. It
doesn't make sense to return from this function as the bootloader is gone.
*/
.section .text
.global _start
.type _start, @function

check_multiboot:
	cmpl $0x36d76289, %eax
	jne error
	ret

	error:
		hlt
		# TODO: Decide on a funny way to return a error 

# To test the CPUID command.
# The () on the registers are used to dereference
verify_cpuid:
	pushf								# Save EFLAGS
    pushf                               # Push EFLAGS to the stack
    xorl $0x00200000, (%esp)            # Invert the ID bit (bit 21) in stored EFLAGS
    popf                                # Load modified EFLAGS (with ID bit inverted)
    pushf                               # Store modified EFLAGS back onto the stack
    popl %eax                           # Load modified EFLAGS into EAX
    xorl (%esp), %eax                   # XOR original with modified to detect change
    popf                                # Restore original EFLAGS
    andl $0x00200000, %eax              # Check if ID bit was actually changed
	jz cpuid_not_supported
	ret

		cpuid_not_supported:
			hlt
			# TODO: Decide on a funny way to return a error 

call_cpuid_to_check_longmode:
	# to check if the extended function that checks long mode support is available
	movl $CPUID_EXTENSIONS, %eax
	cpuid 
	cmpl $CPUID_EXT_FEATURES, %eax
	jb no_longmode_supported
	
	# the extended function can be used to check for long mode support
	movl $CPUID_EXT_FEATURES, %eax
	cpuid
	testl $CPUID_EXT_FEATURES, %edx
	jz no_longmode_supported
	ret

		no_longmode_supported:
			hlt

enable_64_bit_paging:
	# Skip these 3 lines if paging is already disabled
	movl %cr0, %ebx
	andl  ~(1 << 31), %ebx
	movl %ebx, %cr0

	# Enable Physical Address Extension
	movl %cr4, %edx
	orl  (1 << 5), %edx
	movl %edx, %cr4

	# Set LME (long mode enable)
	movl 0xC0000080, %ecx
	rdmsr # used to read to model-specific registers (MSRs) in computer hardware
	orl  (1 << 8), %eax
	wrmsr # used to write to model-specific registers (MSRs) in computer hardware

	# Replace 'pml4_table' with the appropriate physical address (and flags, if applicable)
	movl $pml4_table, %eax
	movl %eax, %cr3

	# Enable paging (and protected mode, if it isn't already active)
	orl (1 << 31) | (1 << 0), %ebx
	movl %ebx, %cr0
	ret
		
_start:
	/*
	The bootloader has loaded us into 32-bit protected mode on a x86
	machine. Interrupts are disabled. Paging is disabled. The processor
	state is as defined in the multiboot standard. The kernel has full
	control of the CPU. The kernel can only make use of hardware features
	and any code it provides as part of itself. There's no printf
	function, unless the kernel provides its own <stdio.h> header and a
	printf implementation. There are no security restrictions, no
	safeguards, no debugging mechanisms, only what the kernel provides
	itself. It has absolute and complete power over the
	machine.
	*/

	/*
	To set up a stack, we set the esp register to point to the top of the
	stack (as it grows downwards on x86 systems). This is necessarily done
	in assembly as languages such as C cannot function without a stack.
	*/

	# Registers Calling Convention (32 bits) EDI, ESI, EDX, ECX
	movl $stack_top, %esp
	movl %ebx, %edi # This will be a pointer to my multiboot structure to be later used in C
	call check_multiboot
	call verify_cpuid
	call call_cpuid_to_check_longmode
	# TODO: Enter Long  (https://wiki.osdev.org/Setting_Up_Long_Mode)
	

	/*
	This is a good place to initialize crucial processor state before the
	high-level kernel is entered. It's best to minimize the early
	environment where crucial features are offline. Note that the
	processor is not fully initialized yet: Features such as floating
	point instructions and instruction set extensions are not initialized
	yet. The GDT should be loaded here. Paging should be enabled here.
	C++ features such as global constructors and exceptions will require
	runtime support to work as well.
	*/

	/*
	Enter the high-level kernel. The ABI requires the stack is 16-byte
	aligned at the time of the call instruction (which afterwards pushes
	the return pointer of size 4 bytes). The stack was originally 16-byte
	aligned above and we've pushed a multiple of 16 bytes to the
	stack since (pushed 0 bytes so far), so the alignment has thus been
	preserved and the call is well defined.
	*/
	# call kernel_main

	/*
	If the system has nothing more to do, put the computer into an
	infinite loop. To do that:
	1) Disable interrupts with cli (clear interrupt enable in eflags).
	   They are already disabled by the bootloader, so this is not needed.
	   Mind that you might later enable interrupts and return from
	   kernel_main (which is sort of nonsensical to do).
	2) Wait for the next interrupt to arrive with hlt (halt instruction).
	   Since they are disabled, this will lock up the computer.
	3) Jump to the hlt instruction if it ever wakes up due to a
	   non-maskable interrupt occurring or due to system management mode.
	*/
	cli
1:	hlt
	jmp 1b

/*
Set the size of the _start symbol to the current location '.' minus its start.
This is useful when debugging or when you implement call tracing.
*/
.size _start, . - _start
