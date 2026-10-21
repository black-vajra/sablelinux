# SableLinux Engineering State

Audit date: October 7, 2026. Release target: December 31, 2026.

## Current milestone and authority

Deliver a documented, idempotent, reproducible ISO with live boot and validated
installation. Core architecture and live boot have already been demonstrated.
Current work concerns release quality, automation, validation and maintainability.

Only the running Z890 SableLinux installation supplies authoritative release
inputs. Repository documentation and inspected system evidence establish current
state. BUILDLOG.md and older inventories are historical evidence. Secondary
machines, USB installations, VMs and backups are validation or recovery material;
their binaries must not become canonical build inputs.

## Evidence and inspection boundary

This status derives from operator-supplied October 7 terminal output and a Git
archive of the canonical checkout. The reviewer did not access the host directly.
The two supplied engineering-review tar archives were byte-identical (SHA256
36a20024c6e0dae23301fd9e3b414106a2e4c23356ab56b59b8a3d3801d70fd8).
Recorded build reports were read; current artifact checksums have not been rerun.
The archive is a selected source review, not a full checkout or running inventory.

## Verified current system

- Board: Gigabyte Z890 AORUS ELITE X ICE; previously inspected while booted as pots.
- Canonical OS: Sable Linux 1.0; hostname SableLinux.
- Running kernel: 6.16.1-sable-compat.
- Root: /dev/nvme1n1p3, ext4; /boot: /dev/nvme1n1p2, ext4.
- /boot/efi is not mounted. The inspected fstab names EFI UUID 3745-AF41,
  whereas the current NVMe EFI partition reports 5F1D-6806. Investigate before
  changing fstab or bootloader files; successful installed boot is not media validation.
- Repo: /home/pepper/sablelinux; development; HEAD
  c036dcfc6bb148d734170eeb62b7a56f23147460.
- Remote configured as git@github.com:black-vajra/sablelinux.git. Remote freshness
  is not verified by locally cached origin/development.
- Tracked worktree changes were absent; scripts/boincctl is untracked. Preserve
  and inspect it before deciding whether to commit, relocate or ignore it.
- Workspace: /srv/sablelinux; current-build-id points to
  20260717T213351Z-5318fbe-k6.16.1-sable-compat.
- autofs.service and llama-server.service are active and enabled.
- systemctl --failed reported zero failed units. This is not a functionality suite.

The Ubuntu checkout on pots was at 696561f and is older than the canonical
Sable checkout. Use the latter for current engineering work.

## Changes since the historical checkpoint

The July audit checkpoint was 49f1015364e800df67597648a50a87ad30a1d5d1.
Later local canonical history includes a package staging framework, guarded
rpcsvc-proto/libfuse/libtirpc/autofs activation, CVMFS runtime validation and
successful ATLAS startup documentation through July 26. No later commit was
shown in the supplied canonical HEAD/history. Files outside Git and remote
changes have not been exhaustively audited.

CVMFS 2.13.3 documentation records successful July 26 repository access. Do not
carry forward the earlier partial activation as a present failure. October 7
autofs activity is verified; present CVMFS content access remains unknown.

## Release gates

| Gate | Evidence and present status |
| --- | --- |
| Canonical workspace | Present; paths, current pointer and build metadata inspected |
| Current package baseline | Missing comprehensive verified inventory; existing package-build records present |
| Frozen inputs and kernel/config provenance | Incomplete; running kernel identified, exact matching config still to establish |
| Rootfs generation | July report records successful capture and sanitation; present integrity unverified |
| SquashFS | July report records generation and inspection; present integrity unverified |
| Live initramfs | July report records two byte-identical generations and archive checks; boot gate remains open |
| ext4 test media | July report records generation, read-only fsck and payload checks; present integrity unverified |
| Tier 1 full canonical live boot | Unpassed in available evidence; retained build state is test-media-generated |
| Tier 2 generated ISO via OVMF/GRUB | Unpassed in available evidence |
| Tier 3 installation and independent boot | Unpassed in available evidence; installer promotion unresolved |
| Tier 4 hardware | Unpassed for a release candidate |
| Same-workspace idempotence | Not established; existing stages reject completed-stage reruns |
| Two-fresh-build payload/ISO reproducibility | Not established; embedded invocation metadata is a known source of difference |
| Tagged release bundle | Not produced in inspected evidence |

Earlier recovered EliteBook-derived payload boot and later LHC kernel smoke
results are historical successes, not passes for this canonical live artifact set.

## Source-review findings to investigate individually

1. create-build.sh still writes a package-manifest-status placeholder. The
   historical May inventory combines build notes and file listings; it cannot
   establish current installed versions or a package ownership ledger.
