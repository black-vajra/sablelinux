# ACL 2.4.0 package engineering

Canonical Z890 inspection: 2026-10-13.
Repository baseline: 0dea213.
Running kernel: 6.16.1-sable-gpu-test2.

Purpose: provide ACL headers, library and utilities for an ACL-capable rsync
and validated release-root preservation.

Source review: /srv/sablelinux/sources/acl-review-7kVNUmV5
Source SHA256:
e661131456d2708a01c614a0f400e11d7d1bfaeb6f3e74b75bb980b72f0161a3
Archive signature verified against primary fingerprint:
259B3792B3D6D319212CC4DCD5BF9FEB0313653A

Build: /srv/sablelinux/package-builds/acl-2.4.0-f8orRpQp
Configuration: --prefix=/usr --libdir=/usr/lib --disable-static
--docdir=/usr/share/doc/acl-2.4.0

Compilation passed. Initial tests: 6 PASS, 4 FAIL, 4 SKIP, 2 XFAIL.
The four failures reflected setgid inherited from the canonical workspace.
Original log and directory modes were retained under build/logs.
Removing setgid only from this disposable source tree resolved all four
failures on make recheck. Aggregate results: 10 PASS, 4 SKIP, 2 XFAIL.
Root-only tests remain unpassed; full-suite rerun is not established.

Future build automation must prevent inherited setgid in package source
and staging directories while preserving canonical workspace permissions.

Host activation, rsync rebuild, privileged preservation validation,
idempotence and reproducibility remain pending.

## Staged validation

Staging completed; staged-file hashes passed and activation preflight
reported zero collisions.

Staged getfacl/setfacl reported 2.4.0 and loaded staged libacl.so.1.
Neither utility showed RPATH/RUNPATH.
Numeric named-user ACL set/remove/restore and default ACL inheritance passed.
Evidence: docs/testing/packages/acl-2.4.0-2026-10-13/

The restore smoke test emitted a symlink-traversal warning.
Future automation must specify --physical with --restore.

Host activation remains pending. No full ISO validation is implied.
