#!/usr/bin/env python3
"""Verify an extracted kernel tree against an authenticated tar archive."""

import argparse
import hashlib
import os
from pathlib import Path
import sys
import tarfile


def digest(stream):
    h = hashlib.sha256()
    while chunk := stream.read(1024 * 1024):
        h.update(chunk)
    return h.digest()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("archive", type=Path)
    parser.add_argument("source", type=Path)
    args = parser.parse_args()

    if not args.source.is_dir() or args.source.is_symlink():
        parser.error("source must be a real directory")

    expected = set()
    checked = 0
    errors = []

    with tarfile.open(args.archive, "r:xz") as archive:
        for member in archive:
            parts = Path(member.name).parts
            if not parts or parts[0] != "linux-6.16.1":
                errors.append(f"unexpected archive path: {member.name}")
                continue

            if len(parts) == 1:
                continue

            relative = Path(*parts[1:])
            if any(p in (".", "..") for p in relative.parts):
                errors.append(f"unsafe archive path: {member.name}")
                continue

            expected.add(relative.as_posix())
            target = args.source / relative

            if member.isfile():
                if not target.is_file() or target.is_symlink():
                    errors.append(f"missing/nonregular: {relative}")
                    continue
                with archive.extractfile(member) as original:
                    with target.open("rb") as extracted:
                        if digest(original) != digest(extracted):
                            errors.append(f"content mismatch: {relative}")
                checked += 1
            elif member.issym():
                if not target.is_symlink() or os.readlink(target) != member.linkname:
                    errors.append(f"symlink mismatch: {relative}")
            elif member.isdir():
                if not target.is_dir() or target.is_symlink():
                    errors.append(f"directory mismatch: {relative}")
            else:
                errors.append(f"unsupported archive member: {relative}")

    for root, dirs, files in os.walk(args.source, followlinks=False):
        for name in dirs + files:
            relative = (Path(root) / name).relative_to(args.source).as_posix()
            if relative not in expected:
                errors.append(f"unexpected extracted entry: {relative}")

    for error in errors[:20]:
        print(f"FAIL: {error}", file=sys.stderr)

    if errors:
        print(f"FAIL: {len(errors)} source integrity errors", file=sys.stderr)
        return 1

    print(f"PASS: {checked} regular source files verified")
    print("PASS: Source directory matches authenticated archive")
    return 0


if __name__ == "__main__":
    sys.exit(main())
