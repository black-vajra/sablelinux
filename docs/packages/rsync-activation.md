# Rsync activation and recovery

The activator pins the five original rsync 3.3.0 file hashes recorded on
2026-10-13 and permits only the exact five-file normalized rsync A payload
already validated in the committed VM. Installed ACL file hashes must match.
No dependencies, kernel files, services or directories are changed.

Run preflight as pepper, then exercise as root:

```sh
bash scripts/packages/activate-rsync.sh --preflight
sudo bash scripts/packages/activate-rsync.sh --exercise
```

The exercise creates an isolated root fixture from canonical originals,
backs them up, installs the candidate into that fixture, verifies its hashes,
modes, ownership and executable version, restores the originals and checks
their hashes/metadata. The installed host files remain untouched. Logs and
snapshots remain under `/srv/sablelinux/package-builds/rsync-transaction-exercise-*`.
This tests transaction mechanics separately from the already-passing VM
preservation tests. Retain the successful exercise record before activation.

```sh
sudo bash scripts/packages/activate-rsync.sh --activate
sudo bash scripts/packages/activate-rsync.sh --validate
```

Original files are preserved with cp -a and a numeric getfacl snapshot in a
protected activation directory. Candidate installation uses same-directory
temporary files and atomic per-file renames. This is not an atomic five-file
transaction: a failure leaves pending state and recovery information. Inspect
before recovery. Do not run rsync workloads during replacement or rollback.

```sh
sudo bash scripts/packages/activate-rsync.sh --rollback
```

Rollback verifies original backup hashes and rejects edited live destinations
before restoring any. Original ownership, modes, timestamps and copied xattrs
are retained, and ACL metadata is restored explicitly. ACL remains installed.
After restoring rsync, the separate ACL rollback can be considered if required.
Pending or rolled-back activation records are preserved and cannot be reused
as a new transaction. Repeating successful activation verifies recorded files
without reinstalling them. Host functionality and measured reuse checks remain
required; this does not satisfy ISO boot or installation gates.
