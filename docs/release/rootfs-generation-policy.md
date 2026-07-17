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
