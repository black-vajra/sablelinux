"""Functional tests for SableLinux candidate build publication."""

import fcntl
import hashlib
import os
import importlib.util
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "scripts/release/publish-candidate-build.py"

spec = importlib.util.spec_from_file_location(
    "candidate_build_publication", SCRIPT
)
publication = importlib.util.module_from_spec(spec)
spec.loader.exec_module(publication)


class CandidateBuildPublicationTests(unittest.TestCase):

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)

        base = Path(self.temp.name)
        self.build_id = "test-candidate-build"
        self.root = base / self.build_id
        self.boot = self.root / "boot"
        self.metadata = self.root / "metadata"
        self.state_dir = base / "state"

        for directory in (self.boot, self.metadata, self.state_dir):
            directory.mkdir(parents=True)

        self.marker = self.root / "BUILD_STATE"
        self.env = self.metadata / "build.env"
        self.pointer = self.state_dir / "current-build-id"

        self.marker.write_text("initializing\n")
        self.pointer.write_text("previous-build\n")

        self.env.write_text(
            f"BUILD_ID={self.build_id}\n"
            "BUILD_STATE=initializing\n"
            "KERNEL_RELEASE=test-kernel\n"
            "KERNEL_CANDIDATE_ID=test-candidate\n"
            "KERNEL_PREPARATION_COMMIT=abc123\n"
            "KERNEL_BUILD_COMMIT=def456\n"
            "KERNEL_MODULES_STAGED=false\n"
        )

        (self.metadata / "candidate-kernel-modules.sha256").write_text(
            "recorded candidate module manifest\n"
        )

        records = []

        for name in (
            "vmlinuz-test-kernel",
            "System.map-test-kernel",
            "config-test-kernel",
        ):
            content = name.encode()
            (self.boot / name).write_bytes(content)

            checksum = hashlib.sha256(content).hexdigest()
            records.append(f"{checksum}  {name}")

        (self.boot / "kernel-artifacts.sha256").write_text(
            "\n".join(records) + "\n"
        )

    def publish(self):
        publication.publish(
            self.root,
            self.state_dir,
            self.build_id,
        )

    def assert_not_published(self):
        self.assertEqual(
            self.pointer.read_text(),
            "previous-build\n",
        )
        self.assertEqual(
            self.marker.read_text(),
            "initializing\n",
        )

    def test_successful_publication(self):
        self.publish()

        self.assertEqual(
            self.marker.read_text(),
            "initialized\n",
        )
        self.assertEqual(
            self.pointer.read_text(),
            self.build_id + "\n",
        )
        self.assertIn(
            "BUILD_STATE=initialized",
            self.env.read_text(),
        )

    def test_missing_manifest_rejected(self):
        (self.boot / "kernel-artifacts.sha256").unlink()

        with self.assertRaises(ValueError):
            self.publish()

        self.assert_not_published()

    def test_modified_artifact_rejected(self):
        (self.boot / "vmlinuz-test-kernel").write_bytes(b"corrupt")

        with self.assertRaises(ValueError):
            self.publish()

        self.assert_not_published()

    def test_metadata_mismatch_rejected(self):
        original = self.env.read_text()

        self.env.write_text(
            original.replace(
                f"BUILD_ID={self.build_id}",
                "BUILD_ID=incorrect",
            )
        )

        with self.assertRaises(ValueError):
            self.publish()

        self.assert_not_published()

    def test_pointer_failure_preserves_old_pointer(self):
        original_replace = publication.os.replace

        def fail_pointer_update(source, destination):
            if Path(destination) == self.pointer:
                raise OSError("simulated pointer failure")
            return original_replace(source, destination)

        with patch.object(
            publication.os,
            "replace",
            side_effect=fail_pointer_update,
        ):
            with self.assertRaises(OSError):
                self.publish()

        self.assertEqual(
            self.pointer.read_text(),
            "previous-build\n",
        )
        self.assertEqual(
            self.marker.read_text(),
            "initialized\n",
        )

    def test_second_publication_rejected(self):
        self.publish()

        with self.assertRaises(ValueError):
            self.publish()



    def test_concurrent_publication_rejected(self):
        fd = os.open(
            self.state_dir,
            os.O_RDONLY | os.O_DIRECTORY,
        )

        try:
            fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)

            with self.assertRaisesRegex(
                ValueError,
                "another build publication is active",
            ):
                self.publish()

            self.assert_not_published()
        finally:
            fcntl.flock(fd, fcntl.LOCK_UN)
            os.close(fd)

    def test_publication_after_lock_release(self):
        fd = os.open(
            self.state_dir,
            os.O_RDONLY | os.O_DIRECTORY,
        )

        fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        fcntl.flock(fd, fcntl.LOCK_UN)
        os.close(fd)

        self.publish()

        self.assertEqual(
            self.marker.read_text(),
            "initialized" + chr(10),
        )

        self.assertEqual(
            self.pointer.read_text(),
            self.build_id + chr(10),
        )


if __name__ == "__main__":
    unittest.main()
