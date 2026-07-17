# Tier 1 Direct-Boot Test Media

Generator:

scripts/live/build-test-media.sh

Required input state:

initramfs-generated

Output:

/srv/sablelinux/builds/<build-id>/media/sablelinux-live-test.ext4

The generated image is a sparse ext4 filesystem labeled:

SABLELINUX

It contains:

/live/filesystem.squashfs
/live/filesystem.squashfs.sha256
/live/build.env
/live/README.txt

The image is not a release ISO or USB artifact. It exists specifically for
Tier 1 direct-kernel QEMU/KVM validation.

The generator:

- verifies clean repository and build provenance
- verifies kernel, initramfs, and SquashFS inputs
- calculates an image size from the SquashFS size
- creates a sparse ext4 image
- assigns the required SABLELINUX label
- copies the canonical SquashFS to /live/filesystem.squashfs
- embeds build metadata and the SquashFS checksum
- runs a read-only e2fsck validation
- remounts the image read-only
- validates the embedded SquashFS byte-for-byte
- records filesystem UUID, size, hashes, and generator version

Successful state:

test-media-generated

The next state is reached only after direct QEMU/KVM validation:

tier1-validated
