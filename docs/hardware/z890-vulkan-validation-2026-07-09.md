# Z890 Vulkan Validation — 2026-07-09

## Host

- System: Z890 SableLinux flagship install
- Kernel: `6.16.1-sable-compat`
- GPU: AMD Navi 44 / Radeon RX 9060 XT
- Mesa: 25.0.1
- Vulkan target: 1.4.305

## Initial State

The system had Mesa Vulkan ICD drivers and JSON manifests, but did not have the Vulkan loader or Vulkan tools installed.

Present before repair:

- `/usr/lib/libvulkan_radeon.so`
- `/usr/lib64/libvulkan_radeon.so`
- `/usr/lib/libvulkan_intel.so`
- `/usr/share/vulkan/icd.d/radeon_icd.x86_64.json`
- `/usr/share/vulkan/icd.d/intel_icd.x86_64.json`

Missing before repair:

- `libvulkan.so`
- `vulkan.pc`
- `vulkaninfo`

The installed Vulkan headers were initially `1.3.290`, while the Mesa ICD files advertised Vulkan API `1.4.305`.

## Repair

Installed:

- Vulkan-Headers `1.4.305`
- Vulkan-Loader `1.4.305`
- volk
- Vulkan-Tools `1.4.305`

The full recursive Khronos clone path was slow/interrupted, so shallow tag clones were used successfully.

## Validation Result

`vulkaninfo --summary` confirmed:

- Vulkan Instance Version: `1.4.305`
- GPU: `AMD Radeon Graphics (RADV GFX1200)`
- Device type: `PHYSICAL_DEVICE_TYPE_DISCRETE_GPU`
- Vendor ID: `0x1002`
- Device ID: `0x7590`
- Driver ID: `DRIVER_ID_MESA_RADV`
- Driver name: `radv`
- Driver info: `Mesa 25.0.1`

`MESA_VK_DEVICE_SELECT=list vulkaninfo --summary` confirmed:

- `GPU 0: 1002:7590 "AMD Radeon Graphics (RADV GFX1200)" discrete GPU 0000:03:00.0`

## Notes

Observed warnings:

- `WARNING: radv is not a conformant Vulkan implementation, testing use only.`
- `MESA: warning: Could not get intel_device_info.`

These are not blockers for the AMD dGPU validation. The RADV warning indicates the current GFX1200 stack is not reporting formal Khronos conformance. The Intel warning should be investigated later if Intel iGPU Vulkan support becomes a requirement.

## Status

Vulkan runtime validation for the Z890 AMD dGPU is successful.
