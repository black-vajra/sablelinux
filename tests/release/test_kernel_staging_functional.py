"""Functional tests of the release initializer's kernel staging branch."""

import os
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[2]
SOURCE = REPO / "scripts/release/create-build.sh"
WORKSPACE = Path("/srv/sablelinux/kernel-builds")

CANDIDATE = (
    "20261028T212705Z-622d439-linux-6.16.1-xattr-test1"
)

RELEASE = "6.16.1-sable-xattr-test1"


def extract_staging_branch():
    source = SOURCE.read_text()

    start_marker = (
        'if [ -n "$KERNEL_CANDIDATE" ]; then\n'
        '    STAGER='
    )

    end_marker = "\nelse\n"

    if source.count(start_marker) != 1:
        raise AssertionError("staging branch anchor is not unique")

    start = source.index(start_marker)
    end = source.index(end_marker, start)

    # The branch includes the opening conditional.
    # Supply a matching fi to execute it independently.
    branch = source[start:end]

    if '--destination "$BUILD_ROOT/boot"' not in branch:
        raise AssertionError("staging destination is incorrect")

    return branch + "\nfi\n"


class KernelStagingFunctionalTests(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        candidate_root = WORKSPACE / CANDIDATE

        required = (
            candidate_root / "BUILD_STATE",
            candidate_root / "metadata/compilation.env",
            candidate_root / "metadata/kernel-modules.sha256",
        )

        if not all(path.is_file() for path in required):
            raise unittest.SkipTest(
                "canonical kernel candidate is unavailable"
            )

        cls.branch = extract_staging_branch()

    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(
            prefix="sable-staging-functional-",
            dir="/srv/sablelinux/testing",
        )

        self.addCleanup(self.temporary.cleanup)

        self.root = Path(self.temporary.name)
        self.build = self.root / "build"
        self.build.mkdir()
        (self.build / "metadata").mkdir()

        (self.build / "BUILD_STATE").write_text("initializing\n")
        self.pointer = self.root / "current-build-id"
        self.pointer.write_text("previous-build\n")

    def execute(self, candidate=CANDIDATE):
        script = "\n".join((
            "set -Eeuo pipefail",
            'die() { echo "ERROR: $*" >&2; exit 1; }',
            self.branch,
        ))

        env = os.environ.copy()

        env.update({
            "REPO": str(REPO),
            "WORKSPACE": "/srv/sablelinux",
            "BUILD_ROOT": str(self.build),
            "KERNEL_CANDIDATE": candidate,
            "CANDIDATE_ROOT": str(WORKSPACE / candidate),
            "KERNEL_RELEASE": RELEASE,
        })

        return subprocess.run(
            ["bash", "-c", script],
            env=env,
            text=True,
            capture_output=True,
            check=False,
        )

    def test_valid_candidate_stages_boot_artifacts(self):
        result = self.execute()

        self.assertEqual(
            result.returncode,
            0,
            result.stdout + result.stderr,
        )

        boot = self.build / "boot"

        expected = (
            f"vmlinuz-{RELEASE}",
            f"System.map-{RELEASE}",
            f"config-{RELEASE}",
            "kernel-artifacts.sha256",
        )

        for name in expected:
            with self.subTest(name=name):
                self.assertTrue((boot / name).is_file())

        self.assertTrue(
            (
                self.build
                / "metadata/candidate-kernel-modules.sha256"
            ).is_file()
        )

        check = subprocess.run(
            ["sha256sum", "-c", "kernel-artifacts.sha256"],
            cwd=boot,
            capture_output=True,
            text=True,
            check=False,
        )

        self.assertEqual(check.returncode, 0, check.stdout + check.stderr)

    def test_invalid_candidate_fails_without_publication(self):
        result = self.execute(
            candidate="nonexistent-release-candidate"
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.build / "boot").exists())

        self.assertEqual(
            (self.build / "BUILD_STATE").read_text(),
            "initializing\n",
        )

        self.assertEqual(
            self.pointer.read_text(),
            "previous-build\n",
        )

    def test_existing_destination_is_preserved(self):
        boot = self.build / "boot"
        boot.mkdir()

        marker = boot / "preserve.txt"
        marker.write_text("do not overwrite\n")

        result = self.execute()

        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(marker.read_text(), "do not overwrite\n")

        self.assertEqual(
            (self.build / "BUILD_STATE").read_text(),
            "initializing\n",
        )

        self.assertEqual(
            self.pointer.read_text(),
            "previous-build\n",
        )


if __name__ == "__main__":
    unittest.main()
