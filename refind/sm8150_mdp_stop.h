/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Stop Qualcomm SM8150 MDP scanout before handing off to Linux.
 */

#ifndef __SM8150_MDP_STOP_H_
#define __SM8150_MDP_STOP_H_

#ifdef __MAKEWITH_GNUEFI
#include "efi.h"
#else
#include "../include/tiano_includes.h"
#endif

VOID sm8150_mdp_stop_scanout(VOID);

#endif
