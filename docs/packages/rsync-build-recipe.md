# Canonical rsync staged build recipe

The recipe pins rsync 3.5.1 and verifies both reviewed archive signatures.
It uses a completed canonical ACL recipe build without installing that library
on the host. No downloads, host installation or deletion are performed.

```sh
bash scripts/packages/build-rsync.sh --stage \
  --source-review /srv/sablelinux/sources/rsync-review-x36DgAZ9 \
  --acl-build /srv/sablelinux/package-builds/acl/2.4.0/path-normalized-A \
  --build-dir /srv/sablelinux/package-builds/rsync/3.5.1/recipe-validation-A
```

IDN is explicitly disabled, following the reviewed missing-idn2.h decision.
ACL, xattr and IPv6 support must be present. The included zlib remains the
configure default used in the successful manual candidate. Source debug paths
are mapped to `/usr/src/sablelinux/rsync-3.5.1`; symbols and build IDs remain.
Default C/C++ flags are -g -O2. Nonempty operator overrides are recorded.

The first invocation verifies sources and ACL payload, builds, runs upstream
tests and validates isolated staged files and library linkage. A completed
matching attempt verifies its payload without rebuild or build-tree writes.
Incomplete attempts and changed declared inputs are preserved and rejected.

Repeat the same command for completed-stage reuse; build in a second fresh
directory with the same ACL input and compare staged inventories and file
hashes. This resume identity records selected sources/tools/dependencies, not
the full frozen host input closure. Do not claim ISO reproducibility from this
package comparison. Skipped upstream tests remain explicitly unpassed.

New package output hashes require exact-artifact disposable VM validation
before host activation. The initial VM harness pins the earlier manual build
paths; its inputs must be updated explicitly for recipe candidates rather than
silently substituted. Existing candidates and logs are retained.
