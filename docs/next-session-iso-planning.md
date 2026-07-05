# SableLinux — Next Session Prompt
## Topic: ISO Distribution Pipeline Planning

Please read the attached system prompt and project files in full before responding.

---

We are ready to begin planning the SableLinux ISO distribution pipeline. SableLinux is a fully operational source-built Linux distribution (LFS 12.4-systemd base) running Sway 1.10 on AMD RDNA4 hardware. The system is stable, the security/pentest stack is substantially complete, WireGuard VPN is live, and QEMU/KVM virtualization is working.

The next major milestone is producing a bootable, portable SableLinux ISO suitable for:
1. Live environment boot (try before install)
2. Installation onto target hardware via an installer
3. Eventually: public distribution as a commercial security research platform

This session is a planning and architecture session. I want to understand the full build pipeline from current system state to distributable ISO — what needs to be built, in what order, and what the major decision points are. Do not start building anything yet. Lay out the roadmap.

---

## Specific questions to address:

**1. Live environment architecture**
- squashfs + overlayfs approach: how does it work, what tools are needed
- How to capture current SableLinux system state into a squashfs image
- What needs to be stripped or added for a live environment vs. installed system
- initramfs design for live boot (vs. current installed-system initramfs)

**2. Hardware abstraction**
- Current kernel config is tuned for specific hardware (Intel Core Ultra 5 245K, AMD RX 9070 XT RDNA4, Z890 board)
- What needs to change in kernel config for a generic/portable ISO that boots on diverse hardware
- Firmware blob strategy for live ISO (AMD, Intel, broadcom wifi, etc.)
- How to handle RDNA4-specific Mesa/firmware requirements without breaking lesser hardware

**3. ISO assembly pipeline**
- Tools needed: grub-mkrescue, xorriso, mksquashfs — what's the full toolchain
- EFI + BIOS hybrid boot support
- GRUB config for live vs. install boot entries
- Build script architecture: reproducible, scriptable, automated

**4. Installer**
- Calamares vs. custom shell installer — tradeoffs for a security distro
- Calamares dependency chain on a source-built system
- Minimum viable installer for first release

**5. Package/layer strategy**
- How to implement the tiered layer concept (base ISO + inference layer + rocm-full + rocm-dev)
- Whether to pursue a pacman-format custom repo now or defer
- What belongs in the base ISO vs. optional layers

**6. Build environment**
- Should ISO builds happen on SableLinux itself, or in a chroot on the host (pots/Kubuntu)?
- Reproducibility: how to ensure ISO builds are consistent
- Where in the repo to put the ISO build pipeline (build-scripts/ or new iso-build/ directory)

**7. Secure Boot (future)**
- Brief note on where sbsigntools + efitools fit into the pipeline
- Defer to RC phase but note the integration point

---

## Current system state summary:
- SableLinux running on 500GB SATA SSD (/dev/sda), migrating to WD SN560 1TB NVMe (ordered)
- Kernel 6.16.1-lfs-12.4-systemd (rebuild #4 — dm-crypt, WireGuard, KVM, virtio all present)
- Full Sway desktop stack operational
- Security/pentest stack substantially complete
- WireGuard full tunnel to Linode vajra server operational
- QEMU/KVM with Ubuntu 24.04 VM confirmed working
- ROCm stack not yet started (next major build after ISO planning)
- NVMe migration pending (will happen before or alongside ISO work)

Please produce a structured roadmap with build order, decision points, and recommended approaches for each phase. Flag any blockers or prerequisites that need to be resolved before ISO work can begin.
