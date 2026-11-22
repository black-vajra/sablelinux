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


import ctypes
import errno

RENAME_NOREPLACE = 1


def rename_noreplace(source_fd, source_name, dest_fd, dest_name):
    """Atomically rename without replacing an existing destination."""
    libc = ctypes.CDLL(None, use_errno=True)

    renameat2 = getattr(libc, "renameat2", None)
    if renameat2 is None:
        raise OSError(errno.ENOSYS, "renameat2 unavailable")

    renameat2.argtypes = [
        ctypes.c_int,
        ctypes.c_char_p,
        ctypes.c_int,
        ctypes.c_char_p,
        ctypes.c_uint,
    ]
    renameat2.restype = ctypes.c_int

    result = renameat2(
        source_fd,
        os.fsencode(source_name),
        dest_fd,
        os.fsencode(dest_name),
        RENAME_NOREPLACE,
    )

    if result != 0:
        error = ctypes.get_errno()
        raise OSError(error, os.strerror(error))


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


def inspect(build_id, operation=None):
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

        abandoned = sorted(
            name for name in os.listdir(build)
            if name.startswith(
                (".rootfs-quarantine-", ".rootfs-recovery-")
            )
        )
        require(
            not abandoned,
            "abandoned rootfs staging requires inspection",
        )

        entries = os.listdir(rootfs)
        require(bool(entries), "rootfs is already empty")

        result = {
            "build_id": build_id,
            "build_state": marker,
            "rootfs": rootfs_path,
            "rootfs_entries": len(entries),
            "nested_mounts": mounts,
            "build_lock": "acquired",
            "action": "inspection-only",
            "safe_to_consider_quarantine": True,
        }

        if operation is not None:
            return operation(result, build, rootfs)
        return result


def quarantine(build_id):
    """Quarantine an inspected rootfs while retaining the build lock."""

    def transaction(result, build_fd, rootfs_fd):
        workspace_fd = os.open(WORKSPACE, DIR_FLAGS)
        try:
            created_quarantine = False
            try:
                os.mkdir(
                    "quarantine", 0o700, dir_fd=workspace_fd
                )
                created_quarantine = True
            except FileExistsError:
                pass

            quarantine_fd = os.open(
                "quarantine", DIR_FLAGS, dir_fd=workspace_fd
            )
            try:
                # Only normalize a directory created by this operation.
                # Existing directories must pass validation unchanged.
                if created_quarantine:
                    os.fchmod(quarantine_fd, 0o700)

                quarantine_info = os.fstat(quarantine_fd)
                build_info = os.fstat(build_fd)
                root_info = os.fstat(rootfs_fd)

                require(
                    quarantine_info.st_uid == 0
                    and stat.S_IMODE(quarantine_info.st_mode) == 0o700,
                    "quarantine parent is not private and root-owned",
                )
                require(
                    quarantine_info.st_dev == build_info.st_dev,
                    "quarantine is on another filesystem",
                )
                if created_quarantine:
                    os.fsync(quarantine_fd)
                    os.fsync(workspace_fd)

                current = os.stat(
                    "rootfs", dir_fd=build_fd,
                    follow_symlinks=False,
                )
                require(
                    (current.st_dev, current.st_ino)
                    == (root_info.st_dev, root_info.st_ino),
                    "rootfs identity changed",
                )

                os.mkdir(
                    build_id, 0o700, dir_fd=quarantine_fd
                )
                destination_fd = os.open(
                    build_id, DIR_FLAGS, dir_fd=quarantine_fd
                )
                try:
                    # Explicitly clear inherited setgid on the new
                    # private per-build quarantine directory.
                    os.fchmod(destination_fd, 0o700)

                    record = {
                        "build_id": build_id,
                        "action": "failed-rootfs-quarantine",
                        "original_rootfs_device": root_info.st_dev,
                        "original_rootfs_inode": root_info.st_ino,
                        "original_rootfs_entries":
                            result["rootfs_entries"],
                    }

                    evidence_fd = os.open(
                        "recovery.json",
                        os.O_WRONLY | os.O_CREAT |
                        os.O_EXCL | os.O_NOFOLLOW,
                        0o600,
                        dir_fd=destination_fd,
                    )
                    with os.fdopen(evidence_fd, "w") as output:
                        json.dump(record, output, sort_keys=True)
                        output.write("\n")
                        output.flush()
                        os.fsync(output.fileno())

                    os.fsync(destination_fd)
                    os.fsync(quarantine_fd)

                    rename_noreplace(
                        build_fd, "rootfs",
                        destination_fd, "rootfs",
                    )

                    # Make the moved capture durable before preparing
                    # the new active staging directory.
                    os.fsync(destination_fd)
                    os.fsync(build_fd)

                    import uuid

                    temporary = (
                        ".rootfs-quarantine-" + uuid.uuid4().hex
                    )

                    try:
                        os.mkdir(
                            temporary, 0o700, dir_fd=build_fd
                        )
                        staging_fd = os.open(
                            temporary, DIR_FLAGS, dir_fd=build_fd
                        )
                        try:
                            os.fchown(
                                staging_fd, 0, build_info.st_gid
                            )
                            os.fchmod(staging_fd, 0o2775)

                            prepared = os.fstat(staging_fd)
                            require(
                                prepared.st_uid == 0
                                and prepared.st_gid == build_info.st_gid
                                and stat.S_IMODE(prepared.st_mode)
                                == 0o2775,
                                "replacement metadata invalid",
                            )
                            require(
                                not os.listdir(staging_fd),
                                "replacement staging is not empty",
                            )
                            os.fsync(staging_fd)
                        finally:
                            os.close(staging_fd)

                        rename_noreplace(
                            build_fd, temporary,
                            build_fd, "rootfs",
                        )

                    except OSError:
                        # Remove only our own empty, unpublished staging
                        # directory. Never remove unexpected contents.
                        try:
                            os.rmdir(
                                temporary, dir_fd=build_fd
                            )
                        except FileNotFoundError:
                            pass
                        except OSError:
                            # Preserve unexplained state for inspection.
                            pass

                        # Roll back only when the active name is absent.
                        try:
                            os.stat(
                                "rootfs", dir_fd=build_fd,
                                follow_symlinks=False,
                            )
                        except FileNotFoundError:
                            rename_noreplace(
                                destination_fd, "rootfs",
                                build_fd, "rootfs",
                            )
                            os.fsync(destination_fd)
                            os.fsync(build_fd)
                        raise

                    os.fsync(destination_fd)
                    os.fsync(build_fd)

                    result["action"] = "quarantined"
                    result["quarantine"] = str(
                        WORKSPACE / "quarantine"
                        / build_id / "rootfs"
                    )
                    return result
                finally:
                    os.close(destination_fd)
            finally:
                os.close(quarantine_fd)
        finally:
            os.close(workspace_fd)

    return inspect(build_id, operation=transaction)



