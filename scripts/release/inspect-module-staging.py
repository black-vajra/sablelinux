#!/usr/bin/env python3
"""Read-only classification of a kernel-module staging transaction."""
import argparse
from pathlib import Path
import sys


def read_env(path):
    values = {}
    for line in path.read_text().splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            values[key] = value
    return values


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

    parent = build_root / "rootfs/lib/modules"
    if parent.is_symlink() or not parent.is_dir():
        raise ValueError("unsupported module directory layout")

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

    return "PUBLISHED_UNVERIFIED: verify both artifacts before recovery"


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
