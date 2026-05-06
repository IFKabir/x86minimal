#!/usr/bin/env bash
# Usage: ./build.sh run or ./build.sh clean or ./build.sh
set -euo pipefail

BUILD_DIR="$(dirname "$0")/build"

case "${1:-}" in
    clean) rm -rf "$BUILD_DIR"; echo "Cleaned."; exit 0 ;;
    run)   BUILD=1; RUN=1 ;;
    *)     BUILD=1; RUN=0 ;;
esac

if [[ $BUILD -eq 1 ]]; then
    cmake -S "$(dirname "$0")" -B "$BUILD_DIR" --fresh -DCMAKE_BUILD_TYPE=Release
    cmake --build "$BUILD_DIR" --parallel "$(nproc)"
fi

if [[ $RUN -eq 1 ]]; then
    qemu-system-i386 -cdrom "$BUILD_DIR/os.iso"
fi
