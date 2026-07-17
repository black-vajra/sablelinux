# Canonical Live Initramfs Generation

The canonical live initramfs is generated after a build reaches state:

squashfs-generated

Generators:

scripts/live/build-live-initramfs-busybox.sh
scripts/live/build-live-initramfs-stage.sh

The low-level builder creates a minimal static-BusyBox archive that:

- discovers media labeled SABLELINUX
- mounts /live/filesystem.squashfs
- constructs a tmpfs-backed overlay
- switches into the generated SableLinux root

The stage wrapper:

- verifies repository and build provenance
- verifies the kernel, module tree, SquashFS, and static BusyBox inputs
- derives SOURCE_DATE_EPOCH from the build Git commit
- builds the archive twice in independent work directories
- requires byte-identical results
- validates gzip and cpio integrity
- inspects the embedded init implementation
- copies the matching canonical kernel into the build boot directory
- records hashes, size, archive contents, and generation metadata
- changes state only after successful validation

Output files:

/srv/sablelinux/builds/<build-id>/boot/vmlinuz-<kernel-release>

/srv/sablelinux/builds/<build-id>/initramfs/initramfs-live.img

Successful state:

initramfs-generated
