/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Raphael (SM8150): optional pause of MDP intf scanout before Linux.
 * Disabled by default (see pause_sm8150_mdp_scanout in refind.conf) so XBL
 * splash can continue into the kernel.  When enabled, only clears intf timing
 * and flush — does not gate DISPCC clocks or clear CTL pipe.
 */

#include "global.h"
#include "sm8150_mdp_stop.h"
#include "log.h"

#if defined(EFIAARCH64)

#define SM8150_GCC_PHYS         0x00100000UL
#define SM8150_GCC_DISP_AHB     0xb00c
#define SM8150_GCC_DISP_AXI     0xb038
#define SM8150_DISPCC_PHYS      0x0af00000UL
#define SM8150_DISPCC_MDSS_AHB  0x2080
#define SM8150_MDP_PHYS         0x0ae01000UL
#define SM8150_CTL0_OFF         0x1000
#define CTL_INTF_FLUSH          0x110
#define INTF_TIMING_ENGINE_EN   0x000

static const UINT32 IntfBases[] = { 0x6a000, 0x6a800, 0x6b000, 0x6b800 };

static UINT32 MmioRead32(UINTN Address)
{
	return *(volatile UINT32 *)(UINTN)Address;
}

static VOID MmioWrite32(UINTN Address, UINT32 Value)
{
	*(volatile UINT32 *)(UINTN)Address = Value;
}

static VOID MmioSetBits32(UINTN Address, UINT32 Mask)
{
	MmioWrite32(Address, MmioRead32(Address) | Mask);
}

VOID sm8150_mdp_stop_scanout(VOID)
{
	UINTN i;

	LOG(1, LOG_LINE_NORMAL, L"SM8150: pausing MDP intf scanout before kernel");

	MmioSetBits32(SM8150_GCC_PHYS + SM8150_GCC_DISP_AHB, 1);
	MmioSetBits32(SM8150_GCC_PHYS + SM8150_GCC_DISP_AXI, 1);
	MmioSetBits32(SM8150_DISPCC_PHYS + SM8150_DISPCC_MDSS_AHB, 1);

	for (i = 0; i < sizeof(IntfBases) / sizeof(IntfBases[0]); i++) {
		UINTN Intf = SM8150_MDP_PHYS + IntfBases[i];

		if (!MmioRead32(Intf + INTF_TIMING_ENGINE_EN))
			continue;

		MmioWrite32(Intf + INTF_TIMING_ENGINE_EN, 0);
		MmioWrite32(SM8150_MDP_PHYS + SM8150_CTL0_OFF + CTL_INTF_FLUSH, 1U << i);
	}
}

#else

VOID sm8150_mdp_stop_scanout(VOID)
{
}

#endif
