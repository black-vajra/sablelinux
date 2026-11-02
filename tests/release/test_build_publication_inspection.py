#!/usr/bin/env python3
"""Regression tests for read-only build publication inspection."""

import importlib.util
import tempfile
import unittest
from pathlib import Path


SCRIPT = (
    Path(__file__).resolve().parents[2]
    / "scripts/release/inspect-build-publication.py"
)

spec = importlib.util.spec_from_file_location(
    "sable_build_inspection", SCRIPT
)
inspector = importlib.util.module_from_spec(spec)
spec.loader.exec_module(inspector)


class BuildPublicationInspectionTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(
            prefix="sable-publication-inspection-"
        )
        self.addCleanup(temporary.cleanup)

        base = Path(temporary.name)
        self.root = base / "test-build"
        self.metadata = self.root / "metadata"
        self.state_dir = base / "state"

        self.metadata.mkdir(parents=True)
        self.state_dir.mkdir()

        self.marker = self.root / "BUILD_STATE"
        self.env = self.metadata / "build.env"
        self.pointer = self.state_dir / "current-build-id"

        self.marker.write_text("initializing\n")
        self.pointer.write_text("previous-build\n")

        self.set_metadata("initializing")

    def set_metadata(self, state):
        self.env.write_text(
            "BUILD_ID=test-build\n"
            f"BUILD_STATE={state}\n"
        )

    def inspect(self):
        tracked = (self.marker, self.env, self.pointer)
        before = {
            path: path.read_bytes()
            for path in tracked
            if path.is_file() and not path.is_symlink()
        }

        result = inspector.inspect(self.root, self.state_dir)

        for path, content in before.items():
            self.assertEqual(path.read_bytes(), content)

        return result

    def test_initializing(self):
        result = self.inspect()
        self.assertEqual(result["classification"], "initializing")
        self.assertFalse(result["selected"])

    def test_interrupted_after_metadata_write(self):
        self.set_metadata("initialized")
        result = self.inspect()
        self.assertEqual(result["classification"], "interrupted")

    def test_completed_but_unselected(self):
        self.set_metadata("initialized")
        self.marker.write_text("initialized\n")
        result = self.inspect()
        self.assertEqual(
            result["classification"],
            "initialized-unselected",
        )

    def test_completed_and_selected(self):
        self.set_metadata("initialized")
        self.marker.write_text("initialized\n")
        self.pointer.write_text("test-build\n")

        result = self.inspect()

        self.assertEqual(
            result["classification"],
            "initialized-selected",
        )
        self.assertTrue(result["selected"])

    def test_incomplete_build_selected_rejected(self):
        self.pointer.write_text("test-build\n")

        with self.assertRaisesRegex(
            ValueError, "incomplete build selected"
        ):
            self.inspect()

    def test_contradictory_completion_marker_rejected(self):
        self.marker.write_text("initialized\n")

        with self.assertRaisesRegex(
            ValueError, "contradicts metadata"
        ):
            self.inspect()

    def test_build_identity_mismatch_rejected(self):
        self.env.write_text(
            "BUILD_ID=different-build\n"
            "BUILD_STATE=initializing\n"
        )

        with self.assertRaisesRegex(
            ValueError, "build identity mismatch"
        ):
            self.inspect()

    def test_symlink_pointer_rejected(self):
        self.pointer.unlink()
        self.pointer.symlink_to(self.env)

        with self.assertRaisesRegex(ValueError, "symlink"):
            self.inspect()

    def test_missing_pointer_is_unselected(self):
        self.pointer.unlink()

        result = self.inspect()

        self.assertEqual(result["classification"], "initializing")
        self.assertIsNone(result["current_build_id"])

    def test_duplicate_metadata_rejected(self):
        with self.env.open("a") as output:
            output.write("BUILD_STATE=initialized\n")

        with self.assertRaisesRegex(
            ValueError, "duplicate metadata key"
        ):
            self.inspect()


if __name__ == "__main__":
    unittest.main()
