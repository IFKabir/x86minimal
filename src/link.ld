/* link.ld — Custom linker script for ZeroRing kernel.
 *
 * Places the kernel at physical address 0x00100000 (1 MB), the conventional
 * start address for protected-mode x86 kernels. Each section is aligned to
 * 4 KB page boundaries.
 *
 * Section Layout:
 *   .text   — Executable code (loader + kernel)
 *   .rodata — Read-only data (string literals, constants)
 *   .data   — Initialized global/static data
 *   .bss    — Uninitialized data (includes kernel stack)
 */

ENTRY(loader)

SECTIONS {
    . = 0x00100000;

    .text ALIGN (0x1000) :
    {
        *(.text)
    }

    .rodata ALIGN (0x1000) :
    {
        *(.rodata*)
    }

    .data ALIGN (0x1000) :
    {
        *(.data)
    }

    .bss ALIGN (0x1000) :
    {
        *(COMMON)
        *(.bss)
    }
}