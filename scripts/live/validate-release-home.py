#!/usr/bin/env python3
"""Fail-closed validation of the generated SableLinux live-user home."""

import argparse
import os
import stat
import sys
from pathlib import Path

FILES = {
    ".bashrc": (None, 0o644),
    ".bash_profile": ("configs/live/sable-bash-profile", 0o644),
    ".config/sway/config": ("configs/desktop/sway/config", 0o644),
    ".config/waybar/config": ("configs/desktop/waybar/config", 0o644),
    ".config/waybar/style.css": ("configs/desktop/waybar/style.css", 0o644),
    ".config/waybar/bottom-config": ("configs/desktop/waybar/bottom-config", 0o644),
    ".config/waybar/bottom-style.css": ("configs/desktop/waybar/bottom-style.css", 0o644),
    ".local/bin/sable-window-control": ("configs/desktop/waybar/sable-window-control", 0o755),
    ".config/fuzzel/fuzzel.ini": ("configs/desktop/fuzzel/fuzzel.ini", 0o644),
    ".local/bin/sable-power-menu": ("configs/desktop/waybar/sable-power-menu", 0o755),
    ".local/bin/sable-workspace-label": ("configs/desktop/waybar/sable-workspace-label", 0o755),
    ".local/bin/sable-sensors": ("configs/desktop/waybar/sable-sensors", 0o755),
    ".local/bin/sable-network-status": ("configs/desktop/waybar/sable-network-status", 0o755),
}

DIRECTORIES = {
    ".",
    ".config",
    ".config/sway",
    ".config/waybar",
    ".config/fuzzel",
    ".local",
    ".local/bin",
}

BASHRC = b"PS1='[\\u@\\h \\w]\\$ '\n"


def fail(message):
    raise ValueError(message)


def account_ids(root):
    passwd = root / "etc/passwd"
    entries = []
    for line in passwd.read_text().splitlines():
        fields = line.split(":")
        if fields[0] == "sable":
            if len(fields) != 7:
                fail("malformed sable passwd entry")
            entries.append(fields)
    if len(entries) != 1:
        fail("expected exactly one sable passwd entry")
    fields = entries[0]
    if fields[5] != "/home/sable":
        fail("unexpected sable home path")
    uid, gid = int(fields[2]), int(fields[3])
    if uid <= 0 or gid <= 0:
        fail("invalid live-user UID/GID")
    return uid, gid


def validate(root, repo):
    root = root.absolute()
    repo = repo.absolute()
    uid, gid = account_ids(root)

    # The release home must have a real, root-owned parent.
    home_parent = root / "home"
    parent_stat = os.lstat(home_parent)

    if not stat.S_ISDIR(parent_stat.st_mode):
        fail("release /home parent is not a real directory")

    if (parent_stat.st_uid, parent_stat.st_gid) != (0, 0):
        fail("release /home parent has unexpected ownership")

    if stat.S_IMODE(parent_stat.st_mode) != 0o755:
        fail("release /home parent has unsafe permissions")

    if os.listxattr(home_parent, follow_symlinks=False):
        fail("release /home parent has unexpected metadata")

    # The release root permits exactly one user-home directory.
    # Unexpected homes are a hard failure, not silently removed.
    with os.scandir(home_parent) as entries:
        home_entries = sorted(entry.name for entry in entries)

    if home_entries != ["sable"]:
        fail(
            f"unexpected release /home entries: {home_entries}"
        )

    home = home_parent / "sable"

    expected = DIRECTORIES | set(FILES)
    actual = set()

    def inspect(path, relative):
        st = os.lstat(path)
        name = "." if relative == "." else relative
        actual.add(name)

        if name not in expected:
            fail(f"unexpected release-home object: {name}")

        if (st.st_uid, st.st_gid) != (uid, gid):
            fail(f"incorrect ownership: {name}")

        mode = stat.S_IMODE(st.st_mode)

        # Release-home objects must carry no inherited host metadata.
        # POSIX ACLs are represented by system.posix_acl_* xattrs.
        attributes = os.listxattr(path, follow_symlinks=False)
        if attributes:
            fail(
                f"unexpected extended attributes or ACLs on {name}: "
                f"{sorted(attributes)}"
            )

        if name in DIRECTORIES:
            if not stat.S_ISDIR(st.st_mode) or mode != 0o755:
                fail(f"invalid directory type or mode: {name}")
            with os.scandir(path) as entries:
                children = sorted(entries, key=lambda e: e.name)
            for child in children:
                child_name = child.name if name == "." else f"{name}/{child.name}"
                inspect(Path(child.path), child_name)
        else:
            source, required_mode = FILES[name]
            if not stat.S_ISREG(st.st_mode) or mode != required_mode:
                fail(f"invalid file type or mode: {name}")
            expected_data = (
                BASHRC if source is None
                else (repo / source).read_bytes()
            )
            if path.read_bytes() != expected_data:
                fail(f"content mismatch: {name}")

    inspect(home, ".")

    missing = expected - actual
    if missing:
        fail(f"missing release-home objects: {sorted(missing)}")

    print(
        f"PASS: release home validated "
        f"({len(FILES)} files, {len(DIRECTORIES)} directories, "
        f"UID={uid}, GID={gid})"
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--rootfs", required=True, type=Path)
    parser.add_argument("--repo", required=True, type=Path)
    args = parser.parse_args()
    try:
        validate(args.rootfs, args.repo)
    except (OSError, ValueError) as exc:
        print(f"ERROR: release-home validation failed: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
