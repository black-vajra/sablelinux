#!/usr/bin/env python3
"""Regression tests for release-build candidate argument handling."""

import subprocess
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "scripts/release/create-build.sh"


class CreateBuildPreflightTests(unittest.TestCase):
    def invoke(self, *arguments):
        return subprocess.run(
            ["bash", str(SCRIPT), *arguments],
            capture_output=True,
            text=True,
            check=False,
        )

    def test_unknown_argument_rejected(self):
        result = self.invoke("--unknown-option")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("unknown argument", result.stderr)

    def test_missing_candidate_id_rejected(self):
        result = self.invoke("--kernel-candidate")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("requires an ID", result.stderr)

    def test_empty_candidate_id_rejected(self):
        result = self.invoke("--kernel-candidate", "")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("nonempty ID", result.stderr)

    def test_duplicate_candidate_rejected(self):
        result = self.invoke(
            "--kernel-candidate", "candidate-one",
            "--kernel-candidate", "candidate-two",
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("specified more than once", result.stderr)

    def test_nonroot_execution_rejected(self):
        # These tests must never invoke the release script as root.
        # Root-capable execution is tested separately on canonical Z890.
        import os

        if os.geteuid() == 0:
            self.skipTest("nonroot test requires nonroot execution")

        result = self.invoke(
            "--kernel-candidate", "test-candidate",
            "--verify-candidate-only",
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("run this script through sudo", result.stderr)


if __name__ == "__main__":
    unittest.main()
