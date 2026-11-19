# Canonical Z890 Migration and ISO Findings
Date: 2026-11-18 (local), continuing 2026-11-19 UTC
Status: Migration in progress; release build not yet validated

## Objective

Migrate canonical SableLinux development from the older Z890
NVMe installation to the new SATA installation, preserving all
source work, release engineering capability, and required services.

The old NVMe installation remains mounted read-only at
/mnt/old-sable and must not be erased until migration validation
is complete.

## New Canonical Installation

- Hardware: Gigabyte Z890 AORUS ELITE X ICE
- Root: /dev/sda3, ext4
- Hostname: SableLinux
- Build account: sable
- Kernel: 6.16.1-sable-portable-test1
- Repository: /home/sable/sablelinux
- Workspace: /srv/sablelinux
- Git baseline: development
- Migration HEAD: 82ad8e7
- Workspace layout: 1
- Workspace initialized successfully on 2026-11-19 UTC

## Repository Migration

The complete old Git checkout was copied, including Git objects,
local commits, and untracked files.

At migration:
- a992374 Package Waybar VPN, LAN, and battery indicators
- 82ad8e7 Add fresh install mode for prepared partitions

Both were ahead of the locally recorded origin/development.

Untracked materials:
- docs/release/sablelinux-asus-idle-recovery-2026-11-09.md
- scripts/boincctl

The boincctl utility is local-only and must not become a release
input. Git object-integrity verification passed. Full source
filesystem comparison and current GitHub divergence verification
remain outstanding.

## WireGuard and SSH

The new SATA installation has its own WireGuard identity:
- Interface: wg-z890
- Address: 10.0.0.10/24
- Server: 172.233.44.146:51820

The server peer is registered in live and saved WireGuard
configuration.

Verified:
- New Z890 to VPN server: successful
- VPN server to Z890: ping and TCP 2269 successful
- EliteBook Kubuntu (logos, 10.0.0.6) to Z890:
  4/4 ping replies; SSH host fingerprint matched
- SSH daemon active and enabled on new Z890
- WireGuard enabled for future startup
- Waybar VPN indicator displays the correct tunnel status

The server firewall's new forwarding exceptions were saved,
and nftables syntax validation passed.

Still required:
- Controlled server firewall reload and persistence test
- Restore/reconcile historical Pavilion forwarding exceptions
- New Z890 reboot/startup verification
- Authenticated inbound SSH test from another intended client
- Final verification of EliteBook Sable and ASUS configurations

## ISO and Installation Defects

1. Installed SSH configuration inherited AllowUsers pepper even
   when the installed account was sable.
2. Installed OpenSSH rejected the UsePAM directive.
3. Installed systems lacked generated SSH host keys.
4. Obsolete wg-quick@client1 service configuration was inherited.
5. Waybar WireGuard helper was hardcoded to client1.
6. Waybar sudoers permission was likewise restricted to client1.
7. Screenshot bindings used /home/pepper/screenshots rather
   than an installation-independent location.
8. Desktop changes made manually on development installations
   are not reliably reflected in release-controlled profiles.
9. Rootfs exclusion policy excludes pepper/tester homes but
   not the new canonical /home/sable. Audit for leakage of
   personal data, credentials, and local runtime state.
10. Release scripts retain some old /home/pepper assumptions,
    including package activation. Distinguish build-host paths
    from deliberately constructed live-user paths.
11. Boot-time WireGuard and SSH defaults need installation-
    specific configuration and release-validation tests.

These are observed issues or audit findings, not claims that
all have already been corrected in release source.

## Build Workspace Migration

Old workspace: approximately 234 GB
- builds: 217 GB
- kernel-builds: 15 GB
- package-builds: 2.5 GB

Reusable sources, testing, reports, releases, cache, and package
backups were copied to the new workspace (approximately 70 MB).

The original build artifacts and kernel candidates remain
accessible from the old read-only filesystem.

A fresh workspace was initialized under the sable account.
No historical current-build-id was imported.

## Release-Blocking Work

- Audit and correct rootfs home-directory exclusion/sanitization.
- Verify no personal credentials or host identity enter live media.
- Correct release-controlled SSH and WireGuard defaults.
- Fix installation-independent desktop and screenshot paths.
- Review affected installer and first-boot configuration.
- Resolve untracked release-source material.
- Verify GitHub authentication and remote divergence.
- Inventory missing build dependencies and package build inputs.
- Validate kernel staging, inspector, and build publication tests.
- Exercise rootfs dry run and preservation prerequisite.
- Verify a fresh canonical build and ISO pipeline on the SATA host.
- Record full migration inventory and service health checks.

## Remaining Device/Workload Migration

- Verify GitHub synchronization on all four Sable installations.
- Restore required scripts and desktop customizations.
- Inventory and validate Freenet and BOINC runtime paths.
- Preserve the EliteBook BOINC manual-start requirement.
- Keep Pavilion Rubin runtime/database state local.
- Inventory local inference tools where applicable.
- Keep live data, private credentials, and large build artifacts
  outside the source repository.

## Retirement Criterion

Do not erase the old NVMe Sable installation until the new SATA
canonical environment has verified Git synchronization, build
capability, startup services, required workloads, and retained
development records.
