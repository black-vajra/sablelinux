# SableLinux Repository Layout

This repository contains SableLinux source-build engineering material, scripts, documentation, release notes, and historical project evidence.

## Top-Level Layout

- `assets/` — Project assets such as screenshots, device notes, and non-source media.
- `blfs/` — SableLinux-specific BLFS notes and policy. Full BLFS book mirrors are not stored here.
- `build/` — Active low-level build helpers and kernel/initramfs configuration material.
- `build-logs/` — Current build milestone/package logs.
- `build-scripts/` — Active package/build scripts used during SableLinux construction.
- `docs/` — Maintained current documentation, engineering state, release plans, hardware notes, and procedures.
- `history/` — Historical evidence only. Not authoritative for current system state.
- `scripts/` — Structured project scripts, especially installer-related tooling.
- `tools/` — Operator tools, inspection utilities, maintenance helpers, and verification notes.

## Current vs Historical Material

`docs/` is the authoritative location for maintained project documentation.

`history/` preserves old notes, handoff material, archived scripts, imported project memory, and build evidence. Material in `history/` may be outdated and must not be treated as current without verification.

## External Reference Material

Large upstream documentation mirrors, including LFS/BLFS HTML book trees, are not stored in this repository. Reference material should be linked, regenerated, or downloaded outside the Git worktree when needed.

## Executable Files

Executable tracked files should be limited to actual runnable scripts and tools.

Documentation, logs, archived scripts, screenshots, PDFs, text inventories, and historical notes should be mode `0644`.

## Generated Artifacts

Generated build output, ISO images, squashfs images, temporary chroots, and local staging trees should remain outside the repository unless deliberately added as small manifests or documentation.
