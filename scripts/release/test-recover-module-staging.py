#!/usr/bin/env python3
"""Disposable acceptance tests for explicitly requested staging recovery."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

HELPER = Path(__file__).with_name("recover-module-staging.py")
ACTION = "--quarantine-orphan-manifest"


class RecoveryTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="sable-m113-recovery-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.metadata = self.root / "metadata"
        self.metadata.mkdir()
        self.parent = self.root / "rootfs/lib/modules"
        self.parent.mkdir(parents=True)
        (self.root / "BUILD_STATE").write_text("initialized\n")
        (self.metadata / "build.env").write_text(
            "BUILD_ID=fixture-build\nBUILD_STATE=initialized\n"
            "KERNEL_MODULES_STAGED=false\nKERNEL_RELEASE=6.16.1-test\n"
        )
        self.manifest = self.metadata / "staged-kernel-module-indexes.sha256"
        self.payload = b"orphan evidence\n"
        self.manifest.write_bytes(self.payload)

    def run_helper(self, *arguments):
        return subprocess.run(
            [sys.executable, "-B", str(HELPER),
             "--build-root", str(self.root), *arguments],
            capture_output=True, text=True, timeout=10,
        )

    def test_explicit_action_required(self):
        result = self.run_helper()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(ACTION, result.stderr)
        self.assertEqual(self.manifest.read_bytes(), self.payload)

    def test_quarantine_preserves_evidence(self):
        result = self.run_helper(ACTION)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.manifest.exists())
        evidence = list(self.metadata.glob("module-recovery-*"))
        self.assertEqual(len(evidence), 1)
        self.assertEqual(
            (evidence[0] / "manifest.sha256").read_bytes(), self.payload
        )
        record = json.loads((evidence[0] / "recovery.json").read_text())
        self.assertEqual(record["build_id"], "fixture-build")
        self.assertEqual(
            record["manifest_sha256"],
            hashlib.sha256(self.payload).hexdigest(),
        )
        self.assertEqual((self.root / "BUILD_STATE").read_text(), "initialized\n")

    def test_dangling_tree_symlink_refused(self):
        tree = self.parent / "6.16.1-test"
        tree.symlink_to(self.root / "missing")
        result = self.run_helper(ACTION)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("module tree exists", result.stderr)
        self.assertTrue(tree.is_symlink())
        self.assertEqual(self.manifest.read_bytes(), self.payload)

    def test_both_locks_refused(self):
        import fcntl
        import os
        for target, message in (
            (self.root, "build lock is held"),
            (self.parent, "module staging lock is held"),
        ):
            with self.subTest(target=target):
                fd = os.open(target, os.O_RDONLY | os.O_DIRECTORY)
                try:
                    fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
                    result = self.run_helper(ACTION)
                finally:
                    os.close(fd)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(message, result.stderr)
                self.assertEqual(self.manifest.read_bytes(), self.payload)
                self.assertEqual(list(self.metadata.glob("module-recovery-*")), [])

    def test_conflicting_state_refused(self):
        (self.root / "BUILD_STATE").write_text("rootfs-generated\n")
        result = self.run_helper(ACTION)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("build state mismatch", result.stderr)
        self.assertEqual(self.manifest.read_bytes(), self.payload)

    def test_symlinked_metadata_directory_refused(self):
        saved = self.root / "saved-metadata"
        self.metadata.rename(saved)
        self.metadata.symlink_to(saved, target_is_directory=True)
        result = self.run_helper(ACTION)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.manifest.read_bytes(), self.payload)
        self.assertEqual(list(saved.glob("module-recovery-*")), [])

    def test_unsafe_manifest_objects_refused(self):
        import os
        self.manifest.unlink()
        target = self.metadata / "saved-manifest"
        target.write_bytes(self.payload)
        self.manifest.symlink_to(target)
        result = self.run_helper(ACTION)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(target.read_bytes(), self.payload)
        self.manifest.unlink()
        os.mkfifo(self.manifest)
        result = self.run_helper(ACTION)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(list(self.metadata.glob("module-recovery-*")), [])

    def test_interruption_before_source_removal_preserves_evidence(self):
        import importlib.util
        from unittest.mock import patch

        spec = importlib.util.spec_from_file_location("recovery", HELPER)
        recovery = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(recovery)
        with patch.object(
            recovery.os, "unlink", side_effect=OSError("injected interruption")
        ):
            with self.assertRaisesRegex(OSError, "injected interruption"):
                recovery.recover(str(self.root))

        self.assertEqual(self.manifest.read_bytes(), self.payload)
        evidence = list(self.metadata.glob("module-recovery-*"))
        self.assertEqual(len(evidence), 1)
        self.assertEqual(
            (evidence[0] / "manifest.sha256").read_bytes(), self.payload
        )
        before = (evidence[0] / "recovery.json").read_bytes()
        retry = self.run_helper(ACTION)
        self.assertEqual(retry.returncode, 0, retry.stderr)
        self.assertEqual(len(list(self.metadata.glob("module-recovery-*"))), 2)
        self.assertEqual((evidence[0] / "recovery.json").read_bytes(), before)

    def test_interrupted_staging_quarantine_and_retry(self):
        import importlib.util

        source = HELPER.with_name("test-stage-kernel-modules.py")
        spec = importlib.util.spec_from_file_location("staging_fixture", source)
        staging = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(staging)
        fixture = staging.ModuleStagingTests()
        self.addCleanup(fixture.doCleanups)
        fixture.setUp()

        # Reuse the existing abrupt-exit test and its refused staging retry.
        fixture.test_abrupt_exit_after_manifest_publication()
        build = fixture.build
        env = build / "metadata/build.env"
        with env.open("a") as stream:
            stream.write("BUILD_ID=interrupted-fixture\n")
        (build / "BUILD_STATE").write_text("initialized\n")
        original_env = env.read_bytes()
        manifest = build / "metadata" / "staged-kernel-module-indexes.sha256"
        original_manifest = manifest.read_bytes()
        remnants = list(build.rglob(".module-staging-*"))
        remnants += list(build.rglob(".module-manifest-*"))
        self.assertTrue(remnants)

        result = subprocess.run(
            [sys.executable, "-B", str(HELPER),
             "--build-root", str(build), ACTION],
            capture_output=True, text=True, timeout=10,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(manifest.exists())
        evidence = list((build / "metadata").glob("module-recovery-*"))
        self.assertEqual(len(evidence), 1)
        self.assertEqual(
            (evidence[0] / "manifest.sha256").read_bytes(), original_manifest
        )
        self.assertTrue(all(path.exists() for path in remnants))

        retry = fixture.run_stage()
        self.assertEqual(retry.returncode, 0, retry.stderr)
        self.assertEqual(
            (build / "rootfs" / fixture.module_path).read_bytes(),
            b"test module payload",
        )
        self.assertTrue(manifest.is_file())
        self.assertEqual(env.read_bytes(), original_env)
        self.assertEqual((build / "BUILD_STATE").read_text(), "initialized\n")
        self.assertEqual(
            (evidence[0] / "manifest.sha256").read_bytes(), original_manifest
        )
        self.assertTrue(all(path.exists() for path in remnants))

    def test_invalid_metadata_refused(self):
        env = self.metadata / "build.env"
        original = env.read_text()
        variants = (
            original + "BUILD_STATE=initialized\n",
            original + "malformed-line\n",
            original.replace("KERNEL_MODULES_STAGED=false",
                             "KERNEL_MODULES_STAGED=true"),
            original.replace("KERNEL_RELEASE=6.16.1-test",
                             "KERNEL_RELEASE=../outside"),
        )
        for contents in variants:
            with self.subTest(contents=contents):
                env.write_text(contents)
                result = self.run_helper(ACTION)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(self.manifest.read_bytes(), self.payload)
                self.assertEqual(list(self.metadata.glob("module-recovery-*")), [])
        env.write_text(original)

    def test_symlinked_module_parent_refused(self):
        saved = self.root / "saved-modules"
        self.parent.rename(saved)
        self.parent.symlink_to(saved, target_is_directory=True)
        result = self.run_helper(ACTION)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.manifest.read_bytes(), self.payload)
        self.assertEqual(list(self.metadata.glob("module-recovery-*")), [])

    def test_merged_usr_quarantine(self):
        lib = self.root / "rootfs/lib"
        usr = self.root / "rootfs/usr"
        usr.mkdir()
        lib.rename(usr / "lib")
        lib.symlink_to("usr/lib", target_is_directory=True)
        result = self.run_helper(ACTION)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(lib.is_symlink())
        self.assertFalse(self.manifest.exists())
        evidence = list(self.metadata.glob("module-recovery-*"))
        self.assertEqual(len(evidence), 1)
        self.assertEqual(
            (evidence[0] / "manifest.sha256").read_bytes(), self.payload
        )

    def test_evidence_sync_failure_preserves_source(self):
        import importlib.util
        from unittest.mock import patch

        spec = importlib.util.spec_from_file_location("recovery_sync", HELPER)
        recovery = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(recovery)
        with patch.object(
            recovery.os, "fsync", side_effect=OSError("injected sync failure")
        ):
            with self.assertRaisesRegex(OSError, "injected sync failure"):
                recovery.recover(str(self.root))
        self.assertEqual(self.manifest.read_bytes(), self.payload)

    def test_existing_tree_refused(self):
        tree = self.parent / "6.16.1-test"
        tree.mkdir()
        sentinel = tree / "keep"
        sentinel.write_bytes(b"published evidence")
        result = self.run_helper(ACTION)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("module tree exists", result.stderr)
        self.assertEqual(sentinel.read_bytes(), b"published evidence")
        self.assertEqual(self.manifest.read_bytes(), self.payload)


if __name__ == "__main__":
    unittest.main(verbosity=2)
