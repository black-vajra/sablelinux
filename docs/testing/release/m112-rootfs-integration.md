# M1.12 — Self-Contained Rootfs Integration Validation

Date: 2026-11-05
Canonical host: Z890 SableLinux
Branch: development
Baseline commit: e5a247e

## Objective

Convert the successful M1.11 rootfs integration procedure into
a repeatable, self-contained regression test.

## Execution

Command:

    bash tests/release/run-rootfs-selfcontained.sh

Result:

    SABLE_M112_SELFCONTAINED_E2E_PASS

Evidence:

    /var/tmp/sable-m112-e2e-fX56znst

## Verified

- Canonical initialized-build preflight
- Synthetic rootfs fixture generation
- Disposable Git checkout and test-only commit
- Disposable build workspace initialization
- Verified 57-entry kernel-module manifest
- Read-only kernel-candidate mount
- Namespace-isolated rootfs generation
- Kernel-module checksum verification
- Published kernel-module directory permissions: 0755
- Rootfs validation and host-data exclusions
- Final build metadata and state promotion
- Canonical pointer, metadata, state and rootfs unchanged

## Limitations

- Positive-path integration testing has passed.
- Failure-path recovery and crash consistency remain to be tested.
- The harness still uses canonical Z890 paths and requires sudo.
- The actual canonical release rootfs has not been generated.
- SquashFS, live initramfs, boot media and installer testing remain pending.

## Next Work

1. Add negative-path and interruption-recovery regression coverage.
2. Improve test portability and isolation safeguards.
3. Validate canonical rootfs generation.
4. Continue through SquashFS, initramfs and QEMU boot testing.
