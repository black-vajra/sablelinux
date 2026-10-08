# Sable Linux — Intel GPU Test 2

Date: 2026-10-08
Kernel: 6.16.1-sable-gpu-test2
Platform: Gigabyte Z890 AORUS ELITE X ICE

## Corrections
- CONFIG_DRM_I915=y changed to CONFIG_DRM_I915=m
- CONFIG_INTEL_MEI_GSC=m enabled
- CONFIG_INTEL_MEI_GSC_PROXY=m enabled
- Dracut includes Intel firmware and required GPU/MEI modules.

## Verified results
- Intel DMC, GuC, HuC and GSC firmware initialized.
- Intel MEI GSC proxy bound successfully.
- Original missing-firmware and wedged-GPU errors eliminated.
- AMD Radeon RX 9060 XT remained operational.

## Outstanding work
- Investigate AMD SMU mismatch and display timeouts.
- Complete the original dmesg audit.
- Integrate corrections into the reproducible ISO build.
- Validate on additional hardware.

## Evidence
See kernel.config, original-kernel.config, kernel-config.diff,
initramfs-manifest.txt, gpu-modules.txt and SHA256SUMS.

Status: Workstation validation passed; ISO integration pending.
