# ══════════════════════════════════════════════════════════════
#  ZeroRing — Bare-metal i386 Kernel
# ══════════════════════════════════════════════════════════════
cmake_minimum_required(VERSION 3.16)
project(ZeroRing NONE)          # NONE: we configure languages manually below

# ── Options ──────────────────────────────────────────────────
option(ZERORING_CREATE_ISO "Generate a bootable ISO image" ON)

# ── Find kernel tools (optional — allows docs-only builds) ───
find_program(NASM nasm)
find_program(GXX  g++)
find_program(LD   ld)

if(NASM AND GXX AND LD)
    set(ZERORING_BUILD_KERNEL TRUE)
else()
    set(ZERORING_BUILD_KERNEL FALSE)
    set(_missing "")
    if(NOT NASM)
        list(APPEND _missing "nasm")
    endif()
    if(NOT GXX)
        list(APPEND _missing "g++")
    endif()
    if(NOT LD)
        list(APPEND _missing "ld")
    endif()
    string(REPLACE ";" ", " _missing_str "${_missing}")
    message(WARNING
        "Kernel build disabled — missing: ${_missing_str}\n"
        "  Install with:  sudo apt install nasm g++ binutils"
    )
endif()

# ── Paths ────────────────────────────────────────────────────
set(SRC_DIR    ${CMAKE_CURRENT_SOURCE_DIR}/src)
set(GRUB_DIR   ${CMAKE_CURRENT_SOURCE_DIR}/grub)
set(LINKER_SCRIPT ${SRC_DIR}/link.ld)

# ── Source files ─────────────────────────────────────────────
set(ASM_SOURCES ${SRC_DIR}/loader.s)
set(CXX_SOURCES ${SRC_DIR}/kmain.cpp)

if(ZERORING_BUILD_KERNEL)
# ── Freestanding C++ flags ───────────────────────────────────
# These flags ensure we compile for a bare-metal i386 target with
# absolutely no host OS runtime dependencies.
set(FREESTANDING_CXX_FLAGS
    -m32                    # 32-bit i386 code generation
    -ffreestanding          # Freestanding environment (no hosted runtime)
    -fno-builtin            # Don't use compiler built-in functions
    -fno-stack-protector    # No stack canaries (no libc to provide __stack_chk_fail)
    -fno-exceptions         # No C++ exceptions (requires runtime support)
    -fno-rtti               # No RTTI (requires runtime support)
    -nostdlib               # Don't link standard libraries
    -nostdinc               # Don't search standard include paths
    -nostartfiles           # Don't link crt0/crti/crtn
    -nodefaultlibs          # Don't link default libraries
    -Wall -Wextra -Werror   # Strict warnings
)

# ══════════════════════════════════════════════════════════════
#  Step 1: Assemble .s → .o  (NASM, elf32)
# ══════════════════════════════════════════════════════════════
set(ASM_OBJECTS "")
foreach(asm_src ${ASM_SOURCES})
    get_filename_component(asm_name ${asm_src} NAME_WE)
    set(asm_obj ${CMAKE_CURRENT_BINARY_DIR}/${asm_name}.o)
    add_custom_command(
        OUTPUT  ${asm_obj}
        COMMAND ${NASM} -f elf32 ${asm_src} -o ${asm_obj}
        DEPENDS ${asm_src}
        COMMENT "[NASM] Assembling ${asm_name}.s → ${asm_name}.o"
        VERBATIM
    )
    list(APPEND ASM_OBJECTS ${asm_obj})
endforeach()

# ══════════════════════════════════════════════════════════════
#  Step 2: Compile .cpp → .o  (g++, freestanding i386)
# ══════════════════════════════════════════════════════════════
set(CXX_OBJECTS "")
foreach(cxx_src ${CXX_SOURCES})
    get_filename_component(cxx_name ${cxx_src} NAME_WE)
    set(cxx_obj ${CMAKE_CURRENT_BINARY_DIR}/${cxx_name}.o)
    add_custom_command(
        OUTPUT  ${cxx_obj}
        COMMAND ${GXX} ${FREESTANDING_CXX_FLAGS} -c ${cxx_src} -o ${cxx_obj}
        DEPENDS ${cxx_src}
        COMMENT "[G++]  Compiling ${cxx_name}.cpp → ${cxx_name}.o"
        VERBATIM
    )
    list(APPEND CXX_OBJECTS ${cxx_obj})
