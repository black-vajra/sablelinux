"""Regression checks for canonical release initialization ordering."""

import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "scripts/release/create-build.sh"


class InitializationStateTests(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        cls.source = SCRIPT.read_text()

    def test_initial_state_is_incomplete(self):
        source = self.source

        self.assertIn(
            'cat > "$BUILD_ROOT/BUILD_STATE" <<STATE\ninitializing\nSTATE',
            source,
        )

        self.assertIn(
            'BUILD_STATE=initializing\nCREATED_AT=',
            source,
        )

    def test_completion_follows_kernel_verification(self):
        source = self.source

        verification = source.index(
            'sha256sum "$KERNEL_CONFIG"'
        )

        completion = source.index(
            '"initialized" > "$BUILD_ROOT/BUILD_STATE"'
        )

        self.assertLess(verification, completion)

    def test_metadata_finalized_before_completion_marker(self):
        source = self.source

        metadata = source.index(
            's/^BUILD_STATE=initializing$/BUILD_STATE=initialized/'
        )

        completion = source.index(
            '"initialized" > "$BUILD_ROOT/BUILD_STATE"'
        )

        self.assertLess(metadata, completion)

    def test_completion_precedes_current_build_publication(self):
        source = self.source

        completion = source.index(
            '"initialized" > "$BUILD_ROOT/BUILD_STATE"'
        )

        publication = source.index(
            '> "$WORKSPACE/state/current-build-id"'
        )

        self.assertLess(completion, publication)

    def test_candidate_release_creation_remains_blocked(self):
        self.assertIn(
            'die "candidate release creation awaits staging integration"',
            self.source,
        )


if __name__ == "__main__":
    unittest.main()
