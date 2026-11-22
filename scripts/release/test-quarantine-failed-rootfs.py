#!/usr/bin/env python3
"""Regression tests for failed-rootfs quarantine preflight."""

import fcntl
import importlib.util
import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

SCRIPT = Path(__file__).with_name("quarantine-failed-rootfs.py")
spec = importlib.util.spec_from_file_location("rootfs_quarantine", SCRIPT)
recovery = importlib.util.module_from_spec(spec)
spec.loader.exec_module(recovery)


class QuarantinePreflightTests(unittest.TestCase):

    def setUp(self):
        temporary = tempfile.TemporaryDirectory(
            prefix="sable-rootfs-quarantine-test-"
        )
        self.addCleanup(temporary.cleanup)

        self.workspace = Path(temporary.name)
        self.build_id = "test-build"
        self.state = self.workspace / "state"
        self.build = self.workspace / "builds" / self.build_id
        self.rootfs = self.build / "rootfs"
        self.metadata = self.build / "metadata"

        self.state.mkdir()
        self.rootfs.mkdir(parents=True)
        self.metadata.mkdir()

        (self.state / "current-build-id").write_text(
            self.build_id + "\n"
        )
        (self.build / "BUILD_STATE").write_text(
            "initialized\n"
        )
        (self.metadata / "build.env").write_text(
            f"BUILD_ID={self.build_id}\n"
            "BUILD_STATE=initialized\n"
            "KERNEL_MODULES_STAGED=false\n"
        )
        (self.rootfs / "failed-capture").write_text("evidence")

        self.workspace_patch = patch.object(
            recovery, "WORKSPACE", self.workspace
        )
        self.mount_patch = patch.object(
            recovery, "nested_mounts", return_value=[]
        )
        self.workspace_patch.start()
        self.mount_patch.start()
        self.addCleanup(self.workspace_patch.stop)
        self.addCleanup(self.mount_patch.stop)

    def test_valid_preflight(self):
        result = recovery.inspect(self.build_id)
        self.assertEqual(result["build_state"], "initialized")
        self.assertEqual(result["action"], "inspection-only")
        self.assertTrue(result["safe_to_consider_quarantine"])
        self.assertTrue((self.rootfs / "failed-capture").exists())

    def test_invalid_build_id_rejected(self):
        with self.assertRaises(ValueError):
            recovery.inspect("../test-build")

    def test_wrong_selected_build_rejected(self):
        (self.state / "current-build-id").write_text("other-build\n")
        with self.assertRaisesRegex(ValueError, "not selected"):
            recovery.inspect(self.build_id)

    def test_advanced_state_rejected(self):
        (self.build / "BUILD_STATE").write_text(
            "rootfs-generated\n"
        )
        (self.metadata / "build.env").write_text(
            f"BUILD_ID={self.build_id}\n"
            "BUILD_STATE=rootfs-generated\n"
            "KERNEL_MODULES_STAGED=true\n"
        )
        with self.assertRaisesRegex(ValueError, "initialized"):
            recovery.inspect(self.build_id)

    def test_symlinked_rootfs_rejected(self):
        (self.rootfs / "failed-capture").unlink()
        self.rootfs.rmdir()
        self.rootfs.symlink_to(self.metadata, target_is_directory=True)

        with self.assertRaises(OSError):
            recovery.inspect(self.build_id)

    def test_build_lock_rejected(self):
        fd = os.open(
            self.build, os.O_RDONLY | os.O_DIRECTORY
        )
        try:
            fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
            with self.assertRaisesRegex(ValueError, "lock is held"):
                recovery.inspect(self.build_id)
        finally:
            os.close(fd)

    def test_nested_mount_rejected(self):
        with patch.object(
            recovery, "nested_mounts",
            return_value=[str(self.rootfs / "mnt")],
        ):
            with self.assertRaisesRegex(ValueError, "contains mounts"):
                recovery.inspect(self.build_id)


    def test_non_root_owned_rootfs_rejected(self):
        os.chown(self.rootfs, 1000, 1000)

        with self.assertRaisesRegex(
            ValueError, "not root-owned"
        ):
            recovery.inspect(self.build_id)

    def test_different_filesystem_rejected(self):
        original_fstat = recovery.os.fstat
        root_inode = self.rootfs.stat().st_ino

        def simulated_fstat(fd):
            result = original_fstat(fd)
            if result.st_ino == root_inode:
                values = list(result)
                values[2] = result.st_dev + 1
                return os.stat_result(values)
            return result

        with patch.object(
            recovery.os, "fstat", side_effect=simulated_fstat
        ):
            with self.assertRaisesRegex(
                ValueError, "different filesystem"
            ):
                recovery.inspect(self.build_id)


    def test_replacement_creation_failure_rolls_back(self):
        original_mkdir = recovery.os.mkdir

        def fail_replacement(path, *args, **kwargs):
            if path == "rootfs" and "dir_fd" in kwargs:
                raise OSError("INJECTED_REPLACEMENT_FAILURE")
            return original_mkdir(path, *args, **kwargs)

        with patch.object(
            recovery.os, "mkdir", side_effect=fail_replacement
        ):
            with self.assertRaisesRegex(
                OSError, "INJECTED_REPLACEMENT_FAILURE"
            ):
                recovery.quarantine(self.build_id)

        # The original capture must remain accessible.
        self.assertTrue(self.rootfs.is_dir())
        self.assertEqual(
            (self.rootfs / "failed-capture").read_text(),
            "evidence",
        )

        # No second copy of the capture may remain.
        saved = (
            self.workspace / "quarantine"
            / self.build_id / "rootfs"
        )
        self.assertFalse(saved.exists())

        # The release state must remain unchanged.
        self.assertEqual(
            (self.build / "BUILD_STATE").read_text().strip(),
            "initialized",
        )


    def test_interruption_after_rename_preserves_capture(self):
        original_mkdir = recovery.os.mkdir

        def interrupt_replacement(path, *args, **kwargs):
            if path == "rootfs" and "dir_fd" in kwargs:
                raise KeyboardInterrupt(
                    "INJECTED_POST_RENAME_INTERRUPTION"
                )
            return original_mkdir(path, *args, **kwargs)

        with patch.object(
            recovery.os, "mkdir",
            side_effect=interrupt_replacement,
        ):
            with self.assertRaisesRegex(
                KeyboardInterrupt,
                "INJECTED_POST_RENAME_INTERRUPTION",
            ):
                recovery.quarantine(self.build_id)

        saved = (
            self.workspace / "quarantine"
            / self.build_id / "rootfs"
        )

        self.assertFalse(self.rootfs.exists())
        self.assertEqual(
            (saved / "failed-capture").read_text(),
            "evidence",
        )
        self.assertTrue(
            (saved.parent / "recovery.json").is_file()
        )
        self.assertEqual(
            (self.build / "BUILD_STATE").read_text().strip(),
            "initialized",
        )


    def test_recover_interrupted_quarantine(self):
        original_mkdir = recovery.os.mkdir

        def interrupt_replacement(path, *args, **kwargs):
            if path == "rootfs" and "dir_fd" in kwargs:
                raise KeyboardInterrupt("INJECTED_INTERRUPTION")
            return original_mkdir(path, *args, **kwargs)

        with patch.object(
            recovery.os, "mkdir",
            side_effect=interrupt_replacement,
        ):
            with self.assertRaises(KeyboardInterrupt):
                recovery.quarantine(self.build_id)

        saved = (
            self.workspace / "quarantine"
            / self.build_id / "rootfs"
        )

        self.assertFalse(self.rootfs.exists())
        self.assertTrue(saved.is_dir())

        # Complete the interrupted transaction.
        result = recovery.recover_interrupted(self.build_id)

        self.assertTrue(self.rootfs.is_dir())
        self.assertEqual(list(self.rootfs.iterdir()), [])
        self.assertEqual(
            (saved / "failed-capture").read_text(),
            "evidence",
        )
        self.assertEqual(
            (self.build / "BUILD_STATE").read_text().strip(),
            "initialized",
        )
        self.assertIsNotNone(result)

    def test_recovery_refuses_existing_rootfs(self):
        with self.assertRaises((ValueError, OSError)):
            recovery.recover_interrupted(self.build_id)

        self.assertEqual(
            (self.rootfs / "failed-capture").read_text(),
            "evidence",
        )


    def prepare_interrupted_quarantine(self):
        original_mkdir = recovery.os.mkdir

        def interrupt(path, *args, **kwargs):
            if path == "rootfs" and "dir_fd" in kwargs:
                raise KeyboardInterrupt("INJECTED_INTERRUPTION")
            return original_mkdir(path, *args, **kwargs)

        with patch.object(
            recovery.os, "mkdir", side_effect=interrupt
        ):
            with self.assertRaises(KeyboardInterrupt):
                recovery.quarantine(self.build_id)

        return (
            self.workspace / "quarantine"
            / self.build_id
        )

    def test_recovery_rejects_tampered_build_id(self):
        import json

        saved = self.prepare_interrupted_quarantine()
        evidence = saved / "recovery.json"
        record = json.loads(evidence.read_text())
        record["build_id"] = "different-build"
        evidence.write_text(json.dumps(record))

        with self.assertRaisesRegex(
            ValueError, "build ID mismatch"
        ):
            recovery.recover_interrupted(self.build_id)

        self.assertFalse(self.rootfs.exists())
        self.assertTrue((saved / "rootfs").is_dir())

    def test_recovery_rejects_tampered_inode(self):
        import json

        saved = self.prepare_interrupted_quarantine()
        evidence = saved / "recovery.json"
        record = json.loads(evidence.read_text())
        record["original_rootfs_inode"] += 1
        evidence.write_text(json.dumps(record))

        with self.assertRaisesRegex(
            ValueError, "identity mismatch"
        ):
            recovery.recover_interrupted(self.build_id)

        self.assertFalse(self.rootfs.exists())
        self.assertTrue((saved / "rootfs").is_dir())

    def test_recovery_rejects_unsafe_quarantine_mode(self):
        saved = self.prepare_interrupted_quarantine()
        saved.chmod(0o755)

        with self.assertRaisesRegex(
            ValueError, "not private and root-owned"
        ):
            recovery.recover_interrupted(self.build_id)

        self.assertFalse(self.rootfs.exists())
        self.assertTrue((saved / "rootfs").is_dir())


    def test_recovery_interruption_leaves_no_active_rootfs(self):
        saved = self.prepare_interrupted_quarantine()

        def interrupt_chown(fd, uid, gid):
            raise KeyboardInterrupt(
                "INJECTED_RECOVERY_INITIALIZATION_INTERRUPTION"
            )

        with patch.object(
            recovery.os, "fchown",
            side_effect=interrupt_chown,
        ):
            with self.assertRaises(KeyboardInterrupt):
                recovery.recover_interrupted(self.build_id)

        # A partially initialized directory must not become active.
        self.assertFalse(
            self.rootfs.exists(),
            "Partially initialized rootfs was exposed"
        )

        # Quarantined evidence must remain intact.
        self.assertEqual(
            (saved / "rootfs" / "failed-capture").read_text(),
            "evidence",
        )


    def test_recovery_never_replaces_racing_destination(self):
        saved = self.prepare_interrupted_quarantine()
        original_rename = recovery.rename_noreplace
        collision = []

        def create_collision(source_fd, source_name, dest_fd, dest_name):
            if (
                dest_name == "rootfs"
                and source_name.startswith(".rootfs-recovery-")
            ):
                self.rootfs.mkdir()
                collision.append(self.rootfs.stat().st_ino)

            return original_rename(
                source_fd, source_name, dest_fd, dest_name
            )

        with patch.object(
            recovery, "rename_noreplace",
            side_effect=create_collision,
        ):
            with self.assertRaises((OSError, ValueError)):
                recovery.recover_interrupted(self.build_id)

        self.assertEqual(len(collision), 1)
        self.assertTrue(self.rootfs.is_dir())
        self.assertEqual(
            self.rootfs.stat().st_ino,
            collision[0],
            "Unexpected destination was replaced",
        )
        self.assertEqual(
            (saved / "rootfs" / "failed-capture").read_text(),
            "evidence",
        )


    def test_quarantine_refuses_racing_destination(self):
        original_rename = recovery.rename_noreplace
        collisions = []

        def create_collision(source_fd, source_name, dest_fd, dest_name):
            if (
                source_name == "rootfs"
                and dest_name == "rootfs"
            ):
                recovery.os.mkdir("rootfs", dir_fd=dest_fd)
                info = recovery.os.stat(
                    "rootfs", dir_fd=dest_fd,
                    follow_symlinks=False,
                )
                collisions.append(info.st_ino)

            return original_rename(
                source_fd, source_name, dest_fd, dest_name
            )

        with patch.object(
            recovery, "rename_noreplace",
            side_effect=create_collision,
        ):
            with self.assertRaises(OSError):
                recovery.quarantine(self.build_id)

        self.assertEqual(len(collisions), 1)
        self.assertEqual(
            (self.rootfs / "failed-capture").read_text(),
            "evidence",
        )

        competing = (
            self.workspace / "quarantine"
            / self.build_id / "rootfs"
        )
        self.assertEqual(competing.stat().st_ino, collisions[0])

    def test_quarantine_fails_closed_without_renameat2(self):
        import errno

        with patch.object(
            recovery, "rename_noreplace",
            side_effect=OSError(
                errno.ENOSYS, "renameat2 unavailable"
            ),
        ):
            with self.assertRaises(OSError):
                recovery.quarantine(self.build_id)

        self.assertEqual(
            (self.rootfs / "failed-capture").read_text(),
            "evidence",
        )
        self.assertEqual(
            (self.build / "BUILD_STATE").read_text().strip(),
            "initialized",
        )

    def test_empty_rootfs_rejected(self):
        (self.rootfs / "failed-capture").unlink()
        with self.assertRaisesRegex(ValueError, "already empty"):
            recovery.inspect(self.build_id)


    def test_quarantine_preserves_capture(self):
        # Reproduce canonical workspace setgid inheritance.
        self.workspace.chmod(0o2775)

        result = recovery.quarantine(self.build_id)

        saved = (
            self.workspace / "quarantine"
            / self.build_id / "rootfs"
        )

        self.assertTrue(saved.is_dir())
        self.assertEqual(
            saved.parent.stat().st_mode & 0o7777, 0o700
        )
        self.assertEqual(
            saved.parent.parent.stat().st_mode & 0o7777, 0o700
        )
        self.assertEqual(
            (saved / "failed-capture").read_text(),
            "evidence",
        )
        self.assertTrue(self.rootfs.is_dir())
        self.assertEqual(list(self.rootfs.iterdir()), [])
        self.assertEqual(
            (self.build / "BUILD_STATE").read_text(),
            "initialized\n",
        )
        self.assertIsNotNone(result)

    def test_quarantine_rejects_existing_destination(self):
        destination = (
            self.workspace / "quarantine" / self.build_id
        )
        destination.mkdir(parents=True)
        (destination / "rootfs").mkdir()

        with self.assertRaises((ValueError, OSError)):
            recovery.quarantine(self.build_id)

        self.assertTrue(
            (self.rootfs / "failed-capture").exists()
        )

    def test_quarantine_refuses_advanced_state(self):
        (self.build / "BUILD_STATE").write_text(
            "rootfs-generated\\n"
        )

        with self.assertRaises((ValueError, OSError)):
            recovery.quarantine(self.build_id)

        self.assertTrue(
            (self.rootfs / "failed-capture").exists()
        )

    def test_quarantine_refuses_held_build_lock(self):
        fd = os.open(
            self.build, os.O_RDONLY | os.O_DIRECTORY
        )
        try:
            fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
            with self.assertRaises((ValueError, OSError)):
                recovery.quarantine(self.build_id)
        finally:
            os.close(fd)

        self.assertTrue(
            (self.rootfs / "failed-capture").exists()
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
