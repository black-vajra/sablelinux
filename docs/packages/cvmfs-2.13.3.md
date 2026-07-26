# CVMFS 2.13.3

## Status

CVMFS 2.13.3 is installed and runtime-validated on the canonical Z890
SableLinux system.

Validation date: 2026-07-26

## Role

CVMFS provides the software repositories required by BOINC LHC@home ATLAS
workloads.

The installation is client-only. No CVMFS server, gateway, receiver, DUCC, or
snapshotter components are installed.

## Source

Version: 2.13.3

Upstream tag: `cvmfs-2.13.3`

Upstream commit:

`eb5798f613225b4364781d90af2d2c7269a63824`

Source archive:

`cvmfs-2.13.3.tar.gz`

SHA256:

`1ee9db980608d6cd25c6566c49acf5903b67e9110774563df4ca2397eb137393`

## Build policy

The package was built client-only with FUSE3 support.

SableLinux explicitly uses:

`CMAKE_INSTALL_LIBDIR=lib`

A local source patch prevents upstream CMake logic from forcing `lib64` on
unrecognized 64-bit Linux distributions.

Bundled externals remain enabled for this build because the canonical system
does not yet provide validated system protobuf and LevelDB dependencies.

## Runtime policy

Configuration file:

`/etc/cvmfs/default.local`

Repository allowlist:

- `cvmfs-config.cern.ch`
- `atlas.cern.ch`
- `atlas-condb.cern.ch`
- `grid.cern.ch`
- `unpacked.cern.ch`

Transport:

`CVMFS_HTTP_PROXY=DIRECT`

Cache:

`CVMFS_CACHE_BASE=/var/lib/cvmfs`

`CVMFS_QUOTA_LIMIT=20000`

`CVMFS_SHARED_CACHE=yes`

Security and mount policy:

`CVMFS_STRICT_MOUNT=yes`

`CVMFS_CHECK_PERMISSIONS=yes`

`CVMFS_CLAIM_OWNERSHIP=yes`

Mount root:

`/cvmfs`

Autofs map:

`/etc/auto.master.d/cvmfs.autofs`

## Account and ownership

Service account:

`cvmfs`

Home:

`/var/lib/cvmfs`

Shell:

`/sbin/nologin`

Installed package files are owned by `root:root`.

The persistent cache is owned by `cvmfs:cvmfs`.

## Service policy

`autofs.service` is enabled and active.

`cvmfs-reload.service` is static and is not independently enabled.

Repositories are mounted lazily through autofs.

## Validated repositories

The following repositories were successfully probed, mounted, and read:

- `cvmfs-config.cern.ch`
- `atlas.cern.ch`
- `atlas-condb.cern.ch`
- `grid.cern.ch`
- `unpacked.cern.ch`

The `boinc` service account successfully traversed all five repositories.

## Expected warnings

`cvmfs_config chksetup` may report failed Geo-API queries or failed access to
individual Stratum 1 servers. These warnings are nonfatal when repository
probes succeed through alternate servers.

Runtime acceptance depends on successful repository probes and content access,
not on every configured Stratum 1 endpoint responding.

## Validation hierarchy

CVMFS installation and repository access are now validated.

The next BOINC/LHC phase may resume workload fetching and validate an actual
ATLAS task against the mounted repositories.
