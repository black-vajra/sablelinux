# Canonical SquashFS Generation

The canonical SquashFS image is generated from a validated build root in
state rootfs-generated.

Generator:

scripts/live/build-squashfs.sh

Output:

/srv/sablelinux/builds/<build-id>/squashfs/filesystem.squashfs

The generator:

- verifies repository and build provenance
- refuses dirty repository state
- accepts only rootfs-generated builds
- uses Zstandard compression
- uses a 1 MiB SquashFS block size
- uses the Git commit timestamp for supported time-normalization options
- enables mksquashfs reproducibility support when available
- writes through a temporary output and promotes atomically
- validates the generated filesystem with unsquashfs
- reads embedded SableLinux identity and build metadata
- records tool options, source-manifest hash, size, and SHA-256
- changes build state only after validation succeeds

A stage-validation build may be superseded after proving its intended stage.
A release-candidate build must originate from a commit containing every
generator used for that candidate.
