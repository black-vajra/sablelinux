# SableLinux Canonical Package Framework

The Z890 SableLinux installation is the canonical build and release authority.

Package engineering follows this sequence:

1. Verify source provenance and hashes.
2. Build outside the repository.
3. Install into an isolated staged filesystem tree.
4. Remove runtime-generated and host-specific files.
5. Reject device nodes, sockets, pipes, and other special files.
6. Validate required package contents.
7. Generate deterministic file and SHA256 manifests.
8. Record build metadata.
9. Run a non-modifying activation preflight.
10. Activate only through a separate reviewed operation.
11. Validate the running system.
12. Commit scripts, documentation, and validation evidence.

Build and activation are deliberately separate.

A successful build does not authorize running-system modification.

## Shared Framework

`common.sh` contains reusable package-engineering functions.

Package-specific scripts should define only:

- source and version;
- source verification requirements;
- configure and build commands;
- staged-payload policy;
- package-specific validation;
- activation requirements.

Generated build trees and package payloads remain outside the Git repository
under `/srv/sablelinux`.

Canonical source archives remain under `/srv/sablelinux/sources`.
