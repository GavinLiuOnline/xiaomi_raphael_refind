/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Raphael (SM8150): phone key support for rEFInd.
 *
 * Physical keys are handled by U-Boot's button-kbd driver and exposed to
 * rEFInd through EFI Simple Text Input (stdin=serial,button-kbd in
 * raphael-phone.env).  BUTTON_REMAP_PHONE_KEYS maps volume up/down to arrow
 * keys and power to enter before keys reach EFI ConIn.
 *
 * Direct SPMI/PMIC MMIO from rEFInd was tried but faults on SM8150 EFI and
 * reboots the device before the menu can be shown.
 */

#include "global.h"
#include "sm8150_keys.h"
#include "log.h"

VOID sm8150_keys_init(VOID)
{
#if defined(EFIAARCH64)
    LOG(2, LOG_LINE_NORMAL, L"SM8150 phone keys: using EFI ConIn from U-Boot button-kbd");
#else
    LOG(2, LOG_LINE_NORMAL, L"SM8150 phone keys: not available on this platform");
#endif
}

BOOLEAN sm8150_key_pending(VOID)
{
    return FALSE;
}

BOOLEAN sm8150_try_read_key(OUT EFI_INPUT_KEY *Key)
{
    (VOID)Key;
    return FALSE;
}
