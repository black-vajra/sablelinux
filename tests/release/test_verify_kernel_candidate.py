#!/usr/bin/env python3
"""Regression tests for the SableLinux kernel candidate verifier."""

import hashlib
import importlib.util
import tempfile
import unittest
from pathlib import Path


VERIFIER_PATH = (
    Path(__file__).resolve().parents[2]
    / "scripts/release/verify-kernel-candidate.py"
)

spec = importlib.util.spec_from_file_location(
    "sable_kernel_candidate_verifier",
    VERIFIER_PATH,
)
verifier = importlib.util.module_from_spec(spec)
spec.loader.exec_module(verifier)


class ManifestTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(
            prefix="sable-kernel-verifier-"
        )
        self.addCleanup(self.temporary.cleanup)

        self.root = Path(self.temporary.name)
        self.artifacts = self.root / "artifacts"
        self.artifacts.mkdir()
        self.manifest = self.root / "manifest.sha256"

    def populate(self, count):
        entries = []

        for index in range(count):
            name = f"module-{index}.ko"
            content = f"test-module-{index}".encode()

            (self.artifacts / name).write_bytes(content)

            digest = hashlib.sha256(content).hexdigest()
            entries.append(f"{digest}  {name}")

        self.manifest.write_text(
            "\n".join(entries) + ("\n" if entries else "")
        )

        return entries

    def verify(self, expected_count=None):
        return verifier.verify_manifest(
            self.artifacts,
            self.manifest,
            expected_count,
        )

    def test_dynamic_module_counts(self):
        for count in (1, 3, 57, 58):
            with self.subTest(count=count):
                self.populate(count)
                self.assertEqual(len(self.verify()), count)

    def test_empty_manifest_rejected(self):
        self.populate(0)

        with self.assertRaises(ValueError):
            self.verify()

    def test_modified_artifact_rejected(self):
        self.populate(1)
        (self.artifacts / "module-0.ko").write_bytes(b"tampered")

        with self.assertRaises(ValueError):
            self.verify()

    def test_path_traversal_rejected(self):
        entries = self.populate(1)
        digest = entries[0].split()[0]

        self.manifest.write_text(
            f"{digest}  ../outside.ko\n"
        )

        with self.assertRaises(ValueError):
            self.verify()

    def test_missing_artifact_rejected(self):
        self.populate(1)
        (self.artifacts / "module-0.ko").unlink()

        with self.assertRaises(ValueError):
            self.verify()

    def test_duplicate_manifest_entry_rejected(self):
        entries = self.populate(1)
        self.manifest.write_text(
            entries[0] + "\n" + entries[0] + "\n"
        )

        with self.assertRaises(ValueError):
            self.verify()

    def test_symlink_artifact_rejected(self):
        self.populate(1)

        target = self.artifacts / "module-0.ko"
        original = self.root / "original.ko"

        target.rename(original)
        target.symlink_to(original)

        with self.assertRaises(ValueError):
            self.verify()

    def test_fixed_artifact_count(self):
        self.populate(3)

        self.assertEqual(len(self.verify(3)), 3)

        with self.assertRaises(ValueError):
            self.verify(4)


if __name__ == "__main__":
    unittest.main()
