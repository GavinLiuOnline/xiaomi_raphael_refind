#!/usr/bin/env bash
# Build refind_aa64.efi and drivers_aa64/ using the local .gnuefi-aa64 toolchain.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GNUEFI="$ROOT/.gnuefi-aa64"

if [[ ! -f "$GNUEFI/include/efi/aarch64/efibind.h" ]]; then
    echo "error: $GNUEFI not found; run ./scripts/prepare-gnuefi-aa64.sh first" >&2
    exit 1
fi

MAKE_ARGS=(
    ARCH=aarch64
    GNUEFI_ARM64_TARGET_SUPPORT=y
    EFIINC="$GNUEFI/include/efi"
    GNUEFILIB="$GNUEFI/lib"
    EFILIB="$GNUEFI/lib"
    EFICRT0="$GNUEFI/lib"
)

cd "$ROOT"
make gnuefi "${MAKE_ARGS[@]}"
make fs_gnuefi "${MAKE_ARGS[@]}"

driver_count="$(find "$ROOT/drivers_aa64" -maxdepth 1 -name '*_aa64.efi' 2>/dev/null | wc -l)"
if [[ "$driver_count" -lt 6 ]]; then
    echo "error: expected at least 6 drivers in drivers_aa64/, found ${driver_count}" >&2
    exit 1
fi

echo "==> built:"
ls -lh "$ROOT/refind/refind_aa64.efi" "$ROOT/gptsync/gptsync_aa64.efi"
ls -lh "$ROOT/drivers_aa64/"
file "$ROOT/refind/refind_aa64.efi"
