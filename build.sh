#!/usr/bin/env bash
# Usage: ./build.sh          – clean, build, and run
#        ./build.sh build    – clean and build only (no QEMU)
#        ./build.sh clean    – remove build directory only
set -euo pipefail

BUILD_DIR="$(dirname "$0")/build"

case "${1:-}" in
    clean) rm -rf "$BUILD_DIR"; echo "Cleaned."; exit 0 ;;
    build) RUN=0 ;;
    *)     RUN=1 ;;
esac

# Always clean before building
echo "==> Cleaning build directory..."
rm -rf "$BUILD_DIR"

echo "==> Configuring..."
cmake -S "$(dirname "$0")" -B "$BUILD_DIR" --fresh -DCMAKE_BUILD_TYPE=Release

echo "==> Building..."
cmake --build "$BUILD_DIR" --parallel "$(nproc)"

if [[ $RUN -eq 1 ]]; then
    echo "==> Launching QEMU..."
    qemu-system-i386 -boot d -cdrom "$BUILD_DIR/os.iso"
fi
