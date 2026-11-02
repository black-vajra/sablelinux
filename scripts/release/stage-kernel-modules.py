#!/usr/bin/env python3
"""Stage verified kernel-candidate modules into an existing release rootfs.

A successful run publishes only the selected release module tree inside rootfs.
It does not alter BUILD_STATE or KERNEL_MODULES_STAGED; the calling release
stage must update metadata only after its remaining validations succeed.
"""

import argparse
import fcntl
import hashlib
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

HASH_LINE = re.compile(r"([0-9a-f]{64})  (.+)")


def fail(message):
    raise ValueError(message)


def fields(path):
    result = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        if "=" not in line:
            fail(f"malformed metadata: {path}")
        name, value = line.split("=", 1)
        if name in result:
            fail(f"duplicate metadata key: {name}")
        result[name] = value
    return result


def hash_file(path):
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def no_symlink_ancestors(path, root):
    """Ensure root and every existing descendant on path are real directories."""
    if not root.is_dir() or root.is_symlink():
        fail(f"unsafe root directory: {root}")
    try:
        relative = path.relative_to(root)
    except ValueError:
        fail(f"path escapes expected root: {path}")
    node = root
    for part in relative.parts:
        node = node / part
        if node.is_symlink():
            fail(f"symlink in directory path: {node}")
        if node.exists() and not node.is_dir():
            fail(f"non-directory in directory path: {node}")


