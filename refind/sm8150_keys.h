/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Raphael (SM8150): poll PMIC buttons for rEFInd menu navigation.
 * Volume Up/Down move the selection; Power confirms (same as U-Boot).
 */

#ifndef __SM8150_KEYS_H_
#define __SM8150_KEYS_H_

#ifdef __MAKEWITH_GNUEFI
#include "efi.h"
#include "efilib.h"
#else
#include "../include/tiano_includes.h"
#endif

VOID sm8150_keys_init(VOID);
BOOLEAN sm8150_key_pending(VOID);
BOOLEAN sm8150_try_read_key(OUT EFI_INPUT_KEY *Key);

#endif
