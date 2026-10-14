# Rootfs exclusion validation — 2026-10-14

Canonical Z890, SableLinux, kernel 6.16.1-sable-gpu-test2.

Approved scope excludes personal BOINC software and guest payloads while
retaining QEMU/KVM tooling, firmware and shared dependencies. Host software,
services, guest disks and historical builds were not modified.

Validation: bash scripts/live/test-rootfs-excludes.sh

Passed:
- Unfiltered control contains all excluded fixture payloads.
- Filtered copy excludes BOINC binaries, libraries, configuration,
  credentials, service units, drop-ins and same-named enablement links.
- Existing guest-storage exclusions remove representative guest payloads.
- Representative QEMU executables, OVMF/QEMU firmware, dracut modules,
  GRUB images and shared libraries remain.
- QEMU executable modes remain executable.
- Repeat fixture copy produces no itemized changes.
- Source fixture content and symlinks match the control afterward.
- Generator/test shell syntax and tracked diff whitespace checks pass.

Fixture retained at /tmp/sable-exclusions-7mlRVz38.
This temporary path is diagnostic; the repository test recreates fixtures.

The location inventory was bounded. Missing /etc/libvirt and unavailable
virsh were recorded. The linker-reference search returned no BOINC matches.

The generator's new absence assertions were reviewed and syntax checked;
the full generator was not executed. This is not a filesystem-preservation,
rootfs-idempotence, live-boot, installer or ISO reproducibility gate pass.
CVMFS/autofs inclusion and fail-closed preservation remain separate work.

Repository inventory copies have trailing spaces/tabs removed.
Original operator reports remain unchanged at their recorded host paths.
