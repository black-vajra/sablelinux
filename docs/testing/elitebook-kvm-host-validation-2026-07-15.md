# EliteBook KVM Host Validation — 2026-07-15

## Host

- Hostname: vulfen
- Operating system: Sable Linux 1.0
- Kernel: 6.16.1-sable-compat2
- CPU: AMD Ryzen 7 PRO 5875U
- Logical CPUs: 16
- Memory: approximately 14 GiB

## Verified capabilities

The EliteBook successfully operated as a hardware-accelerated QEMU/KVM host.

Verified:

- AMD-V enabled
- /dev/kvm available to user sable
- kvm_amd active
- Nested virtualization enabled
- Nested paging enabled
- AMD IOMMU active
- QEMU 9.2.3 operational
- Q35 machine emulation operational
- EDK2 UEFI firmware operational
- VirtIO block, network, and display devices available
- QEMU user-mode networking available
- GTK and SDL display backends available

A blank UEFI VM booted successfully, proving the basic KVM, Q35, firmware,
display, storage, and networking path.

## Recovered live assets

The July live-build assets remain on the encrypted Kubuntu installation:

- /mnt/kubuntu-root/home/angel/sablelinux-transfer-live/boot/vmlinuz-6.16.1-sable-compat2
- /mnt/kubuntu-root/home/angel/sablelinux-transfer-live/boot/initramfs-6.16.1-sable-compat2.img
- /mnt/kubuntu-root/home/angel/sablelinux-transfer-live/live/filesystem.squashfs
- /mnt/kubuntu-root/home/angel/VMs/sablelinux/disks/sable-live-media.raw

Recorded SHA-256 values:

- Kernel: a1582514ef786631e0e15f2f0fea0002fa6d458cf3e3c620bd66875d1d8a45ba
- Installed initramfs: 8a0c382d8cbd63526d658329a1c838c998c26d81770cb4e02f8689312b4a17e2
- SquashFS: 7655b52c7b3cb87c2b2021edb26a1afb15b2b9fe3e411dc060b708a2230111bf
- Raw live medium: 244faeb9d2f84328315333094fd52cd58df632b5d081e2311ad687da63f53611

The recovered kernel matches the installed EliteBook kernel exactly.

## Live-initramfs requirement

The installed initramfs is not the correct direct-live-boot initramfs.

The successful path uses:

scripts/live/build-live-initramfs-busybox.sh \
  ~/VMs/sablelinux/disks/initramfs-live-busybox-test.img

That BusyBox initramfs locates LABEL=SABLELINUX, mounts the SquashFS,
constructs the overlay root, and performs switch_root.

## Successful VM configuration

The validated guest used:

- 2 virtual CPUs
- 3072 MiB RAM
- Q35 with KVM acceleration
- virtio-vga
- SDL display backend
- VirtIO raw live medium
- QEMU user-mode networking
- BusyBox live initramfs

The guest reached SableLinux userspace and displayed its login environment.
The host Sway session, terminal, Waybar, and Firefox remained operational.

## GTK observation

An earlier GTK-backed run appeared to disrupt the graphical session.

Journal review found no evidence of:

- OOM termination
- amdgpu reset
- GPU ring timeout
- kernel panic
- QEMU coredump
- Sway coredump
- Waybar coredump

The host remained responsive and completed an orderly shutdown. Therefore,
the event is not evidence that the EliteBook lacks adequate hardware capacity.

SDL is the currently validated backend. GTK under Sway remains unresolved.

## Engineering conclusion

The EliteBook is suitable as a direct QEMU/KVM development and regression
platform for SableLinux.

The next step is to convert the validated command into a repository script
with prerequisite checks, structured logging, and a writable installation
target.
