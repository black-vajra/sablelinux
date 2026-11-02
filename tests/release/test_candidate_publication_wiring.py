#!/usr/bin/env python3
"""Structural regression tests for candidate publication wiring."""

import subprocess
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "scripts/release/create-build.sh"


class CandidatePublicationWiringTests(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        cls.source = SCRIPT.read_text()

        cls.gate = (
            'die "candidate release creation awaits '
            'staging integration"'
        )

        cls.publisher_assignment = (
            'PUBLISHER="$REPO/scripts/release/'
            'publish-candidate-build.py"'
        )

        cls.branch_start = cls.source.rfind(
            'if [ -n "$KERNEL_CANDIDATE" ]; then'
        )

        if cls.branch_start < 0:
            raise AssertionError("Candidate publication branch missing")

        cls.publication_tail = cls.source[cls.branch_start:]

    def test_shell_syntax(self):
        result = subprocess.run(
            ["bash", "-n", str(SCRIPT)],
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_candidate_publication_requires_verified_staging(self):
        self.assertNotIn(self.gate, self.source)
        self.assertEqual(
            self.source.count(self.publisher_assignment), 1
        )

        verification = self.source.index(
            'python3 -B "$VERIFIER"'
        )
        staging = self.source.index(
            'python3 -B "$STAGER"'
        )
        publication = self.source.index(
            'python3 -B "$PUBLISHER"'
        )

        self.assertLess(verification, staging)
        self.assertLess(staging, publication)


    def test_candidate_publisher_receives_required_inputs(self):
        tail = self.publication_tail
        self.assertIn(self.publisher_assignment, tail)

        required = (
            'python3 -B "$PUBLISHER"',
            '--build-root "$BUILD_ROOT"',
            '--state-dir "$WORKSPACE/state"',
            '--build-id "$BUILD_ID"',
            '--workspace "$WORKSPACE/kernel-builds"',
            'die "candidate build publication failed"',
        )

        for expression in required:
            with self.subTest(expression=expression):
                self.assertIn(expression, tail)

    def test_host_publication_remains_separate(self):
        tail = self.publication_tail

        self.assertIn(
            'if [ -n "$KERNEL_CANDIDATE" ]; then',
            tail,
        )
        self.assertIn(
            'else\n    sed -i',
            tail,
        )
        self.assertIn(
            's/^BUILD_STATE=initializing$/BUILD_STATE=initialized/',
            tail,
        )
        self.assertIn(
            '> "$WORKSPACE/state/current-build-id"',
            tail,
        )

    def test_candidate_branch_does_not_write_pointer_directly(self):
        tail = self.publication_tail

        candidate_branch, separator, host_branch = (
            tail.partition('\nelse\n')
        )

        self.assertTrue(separator, "Missing host-mode branch")
        self.assertIn(self.publisher_assignment, candidate_branch)
        self.assertNotIn(
            '> "$WORKSPACE/state/current-build-id"',
            candidate_branch,
        )
        self.assertIn(
            '> "$WORKSPACE/state/current-build-id"',
            host_branch,
        )


if __name__ == "__main__":
    unittest.main()
