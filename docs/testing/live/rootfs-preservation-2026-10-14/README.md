# Mandatory capture preservation — 2026-10-14

Validated on canonical Z890, kernel 6.16.1-sable-gpu-test2.

Command:
sudo python3 scripts/live/test-rootfs-preservation.py --workspace /srv/sablelinux

Passed:
- Installed rsync: fixture content and metadata preserved.
- Deliberately dropped ACLs: rejected with exit 1.
- Deliberately dropped xattrs: rejected with exit 1.
- Deliberate rsync copy failure: rejected with exit 1.
- Generator source integration: prerequisite precedes host-root capture;
  optional ACL/xattr fallback removed.

Fixture covers foreign numeric ownership, special modes, whole-second
mtimes, hardlinks, symlinks, access/default/inherited ACLs, visible xattrs,
a FIFO and repeat-copy behavior. Security xattr namespace coverage is
not exhaustive.

Detailed probe diagnostics are in probe-evidence.json.
Original fixtures remain:
 /srv/sablelinux/rootfs-preservation-tests-49pkhpct

Full generator execution was not tested. Historical builds were not used.
This is not a live-boot, installation, rootfs-idempotence or ISO
reproducibility gate pass.
