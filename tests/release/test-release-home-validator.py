#!/usr/bin/env python3
"""Regression tests for the generated release-home security validator."""

import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
VALIDATOR = REPO / "scripts/live/validate-release-home.py"

FILES = {
    ".bash_profile": "configs/live/sable-bash-profile",
    ".config/sway/config": "configs/desktop/sway/config",
    ".config/waybar/config": "configs/desktop/waybar/config",
    ".config/waybar/style.css": "configs/desktop/waybar/style.css",
    ".config/waybar/bottom-config": "configs/desktop/waybar/bottom-config",
    ".config/waybar/bottom-style.css": "configs/desktop/waybar/bottom-style.css",
    ".local/bin/sable-window-control": "configs/desktop/waybar/sable-window-control",
    ".config/fuzzel/fuzzel.ini": "configs/desktop/fuzzel/fuzzel.ini",
    ".local/bin/sable-power-menu": "configs/desktop/waybar/sable-power-menu",
    ".local/bin/sable-workspace-label":
        "configs/desktop/waybar/sable-workspace-label",
    ".local/bin/sable-sensors": "configs/desktop/waybar/sable-sensors",
    ".local/bin/sable-network-status":
        "configs/desktop/waybar/sable-network-status",
}


class ReleaseHomeTests(unittest.TestCase):

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(
            prefix="sable-release-home-"
        )
        self.addCleanup(self.tmp.cleanup)

        self.root = Path(self.tmp.name) / "rootfs"
        self.home = self.root / "home/sable"
        etc = self.root / "etc"
        etc.mkdir(parents=True)

        self.uid = int(os.environ.get("SUDO_UID", os.getuid()))
        self.gid = int(os.environ.get("SUDO_GID", os.getgid()))
        if os.geteuid() != 0 or self.uid == 0 or self.gid == 0:
            self.fail("root execution with a non-root test account required")

        (etc / "passwd").write_text(
            "root:x:0:0:root:/root:/bin/bash\n"
            f"sable:x:{self.uid}:{self.gid}:"
            "Sable:/home/sable:/bin/bash\n"
        )

        self.home.mkdir(parents=True)
        (self.home / ".bashrc").write_bytes(
            b"PS1='[\\u@\\h \\w]\\$ '\n"
        )

        for relative, source in FILES.items():
            destination = self.home / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(REPO / source, destination)
            destination.chmod(
                0o755 if relative.startswith(".local/bin/")
                else 0o644
            )

        # Fixture-only ownership: /home remains root-owned, while
        # the release-user home and all descendants belong to sable.
        for directory, subdirs, files in os.walk(self.home):
            os.chown(directory, self.uid, self.gid)
            for name in subdirs + files:
                os.chown(Path(directory) / name, self.uid, self.gid)

        self.target = self.home / ".config/sway/config"

    def validate(self, expected_success):
        result = subprocess.run(
            [
                "python3", "-B", str(VALIDATOR),
                "--rootfs", str(self.root),
                "--repo", str(REPO),
            ],
            capture_output=True,
            text=True,
        )

        if expected_success:
            self.assertEqual(result.returncode, 0, result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0)
            self.assertIn(
                "release-home validation failed",
                result.stderr,
            )

    def test_valid_home(self):
        self.validate(True)

    def test_unexpected_file(self):
        (self.home / "private-token").write_text("SENTINEL\n")
        self.validate(False)

    def test_symlink(self):
        self.target.unlink()
        self.target.symlink_to("/etc/passwd")
        self.validate(False)

    def test_wrong_permissions(self):
        self.target.chmod(0o600)
        self.validate(False)

    def test_modified_content(self):
        self.target.write_text("UNAUTHORIZED\n")
        self.validate(False)

    def test_missing_file(self):
        self.target.unlink()
        self.validate(False)

    def test_extended_attribute(self):
        os.setxattr(
            self.target,
            "user.sable_security_test",
            b"UNAUTHORIZED",
        )
        self.validate(False)

    def test_unauthorized_acl(self):
        if not shutil.which("setfacl"):
            self.skipTest("setfacl unavailable")

        subprocess.run(
            ["setfacl", "-m", "u:12345:---", str(self.target)],
            check=True,
        )
        self.validate(False)


    def test_parent_symlink(self):
        parent = self.root / "home"
        saved = self.root / "home-original"
        parent.rename(saved)
        parent.symlink_to(saved.name)
        self.validate(False)

    def test_parent_wrong_mode(self):
        (self.root / "home").chmod(0o777)
        self.validate(False)

    def test_parent_wrong_owner(self):
        os.chown(self.root / "home", self.uid, self.gid)
        self.validate(False)

    def test_parent_extended_attribute(self):
        os.setxattr(
            self.root / "home",
            "user.sable_security_test",
            b"UNAUTHORIZED",
        )
        self.validate(False)

    def test_home_wrong_owner(self):
        os.chown(self.home, 0, 0)
        self.validate(False)

    def test_unexpected_second_home(self):
        (self.root / "home/another-user").mkdir()
        self.validate(False)

    def test_unexpected_home_parent_file(self):
        (self.root / "home/host-secret").write_text(
            "SYNTHETIC PRIVATE SENTINEL\n"
        )
        self.validate(False)


if __name__ == "__main__":
    unittest.main(verbosity=2)
