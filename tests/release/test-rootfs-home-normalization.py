#!/usr/bin/env python3
"""Exercise the generator's release-home placeholder normalization."""

import os
import shlex
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
GENERATOR = REPO / "scripts/live/generate-rootfs.sh"

START = 'for release_home in "$ROOTFS/home" "$ROOTFS/root"; do'
END = 'chmod 00700 "$ROOTFS/root"'


class RootfsHomeNormalizationTests(unittest.TestCase):

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(
            prefix="sable-home-normalization-"
        )
        self.addCleanup(self.temp.cleanup)

        self.rootfs = Path(self.temp.name) / "rootfs"
        self.rootfs.mkdir()

        for name, mode in (("home", 0o2755), ("root", 0o2700)):
            path = self.rootfs / name
            path.mkdir()
            path.chmod(mode)

    def run_normalization(self):
        source = GENERATOR.read_text()

        self.assertEqual(source.count(START), 1)
        self.assertEqual(source.count(END), 1)

        start = source.index(START)
        end = source.index(END, start) + len(END)
        block = source[start:end]

        script = f"""#!/usr/bin/env bash
set -Eeuo pipefail

ROOTFS={shlex.quote(str(self.rootfs))}

die() {{
    printf '%s\\n' "$*" >&2
    exit 1
}}

{block}
"""

        return subprocess.run(
            ["bash"],
            input=script,
            text=True,
            capture_output=True,
        )

    @unittest.skipUnless(os.geteuid() == 0, "requires root")
    def test_inherited_metadata_normalized(self):
        for name in ("home", "root"):
            os.chown(self.rootfs / name, 0, 1000)

        result = self.run_normalization()
        self.assertEqual(result.returncode, 0, result.stderr)

        for name, mode in (("home", 0o755), ("root", 0o700)):
            path = self.rootfs / name
            metadata = path.stat()

            self.assertEqual(metadata.st_uid, 0)
            self.assertEqual(metadata.st_gid, 0)
            self.assertEqual(stat.S_IMODE(metadata.st_mode), mode)

    def test_unexpected_home_file_rejected(self):
        (self.rootfs / "home" / "private-key").write_text("secret")

        result = self.run_normalization()

        self.assertNotEqual(result.returncode, 0)
        self.assertTrue(
            (self.rootfs / "home" / "private-key").exists()
        )

    def test_unexpected_root_file_rejected(self):
        (self.rootfs / "root" / ".credentials").write_text("secret")

        result = self.run_normalization()

        self.assertNotEqual(result.returncode, 0)
        self.assertTrue(
            (self.rootfs / "root" / ".credentials").exists()
        )

    def test_symlinked_home_rejected(self):
        (self.rootfs / "home").rmdir()
        (self.rootfs / "home").symlink_to(self.rootfs / "root")

        result = self.run_normalization()

        self.assertNotEqual(result.returncode, 0)

    def test_unexpected_extended_attribute_rejected(self):
        path = self.rootfs / "home"

        try:
            os.setxattr(path, "user.sable_test", b"unexpected")
        except OSError as error:
            self.skipTest(f"filesystem does not support xattrs: {error}")

        result = self.run_normalization()

        self.assertNotEqual(result.returncode, 0)
        self.assertIn(
            "unexpected metadata",
            result.stderr,
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
