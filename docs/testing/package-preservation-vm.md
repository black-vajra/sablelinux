# Disposable package-preservation VM

Run `bash scripts/testing/run-package-preservation-vm.sh` as pepper on canonical
Z890 SableLinux. This first implementation pins the reviewed ACL 2.4.0 and
rsync 3.5.1 staging paths and GPU Test 2 kernel; it does not select arbitrary
or secondary-system inputs.

The script verifies package file hashes and the documented kernel config,
copies canonical binaries and their resolved libraries into a minimal initramfs,
and boots QEMU/KVM with a new 256 MiB ext4 regular-file disk. No physical disks,
network interfaces or shared host directories are attached to the guest.
The guest runs as root and validates foreign numeric ownership, setuid/setgid,
hardlinks, symlinks, ACLs, default ACLs, user xattrs, physical ACL restoration
and a checksum/itemized repeat copy. This does not execute every skipped
upstream test or validate capabilities/security xattrs.

Each run is retained under `/srv/sablelinux/package-builds/` with provenance,
input hashes, initramfs file hashes, launch command and serial log. A zero QEMU
exit status and guest pass marker are required. Timeout, missing pass marker
or a guest failure marker fails the gate.

This is package validation, not full release Tier 1: it does not mount a
SquashFS payload, build an overlay or switch_root. It does not establish ISO
boot, installation, host activation, build idempotence or byte reproducibility.
The test initramfs and disk are disposable validation artifacts, not release
inputs. Their invocation timestamps remain in external provenance/logs.

## Current status

Canonical automated run passed on 2026-10-13:
`/srv/sablelinux/package-builds/package-preservation-vm-4uiFTzRC`.
QEMU exited successfully; the guest pass marker was verified.
Evidence: docs/testing/packages/package-preservation-vm-2026-10-13/

The BusyBox applet loop was corrected to skip the already-copied binary.
Initial boots timed out with empty serial logs. Diagnostic console arguments
reached passing tests and were incorporated into the harness. The original
silent timeout's cause remains unresolved. QEMU stdin is disconnected to
prevent it consuming pasted shell input.

Host activation remains pending. Review and promote the successful package
build procedures into canonical recipes before activation.
