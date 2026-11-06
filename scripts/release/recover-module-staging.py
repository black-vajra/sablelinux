#!/usr/bin/env python3
"""Explicit, evidence-preserving quarantine of an orphan module manifest."""
import argparse
from contextlib import ExitStack
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import sys
import uuid

DIRECTORY = os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW
REGULAR = os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK
MANIFEST = "staged-kernel-module-indexes.sha256"


def recover(build_root):
    with ExitStack() as stack:
        def directory(name, parent=None):
            fd = os.open(name, DIRECTORY, dir_fd=parent)
            stack.callback(os.close, fd)
            return fd

        def read_file(parent, name):
            fd = os.open(name, REGULAR, dir_fd=parent)
            with os.fdopen(fd, "rb") as stream:
                info = os.fstat(stream.fileno())
                if not stat.S_ISREG(info.st_mode):
                    raise ValueError(f"not a regular file: {name}")
                return stream.read(), info

        def fields(data):
            result = {}
            for line in data.decode("utf-8").splitlines():
                if not line.strip():
                    continue
                if "=" not in line:
                    raise ValueError("malformed metadata")
                key, value = line.split("=", 1)
                if not key.strip() or key in result:
                    raise ValueError("empty or duplicate metadata key")
                result[key] = value
            return result

        def lock(fd, description):
            try:
                fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                raise ValueError(f"{description} lock is held") from None

        def require_no_tree():
            try:
                os.stat(release, dir_fd=modules, follow_symlinks=False)
            except FileNotFoundError:
                return
            raise ValueError("module tree exists; refusing recovery")

        def save(name, payload):
            fd = os.open(
                name, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW,
                0o600, dir_fd=evidence,
            )
            with os.fdopen(fd, "wb") as stream:
                stream.write(payload)
                stream.flush()
                os.fsync(stream.fileno())

        absolute = Path(os.path.abspath(build_root))
        if ".." in Path(build_root).parts:
            raise ValueError("parent traversal in build path")
        build = directory("/")
        for component in absolute.parts[1:]:
            build = directory(component, build)
        lock(build, "build")

        metadata = directory("metadata", build)
        env_bytes, _ = read_file(metadata, "build.env")
        env = fields(env_bytes)
        state_bytes, _ = read_file(build, "BUILD_STATE")
        if state_bytes.decode("utf-8").strip() != env.get("BUILD_STATE"):
            raise ValueError("build state mismatch")
        if env.get("BUILD_STATE") != "initialized":
            raise ValueError("build is not initialized")
        if env.get("KERNEL_MODULES_STAGED") != "false":
            raise ValueError("modules already marked staged")
        release = env.get("KERNEL_RELEASE", "")
        if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._+~-]*", release):
            raise ValueError("invalid kernel release")
        if not env.get("BUILD_ID"):
            raise ValueError("missing build identity")

        rootfs = directory("rootfs", build)
        lib_info = os.stat("lib", dir_fd=rootfs, follow_symlinks=False)
        if stat.S_ISLNK(lib_info.st_mode):
            if os.readlink("lib", dir_fd=rootfs) != "usr/lib":
                raise ValueError("unsafe merged-usr symlink")
            usr = directory("usr", rootfs)
            lib = directory("lib", usr)
        else:
            lib = directory("lib", rootfs)
        modules = directory("modules", lib)
        lock(modules, "module staging")
        require_no_tree()

        payload, original = read_file(metadata, MANIFEST)
        evidence_name = "module-recovery-" + uuid.uuid4().hex
        os.mkdir(evidence_name, mode=0o700, dir_fd=metadata)
        evidence = directory(evidence_name, metadata)
        save("manifest.sha256", payload)
        record = {
            "build_id": env["BUILD_ID"],
            "kernel_release": release,
            "source_path": "metadata/" + MANIFEST,
            "manifest_sha256": hashlib.sha256(payload).hexdigest(),
        }
        save("recovery.json", (json.dumps(record, sort_keys=True) + "\n").encode())
        os.fsync(evidence)
        os.fsync(metadata)

        # Preserve the source if anything changed during evidence preparation.
        require_no_tree()
        current_payload, current = read_file(metadata, MANIFEST)
        if (
            (current.st_dev, current.st_ino) !=
            (original.st_dev, original.st_ino)
            or current_payload != payload
        ):
            raise ValueError("orphan manifest changed; evidence retained")
        os.unlink(MANIFEST, dir_fd=metadata)
        os.fsync(metadata)
        return evidence_name


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build-root", required=True)
    parser.add_argument("--quarantine-orphan-manifest",
                        action="store_true", required=True)
    args = parser.parse_args()
    try:
        evidence = recover(args.build_root)
    except (OSError, ValueError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print(f"QUARANTINED: metadata/{evidence}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
