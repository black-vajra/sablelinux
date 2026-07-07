# SableLinux QEMU/KVM Direct Live Boot Test — logos — 2026-07-07

## Purpose

Document the first successful QEMU/KVM live boot of the recovered EliteBook-derived SableLinux payload on the Kubuntu partition of the HP EliteBook host `logos`.

This was a direct kernel/initramfs/live-media test, not a full ISO, GRUB, or OVMF validation.

## Host

- Hostname: `logos`
- Host OS: Ubuntu/Kubuntu 26.04 LTS
- Kernel: `7.0.0-27-generic`
- User: `angel`
- Virtualization: AMD SVM, `/dev/kvm`, `kvm_amd`, QEMU/KVM available

## Artifact layout

- Repository: `/home/angel/sablelinux`
- Recovered live payload: `/home/angel/sablelinux-transfer-live`
- VM workspace: `/home/angel/VMs/sablelinux`
- Live media image: `/home/angel/VMs/sablelinux/disks/sable-live-media.raw`
- Working BusyBox test initramfs: `/home/angel/VMs/sablelinux/disks/initramfs-live-busybox-test.img`

## Live media image

The VM live media is an 8G sparse raw image with one ext4 partition labeled `SABLELINUX`.

Expected contents:

- `/live/filesystem.squashfs`
- `/boot/vmlinuz-6.16.1-sable-compat2`
- `/boot/initramfs-6.16.1-sable-compat2.img`
- `/logs/elitebook-vulfen-live-payload-20260703.sha256`

## Failed dracut path

The transferred `initramfs-6.16.1-sable-compat2.img` is dracut/systemd based.

Observed failures:

1. Direct boot without live arguments dropped to initramfs emergency mode.
2. Dracut live arguments waited on `/dev/mapper/live-rw`.
3. Overlayfs dracut attempt failed resolving `/run/rootfsbase`.

Conclusion: the dracut live path is currently mismatched with the recovered live-media layout.

## Successful BusyBox path

A temporary BusyBox initramfs successfully performed:

1. `findfs LABEL=SABLELINUX`
2. ext4 mount of the live media
3. squashfs mount of `/live/filesystem.squashfs`
4. tmpfs-backed overlay mount
5. `switch_root` into `/sbin/init`

Observed result:

- SableLinux reached graphical Sway userspace.
- Terminal was available as user `sable` on host `vulfen`.
- QEMU user networking assigned `10.0.2.15/24`.
- WireGuard interface `wg0` was present with `10.6.0.5/24`.

## Build command

From the repository:

    cd ~/sablelinux || exit 1
    scripts/live/build-live-initramfs-busybox.sh \
      ~/VMs/sablelinux/disks/initramfs-live-busybox-test.img

## QEMU direct-boot command

    cd ~/VMs/sablelinux/disks || exit 1

    qemu-system-x86_64 \
      -name sablelinux-live-busybox-test \
      -enable-kvm \
      -cpu host \
      -smp 4 \
      -m 4096 \
      -machine q35,accel=kvm \
      -kernel "$HOME/sablelinux-transfer-live/boot/vmlinuz-6.16.1-sable-compat2" \
      -initrd "$HOME/VMs/sablelinux/disks/initramfs-live-busybox-test.img" \
      -append "console=ttyS0 console=tty0 loglevel=7" \
      -drive file="$HOME/VMs/sablelinux/disks/sable-live-media.raw",format=raw,if=virtio,readonly=on \
      -device virtio-vga \
      -display gtk \
      -netdev user,id=net0 \
      -device virtio-net-pci,netdev=net0 \
      -serial mon:stdio \
      -no-reboot

Exit QEMU from the initiating terminal with `Ctrl-a x`.

## Validation status

Validated:

- QEMU/KVM launches the VM.
- Kernel boots.
- BusyBox initramfs finds `LABEL=SABLELINUX`.
- Squashfs mounts.
- Overlay root mounts.
- `switch_root` succeeds.
- SableLinux reaches Sway userspace.
- Basic network presence observed.

Deferred:

- Full in-guest command capture.
- Firefox launch validation.
- Installer validation.
- OVMF/GRUB ISO validation.
- Install-target qcow2 testing.
- LUKS install testing.
