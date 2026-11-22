#!/usr/bin/env python3
"""Inspect a failed canonical rootfs before controlled quarantine."""

import argparse
import fcntl
import json
import os
import re
import stat
import sys
from contextlib import ExitStack
from pathlib import Path

WORKSPACE = Path("/srv/sablelinux")
DIR_FLAGS = os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW
FILE_FLAGS = os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK


def require(condition, message):
    if not condition:
        raise ValueError(message)


def read_regular(parent_fd, name):
    fd = os.open(name, FILE_FLAGS, dir_fd=parent_fd)
    with os.fdopen(fd, "rb") as stream:
        require(stat.S_ISREG(os.fstat(stream.fileno()).st_mode),
                f"not a regular file: {name}")
        return stream.read().decode("utf-8")


def metadata(text):
    result = {}
    for line in text.splitlines():
        key, separator, value = line.partition("=")
        require(separator and key and key not in result,
                "malformed or duplicate metadata")
        result[key] = value
    return result


def unescape_mount(value):
    return re.sub(
        r"\\([0-7]{3})",
        lambda match: chr(int(match.group(1), 8)),
        value,
    )


def nested_mounts(rootfs):
    matches = []
    for line in Path("/proc/self/mountinfo").read_text().splitlines():
        fields = line.split()
        mountpoint = unescape_mount(fields[4])
        if mountpoint == rootfs or mountpoint.startswith(rootfs + "/"):
            matches.append(mountpoint)
    return matches


def inspect(build_id):
    require(re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]*", build_id),
            "invalid build ID")

    with ExitStack() as stack:
        def directory(path, parent_fd=None):
            fd = os.open(path, DIR_FLAGS, dir_fd=parent_fd)
            stack.callback(os.close, fd)
            return fd

        state = directory(WORKSPACE / "state")
        builds = directory(WORKSPACE / "builds")
        build = directory(build_id, builds)

        try:
            fcntl.flock(build, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise ValueError("build lock is held") from None

        rootfs = directory("rootfs", build)
        meta = directory("metadata", build)

        root_info = os.fstat(rootfs)
        build_info = os.fstat(build)

        require(root_info.st_uid == 0,
                "rootfs directory is not root-owned")
        require(root_info.st_dev == build_info.st_dev,
                "rootfs is on a different filesystem")

        selected = read_regular(state, "current-build-id").strip()
        require(selected == build_id, "build is not selected")

        env = metadata(read_regular(meta, "build.env"))
        marker = read_regular(build, "BUILD_STATE").strip()

        require(env.get("BUILD_ID") == build_id,
                "build metadata identity mismatch")
        require(marker == env.get("BUILD_STATE") == "initialized",
                "build is not consistently initialized")
        require(env.get("KERNEL_MODULES_STAGED") == "false",
                "kernel modules already staged")

        require(os.fstat(build).st_gid == os.fstat(state).st_gid,
                "build and state groups differ")
        require(os.fstat(build).st_uid == 0,
                "build directory is not root-owned")

        rootfs_path = str(WORKSPACE / "builds" / build_id / "rootfs")
        mounts = nested_mounts(rootfs_path)
        require(not mounts, f"rootfs contains mounts: {mounts}")

        entries = os.listdir(rootfs)
        require(bool(entries), "rootfs is already empty")

        return {
            "build_id": build_id,
            "build_state": marker,
            "rootfs": rootfs_path,
            "rootfs_entries": len(entries),
            "nested_mounts": mounts,
            "build_lock": "acquired",
            "action": "inspection-only",
            "safe_to_consider_quarantine": True,
        }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build-id", required=True)
    args = parser.parse_args()

    try:
        result = inspect(args.build_id)
    except (OSError, ValueError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        return 1

    print(json.dumps(result, indent=2, sort_keys=True))
    print("SABLE_ROOTFS_QUARANTINE_PREFLIGHT_PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
