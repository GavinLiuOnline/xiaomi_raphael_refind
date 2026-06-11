#!/usr/bin/env bash
# Build refind_aa64.efi using the local .gnuefi-aa64 toolchain.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GNUEFI="$ROOT/.gnuefi-aa64"

if [[ ! -f "$GNUEFI/include/efi/aarch64/efibind.h" ]]; then
    echo "error: $GNUEFI not found; run ./scripts/prepare-gnuefi-aa64.sh first" >&2
    exit 1
fi

cd "$ROOT"
make gnuefi ARCH=aarch64 GNUEFI_ARM64_TARGET_SUPPORT=y \
    EFIINC="$GNUEFI/include/efi" \
    GNUEFILIB="$GNUEFI/lib" \
    EFILIB="$GNUEFI/lib" \
    EFICRT0="$GNUEFI/lib"

echo "==> built:"
ls -lh "$ROOT/refind/refind_aa64.efi" "$ROOT/gptsync/gptsync_aa64.efi"
file "$ROOT/refind/refind_aa64.efi"
