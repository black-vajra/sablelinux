#!/usr/bin/env python3
"""Read-only classification of a kernel-module staging transaction."""
import argparse
import fcntl
import os
from pathlib import Path
import sys


def read_env(path):
    values = {}
    for line in path.read_text().splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            values[key] = value
    return values


def verify_publication(build_root, tree, release, index_manifest):
    import hashlib

    prefix = f"lib/modules/{release}/"

    def read_manifest(path):
        if path.is_symlink() or not path.is_file():
            raise ValueError("invalid manifest")

        entries = {}
        for line in path.read_text(encoding="utf-8").splitlines():
            if "  " not in line:
                raise ValueError("invalid manifest")

            digest, name = line.split("  ", 1)

            if (
                not name.startswith(prefix)
                or not name[len(prefix):]
                or any(part in ("", ".", "..") for part in name.split("/"))
                or chr(92) in name
                or chr(0) in name
            ):
                raise ValueError("unsafe manifest path")

            if (
                len(digest) != 64
                or any(c not in "0123456789abcdef" for c in digest)
                or name in entries
            ):
                raise ValueError("invalid manifest")

            entries[name] = digest

        if not entries:
            raise ValueError("invalid manifest")
        return entries

    candidate_path = (
        build_root / "metadata/candidate-kernel-modules.sha256"
    )

    if not candidate_path.exists():
        return "PUBLISHED_UNVERIFIED: verify both artifacts before recovery"

    try:
        candidate = read_manifest(candidate_path)
        indexes = read_manifest(index_manifest)
    except (ValueError, OSError, UnicodeError) as error:
        if str(error) == "unsafe manifest path":
            return "REFUSE: unsafe manifest path"
        return "REFUSE: invalid manifest"

    expected_indexes = {
        name: digest
        for name, digest in candidate.items()
        if (
            name[len(prefix):].startswith("modules.")
            and "/" not in name[len(prefix):]
        )
    }

    if not expected_indexes or indexes != expected_indexes:
        return "REFUSE: inconsistent module manifests"

    if not any(name.endswith(".ko") for name in candidate):
        return "REFUSE: invalid manifest"

    # A verified manifest must describe the complete published tree.
    # Reject unexpected files, symlinks and non-directory objects.
    expected_files = {
        name[len(prefix):] for name in candidate
    }
    actual_files = set()

    def refuse_traversal_error(error):
        # An incomplete inventory cannot establish publication integrity.
        raise error

    for directory, subdirs, files in os.walk(
        tree, topdown=True, followlinks=False,
        onerror=refuse_traversal_error,
    ):
        base = Path(directory)

        for name in subdirs:
            entry = base / name
            if entry.is_symlink():
                return "REFUSE: unsafe published file"

        for name in files:
            entry = base / name
            if entry.is_symlink() or not entry.is_file():
                return "REFUSE: unsafe published file"
            actual_files.add(entry.relative_to(tree).as_posix())

    missing_files = expected_files - actual_files
    unexpected_files = actual_files - expected_files

    if missing_files:
        return "REFUSE: published checksum mismatch"

    if unexpected_files:
        return "REFUSE: unexpected published file"

    for name, digest in candidate.items():
        relative = name[len(prefix):]

        current = tree
        if current.is_symlink() or not current.is_dir():
            return "REFUSE: unsafe published file"

        for component in relative.split("/"):
            current = current / component
            if current.is_symlink():
                return "REFUSE: unsafe published file"

        if not current.is_file():
            return "REFUSE: published checksum mismatch"

        try:
            checksum = hashlib.sha256()
            with current.open("rb") as stream:
                for chunk in iter(
                    lambda: stream.read(1024 * 1024), b""
                ):
                    checksum.update(chunk)
        except OSError:
            return "REFUSE: published checksum mismatch"

        if checksum.hexdigest() != digest:
            return "REFUSE: published checksum mismatch"

    return "PUBLISHED_VERIFIED"

def inspect(build_root):
    if not build_root.is_dir() or build_root.is_symlink():
        raise ValueError("invalid build root")

    env_path = build_root / "metadata/build.env"
    if env_path.is_symlink() or not env_path.is_file():
        raise ValueError("invalid build metadata")

    env = read_env(env_path)

    if env.get("BUILD_STATE") != "initialized":
        return "REFUSE: build is not initialized"

    if env.get("KERNEL_MODULES_STAGED") != "false":
        return "REFUSE: modules already marked staged"

    release = env.get("KERNEL_RELEASE", "")
    if not release or "/" in release or release in (".", ".."):
        raise ValueError("invalid kernel release")

    rootfs = build_root / "rootfs"
    if rootfs.is_symlink() or not rootfs.is_dir():
        raise ValueError("invalid rootfs directory")

    lib = rootfs / "lib"

    if lib.is_symlink():
        if lib.readlink() != Path("usr/lib"):
            raise ValueError("unsafe merged-usr symlink")

        parent = rootfs / "usr/lib/modules"
        for component in (
            rootfs / "usr",
            rootfs / "usr/lib",
            parent,
        ):
            if component.is_symlink():
                raise ValueError("unsafe module path symlink")
    else:
        parent = lib / "modules"
        if lib.is_symlink():
            raise ValueError("unsafe lib directory")

    if parent.is_symlink() or not parent.is_dir():
        raise ValueError("unsupported module directory layout")

    fd = os.open(
        parent,
        os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW
    )
    try:
        try:
            fcntl.flock(fd, fcntl.LOCK_SH | fcntl.LOCK_NB)
        except BlockingIOError:
            raise ValueError("module staging lock is held")

        tree = parent / release
        manifest = build_root / "metadata/staged-kernel-module-indexes.sha256"

        if tree.is_symlink() or manifest.is_symlink():
            return "REFUSE: unexpected symlink"

        has_tree = tree.exists()
        has_manifest = manifest.exists()

        if not has_tree and not has_manifest:
            return "CLEAN: nothing published"

        if not has_tree and has_manifest:
            return "ORPHAN_MANIFEST: interrupted publication suspected"

        if has_tree and not has_manifest:
            return "REFUSE: module tree exists without manifest"

        return verify_publication(build_root, tree, release, manifest)
    finally:
        os.close(fd)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--build-root", type=Path, required=True)
    args = parser.parse_args()

    try:
        print(inspect(args.build_root))
    except (OSError, ValueError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