2. generate-rootfs.sh embeds build.env with BUILD_ID and CREATED_AT. Unique
   invocation IDs/timestamps therefore change payload content between fresh
   builds despite fixed SquashFS timestamps. Separate immutable release metadata
   from actual run metadata before claiming byte reproducibility.
3. Build stages require a clean worktree and matching build/HEAD revisions.
   The untracked boincctl currently fails that clean-tree requirement. The
   retained July build also predates current HEAD; do not bypass these guards.
4. The minimal BusyBox builder contains no kernel modules and mounts media as
   ext4. Verify required built-in drivers and filesystems for Tier 1; design and
   validate ISO media discovery before Tier 2. Do not assume ext4 discovery boots ISO9660.
5. The reviewed scripts contain hardware-detection scaffolding but do not
   establish an authoritative installer. Inventory the remaining installer
   candidates, including low-level helpers and historical copies, before promotion.
6. Rootfs excludes /opt/models and disables llama-server and sshd. Retain this
   policy. Review BOINC/autofs/CVMFS runtime paths and service behavior before the
   next capture, especially persistent CVMFS cache under /var/lib/cvmfs. No policy
   change or host service disablement has yet been made.

## Backups

While booted into Ubuntu, /mnt/two was the external4t filesystem with UUID
35d4bbc8-bfc7-410f-8bd0-f1c1ba54e89b. Sable backup directories were observed
beneath /mnt/two/backups/sable-system and ISO material beneath /mnt/two/backups/iso.
/mnt/three was /dev/sda1 with UUID c1a3ad04-f50c-448c-9b39-49dbc6031692;
/mnt/three/backups/sable-system exists. Current Sable mount locations and backup
completeness, hashes and recoverability remain unverified. Use filesystem UUIDs
rather than assuming device names or mount locations persist across boot.

## Restart decision and next action

Recommend D for the release baseline: audit packages, perform validated upgrades,
freeze canonical inputs, then generate a fresh build. Preserve the July build as
historical evidence and a possible diagnostic Tier 1 fixture after integrity
verification. This does not authorize rewriting it or resetting Git history.

Next action: inspect tools/sable-inventory.sh without executing it, establish a
current package and functionality baseline, then select the first bounded package
upgrade or release-blocker correction from the resulting evidence.

No new build, package upgrade, service change, bootloader edit or runtime test was
performed by the reviewer during this audit. Apply and commit this documentation
on the canonical host to complete the repository checkpoint.

## Package checkpoint — 2026-10-13

Canonical ACL 2.4.0 and rsync 3.5.1 staged recipes are implemented.
Completed-stage reuse comparisons passed. Two fresh builds of each package
matched staged inventories and file hashes after debug-path normalization.
The finalized ACL/rsync candidates passed privileged ext4 preservation
validation in a disposable QEMU/KVM guest.
ACL 2.4.0 and rsync 3.5.1 host activation and installed-runtime validation
passed on the canonical Z890. The rsync replacement/rollback fixture passed
before activation; original host rsync files and recovery records are retained.
Full live-ISO gates remain pending.
The release plan records the operator-requested kernel built-in selection
audit as a deferred task before release-kernel input freeze.

## Capture review checkpoint — 2026-10-13

Canonical development was pushed through 72f99ce; the reported tracked worktree
is clean, with scripts/boincctl still untracked and preserved. Running kernel
6.16.1-sable-gpu-test2 has workstation validation evidence; canonical ISO
integration remains pending. The October 7 system section above is historical
and does not describe the current running kernel or repository HEAD.

Current build pointer remains 20260717T213351Z-5318fbe-k6.16.1-sable-compat.
Do not resume it as a current release build without coherent input provenance.
Recommendation D remains: complete the package audit and validated upgrades,
freeze inputs, then initialize a fresh canonical build.

Reviewed generate-rootfs.sh still probes ACL/xattr option acceptance using dry
runs and silently omits unsupported preservation options. Actual installed rsync
fixture preservation now passes, but that result is not yet an enforced capture
prerequisite. Investigate a fail-closed preservation gate as one bounded change.
The generator still embeds invocation identity/timestamps, requires an empty
initialized rootfs, and does not inject an installer. Rootfs rerun acceptance,
frozen-input capture and complete ISO reproducibility remain unpassed.

Next action: inspect capture-relevant BOINC/autofs/CVMFS state and installer
candidate paths, then implement and test the bounded capture preservation gate.
Keep AI model exclusion and llama-server live disablement unchanged.

## Capture exclusion checkpoint — 2026-10-14

