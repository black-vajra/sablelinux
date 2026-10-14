# Canonical Live Root Generation Policy

The canonical live root is generated from the running Z890 SableLinux
installation.

The running system is an authoritative source for installed runtime files,
libraries, firmware, kernel modules, utilities, and package selection.

It is not an authoritative source for personal data, host identity, secrets,
runtime state, build sources, VM disks, caches, logs, or credentials.

## Source

Source filesystem:

/

Destination:

/srv/sablelinux/builds/<build-id>/rootfs/

## Excluded Categories

The generator excludes:

- pseudo and volatile filesystems
- mounted build and media paths
- /srv generated-artifact state
- /sources build trees
- the Z890 /boot filesystem
- swap files
- pepper and tester home data
- root home contents
- shell histories
- SSH, GnuPG, browser, cloud, and user credentials
- SSH host keys
- WireGuard keys and configuration
- machine identity
- host UUID-based fstab data
- logs and caches
- QEMU and VM payloads
- system random seeds
- local AI model payloads
- source trees and Git metadata

The maintained exclusion list is:

configs/live/rootfs-excludes.rsync

## Account Policy

The live root retains the dedicated sable account.

The generator removes the canonical build-host accounts pepper and tester
from the generated account databases.

All copied password hashes are discarded. Root and sable are locked in the
generated shadow database.

The sable live account receives console autologin and passwordless sudo.
Remote SSH is disabled by default.

## Host Identity Policy

The generated root uses:

hostname: sablelinux

The machine-id file is left empty so that a new identity is generated at
runtime.

SSH host keys and WireGuard keys are not copied.

The Z890 fstab is replaced with a generic live-root fstab.

## Desktop Policy

The live-user Sway and Waybar files are injected from repository-controlled
files under:

configs/desktop/

The running pepper desktop configuration is not copied.

## Service Policy

Services listed in:

configs/live/disabled-services.list

are disabled in the generated root by removing enablement links.

The local llama-server service is disabled because the local model payload is
not part of the live root.

SSH is disabled because canonical host keys are removed and remote access is
not required for Tier 1 live-boot validation.

## Installer Policy

No installer is injected during this step.

The repository currently contains multiple installer candidates. They must be
reviewed and reconciled before one is promoted into the canonical live root.

## Build-State Transition

The rootfs generator accepts only a build in state:

initialized

A successful execution changes the state to:

rootfs-generated

A dry run changes no build state and copies no rootfs files.

## BOINC and guest payload scope — 2026-10-14

Exclude the personal /opt/boinc installation, including its package
libraries; /var/lib/boinc-client workload data and credentials;
/etc/boinc and /etc/boinc-client configuration; /usr/local/bin/boincctl;
and boinc-client.service units, same-named enablement links and drop-ins.
Preserve the host installation and shared dependencies.

Exclude preinstalled guest operating systems, disks, snapshots, saved
memory and downloaded guest installation media. The bounded Z890 inventory
found guest disks under /var/lib/qemu, already excluded. Existing rules
also exclude /var/lib/libvirt, /srv, /mnt, /media and host user homes.

Retain QEMU executables, /usr/share/qemu firmware, QEMU dracut modules,
GRUB images and /opt/sablelinux/qemu/firmware/ovmf. The inspected OVMF
directory contains firmware code and a variable-store template.
Do not exclude files globally by image extension.

The inventory was bounded; review exclusions when storage changes.
CVMFS is excluded and autofs is disabled in the generated live root, as described below. Fixture filtering tests do not
establish filesystem preservation, full rootfs idempotence or ISO readiness.

## Mandatory filesystem preservation prerequisite

Before both dry-run and execute capture, after the existing host, empty-rootfs,
clean-tree, build-state and Git provenance guards, the generator runs
scripts/live/check-rootfs-preservation.py. A real copy with installed rsync
must preserve content, foreign numeric UID/GID, file types and mode bits
(including setuid/setgid), whole-second mtimes, symlinks, hardlink identity,
access/default/inherited ACLs, xattrs and a FIFO. The fixture compares all
xattrs visible to root on its non-symlink objects, including a known user
attribute. It does not claim coverage of every security xattr namespace.

Fixtures reside in fresh private directories under the build tmp directory,
which must be on the destination rootfs filesystem. They and the prerequisite
report remain after success or failure. No fixed probe directory is deleted.
Missing tools, failed commands or mismatches abort before host-root rsync;
ACL/xattr support is mandatory and never silently downgraded. A failed
prerequisite does not modify rootfs or promote BUILD_STATE. The probe writes
small fixtures even when the requested capture is a dry run.

Validation on Z890 (authenticate separately before sudo):

    sudo python3 scripts/live/test-rootfs-preservation.py --workspace /srv/sablelinux

The tests exercise installed rsync, deliberate ACL loss, deliberate xattr loss,
and rsync failure. A source integration check verifies placement before capture;
it is not an end-to-end generator execution. No historical build is used.
Existing package-preservation VM acceptance remains separate. This prerequisite
does not freeze live inputs or establish rootfs/ISO reproducibility.

## CVMFS and autofs release decision — 2026-10-14

The canonical documentation identifies BOINC/LHC ATLAS as the only documented
CVMFS consumer. The inspected autofs master includes only auto.master.d,
containing the CVMFS map. No additional release use was established by the
bounded review. CVMFS is therefore outside the baseline ISO scope.

Exclude the CVMFS client executables, package-specific libcvmfs libraries,
headers/documentation, program map, repository configuration, service unit,
mount root and persistent cache using the maintained exclusion list. Retain
autofs tooling, FUSE, libc, libstdc++ and other shared dependencies. Disable
autofs only in the generated live root; its generic configuration remains.
The existing generator removes enablement links and now checks autofs too.

Do not stop host services, remove host packages, access remote repositories
or modify host cache data for this change. Earlier BOINC/CVMFS acceptance
records remain historical evidence. Future optional CVMFS support requires
an explicit supported workload, declared inputs and its own validation.

Validation: bash scripts/live/test-rootfs-excludes.sh. Fixtures verify CVMFS
payload exclusion, shared dependency/tool retention and the generator's actual
service-link removal block. Full rootfs generation and ISO gates remain open.
