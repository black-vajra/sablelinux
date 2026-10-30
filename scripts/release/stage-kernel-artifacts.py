#!/usr/bin/env python3
"""Stage verified kernel artifacts with atomic directory publication."""

import argparse
import fcntl
import hashlib
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


def die(message):
    raise ValueError(message)


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def read_metadata(path):
    result = {}
    for line in path.read_text().splitlines():
        if not line:
            continue
        key, value = line.split("=", 1)
        if key in result:
            die(f"duplicate metadata key: {key}")
        result[key] = value
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--candidate-id", required=True)
    parser.add_argument("--destination", required=True)
    parser.add_argument(
        "--workspace",
        default="/srv/sablelinux/kernel-builds",
    )
    args = parser.parse_args()

    repo = Path(__file__).resolve().parents[2]
    verifier = repo / "scripts/release/verify-kernel-candidate.py"

    destination = Path(os.path.abspath(args.destination))
    parent = destination.parent

    if not parent.is_dir() or parent.is_symlink():
        die("destination parent must be an existing regular directory")

    # Serialize cooperating staging processes for this parent.
    # The lock remains held until the process exits.
    lock_fd = os.open(parent, os.O_RDONLY | os.O_DIRECTORY)

    try:
        fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        os.close(lock_fd)
        die("another kernel staging operation is active")

    if destination.exists() or destination.is_symlink():
        die("destination must not already exist")

    subprocess.run(
        [
            sys.executable,
            "-B",
            str(verifier),
            "--workspace",
            args.workspace,
            "--candidate-id",
            args.candidate_id,
        ],
        check=True,
    )

    candidate = Path(args.workspace) / args.candidate_id
    metadata = read_metadata(candidate / "metadata/compilation.env")
    release = metadata["KERNEL_RELEASE"]

    source = candidate / "artifacts"
    names = [
        f"vmlinuz-{release}",
        f"System.map-{release}",
        f"config-{release}",
    ]

    with tempfile.TemporaryDirectory(
        prefix=".kernel-staging-",
        dir=parent,
    ) as temporary:
        staged_root = Path(temporary)
        records = []

        for name in names:
            original = source / name
            staged = staged_root / name

            shutil.copy2(original, staged)

            original_hash = sha256(original)
            staged_hash = sha256(staged)

            if original_hash != staged_hash:
                die(f"staged artifact checksum mismatch: {name}")

            records.append((name, staged_hash))

        manifest = staged_root / "kernel-artifacts.sha256"
        manifest.write_text(
            "".join(
                f"{digest}  {name}\n"
                for name, digest in records
            )
        )

        for name, expected in records:
            if sha256(staged_root / name) != expected:
                die(f"final staged checksum mismatch: {name}")

        if destination.exists() or destination.is_symlink():
            die("destination appeared during staging")

        # Both directories are on the same filesystem.
        # Publish the fully verified staging directory at once.
        os.rename(staged_root, destination)

    print(f"PASS: Kernel release: {release}")
    print("PASS: Three kernel artifacts staged and verified")
    print(f"PASS: Destination: {destination}")
    print("SABLE_KERNEL_STAGING_PASS")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        sys.exit(1)
