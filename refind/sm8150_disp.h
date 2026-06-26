/*
 * SM8150 (K20 Pro) MDP scanout control before Linux EFI boot.
 *
 * XBL/ABL leave the DPU timing engine scanning 0x9c000000 (continuous splash).
 * Use preserve_sm8150_splash in refind.conf to keep that image visible through
 * rEFInd (avoid textonly/BeginExternalScreen clears).  pause_sm8150_mdp_scanout
 * stops MDP before the kernel and is forced off when preserve is enabled.
 */

#ifndef __SM8150_DISP_H_
#define __SM8150_DISP_H_

#include "global.h"

VOID Sm8150StopMdpScanoutBeforeLinux(IN CHAR8 OSType);

#endif
