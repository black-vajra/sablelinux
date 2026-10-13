# Rsync 3.5.1 staged upgrade

Canonical Z890 build, 2026-10-13; repository baseline 51d5af8.
Build: /srv/sablelinux/package-builds/rsync-3.5.1-YbMJUAGF
Source: /srv/sablelinux/sources/rsync-review-x36DgAZ9
Archive SHA256:
c55f9c9dc10fb8bec397b399a0fdded53cc9a2d8e30891bb0d63724d25c37bef

Both archive signatures passed: Zen Dodd and Andrew Tridgell.
Configured with --prefix=/usr --disable-idn.
IDN was explicitly disabled after configure identified missing idn2.h.
Original failure log retained; no dependency installed speculatively.

Built against staged ACL 2.4.0 using CPPFLAGS/LDFLAGS.
ACL, xattr and IPv6 support confirmed.
272 upstream tests passed; 88 skipped; overall result 0.
Staged payload hashes passed. No RPATH/RUNPATH shown.

Unprivileged -aHAX --numeric-ids fixture preserved content, current-user
ownership, modes, timestamps, hardlinks, symlinks, ACLs and user xattrs.
A checksum/itemized repeat copy reported no changes.

Evidence: docs/testing/packages/rsync-3.5.1-2026-10-13/
Privileged ownership and skipped-test validation remain pending.
Host activation and rollback validation remain pending.
Build idempotence, byte reproducibility and ISO gates are not established.

## Privileged VM preservation validation

The canonical automated package VM passed on 2026-10-13 using staged
rsync 3.5.1 and ACL 2.4.0. It verified foreign numeric ownership,
setuid/setgid, links, ACLs, default ACLs, user xattrs, physical ACL
restoration and an unchanged repeat copy on disposable ext4 media.
Evidence: docs/testing/packages/package-preservation-vm-2026-10-13/
This does not establish all skipped upstream tests or live-ISO gates.

## Canonical recipe validation

Two fresh short-path builds, rsync/3.5.1/A and B, passed with matching
staged inventories and file hashes. The daemon-unix-socket-atfd test
passed in both; longer build paths had caused its socket fixture to skip.
The B summary was 272 PASS, 88 SKIP, overall result 0.
An independent completed-stage reuse comparison for A found unchanged
inventory, modification times and regular-file hashes.
Evidence: docs/testing/packages/rsync-recipe-2026-10-13/
TCP-specific skips remain unpassed. Exact-artifact VM validation,
host activation and ISO reproducibility remain pending.