def recover_interrupted(build_id):
    """Complete an interrupted quarantine without moving its evidence."""
    require(
        re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]*", build_id),
        "invalid build ID",
    )

    with ExitStack() as stack:
        def directory(name, parent=None):
            fd = os.open(name, DIR_FLAGS, dir_fd=parent)
            stack.callback(os.close, fd)
            return fd

        workspace = directory(WORKSPACE)
        state = directory("state", workspace)
        builds = directory("builds", workspace)
        build = directory(build_id, builds)

        try:
            fcntl.flock(build, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise ValueError("build lock is held") from None

        metadata_dir = directory("metadata", build)

        selected = read_regular(state, "current-build-id").strip()
        require(selected == build_id, "build is not selected")

        env = metadata(read_regular(metadata_dir, "build.env"))
        marker = read_regular(build, "BUILD_STATE").strip()

        require(env.get("BUILD_ID") == build_id,
                "build metadata identity mismatch")
        require(marker == env.get("BUILD_STATE") == "initialized",
                "build is not consistently initialized")
        require(env.get("KERNEL_MODULES_STAGED") == "false",
                "kernel modules already staged")

        build_info = os.fstat(build)
        state_info = os.fstat(state)
        require(build_info.st_uid == 0,
                "build is not root-owned")
        require(build_info.st_gid == state_info.st_gid,
                "build and state groups differ")

        # Never silently discard state left by an interrupted recovery.
        # An operator must inspect and resolve it separately.
        abandoned = sorted(
            name for name in os.listdir(build)
            if name.startswith(
                (".rootfs-recovery-", ".rootfs-quarantine-")
            )
        )
        require(
            not abandoned,
            "abandoned recovery staging directory requires inspection",
        )

        # Recovery is valid only when the active staging directory
        # is completely absent. Never overwrite any existing object.
        try:
            os.stat("rootfs", dir_fd=build,
                    follow_symlinks=False)
        except FileNotFoundError:
            pass
        else:
            raise ValueError("active rootfs already exists")

        quarantine = directory("quarantine", workspace)
        quarantine_info = os.fstat(quarantine)

        require(
            quarantine_info.st_uid == 0
            and stat.S_IMODE(quarantine_info.st_mode) == 0o700,
            "quarantine parent is not private and root-owned",
        )
        require(quarantine_info.st_dev == build_info.st_dev,
                "quarantine is on another filesystem")

        saved_build = directory(build_id, quarantine)
        saved_info = os.fstat(saved_build)

        require(
            saved_info.st_uid == 0
            and stat.S_IMODE(saved_info.st_mode) == 0o700,
            "per-build quarantine is not private and root-owned",
        )

        saved_rootfs = directory("rootfs", saved_build)
        saved_root_info = os.fstat(saved_rootfs)

        record = json.loads(
            read_regular(saved_build, "recovery.json")
        )

        require(record.get("build_id") == build_id,
                "quarantine evidence build ID mismatch")
        require(
            record.get("action") == "failed-rootfs-quarantine",
            "invalid quarantine evidence action",
        )
        require(
            record.get("original_rootfs_device")
            == saved_root_info.st_dev
            and record.get("original_rootfs_inode")
            == saved_root_info.st_ino,
            "quarantined rootfs identity mismatch",
        )
        require(
            saved_root_info.st_uid == 0
            and saved_root_info.st_dev == build_info.st_dev,
            "unsafe quarantined rootfs identity",
        )
        require(
            isinstance(record.get("original_rootfs_entries"), int)
            and record["original_rootfs_entries"] > 0,
            "invalid quarantine entry count",
        )

        active_path = str(
            WORKSPACE / "builds" / build_id / "rootfs"
        )
        saved_path = str(
            WORKSPACE / "quarantine" / build_id / "rootfs"
        )

        require(
            not nested_mounts(active_path)
            and not nested_mounts(saved_path),
            "rootfs contains mounts",
        )

        # Recheck destination absence while holding the build lock.
        try:
            os.stat("rootfs", dir_fd=build,
                    follow_symlinks=False)
        except FileNotFoundError:
            pass
        else:
            raise ValueError("active rootfs appeared during recovery")

        # Prepare the replacement without exposing an incomplete
        # active rootfs. Publish it only after metadata validation.
        import uuid

        temporary = ".rootfs-recovery-" + uuid.uuid4().hex
        os.mkdir(temporary, 0o700, dir_fd=build)

        published = False
        try:
            staging = directory(temporary, build)

            os.fchown(staging, 0, build_info.st_gid)
            os.fchmod(staging, 0o2775)

            prepared = os.fstat(staging)
            require(
                prepared.st_uid == 0
                and prepared.st_gid == build_info.st_gid
                and stat.S_IMODE(prepared.st_mode) == 0o2775,
                "temporary rootfs metadata invalid",
            )
            require(not os.listdir(staging),
                    "temporary rootfs is not empty")
            os.fsync(staging)

            # Refuse to replace any existing active rootfs.
            try:
                os.stat("rootfs", dir_fd=build,
                        follow_symlinks=False)
            except FileNotFoundError:
                pass
            else:
                raise ValueError("active rootfs appeared during recovery")

            rename_noreplace(
                build, temporary, build, "rootfs"
            )
            published = True
        finally:
            if not published:
                os.rmdir(temporary, dir_fd=build)

        replacement = directory("rootfs", build)
        replacement_info = os.fstat(replacement)
        require(
            replacement_info.st_uid == 0
            and replacement_info.st_gid == build_info.st_gid
            and stat.S_IMODE(replacement_info.st_mode) == 0o2775,
            "replacement rootfs metadata invalid",
        )
        require(not os.listdir(replacement),
                "replacement rootfs is not empty")

        os.fsync(build)

        return {
            "build_id": build_id,
            "action": "interrupted-quarantine-recovered",
            "rootfs": active_path,
            "quarantine": saved_path,
        }



def main():
    parser = argparse.ArgumentParser(
        description=(
            "Inspect or explicitly quarantine a failed "
            "canonical SableLinux rootfs"
        )
    )
    parser.add_argument("--build-id", required=True)

    action = parser.add_mutually_exclusive_group()
    action.add_argument(
        "--execute-quarantine",
        action="store_true",
        help="Move failed rootfs into private quarantine",
    )
    action.add_argument(
        "--recover-interrupted",
        action="store_true",
        help="Recreate missing staging after an interrupted move",
    )

    parser.add_argument(
        "--confirm-build-id",
        help="Required for either mutating operation",
    )

    args = parser.parse_args()

    try:
        modifying = (
            args.execute_quarantine
            or args.recover_interrupted
        )

        if modifying:
            require(
                os.geteuid() == 0,
                "mutating operations require root",
            )
            require(
                args.confirm_build_id == args.build_id,
                "explicit matching --confirm-build-id required",
            )
        else:
            require(
                args.confirm_build_id is None,
                "confirmation is only valid for mutating operations",
            )

        if args.execute_quarantine:
            result = quarantine(args.build_id)
        elif args.recover_interrupted:
            result = recover_interrupted(args.build_id)
        else:
            result = inspect(args.build_id)

        print(json.dumps(result, indent=2, sort_keys=True))

        if modifying:
            print("SABLE_ROOTFS_QUARANTINE_OPERATION_PASS")
        else:
            print("SABLE_ROOTFS_QUARANTINE_PREFLIGHT_PASS")

        return 0

    except (OSError, ValueError) as error:
        print(
            f"SABLE_ROOTFS_QUARANTINE_FAIL: {error}",
            file=sys.stderr,
        )
        return 1


if __name__ == "__main__":
    sys.exit(main())
