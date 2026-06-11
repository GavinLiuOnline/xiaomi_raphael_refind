#!/usr/bin/env bash
# Prepare GNU-EFI with aarch64 headers/libs for cross-compiling rEFInd.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DESTDIR="$ROOT/.gnuefi-aa64"
SRCDIR="${TMPDIR:-/tmp}/gnu-efi-build-$$"
CROSS_COMPILE=aarch64-linux-gnu-
BUILDDIR="$SRCDIR/aarch64"

command -v "${CROSS_COMPILE}gcc" >/dev/null || {
    echo "error: ${CROSS_COMPILE}gcc not found" >&2
    echo "install: sudo apt-get install gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu" >&2
    exit 1
}

echo "==> cloning gnu-efi"
git clone --depth 1 https://github.com/vathpela/gnu-efi.git "$SRCDIR"

echo "==> building gnu-efi lib + gnuefi for aarch64 (skip apps)"
make -C "$SRCDIR" clean
# Only build lib and gnuefi; the apps target links with host ld and fails on CI.
make -C "$SRCDIR" lib gnuefi ARCH=aarch64 CROSS_COMPILE="$CROSS_COMPILE"

echo "==> installing to $DESTDIR"
rm -rf "$DESTDIR"
mkdir -p "$DESTDIR/include" "$DESTDIR/lib"
cp -r "$SRCDIR/inc" "$DESTDIR/include/efi"
cp "$BUILDDIR/gnuefi/crt0-efi-aarch64.o" \
   "$BUILDDIR/gnuefi/libgnuefi.a" \
   "$SRCDIR/gnuefi/elf_aarch64_efi.lds" \
   "$DESTDIR/lib/"
cp "$BUILDDIR/lib/libefi.a" "$DESTDIR/lib/"

rm -rf "$SRCDIR"
echo "done: $DESTDIR"
