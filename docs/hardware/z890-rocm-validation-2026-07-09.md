# Z890 ROCm Validation — 2026-07-09

## Host

- System: Z890 SableLinux flagship install
- Kernel: `6.16.1-sable-compat`
- GPU: AMD Navi 44 / Radeon RX 9060 XT
- ROCm path: `/opt/rocm-7.2.2`

## Result

ROCm runtime dispatch is functional.

`rocminfo` confirmed:

- ROCk module loaded
- `/dev/kfd` present
- AMD GPU exposed as HSA Agent 2
- GPU name: `gfx1200`
- Device type: GPU
- Feature: `KERNEL_DISPATCH`
- Compute units: 32
- Fast F16 operation: true
- ISA support:
  - `amdgcn-amd-amdhsa--gfx1200`
  - `amdgcn-amd-amdhsa--gfx12-generic`

## Environment Fix

The system initially had `/etc/profile.d/rocm.sh`, but `/etc/profile` did not source `/etc/profile.d/*.sh`.

The old user-local ROCm path injection was found in:

- `/home/pepper/.bash_profile`

The corrected distribution approach is:

1. `/etc/profile` sources `/etc/profile.d/*.sh`.
2. ROCm environment is provided by `/etc/profile.d/rocm.sh`.
3. User-local ROCm PATH injection is removed.

## Expected Login Shell Environment

A login shell should report:

- `ROCM_PATH=/opt/rocm-7.2.2`
- `HIP_PATH=/opt/rocm-7.2.2`
- `HIP_PLATFORM=amd`
- `rocminfo` resolves to `/opt/rocm-7.2.2/bin/rocminfo`

## Notes

This validates ROCm runtime visibility and HSA GPU detection. It does not yet validate llama.cpp HIP acceleration or benchmark inference throughput.