Canonical Z890 inventory confirmed BOINC paths and guest disks under the
already-excluded /var/lib/qemu tree. Rootfs filtering now excludes the
identified BOINC installation, data, configuration, helper and service
paths; generated-rootfs absence assertions cover principal BOINC paths.
QEMU tooling, OVMF firmware and shared dependencies remain included.

Disposable fixture validation passed; evidence and limitations are in
docs/testing/live/rootfs-exclusions-2026-10-14/README.md.
No full rootfs capture or release gate was run. July artifacts and the
untracked scripts/boincctl remain preserved.

Next: implement and validate actual fail-closed filesystem preservation
before rootfs capture. Continue package/kernel audit and input freeze
before initializing a fresh canonical build.

## Capture preservation checkpoint — 2026-10-14

Rootfs generation now requires actual installed-rsync preservation
validation on the destination filesystem before dry-run or execute capture.
ACL/xattr flags are mandatory. Failed probes retain diagnostics and stop
before host-root copying; existing provenance guards remain unchanged.

Canonical positive and deliberate ACL-loss, xattr-loss and copy-failure
tests passed. Evidence:
docs/testing/live/rootfs-preservation-2026-10-14/README.md.
Generator integration was source checked; full capture was not executed.

Continue package/functionality audit, CVMFS/autofs scope review and kernel
audit before input freeze and fresh-build initialization. Preserve July
artifacts and the untracked scripts/boincctl.

## CVMFS scope and session checkpoint — 2026-10-14

CVMFS is excluded from the baseline ISO following documented BOINC/ATLAS
usage and canonical autofs-map review. Autofs tooling and shared
dependencies remain included; autofs is disabled only in the generated
live root. Canonical fixture validation passed; evidence:
docs/testing/live/cvmfs-exclusions-2026-10-14/README.md.

BOINC/guest exclusions and mandatory filesystem preservation are committed.
No new canonical build or full rootfs capture has run. Preserve July
artifacts, package/VM recovery records and untracked scripts/boincctl.

Next session:
1. Verify running Z890 identity, HEAD/status and remote checkpoint.
2. Improve tools/sable-inventory.sh before using it: report failures,
   continue sections, bound scans and avoid historical mounted trees.
3. Establish package/functionality inventory and dependency-aware upgrade
   priorities. Complete kernel audit before input freeze.
4. Resolve preserved untracked scripts/boincctl deliberately before any
   clean-tree build operation; never bypass provenance guards.
5. Freeze canonical inputs, then initialize a fresh build.

EFI UUID mismatch remains documented and unresolved. Release boot,
installation, idempotence and byte-reproducibility gates remain open.


## Inventory hardening review checkpoint — 2026-10-16

Operator preflight at 19:23:07Z confirms canonical Z890, running
6.16.1-sable-gpu-test2, development HEAD ba2bc2c and an unchanged cached
origin/development. No remote fetch was performed. Tracked changes were
absent; scripts/boincctl remains untracked and preserved. The July build
pointer and unmounted EFI/fstab UUID mismatch persist.

The old tools/sable-inventory.sh suppressed errors and traversed historical
mounted trees. The proposed correction explicitly reports failures, continues
independent probes, bounds probe time/output, removes recursive historical
and firmware scans, and records source location and provenance observations.
Reviewer-environment syntax and isolated CLI tests passed. Canonical execution
and evidence review remain pending; no package or ISO gate is closed.
See docs/testing/inventory-2026-10-16/README.md for scope and validation.

Next: validate and collect the hardened inventory on Z890, review incomplete
probes, then establish the installed-package/provenance and functionality
baseline. Preserve July/package/VM recovery artifacts and scripts/boincctl.
Do not initialize a fresh build before the remaining audits and input freeze.


## Canonical inventory validation — recorded 2026-10-21

The corrected isolated tests passed on Z890 on October 16. The retained actual
inventory completed 42 probes with two incomplete observations: lsusb timed out
(exit 124) and journalctl lacked permission (exit 1). The tool retained diagnostics,
continued and returned incomplete. USB cause and privileged journal review remain
open. These results validate bounded diagnostic behavior, not package provenance,
hardware functionality or ISO acceptance. Original reports remain outside Git.

Evidence: docs/testing/inventory-2026-10-16/canonical-validation.txt and
canonical-tests.log. October 21 inspection confirms the same inventory/fixture
hashes, running GPU Test 2 and pre-commit HEAD ba2bc2c.

Next: record the October 21 kernel/AI-platform audit, inspect kernel build-tree
provenance and existing AI-stack/package inputs before proposing changes.
Preserve scripts/boincctl, working kernels and historical/recovery artifacts.
