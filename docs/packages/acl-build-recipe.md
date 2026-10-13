# Canonical ACL staged build recipe

`scripts/packages/build-acl.sh` imports the reviewed ACL 2.4.0 build procedure.
It makes no network requests and performs no host installation or deletion.
Run as pepper on Z890 SableLinux:

```sh
bash scripts/packages/build-acl.sh --stage \
  --source-review /srv/sablelinux/sources/acl-review-7kVNUmV5 \
  --build-dir /srv/sablelinux/package-builds/acl/2.4.0/recipe-validation-1
```

Run the identical command again to verify completed-stage reuse. A completed
matching build verifies payload inventory, links, modes, ownership and file
hashes without modifying its build tree. Changed declared inputs or an
incomplete attempt are rejected and preserved; choose a new attempt directory.
The source archive SHA256 and expected GPG signer are pinned. Configure,
compilation, upstream tests and staged physical ACL restoration must succeed
before the completion marker is written. Root-only upstream skips are not
counted as passes.

Source and staging directories are isolated from workspace setgid inheritance.
The canonical workspace's shared-directory policy is retained. No failed test
is automatically waived. All logs and actual invocation timestamps remain in
external build metadata.

The resume identity records recipe/framework/source hashes and selected compiler,
test-tool and attr inputs. It is a guard against known stale-input reuse, not a
complete frozen input closure. Full same-workspace idempotence and fresh-build
byte reproducibility still require measured acceptance tests. New output hashes
must be compared with the already VM-validated candidate; a changed payload
requires affected validation before activation.
