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
