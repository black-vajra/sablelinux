#!/usr/bin/env python3
"""Integration tests for isolated kernel-artifact staging."""

import fcntl
import hashlib
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[2]
STAGER = REPO / "scripts/release/stage-kernel-artifacts.py"

CANDIDATE = (
    "20261028T212705Z-622d439-linux-6.16.1-xattr-test1"
)
RELEASE = "6.16.1-sable-xattr-test1"
WORKSPACE = Path("/srv/sablelinux/kernel-builds")


class KernelStagingTests(unittest.TestCase):
    def setUp(self):
        if not (WORKSPACE / CANDIDATE).is_dir():
            self.skipTest("canonical test candidate unavailable")

        self.temp = tempfile.TemporaryDirectory(
            prefix="sable-stage-regression-"
        )
        self.addCleanup(self.temp.cleanup)

        self.root = Path(self.temp.name)
        self.destination = self.root / "boot"

    def stage(self, candidate=CANDIDATE, destination=None):
        if destination is None:
            destination = self.destination

        return subprocess.run(
            [
                sys.executable,
                "-B",
                str(STAGER),
                "--workspace",
                str(WORKSPACE),
                "--candidate-id",
                candidate,
                "--destination",
                str(destination),
            ],
            capture_output=True,
            text=True,
            check=False,
        )

    def test_valid_candidate_staged(self):
        result = self.stage()

        self.assertEqual(
            result.returncode, 0,
            result.stdout + result.stderr
        )
        self.assertIn(
            "SABLE_KERNEL_STAGING_PASS",
            result.stdout
        )

        manifest = self.destination / "kernel-artifacts.sha256"
        self.assertTrue(manifest.is_file())

        entries = manifest.read_text().splitlines()
        self.assertEqual(len(entries), 3)

        for entry in entries:
            expected, filename = entry.split("  ", 1)
            path = self.destination / filename

            self.assertTrue(path.is_file())
            self.assertEqual(
                hashlib.sha256(path.read_bytes()).hexdigest(),
                expected
            )

        self.assertEqual(
            sorted(path.name for path in self.destination.iterdir()),
            sorted([
                f"vmlinuz-{RELEASE}",
                f"System.map-{RELEASE}",
                f"config-{RELEASE}",
                "kernel-artifacts.sha256",
            ])
        )

    def test_existing_destination_rejected(self):
        self.destination.mkdir()
        marker = self.destination / "preserve.txt"
        marker.write_text("unchanged")

        result = self.stage()

        self.assertNotEqual(result.returncode, 0)
        self.assertIn(
            "destination must not already exist",
            result.stderr
        )
        self.assertEqual(marker.read_text(), "unchanged")

    def test_missing_candidate_rejected(self):
        result = self.stage(
            candidate="nonexistent-candidate"
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.destination.exists())

    def test_missing_parent_rejected(self):
        destination = self.root / "missing-parent" / "boot"

        result = self.stage(destination=destination)

        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(destination.exists())

    def test_symlink_destination_rejected(self):
        target = self.root / "other"
        target.mkdir()
        self.destination.symlink_to(target)

        result = self.stage()

        self.assertNotEqual(result.returncode, 0)
        self.assertTrue(self.destination.is_symlink())

    def test_no_temporary_directories_after_success(self):
        result = self.stage()

        self.assertEqual(
            result.returncode, 0,
            result.stdout + result.stderr
        )
        self.assertEqual(
            list(self.root.glob(".kernel-staging-*")),
            []
        )


    def test_concurrent_staging_rejected(self):
        fd = os.open(
            self.root,
            os.O_RDONLY | os.O_DIRECTORY,
        )

        try:
            fcntl.flock(
                fd,
                fcntl.LOCK_EX | fcntl.LOCK_NB,
            )

            result = self.stage()

            self.assertNotEqual(result.returncode, 0)
            self.assertIn(
                "another kernel staging operation is active",
                result.stderr,
            )
            self.assertFalse(self.destination.exists())

        finally:
            fcntl.flock(fd, fcntl.LOCK_UN)
            os.close(fd)


if __name__ == "__main__":
    unittest.main()