endforeach()

# ══════════════════════════════════════════════════════════════
#  Step 3: Link kernel.elf  (ld, custom linker script)
# ══════════════════════════════════════════════════════════════
set(KERNEL_ELF ${CMAKE_CURRENT_BINARY_DIR}/kernel.elf)
add_custom_command(
    OUTPUT  ${KERNEL_ELF}
    COMMAND ${LD} -T ${LINKER_SCRIPT} -melf_i386
            ${ASM_OBJECTS} ${CXX_OBJECTS}
            -o ${KERNEL_ELF}
    DEPENDS ${ASM_OBJECTS} ${CXX_OBJECTS} ${LINKER_SCRIPT}
    COMMENT "[LD]   Linking kernel.elf"
    VERBATIM
)
add_custom_target(kernel ALL DEPENDS ${KERNEL_ELF})

# ══════════════════════════════════════════════════════════════
#  Step 4: Generate bootable ISO  (grub-mkrescue)
# ══════════════════════════════════════════════════════════════
if(ZERORING_CREATE_ISO)
    find_program(GRUB_MKRESCUE grub-mkrescue)
    find_program(XORRISO       xorriso)
    find_program(MFORMAT       mformat)

    set(_iso_deps_ok TRUE)
    set(_missing "")
    if(NOT GRUB_MKRESCUE)
        set(_iso_deps_ok FALSE)
        list(APPEND _missing "grub-mkrescue (grub-pc-bin)")
    endif()
    if(NOT XORRISO)
        set(_iso_deps_ok FALSE)
        list(APPEND _missing "xorriso")
    endif()
    if(NOT MFORMAT)
        set(_iso_deps_ok FALSE)
        list(APPEND _missing "mformat (mtools)")
    endif()

    if(_iso_deps_ok)
        set(ISO_DIR  ${CMAKE_CURRENT_BINARY_DIR}/isodir)
        set(ISO_FILE ${CMAKE_CURRENT_BINARY_DIR}/os.iso)
        set(GRUB_CFG ${GRUB_DIR}/grub.cfg)

        add_custom_command(
            OUTPUT  ${ISO_FILE}
            # Build ISO directory tree
            COMMAND ${CMAKE_COMMAND} -E make_directory ${ISO_DIR}/boot/grub
            COMMAND ${CMAKE_COMMAND} -E copy ${KERNEL_ELF} ${ISO_DIR}/boot/kernel.elf
            COMMAND ${CMAKE_COMMAND} -E copy ${GRUB_CFG}   ${ISO_DIR}/boot/grub/grub.cfg
            # grub-mkrescue creates a hybrid BIOS/EFI bootable ISO
            COMMAND ${GRUB_MKRESCUE} -o ${ISO_FILE} ${ISO_DIR}
            DEPENDS kernel ${GRUB_CFG}
            COMMENT "[ISO]  Generating bootable ISO → os.iso"
            VERBATIM
        )
        add_custom_target(iso ALL DEPENDS ${ISO_FILE})

        # ── Convenience run targets ──────────────────────────
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
    else()
        string(REPLACE ";" ", " _missing_str "${_missing}")
        message(WARNING
            "ISO generation disabled — missing: ${_missing_str}\n"
            "  Install with:  sudo apt install grub-pc-bin xorriso mtools\n"
            "  The kernel.elf will still be built."
        )
    endif()
endif()
endif() # ZERORING_BUILD_KERNEL


# ── Summary ──────────────────────────────────────────────────
message(STATUS "")
message(STATUS "  ZeroRing build configured")
if(ZERORING_BUILD_KERNEL)
    message(STATUS "    Kernel:  ${KERNEL_ELF}")
    if(_iso_deps_ok)
        message(STATUS "    ISO:     ${ISO_FILE}")
    endif()
else()
    message(STATUS "    Kernel:  SKIPPED (missing tools)")
endif()
message(STATUS "")

