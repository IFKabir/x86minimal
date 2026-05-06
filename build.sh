#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
#  build.sh — Build & run x86minimal from scratch
#
#  Usage:
#    ./build.sh            # build only (produces build/os.iso)
#    ./build.sh run        # build + launch in QEMU
#    ./build.sh clean      # wipe the build directory
# ──────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"

# ── Colours ───────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${CYAN}[*]${NC} $*"; }
ok()    { echo -e "${GREEN}[✓]${NC} $*"; }
err()   { echo -e "${RED}[✗]${NC} $*" >&2; exit 1; }

# ── Clean ─────────────────────────────────────────────────────
if [[ "${1:-}" == "clean" ]]; then
    info "Removing build directory..."
    rm -rf "$BUILD_DIR"
    ok "Clean done."
    exit 0
fi

# ── Dependency check ──────────────────────────────────────────
MISSING=()
for tool in nasm g++ ld grub-mkrescue xorriso mformat cmake; do
    command -v "$tool" &>/dev/null || MISSING+=("$tool")
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
    info "Installing missing tools: ${MISSING[*]}"
    sudo apt-get update -qq
    sudo apt-get install -y nasm g++ binutils grub-pc-bin xorriso mtools cmake
fi

ok "All tools present."

# ── Configure ─────────────────────────────────────────────────
info "Configuring with CMake..."
cmake -S "$SCRIPT_DIR" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release

# ── Build ─────────────────────────────────────────────────────
info "Building kernel + ISO..."
cmake --build "$BUILD_DIR" --parallel "$(nproc)"

ok "Build complete → $BUILD_DIR/os.iso"

# ── Run (optional) ────────────────────────────────────────────
if [[ "${1:-}" == "run" ]]; then
    command -v qemu-system-i386 &>/dev/null || sudo apt-get install -y qemu-system-x86
    info "Launching QEMU..."
    qemu-system-i386 -cdrom "$BUILD_DIR/os.iso"
fi
