# SableLinux

*Developed by Jonathan Brown — Border Cyber Group*

A custom Linux distribution built from source on Linux From Scratch 12.4-systemd.

SableLinux targets advanced users who want a system built for serious work:
security research, penetration testing, OSINT, journalistic research,
AI/LLM workflows, gaming, and virtualization. It is dark, precise, and
high-capability.

**Status:** LFS base complete. BLFS in progress.
**Domain:** [sablelinux.dev](https://sablelinux.dev)
**Blog:** [bordercybergroup.com](https://bordercybergroup.com)

---

## Hardware Target

| Component | Specification |
|-----------|---------------|
| CPU | Intel Core Ultra 5 245K (14 cores) |
| RAM | 30GB |
| GPU (integrated) | Intel Arc / Meteor Lake |
| GPU (discrete) | AMD Radeon PowerColor RDNA4 |
| Boot device | 500GB USB SSD |

---

## Current System State

- **Kernel:** 6.16.1-lfs-12.4-systemd
- **Init:** systemd 257
- **Boot:** Independent UEFI boot from USB SSD, no manual intervention
- **Display:** Intel Arc (i915, firmware loaded) + AMD RDNA4 (amdgpu module)
- **Network:** systemd-networkd + systemd-resolved, 1Gbps confirmed
- **Base:** LFS 12.4-systemd complete

---

## Repository Structure
```
sablelinux/
├── Books/          Reference documentation (LFS 12.4, 13.0-rc1, BLFS)
├── build/          Build scripts and kernel configuration
│   ├── make-initramfs.sh       Custom busybox initramfs builder
│   └── kernel-config-6.16.1   Kernel config for target hardware
├── build-logs/     Package and milestone build logs
├── docs/           Project documentation
│   └── security/   Security concepts and research notes
└── tools/          Build environment utilities
```

---

## Build Highlights

**Custom busybox initramfs** — Ubuntu's mkinitramfs was incompatible with our
unencrypted USB SSD setup due to hardcoded LUKS assumptions. We built a minimal
initramfs from scratch using busybox, with UUID-based root detection and Intel
Arc firmware pre-loaded for early boot GPU initialization.

**Intel Arc firmware** — i915 Meteor Lake requires firmware in the initramfs
(not just /lib/firmware) because the driver is built-in and runs before the
root filesystem mounts. All five firmware blobs are included in the initramfs
build script.

**AMD RDNA4 support** — amdgpu built as a module (not built-in) to avoid the
same firmware timing issue as i915. Module loads after root mounts, firmware
available at load time.

**UUID-based boot** — All partition references use UUIDs throughout grub.cfg,
fstab, and initramfs. Critical for a USB-based system where device enumeration
order varies.

---

## Roadmap

### Phase 1 — LFS Base ✅
Complete. Independent boot, dual GPU support, system stabilization.

### Phase 2 — BLFS Essential Infrastructure 🔄
- sudo, OpenSSH, wget, git, certificates
- Mesa with AMD/Intel GPU support
- Wayland compositor

### Phase 3 — Security Platform
- Network analysis tools
- Exploitation frameworks
- Wireless tools
- OSINT toolchain (Maltego, Recon-ng, theHarvester, etc.)
- Journalistic research tools (metadata analysis, anonymization stack)
- TPM2 integration

### Phase 4 — AI/LLM Stack
- Python scientific computing stack
- ROCm for AMD GPU compute
- Local LLM inference

### Phase 5 — Gaming & Virtualization
- Vulkan, Steam, Wine
- QEMU/KVM, libvirt

### Phase 6 — Distribution
- sable-install.sh installer
- Public release

---

## Key Technical Decisions

**Why LFS?** Full control over every component. Every binary on the system
was compiled from source with deliberate configuration choices. No package
manager assumptions, no distribution decisions we didn't make ourselves.

**Why USB SSD?** Portability — the system runs on the target hardware without
requiring installation. The USB SSD is the distribution medium during
development.

**Why systemd?** Broad BLFS package compatibility and modern service management.
The LFS 12.4-systemd edition was chosen deliberately.

---

## Documentation

Build journey documented at [bordercybergroup.com](https://bordercybergroup.com).

Security concepts in `docs/security/concepts/` covering TPM2, Intel SGX,
and AMD SEV.

---

## Maintainer

**Jonathan Brown**
Chief Researcher, Border Cyber Group
[bordercybergroup.com](https://bordercybergroup.com)

---

## License

See [LICENSE](LICENSE).

---

*SableLinux is under active development. Public release targeted within one year.*
