#!/usr/bin/env python3
"""Exercise installed rsync on the destination filesystem; retain all evidence."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import sys
import tempfile


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def command(args):
    result = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if result.returncode:
        raise RuntimeError(f"command failed ({result.returncode}): {args!r}\n"
                           + result.stderr.decode(errors="replace"))
    return result.stdout


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--workspace", required=True, type=Path)
    parser.add_argument("--destination-root", required=True, type=Path)
    parser.add_argument("--rsync", default="/usr/bin/rsync", type=Path)
    args = parser.parse_args()
    require(os.geteuid() == 0, "root required for foreign ownership validation")
    for directory in (args.workspace, args.destination_root):
        require(directory.is_dir(), f"directory unavailable: {directory}")
    require(args.workspace.stat().st_dev == args.destination_root.stat().st_dev,
            "probe workspace and destination root must use the same filesystem")
    for tool in ("setfacl", "getfacl"):
        require(shutil.which(tool), f"required tool unavailable: {tool}")
    rsync = args.rsync.resolve(strict=True)
    require(os.access(rsync, os.X_OK), "rsync is not executable")
    run = Path(tempfile.mkdtemp(prefix="rootfs-preservation-", dir=args.workspace))
    print(f"Retained probe: {run}", flush=True)
    print(f"Rsync: {rsync}")
    print(f"Rsync SHA256: {hashlib.sha256(rsync.read_bytes()).hexdigest()}")
    (run / "rsync-version.txt").write_bytes(command([str(rsync), "--version"]))
    src, dst = run / "source", run / "destination"
    src.mkdir()
    dst.mkdir()
    file = src / "file"
    file.write_bytes(b"SableLinux capture preservation\n")
    os.chown(file, 12345, 23456)
    file.chmod(0o640)
    os.link(file, src / "hardlink")
    (src / "symlink").symlink_to("file")
    command(["setfacl", "-m", "u:34567:r--", str(file)])
    os.setxattr(file, "user.sable-test", b"preserved")
    default = src / "default"
    default.mkdir()
    command(["setfacl", "-m", "d:u:34567:r--", str(default)])
    (default / "child").write_bytes(b"inherited ACL\n")
    for name, mode in (("setuid", 0o4750), ("setgid", 0o2750)):
        path = src / name
        path.write_bytes(b"mode fixture\n")
        os.chown(path, 12345, 23456)
        path.chmod(mode)
    os.mkfifo(src / "fifo", 0o640)
    # Fix fixture timestamps after construction; compare whole seconds as in
    # the existing canonical package-preservation VM test.
    paths = [src, *sorted(src.rglob("*"))]
    for path in paths:
        os.utime(path, (1700000000, 1700000000), follow_symlinks=False)

    def snapshot(base):
        result = {}
        for original in paths:
            relative = original.relative_to(src)
            path = base / relative
            st = path.lstat()
            entry = [st.st_uid, st.st_gid, st.st_mode, int(st.st_mtime)]
            if stat.S_ISREG(st.st_mode):
                entry.append(hashlib.sha256(path.read_bytes()).hexdigest())
            if stat.S_ISLNK(st.st_mode):
                entry.append(os.readlink(path))
            else:
                attrs = {name: os.getxattr(path, name).hex()
                         for name in os.listxattr(path)}
                entry.append(attrs)
                entry.append(command(["getfacl", "-cpn", str(path)]).decode())
            result[str(relative)] = entry
        return result

    before = snapshot(src)
    (run / "source-before.json").write_text(json.dumps(before, indent=2) + "\n")
    require("user:34567:r--" in command(["getfacl", "-cpn", str(file)]).decode(),
            "source access ACL fixture was not established")
    require("default:user:34567:r--" in
            command(["getfacl", "-cpn", str(default)]).decode(),
            "source default ACL fixture was not established")
    require("user:34567:r--" in
            command(["getfacl", "-cpn", str(default / "child")]).decode(),
            "source child did not inherit its access ACL")
    options = [str(rsync), "-aHAX", "--numeric-ids"]
    (run / "copy.txt").write_bytes(command(options + [str(src) + "/", str(dst) + "/"]))
    destination = snapshot(dst)
    (run / "destination.json").write_text(json.dumps(destination, indent=2) + "\n")
    require(destination == before,
            "destination content, metadata, ACL or xattr mismatch")
    require((dst / "file").stat().st_ino == (dst / "hardlink").stat().st_ino,
            "destination hardlink identity lost")
    repeat = command(options + ["--checksum", "--itemize-changes",
                                str(src) + "/", str(dst) + "/"])
    (run / "repeat.txt").write_bytes(repeat)
    require(not repeat, "repeat copy reported differences")
    require(snapshot(src) == before, "source fixture changed")
    require(snapshot(dst) == before, "repeat copy changed destination metadata")
    print("PASS: rootfs preservation prerequisite")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(f"FAIL: rootfs preservation prerequisite: {error}", file=sys.stderr)
        sys.exit(1)
