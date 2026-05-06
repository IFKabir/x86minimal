; ─────────────────────────────────────────────────────────────
; loader.s — Multiboot-compliant assembly entry point for ZeroRing
;
; Provides the initial boot code that GRUB transfers control to.
; Sets up the Multiboot header, allocates a 4 KB kernel stack in
; BSS, and calls into C++ kernel code.
;
; Boot flow:
;   1. GRUB loads kernel ELF, validates Multiboot header
;   2. Control transfers to `loader`
;   3. ESP set to top of kernel_stack (4096 bytes)
;   4. sum_of_three(1, 2, 3) called as stack/ABI test
;   5. CPU enters infinite loop (halt)
; ─────────────────────────────────────────────────────────────

global loader

MAGIC_NUMBER equ 0x1BADB002
FLAGS equ 0x0
CHECKSUM equ -MAGIC_NUMBER

KERNEL_STACK_SIZE equ 4096

section .multiboot
align 4
    dd MAGIC_NUMBER
    dd FLAGS
    dd CHECKSUM

section .bss
align 4
kernel_stack:
    resb KERNEL_STACK_SIZE

section .text
extern kmain
extern sum_of_three

loader:
    mov esp, kernel_stack + KERNEL_STACK_SIZE

    push dword 3
    push dword 2
    push dword 1
    call sum_of_three

    ; call kmain

.loop:
    jmp .loop