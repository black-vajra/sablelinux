"""Functional tests for SableLinux candidate build publication."""

import fcntl
import hashlib
import os
import shutil
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
            f"KERNEL_PREPARATION_COMMIT={'a' * 40}\n"
            f"KERNEL_BUILD_COMMIT={'b' * 40}\n"
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


        # A complete candidate fixture for the real candidate verifier.
        self.workspace = base / "kernel-builds"
        self.candidate = self.workspace / "test-candidate"
        candidate_meta = self.candidate / "metadata"
        candidate_artifacts = self.candidate / "artifacts"
        candidate_modules = (
            self.candidate / "modules/lib/modules/test-kernel"
        )

        candidate_meta.mkdir(parents=True)
        candidate_artifacts.mkdir()
        candidate_modules.mkdir(parents=True)

        (self.candidate / "BUILD_STATE").write_text("built\n")
        (self.candidate / "obj").mkdir()

        (candidate_meta / "build.env").write_text(
            "CANDIDATE_ID=test-candidate\n"
            "CANONICAL_HOST=SableLinux\n"
            f"GIT_COMMIT={'a' * 40}\n"
        )

        (candidate_meta / "compilation.env").write_text(
            "KERNEL_RELEASE=test-kernel\n"
            f"BUILD_GIT_COMMIT={'b' * 40}\n"
        )

        for name in (
            "vmlinuz-test-kernel",
            "System.map-test-kernel",
            "config-test-kernel",
        ):
            shutil.copyfile(
                self.boot / name,
                candidate_artifacts / name,
            )

        shutil.copyfile(
            self.boot / "kernel-artifacts.sha256",
            candidate_meta / "kernel-artifacts.sha256",
        )

        module_files = {
            "modules.dep": b"test.ko:\n",
            "modules.alias": b"# aliases\n",
            "kernel/test.ko": b"test-module",
        }

        module_records = []

        for name, content in module_files.items():
            target = candidate_modules / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(content)

            checksum = hashlib.sha256(content).hexdigest()
            module_records.append(
                f"{checksum}  lib/modules/test-kernel/{name}"
            )

        manifest_content = "\n".join(module_records) + "\n"

        (candidate_meta / "kernel-modules.sha256").write_text(
            manifest_content
        )

        (
            self.metadata / "candidate-kernel-modules.sha256"
        ).write_text(manifest_content)

        (candidate_modules / "build").symlink_to(
            self.candidate / "obj"
        )

    def publish(self):
        publication.publish(
            self.root,
            self.state_dir,
            self.build_id,
            self.workspace,
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



    def test_candidate_compilation_mismatch_rejected(self):
        path = self.candidate / "metadata/compilation.env"
        path.write_text(
            path.read_text().replace("b" * 40, "c" * 40)
        )

        with self.assertRaisesRegex(
            ValueError, "provenance verification failed"
        ):
            self.publish()

        self.assert_not_published()
        self.assertIn(
            "BUILD_STATE=initializing",
            self.env.read_text(),
        )

    def test_candidate_source_module_corruption_rejected(self):
        path = (
            self.candidate
            / "modules/lib/modules/test-kernel/kernel/test.ko"
        )
        path.write_bytes(b"corrupted-module")

        with self.assertRaisesRegex(
            ValueError, "provenance verification failed"
        ):
            self.publish()

        self.assert_not_published()
        self.assertIn(
            "BUILD_STATE=initializing",
            self.env.read_text(),
        )

    def test_candidate_manifest_mismatch_rejected(self):
        path = (
            self.metadata / "candidate-kernel-modules.sha256"
        )
        path.write_text("incorrect manifest\n")

        with self.assertRaisesRegex(
            ValueError, "provenance verification failed"
        ):
            self.publish()

        self.assert_not_published()
        self.assertIn(
            "BUILD_STATE=initializing",
            self.env.read_text(),
        )

    def test_missing_candidate_rejected(self):
        shutil.rmtree(self.candidate)

        with self.assertRaisesRegex(
            ValueError, "provenance verification failed"
        ):
            self.publish()

        self.assert_not_published()
        self.assertIn(
            "BUILD_STATE=initializing",
            self.env.read_text(),
        )



    def test_metadata_write_failure_preserves_old_build(self):
        original_replace = publication.os.replace

        def fail_metadata(source, destination):
            if Path(destination) == self.env:
                raise OSError("simulated metadata failure")
            return original_replace(source, destination)

        with patch.object(
            publication.os,
            "replace",
            side_effect=fail_metadata,
        ):
            with self.assertRaises(OSError):
                self.publish()

        self.assertIn(
            "BUILD_STATE=initializing",
            self.env.read_text(),
        )
        self.assertEqual(self.marker.read_text(), "initializing\n")
        self.assertEqual(self.pointer.read_text(), "previous-build\n")

    def test_marker_write_failure_preserves_old_pointer(self):
        original_replace = publication.os.replace

        def fail_marker(source, destination):
            if Path(destination) == self.marker:
                raise OSError("simulated marker failure")
            return original_replace(source, destination)

        with patch.object(
            publication.os,
            "replace",
            side_effect=fail_marker,
        ):
            with self.assertRaises(OSError):
                self.publish()

        self.assertIn(
            "BUILD_STATE=initialized",
            self.env.read_text(),
        )
        self.assertEqual(self.marker.read_text(), "initializing\n")
        self.assertEqual(self.pointer.read_text(), "previous-build\n")

if __name__ == "__main__":
    unittest.main()
