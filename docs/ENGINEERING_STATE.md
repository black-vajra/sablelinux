# SableLinux Engineering State

## Current Milestone

Recover the reproducible live/install ISO pipeline.

## Current Position

The previous live staging directories are absent and invalid. The project is being reframed around release engineering rather than ad hoc live USB construction.

## Reference Systems

1. Z890 SableLinux NVMe installation — development head and most complete package set.
2. HP EliteBook SableLinux installation — proven successful live/install deployment baseline.
3. BUILDLOG.md — chronological engineering record.
4. GitHub development branch — canonical repository state.

## Current Policy

VM-first testing.

No physical installs are overwritten until:

1. Live image boots successfully in QEMU/OVMF.
2. Installer succeeds in QEMU against a simulated EliteBook-level target.
3. Installed VM boots independently to Sway with networking.

## Immediate Objective

Create a clean build workspace and reconstruct the live ISO pipeline from documented sources.

## Deferred

- LUKS root install testing
- Secure Boot
- package-group manifests
- local package repository
- physical install testing
