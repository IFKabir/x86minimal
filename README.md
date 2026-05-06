# ZeroRing

<p align="left">
  <img src="docs/logo.svg" alt="ZeroRing Logo" width="120" height="120">
</p>

A tiny x86 kernel that boots up and does... nothing. Yet.

It's 32-bit, boots via GRUB, and currently just sits in an infinite loop. But hey, it *boots*. That's honestly the hardest part.

**[API Reference](https://zeroring.vercel.app/)** · **[Releases](https://github.com/IFKabir/ZeroRing/releases)**

---

## What's here

- Multiboot-compliant GRUB bootloader setup
- NASM assembly entry point + a C++ kernel file
- Builds into a bootable ISO you can throw at QEMU or Bochs
- CMake handles all of it

## Get started

You'll need a few things:

```bash
# the essentials
sudo apt install cmake nasm g++ binutils

# for ISO + emulation
sudo apt install grub-pc-bin xorriso mtools qemu-system-x86 bochs
```

Then:

```bash
cmake -B build
cmake --build build
```

That gives you `build/kernel.elf` and `build/os.iso`.

## Run it

```bash
# qemu
cmake --build build --target run-qemu

# bochs
cmake --build build --target run-bochs
```

Or just do it manually if you prefer:

```bash
qemu-system-i386 -cdrom build/os.iso
```

## Project layout

```
src/loader.s      ← entry point, sets up stack, calls into C++
src/kmain.cpp     ← where your kernel code goes
src/link.ld       ← linker script, loads at 0x00100000
grub/grub.cfg     ← GRUB menu config
bochsrc.txt       ← Bochs emulator settings
CMakeLists.txt    ← build system
```

## Clean up

```bash
rm -rf build
```

## License

MIT. Do whatever you want with it.
