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

    def test_empty_rootfs_rejected(self):
        (self.rootfs / "failed-capture").unlink()
        with self.assertRaisesRegex(ValueError, "already empty"):
            recovery.inspect(self.build_id)


if __name__ == "__main__":
    unittest.main(verbosity=2)
