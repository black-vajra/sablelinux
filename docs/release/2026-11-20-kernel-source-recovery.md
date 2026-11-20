# Canonical Kernel Source Recovery — November 20, 2026

## Context

The new canonical Z890 SableLinux installation did not
contain the historical /sources directory expected by
scripts/kernel/build-kernel.sh.

This blocked preparation of a corrected portable kernel
for the EliteBook Qualcomm Wi-Fi regression.

## Source recovery

Recovered Linux 6.16.1 from kernel.org into:

/srv/sablelinux/cache/downloads/linux-6.16.1.tar.xz

Verified SHA256:

ea43491bc7ace1e414b3b2d957f8cf96e7049155123f0acce798accf8da1acba

The archive passed xz integrity testing and contained
the expected Makefile, Kconfig, and scripts/config.

## Corrections

Updated scripts/kernel/build-kernel.sh to use the
canonical source-cache location.

Updated scripts/kernel/test-build-kernel.sh to remove
the obsolete /home/pepper/sablelinux repository path
and update its source-archive regression fixture.

The existing SHA256 validation and fail-closed behavior
were preserved.

## Verification

- Kernel source checksum: PASS
- Source archive integrity: PASS
- Canonical kernel preflight: PASS
- Kernel configuration checksum: PASS
- Canonical workspace: PASS
- Required build tools: PASS
- Available space: 408 GiB
- Bash syntax validation: PASS
- Git diff whitespace validation: PASS
- Kernel regression suite: 5 PASS, 0 FAIL

No kernel was built, installed, or activated.

## Outstanding work

The EliteBook Qualcomm QCNFA765 (17cb:1103) requires
ath11k PCI support.

The existing portable-test1 kernel lacks that driver.

Next: introduce and validate a separately versioned
portable kernel profile with ath11k support.

The current working kernel must remain available as
a fallback.

## Release status

ISO release gate remains CLOSED.
