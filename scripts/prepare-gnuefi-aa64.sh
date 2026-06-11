#!/usr/bin/env bash
# Prepare GNU-EFI with aarch64 headers/libs for cross-compiling rEFInd.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DESTDIR="$ROOT/.gnuefi-aa64"
SRCDIR="${TMPDIR:-/tmp}/gnu-efi-build-$$"

command -v aarch64-linux-gnu-gcc >/dev/null || {
    echo "error: aarch64-linux-gnu-gcc not found" >&2
    echo "install: sudo apt-get install gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu" >&2
    exit 1
}

echo "==> cloning gnu-efi"
git clone --depth 1 https://github.com/vathpela/gnu-efi.git "$SRCDIR"

echo "==> building gnu-efi for aarch64"
make -C "$SRCDIR" clean
make -C "$SRCDIR" ARCH=aarch64 CC=aarch64-linux-gnu-gcc
make -C "$SRCDIR/gnuefi" ARCH=aarch64 CC=aarch64-linux-gnu-gcc

echo "==> installing to $DESTDIR"
rm -rf "$DESTDIR"
mkdir -p "$DESTDIR/include" "$DESTDIR/lib"
cp -r "$SRCDIR/inc" "$DESTDIR/include/efi"
cp "$SRCDIR/gnuefi/crt0-efi-aarch64.o" \
   "$SRCDIR/gnuefi/libgnuefi.a" \
   "$SRCDIR/gnuefi/elf_aarch64_efi.lds" \
   "$DESTDIR/lib/"
cp "$SRCDIR/aarch64/lib/libefi.a" "$DESTDIR/lib/"

rm -rf "$SRCDIR"
echo "done: $DESTDIR"
