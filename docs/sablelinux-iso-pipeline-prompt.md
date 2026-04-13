# SableLinux — ISO Distribution Pipeline
## New Session Prompt — 2026-04-11

---

## Context

SableLinux is a custom Linux distribution built from source on an LFS 12.4-systemd base. It is a fully operational Wayland desktop with a complete security research and penetration testing stack. The goal of this session is to plan and begin executing the ISO distribution pipeline — the path from a working installed system to a bootable, distributable live ISO with an installer.

**Current system state:**
- Kernel: 6.16.1-lfs-12.4-systemd (rebuilt ×2)
- Desktop: Sway 1.10 on AMD RDNA4 (gfx1201)
- Full security/pentest stack installed (nmap, wireshark, metasploit, ghidra, radare2, etc.)
- Full Wayland stack (sway, foot, waybar, pipewire, firefox)
- Bootloader: GRUB, EFI, installed on /dev/sda (500GB internal SATA SSD)
- Filesystem: merged-usr, ext4 root
- No package manager — all packages built from source (LFS/BLFS)
- Hardware: Intel Core Ultra 5 245K, 32GB RAM, AMD RX 9070 XT (RDNA4/gfx1201)

**Pending before ISO work:**
- NVMe migration (WD SN560 1TB M.2 PCIe 4.0) — ordered, not yet installed
- `mitigations=off` in GRUB must be removed before any distributed ISO
- Secure Boot disabled — revisit at RC phase with sbsigntools + efitools

---

## ISO Pipeline Scope

The full pipeline consists of the following major phases. We will plan all of them and begin executing in order.

### Phase 1 — Hardware-Abstracted Kernel Config
The current kernel config is tuned for specific hardware (Intel Core Ultra 5 245K, RX 9070 XT, Z890 board). A distributable ISO needs a kernel config that boots on a broad range of x86_64 hardware:
- Audit current config for hardware-specific modules built-in vs. modular
- Identify what must be modular for generic hardware support
- Add broad HID, storage controller, NIC, GPU, USB coverage
- Retain security-relevant config (dm-crypt, CRYPTO_XTS, BPF, etc.)
- Retain AMDGPU + i915 support
- Initramfs must handle root detection generically (not hardcoded /dev/sda3)

### Phase 2 — Live Environment Construction
Build the squashfs + overlayfs live environment:
- Create a clean filesystem tree representing the live OS root
- Layer: squashfs (read-only base) + overlayfs (tmpfs writable layer) at boot
- Initramfs must mount squashfs, set up overlayfs, pivot_root into it
- Live user: `sable` (no password or known password) with sudo access
- Persistence: optional, not required for v1

### Phase 3 — Installer (Calamares)
Calamares is the standard graphical installer for custom distros:
- Build Calamares from source (Qt6 + KConfig deps — significant build)
- Configure for SableLinux: partitioning, user creation, bootloader, locale
- Live ISO boots to Sway → user launches Calamares to install to disk
- Post-install: system boots directly to Sway from installed drive

### Phase 4 — ISO Assembly
Assemble the bootable ISO image:
- Tools: grub-mkrescue + xorriso
- Layout: /boot/grub/grub.cfg, /LiveOS/squashfs.img, EFI boot stub
- Both BIOS (GRUB legacy) and UEFI boot support
- ISO must be hybrid (dd-able to USB)

### Phase 5 — Release Hardening
Before any public distribution:
- Remove `mitigations=off` from GRUB config
- Audit /etc for credentials, keys, or site-specific config that must not ship
- Strip build artifacts (/sources, /root build dirs) from the live image
- Set default locale, timezone, keymap to generic/UTC
- Revisit Secure Boot signing (sbsigntools + efitools + self-generated PK/KEK/db keys)

---

## Constraints & Design Decisions

- **No package manager in v1** — sable-install meta-script handles optional layers post-install
- **Tiered package strategy:** base ISO ships lean security stack + HIP runtime; ROCm/inference layers are user-invoked post-install
- **Calamares is the correct installer choice** — do not evaluate alternatives
- **squashfs + overlayfs is the correct live environment architecture** — standard, well-understood
- **grub-mkrescue + xorriso is the correct ISO assembly tool** — do not use mkisofs
- **Accessibility is a first-class feature** — screen reader, AT-SPI, TTS support must be present in the live environment
- **Target users:** HTB/OSCP/bug bounty red team workflows; AI inference on local hardware

---

## Build Environment

- **Host:** pots — Ubuntu 24.04.4 LTS, Intel Core Ultra 5 245K, 32GB RAM
- **SableLinux drive:** /dev/sda, mounted at /mnt/sable from host
- **Chroot available:** standard mount + chroot sequence established
- **Repo:** github.com/black-vajra/sablelinux, development branch
- **Build convention:** make -j14, --libdir=lib (meson), -DCMAKE_INSTALL_LIBDIR=lib (cmake)
- **GCC 15.2:** CFLAGS="-std=gnu17 -O2" for older C codebases
- **Backups at:** /mnt/two/backups/sable-system/blfs-backups/continued/

---

## Session Goal

Begin with Phase 1. Audit the current kernel config for hardware specificity, design the generic kernel config strategy, and produce a concrete plan and command sequence for the kernel rebuild. Then proceed through phases sequentially.

Do not skip ahead. Each phase has blockers that must be resolved before the next.
