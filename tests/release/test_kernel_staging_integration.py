"""Structural guards for kernel staging in release initialization."""

import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "scripts/release/create-build.sh"


class KernelStagingIntegrationTests(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        cls.source = SCRIPT.read_text()

    def test_candidate_staging_uses_release_boot_directory(self):
        source = self.source

        self.assertIn(
            'STAGER="$REPO/scripts/release/stage-kernel-artifacts.py"',
            source,
        )
        self.assertIn(
            '--destination "$BUILD_ROOT/boot"',
            source,
        )

    def test_candidate_boot_directory_is_not_precreated(self):
        source = self.source

        self.assertIn(
            '[ "$directory" = "$BUILD_ROOT/boot" ]',
            source,
        )
        self.assertIn(
            'continue',
            source,
        )

    def test_candidate_provenance_is_recorded(self):
        source = self.source

        for field in (
            'HOST_KERNEL_RELEASE=$HOST_KERNEL_RELEASE',
            'KERNEL_CANDIDATE_ID=$KERNEL_CANDIDATE',
            'KERNEL_PREPARATION_COMMIT=$KERNEL_PREPARATION_COMMIT',
            'KERNEL_BUILD_COMMIT=$KERNEL_BUILD_COMMIT',
            'KERNEL_MODULES_STAGED=false',
        ):
            with self.subTest(field=field):
                self.assertIn(field, source)

    def test_candidate_modules_not_claimed_as_deployed(self):
        source = self.source

        self.assertIn(
            'candidate-kernel-modules.sha256',
            source,
        )
        self.assertNotIn(
            'KERNEL_MODULES_STAGED=true',
            source,
        )

    def test_staging_precedes_completion_publication(self):
        source = self.source

        staging = source.index(
            '--destination "$BUILD_ROOT/boot"'
        )
        completion = source.index(
            '"initialized" > "$BUILD_ROOT/BUILD_STATE"'
        )
        publication = source.index(
            '> "$WORKSPACE/state/current-build-id"'
        )

        self.assertLess(staging, completion)
        self.assertLess(completion, publication)

    def test_candidate_creation_remains_blocked(self):
        self.assertIn(
            'die "candidate release creation awaits staging integration"',
            self.source,
        )


if __name__ == "__main__":
    unittest.main()
