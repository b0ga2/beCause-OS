.code32 # To define the assembly file as a 32 bit

# TODO: Comment what each section is

# Multiboot2 - It's a protocol between GRUB and the kernel that defines 
# how the kernel is loaded, what memory layout GRUB passes to it, etc.

/* Declare constants for the multiboot2 header. */
.set HEADER_LENGHT, header_end - header_start  				/* Little smart way to use labels to know the size of the multiboot header */
.set ARCHITECTURE,  0<<0		 	             		    /* specifies the endianness ISAs */
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

.section .rodata
# In this section I will fill the GDT
# No need to align since thats done in the linker

# The first entry of the GDT is NULL
beggining_gdt:
.quad 0

# To define a code segment (64 bits) we use quad
# From the Acess Byte the following bits are set to 1 : P(47), S(44), E(43), RW(41)
# From the Flags bits are set to 1: L(53)
# Since the Limit and the Base are zero, they are defined implicitly
.quad 1<<47 | 1<<44 | 1<<43 | 1<<41 | 1<<53
ending_gdt:

# To see more https://wiki.osdev.org/Global_Descriptor_Table#System_Segment_Descriptor

# To define GDTR 
gdtr_label:
# To define the SIZE
.word ending_gdt - beggining_gdt -1
# To define the OFFSET, it will be the same as virtual address since I'm using Identity mapping
.quad beggining_gdt

.section .bss
.align 16
stack_bottom:
.skip 16384 # 16 KiB
stack_top:
.align 4096
page_table4:
.skip 4096
page_table3:
.skip 4096
page_table2:
.skip 4096
page_table1: # To be able to map 512 MBs, each table has 512 entries, each entry is 8 bytes and can map 4096 Bytes in RAM
.skip 4096 * 256

/*
This is the base addr used to modify the Page Tables themselves using recursive mapping:
0o177777_777_777_777_777_0000 = 0xffff ffff ffff f000
0o177777 is just the extension to 64 bits*
This are the addresses that must be used to access the page tables themselves.
+-------+-------------------------------+-------------------------------------+
| Table | Address                       | Indexes                             |
| P4    | 0o177777_777_777_777_777_0000 | –                                   |
| P3    | 0o177777_777_777_777_XXX_0000 | XXX is the P4 index                 |
| P2    | 0o177777_777_777_XXX_YYY_0000 | like above, and YYY is the P3 index |
| P1    | 0o177777_777_XXX_YYY_ZZZ_0000 | like above, and ZZZ is the P2 index |
+-------+-------------------------------+-------------------------------------+
As it can be seen, the addresses may be calculated with the following formula:
next_table_address = (table_address << 9) | (index << 12)
The _0000 at the end of the addrs means that they are page table aligned and
may be used as indexes to read/write from/to a page table.
For more information:
https://os.phil-opp.com/page-tables/#mapping-page-tables
https://wiki.osdev.org/User:Neon/Recursive_Paging
*/

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

# Long mode is the usage of 64 bits variables
call_cpuid_to_check_longmode:
	# to check if the extended function that checks long mode support is available
	movl $CPUID_EXTENSIONS, %eax
	cpuid 
	cmpl $CPUID_EXT_FEATURES, %eax
	jb no_longmode_supported
	
	# the extended function can be used to check for long mode support
	movl $CPUID_EXT_FEATURES, %eax
	cpuid
	testl $(1 << 29), %edx
	jz no_longmode_supported
	ret

		no_longmode_supported:
			hlt

enable_64_bit_paging:
	# Skip these 3 lines if paging is already disabled
	# movl %cr0, %ebx
	# andl  ~(1 << 31), %ebx
	# movl %ebx, %cr0

	# Replace 'page_table4' with the appropriate physical address (and flags, if applicable)
	movl $page_table4, %eax
	movl %eax, %cr3

	# Enable Physical Address Extension, TODO: See what PAE means
	movl %cr4, %eax
	orl  $(1 << 5), %eax
	movl %eax, %cr4

	# Set LME (long mode enable)
	movl $0xC0000080, %ecx
	rdmsr # used to read to model-specific registers (MSRs) in computer hardware
	orl $(1 << 8), %eax
	orl $(1 << 11), %eax
	wrmsr # used to write to model-specific registers (MSRs) in computer hardware

	# Enable paging (and protected mode, if it isn't already active)
	movl %cr0, %eax
	orl $(1 << 31), %eax
	orl $(1 << 16), %eax
	movl %eax, %cr0


	ret

recursive_paging:
	movl $page_table4, %eax

	# To define write/read and present permissions 
	# (see https://wiki.osdev.org/Paging#/media/File:64-bit_page_tables1.png)
	orl $0b11, %eax # equivalent to (0b0000000000000000000011) the $ is needed to the assembly doesnt try to read that address

	# To insert the address of p4 in the last entrie of p4 
	movl %eax, page_table4 + (511 * 8)
	
	ret


fill_page_tables:
    # Set up P4 entry 0 to point to P3
    movl $page_table3, %eax
    orl $0b11, %eax
    movl %eax, page_table4
    
    # Set up P3 entry 0 to point to P2  
    movl $page_table2, %eax
    orl $0b11, %eax
    movl %eax, page_table3
    
    # Set up P2 entries to point to P1 tables
    movl $0, %ebx
p2_loop:
    cmpl $256, %ebx
    jge end_p2_loop
    
    # Calculate P1 table address
    movl $page_table1, %eax
    movl %ebx, %ecx
    imull $4096, %ecx, %ecx  # Each P1 table is 4096 bytes
    addl %ecx, %eax
    orl $0b11, %eax
    movl %eax, page_table2(,%ebx,8)
    
    # Fill P1 table with identity mappings
    movl $0, %eax
p1_loop:
    cmpl $512, %eax
    jge end_p1_loop
    
    # Calculate physical address: (ebx * 512 + eax) * 4096
    movl %ebx, %ecx
    shll $9, %ecx      # ebx * 512
    addl %eax, %ecx    # + eax
    shll $12, %ecx     # * 4096
    orl $0b11, %ecx    # Present + writable
    
    # Calculate P1 entry address
    movl $page_table1, %edx
    movl %ebx, %esi
    imull $4096, %esi, %esi
    addl %edx, %esi
    movl %ecx, (%esi,%eax,8)
    
    addl $1, %eax
    jmp p1_loop
    
end_p1_loop:
    addl $1, %ebx
    jmp p2_loop
    
end_p2_loop:
    ret

load_GDT:
	# TODO: Read https://wiki.osdev.org/GDT_Tutorial and https://wiki.osdev.org/Global_Descriptor_Table#System_Segment_Descriptor later
	lgdt gdtr_label
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

	# This will be a pointer to my multiboot structure to be later used in C
	# the register edi, im passing the first argument to C
	movl %ebx, %edi
	
	call check_multiboot
	call verify_cpuid
	call call_cpuid_to_check_longmode
	call recursive_paging
	call fill_page_tables # Map Page Tables
	call enable_64_bit_paging
	call load_GDT  # To load the GDT

	# Enter Long  (https://wiki.osdev.org/Setting_Up_Long_Mode)
	ljmp $0x08, $_start_long_mode

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
	*/
	cli
	hlt

.code64 # This defines that all code after is written in 64 bits

.section .text
_start_long_mode:
	movq $0, %rax 
    movq %rax, %ds
    movq %rax, %es
    movq %rax, %fs
    movq %rax, %gs
    movq %rax, %ss

	call main
	hlt

