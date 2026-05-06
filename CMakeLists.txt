cmake_minimum_required(VERSION 3.16)
project(x86minimal NONE)

# ── Paths ────────────────────────────────────────────────────
set(SRC_DIR       ${CMAKE_CURRENT_SOURCE_DIR}/src)
set(GRUB_DIR      ${CMAKE_CURRENT_SOURCE_DIR}/grub)
set(LINKER_SCRIPT ${SRC_DIR}/link.ld)

# ── Source files ─────────────────────────────────────────────
set(ASM_SRC ${SRC_DIR}/loader.s)
set(CXX_SRC ${SRC_DIR}/kmain.cpp)

# ── Freestanding i386 C++ flags ───────────────────────────────
set(CXX_FLAGS
    -m32
    -ffreestanding
    -fno-builtin
    -fno-stack-protector
    -fno-exceptions
    -fno-rtti
    -nostdlib
    -nostdinc
    -nostartfiles
    -nodefaultlibs
    -Wall -Wextra -Werror
)

# ── Step 1: Assemble loader.s → loader.o ─────────────────────
set(ASM_OBJ ${CMAKE_CURRENT_BINARY_DIR}/loader.o)
add_custom_command(
    OUTPUT  ${ASM_OBJ}
    COMMAND nasm -f elf32 ${ASM_SRC} -o ${ASM_OBJ}
    DEPENDS ${ASM_SRC}
    COMMENT "[NASM] Assembling loader.s"
    VERBATIM
)

# ── Step 2: Compile kmain.cpp → kmain.o ──────────────────────
set(CXX_OBJ ${CMAKE_CURRENT_BINARY_DIR}/kmain.o)
add_custom_command(
    OUTPUT  ${CXX_OBJ}
    COMMAND g++ ${CXX_FLAGS} -c ${CXX_SRC} -o ${CXX_OBJ}
    DEPENDS ${CXX_SRC}
    COMMENT "[G++]  Compiling kmain.cpp"
    VERBATIM
)

# ── Step 3: Link → kernel.elf ────────────────────────────────
set(KERNEL_ELF ${CMAKE_CURRENT_BINARY_DIR}/kernel.elf)
add_custom_command(
    OUTPUT  ${KERNEL_ELF}
    COMMAND ld -T ${LINKER_SCRIPT} -melf_i386 ${ASM_OBJ} ${CXX_OBJ} -o ${KERNEL_ELF}
    DEPENDS ${ASM_OBJ} ${CXX_OBJ} ${LINKER_SCRIPT}
    COMMENT "[LD]   Linking kernel.elf"
    VERBATIM
)
add_custom_target(kernel ALL DEPENDS ${KERNEL_ELF})

# ── Step 4: Build bootable ISO ───────────────────────────────
set(ISO_DIR  ${CMAKE_CURRENT_BINARY_DIR}/isodir)
set(ISO_FILE ${CMAKE_CURRENT_BINARY_DIR}/os.iso)
set(GRUB_CFG ${GRUB_DIR}/grub.cfg)

add_custom_command(
    OUTPUT  ${ISO_FILE}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${ISO_DIR}/boot/grub
    COMMAND ${CMAKE_COMMAND} -E copy ${KERNEL_ELF} ${ISO_DIR}/boot/kernel.elf
    COMMAND ${CMAKE_COMMAND} -E copy ${GRUB_CFG}   ${ISO_DIR}/boot/grub/grub.cfg
    COMMAND grub-mkrescue -o ${ISO_FILE} ${ISO_DIR}
    DEPENDS kernel ${GRUB_CFG}
    COMMENT "[ISO]  Generating os.iso"
    VERBATIM
)
add_custom_target(iso ALL DEPENDS ${ISO_FILE})

# ── Run targets ───────────────────────────────────────────────
add_custom_target(run-qemu
    COMMAND qemu-system-i386 -cdrom ${ISO_FILE}
    DEPENDS iso
    COMMENT "Launching QEMU..."
    USES_TERMINAL
)

add_custom_target(run-bochs
    COMMAND bochs -f ${CMAKE_CURRENT_SOURCE_DIR}/bochsrc.txt -q
    DEPENDS iso
    COMMENT "Launching Bochs..."
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    USES_TERMINAL
)
