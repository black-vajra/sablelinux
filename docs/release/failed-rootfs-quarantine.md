# Failed rootfs quarantine and recovery

## Scope

This procedure applies only to failed rootfs staging directories
on the canonical Z890 SableLinux release authority.

The utility is:

`scripts/release/quarantine-failed-rootfs.py`

The utility preserves the failed capture in a private quarantine
directory. It does not delete the capture or validate a newly
generated rootfs.

## Preconditions

Before any production operation:

1. Confirm the current canonical hostname, filesystem mounts,
   repository revision, and selected build ID.
2. Confirm the build is in its initialized state and no
   other release operation is running.
3. Run the full quarantine regression suite successfully.
4. Review the inspection output and verify there are no
   nested mounts or unexpected staging directories.
5. Confirm sufficient filesystem capacity.

Do not infer current build state from historical build logs.

## Read-only inspection

Run the utility with only `--build-id`:

    sudo python3 -B scripts/release/quarantine-failed-rootfs.py \
      --build-id BUILD_ID

No mutating option is implied.

## Production quarantine

Only after a successful preflight and operator approval:

    sudo python3 -B scripts/release/quarantine-failed-rootfs.py \
      --build-id BUILD_ID \
      --execute-quarantine \
      --confirm-build-id BUILD_ID

Both ID values must match. The operation requires root.

The failed capture is preserved at:

    /srv/sablelinux/quarantine/BUILD_ID/rootfs

The replacement staging directory is:

    /srv/sablelinux/builds/BUILD_ID/rootfs

Do not delete or repurpose the quarantine directory.

## Interrupted transaction

If the original staging directory is absent but the
quarantined capture and recovery evidence are present,
inspect those paths before attempting recovery.

After verifying the interrupted state and obtaining
operator approval:

    sudo python3 -B scripts/release/quarantine-failed-rootfs.py \
      --build-id BUILD_ID \
      --recover-interrupted \
      --confirm-build-id BUILD_ID

Recovery creates an empty staging directory. It does
not return the failed capture to active staging.

Unexpected directories with `.rootfs-recovery-` or
`.rootfs-quarantine-` prefixes require manual inspection.
Never automatically remove or overwrite them.

If active staging already exists, or recovery evidence
fails validation, stop and investigate.

## Security

Quarantine is private and root-owned. It may contain
host-specific configuration, personal data, or secrets.

Never include quarantine contents in release media,
publish them, or treat them as canonical release inputs.

Never bypass the release home-directory security
validator or rootfs exclusion policy.

## Validation after quarantine

Regenerate the rootfs using the canonical release script.

Verify:

- `/home` and `/root` ownership and permissions.
- Absence of host home-directory contents.
- Absence of credentials and other sensitive host data.
- Required release-owned `/home/sable` configuration.
- Release metadata and package staging integrity.
- Rootfs security-validation success.

Proceed to SquashFS generation only after these checks pass.

## Failure policy

Use atomic no-replace renaming. Do not fall back to
ordinary replacing renames.

Unexpected mount points, metadata, files, ownership,
transaction state, or abandoned staging are blockers.

Filesystem synchronization reduces crash exposure,
but these tests do not establish a guarantee of recovery
from every possible power-loss or storage failure.
