#!/usr/bin/env python3
"""Verify and publish a staged SableLinux kernel-candidate build."""

import argparse
import hashlib
import os
import re
import sys
import tempfile
from pathlib import Path


def require(condition, message):
    if not condition:
        raise ValueError(message)


def metadata_from(path):
    result = {}
    for line in path.read_text().splitlines():
        key, separator, value = line.partition("=")
        require(separator and key and key not in result,
                "invalid or duplicate build metadata")
        result[key] = value
    return result


def digest(path):
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1048576), b""):
            h.update(chunk)
    return h.hexdigest()


def atomic_write(path, content):
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w",
            encoding="utf-8",
            prefix=".publish-",
            dir=path.parent,
            delete=False,
        ) as stream:
            temporary = Path(stream.name)
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())

        os.chmod(temporary, 0o664)
        os.replace(temporary, path)
        temporary = None
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def verify_artifacts(root, release):
    boot = root / "boot"
    manifest = boot / "kernel-artifacts.sha256"

    require(boot.is_dir() and not boot.is_symlink(),
            "invalid boot directory")
    require(manifest.is_file() and not manifest.is_symlink(),
            "missing artifact manifest")

    expected = {
        f"vmlinuz-{release}",
        f"System.map-{release}",
        f"config-{release}",
    }

    found = {}

    for line in manifest.read_text().splitlines():
        parts = line.split(maxsplit=1)
        require(len(parts) == 2, "malformed artifact manifest")
        checksum, name = parts
        require(re.fullmatch(r"[0-9a-f]{64}", checksum) is not None,
                "invalid checksum")
        require(name in expected and name not in found,
                "unexpected or duplicate artifact")
        found[name] = checksum

    require(set(found) == expected, "incomplete artifact manifest")

    for name, checksum in found.items():
        path = boot / name
        require(path.is_file() and not path.is_symlink(),
                f"invalid artifact: {name}")
        require(digest(path) == checksum,
                f"checksum mismatch: {name}")


def publish(root, state_dir, build_id):
    require(re.fullmatch(r"[A-Za-z0-9._-]+", build_id) is not None,
            "invalid build ID")
    require(root.is_dir() and not root.is_symlink(),
            "invalid build directory")
    require(root.name == build_id, "build ID does not match directory")
    require(state_dir.is_dir() and not state_dir.is_symlink(),
            "invalid state directory")

    marker = root / "BUILD_STATE"
    env_path = root / "metadata" / "build.env"
    modules = root / "metadata" / "candidate-kernel-modules.sha256"
    pointer = state_dir / "current-build-id"

    for path in (marker, env_path, modules):
        require(path.is_file() and not path.is_symlink(),
                f"missing or invalid input: {path.name}")

    require(not pointer.is_symlink(), "current-build pointer is a symlink")
    require(marker.read_text().strip() == "initializing",
            "build is not initializing")

    env = metadata_from(env_path)

    require(env.get("BUILD_ID") == build_id, "metadata build ID mismatch")
    require(env.get("BUILD_STATE") == "initializing",
            "metadata state mismatch")

    for field in (
        "KERNEL_RELEASE",
        "KERNEL_CANDIDATE_ID",
        "KERNEL_PREPARATION_COMMIT",
        "KERNEL_BUILD_COMMIT",
    ):
        require(bool(env.get(field)), f"missing metadata: {field}")

    require(env.get("KERNEL_MODULES_STAGED") == "false",
            "unexpected module staging state")
    require(modules.stat().st_size > 0, "empty candidate module manifest")

    verify_artifacts(root, env["KERNEL_RELEASE"])

    lines = env_path.read_text().splitlines()
    updated = [
        "BUILD_STATE=initialized"
        if line == "BUILD_STATE=initializing" else line
        for line in lines
    ]

    # Commit metadata, then the authoritative completion marker.
    # Publish the current-build pointer only after both succeed.
    atomic_write(env_path, "\n".join(updated) + "\n")
    atomic_write(marker, "initialized\n")
    atomic_write(pointer, build_id + "\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build-root", type=Path, required=True)
    parser.add_argument("--state-dir", type=Path, required=True)
    parser.add_argument("--build-id", required=True)
    args = parser.parse_args()

    publish(args.build_root, args.state_dir, args.build_id)
    print("SABLE_CANDIDATE_BUILD_PUBLISHED")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        sys.exit(1)
