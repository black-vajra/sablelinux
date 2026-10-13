# ACL 2.4.0 activation and recovery

This procedure is restricted to the exact normalized ACL A payload already
validated in the committed package VM. It uses the existing shared package
helpers. The preflight rejects all existing file/symlink destinations. No
preexisting payload files are backed up or replaced because collisions are
forbidden. Existing directory ownership/modes are retained; new files and
symlinks are root-owned with staged modes.

```sh
bash scripts/packages/activate-acl.sh --preflight
sudo bash scripts/packages/activate-acl.sh --activate
sudo bash scripts/packages/activate-acl.sh --validate
```

Activation creates a protected payload snapshot, provenance, installed-path
inventory and created-directory inventory under the ACL build's `activation/`.
A failure preserves pending recovery records and reports failure; it does not
silently continue. Inspect the record before recovery. The explicit command is:

```sh
sudo bash scripts/packages/activate-acl.sh --rollback
```

Rollback checks still-present installed additions for content/link changes
before removing any and removes newly created directories only when empty.
It refuses once installed rsync depends on libacl; roll back rsync first.
This narrowly handles this ACL-only addition, not arbitrary later consumers
or a general package transaction system. A prior rolled-back or pending
transaction is retained and cannot be reused for a new activation.

Successful repeated activation verifies the recorded installed payload without
reinstalling it. Host runtime regression testing and a measured activation
reuse check remain necessary. This script does not install rsync, change the
kernel, modify existing directory policies or satisfy live-ISO gates.