def load_manifest(path, release):
    prefix = f"lib/modules/{release}/"
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines:
        fail("empty module manifest")
    results = []
    seen = set()
    for line in lines:
        m = HASH_LINE.fullmatch(line)
        if not m:
            fail("invalid manifest entry")
        digest, name = m.groups()
        parts = Path(name)
        if (not name.startswith(prefix) or parts.is_absolute()
                or any(x in (".", "..") for x in parts.parts)
                or name in seen or name.endswith("/")):
            fail(f"unsafe or duplicate module entry: {name}")
        seen.add(name)
        results.append((name, digest))
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build-root", required=True)
    parser.add_argument("--workspace", default="/srv/sablelinux/kernel-builds")
    parser.add_argument("--candidate-id", help="optional assertion against build metadata")
    args = parser.parse_args()

    repo = Path(__file__).resolve().parents[2]
    verifier = repo / "scripts/release/verify-kernel-candidate.py"
    build_root = Path(os.path.abspath(args.build_root))
    workspace = Path(os.path.abspath(args.workspace))
    if not build_root.is_dir() or build_root.is_symlink():
        fail("build root must be an existing real directory")
    if not workspace.is_dir() or workspace.is_symlink():
        fail("kernel workspace must be an existing real directory")
    build = fields(build_root / "metadata/build.env")
    candidate_id = build.get("KERNEL_CANDIDATE_ID", "")
    release = build.get("KERNEL_RELEASE", "")
    if not candidate_id or candidate_id in (".", "..") or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]*", candidate_id):
        fail("missing or unsafe kernel candidate ID")
    if args.candidate_id and args.candidate_id != candidate_id:
        fail("candidate ID does not match build metadata")
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._+~-]*", release):
        fail("missing or unsafe selected kernel release")
    if build.get("BUILD_STATE") != "initialized":
        fail("build must be initialized")
    if build.get("KERNEL_MODULES_STAGED") != "false":
        fail("build must have KERNEL_MODULES_STAGED=false")

    rootfs = build_root / "rootfs"
    # Merged-/usr installations expose /lib -> usr/lib.  Only that exact
    # relative link is accepted; publish through the physical /usr/lib path.
    lib = rootfs / "lib"
    if lib.is_symlink():
        if os.readlink(lib) != "usr/lib":
            fail("unsupported or unsafe /lib symlink")
        parent = rootfs / "usr/lib/modules"
    elif lib.is_dir():
        parent = rootfs / "lib/modules"
    else:
        fail("rootfs/lib missing or not a supported directory")
    no_symlink_ancestors(parent, build_root)
    if not parent.is_dir():
        fail("rootfs/lib/modules must exist after filesystem capture")
    destination = parent / release
    if destination.exists() or destination.is_symlink():
        fail("selected release module tree already exists; refusing overwrite")

    candidate = workspace / candidate_id
    if candidate.is_symlink() or not candidate.is_dir():
        fail("candidate directory missing or symlinked")
    candidate_env = fields(candidate / "metadata/compilation.env")
    if candidate_env.get("KERNEL_RELEASE") != release:
        fail("candidate kernel release does not match build selection")

    expected_manifest = build_root / "metadata/candidate-kernel-modules.sha256"
    original_manifest = candidate / "metadata/kernel-modules.sha256"
    if expected_manifest.is_symlink() or original_manifest.is_symlink():
        fail("manifest must not be symlinked")
    if not original_manifest.is_file() or not expected_manifest.is_file():
        fail("candidate module manifest is missing")
    if expected_manifest.read_bytes() != original_manifest.read_bytes():
        fail("build module manifest does not match verified candidate")

    metadata_manifest = build_root / "metadata/staged-kernel-module-indexes.sha256"
    if metadata_manifest.exists() or metadata_manifest.is_symlink():
        fail("module metadata manifest already exists")

    lock_fd = os.open(parent, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    try:
        try:
            fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            fail("another module staging operation holds the destination lock")
        # Avoid publishing modules unless the full candidate is validated.
        subprocess.run(
            [sys.executable, "-B", str(verifier),
             "--workspace", str(workspace), "--candidate-id", candidate_id],
            check=True,
        )
        records = load_manifest(original_manifest, release)
        source_root = candidate / "modules"
        if source_root.is_symlink() or not source_root.is_dir():
            fail("missing or symlinked candidate module directory")
        with tempfile.TemporaryDirectory(prefix=".module-staging-", dir=parent) as temporary:
            temp_root = Path(temporary)
            for name, digest in records:
                suffix = Path(name).relative_to(f"lib/modules/{release}")
                src = source_root / name
                no_symlink_ancestors(src.parent, source_root)
                if src.is_symlink() or not src.is_file():
                    fail(f"missing or symlinked module: {name}")
                if hash_file(src) != digest:
                    fail(f"candidate module checksum mismatch: {name}")
                dest = temp_root / suffix
                dest.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(src, dest, follow_symlinks=False)
                if hash_file(dest) != digest:
                    fail(f"staged module checksum mismatch: {name}")
            # Kernel-generated depmod inputs and indexes are not included in
            # the .ko manifest. Copy only regular top-level metadata files,
            # record their source checksums, and recheck deployed checksums.
            source_tree = source_root / "lib/modules" / release
            metadata_records = []
            for entry in sorted(source_tree.iterdir(), key=lambda p: p.name):
                if entry.is_symlink():
                    # The kernel's build link points into the canonical
                    # compilation tree. Verify it, but do not publish it
                    # into the release filesystem.
                    expected = candidate / "obj"
                    if (
                        entry.name == "build"
                        and entry.readlink() == expected
                        and expected.is_dir()
                        and not expected.is_symlink()
                    ):
                        continue
                    fail(f"unsafe symlink in candidate module root: {entry}")
                if entry.is_dir():
                    continue
                if not entry.is_file() or not entry.name.startswith("modules."):
                    fail(f"unexpected candidate module metadata: {entry}")
                digest = hash_file(entry)
                target = temp_root / entry.name
                shutil.copy2(entry, target, follow_symlinks=False)
                if hash_file(target) != digest:
                    fail(f"staged module metadata checksum mismatch: {entry.name}")
                metadata_records.append((entry.name, digest))
            if not metadata_records:
                fail("candidate module metadata is missing")
            if destination.exists() or destination.is_symlink():
                fail("selected module destination appeared during staging")
            # TemporaryDirectory defaults to 0700. The published
            # release-kernel module tree must be traversable.
            os.chmod(temp_root, 0o755)

            # Prepare metadata before publishing the module tree.
            # The candidate manifest remains authoritative.
            with tempfile.TemporaryDirectory(
                prefix=".module-manifest-",
                dir=metadata_manifest.parent,
            ) as manifest_tmp:
                prepared = Path(manifest_tmp) / "indexes.sha256"
                with prepared.open("x", encoding="utf-8") as stream:
                    for name, digest in metadata_records:
                        stream.write(
                            f"{digest}  lib/modules/{release}/{name}\n"
                        )
                    stream.flush()
                    os.fsync(stream.fileno())

                if destination.exists() or destination.is_symlink():
                    fail("module destination appeared before publication")

                # Atomic no-overwrite publication of the manifest.
                os.link(prepared, metadata_manifest)

                try:
                    os.rename(temp_root, destination)
                except OSError:
                    # No module tree was published; undo our manifest.
                    metadata_manifest.unlink()
                    raise
        print(f"PASS: published {len(records)} verified module files and {len(metadata_records)} metadata files to {destination}")
        print("NOTE: build metadata and state intentionally unchanged")
    finally:
        os.close(lock_fd)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, subprocess.CalledProcessError, KeyError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(1)
