#!/usr/bin/env python3
"""End-to-end candidate tree regression tests."""

import hashlib
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[2]
VERIFIER = REPO / "scripts/release/verify-kernel-candidate.py"

CANDIDATE_ID = "test-kernel-candidate"
RELEASE = "6.16.1-sable-test"


def sha256(data):
    return hashlib.sha256(data).hexdigest()


class CandidateTreeTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(
            prefix="sable-kernel-tree-"
        )
        self.addCleanup(self.temp.cleanup)

        self.workspace = Path(self.temp.name)
        self.candidate = self.workspace / CANDIDATE_ID
        self.artifacts = self.candidate / "artifacts"
        self.modules = self.candidate / "modules"
        self.module_root = (
            self.modules / "lib/modules" / RELEASE
        )
        self.metadata = self.candidate / "metadata"

        for path in (
            self.artifacts,
            self.module_root,
            self.metadata,
            self.candidate / "obj",
        ):
            path.mkdir(parents=True, exist_ok=True)

        (self.candidate / "BUILD_STATE").write_text("built\n")

        (self.metadata / "build.env").write_text(
            f"CANDIDATE_ID={CANDIDATE_ID}\n"
            "CANONICAL_HOST=SableLinux\n"
            "GIT_COMMIT=" + "a" * 40 + "\n"
        )

        (self.metadata / "compilation.env").write_text(
            f"KERNEL_RELEASE={RELEASE}\n"
            "BUILD_GIT_COMMIT=" + "b" * 40 + "\n"
        )

        artifact_lines = []

        for name in (
            f"config-{RELEASE}",
            f"System.map-{RELEASE}",
            f"vmlinuz-{RELEASE}",
        ):
            content = name.encode()
            (self.artifacts / name).write_bytes(content)
            artifact_lines.append(f"{sha256(content)}  {name}")

        (self.metadata / "kernel-artifacts.sha256").write_text(
            "\n".join(artifact_lines) + "\n"
        )

        module_lines = []

        for name in ("modules.dep", "modules.alias", "kernel/test.ko"):
            path = self.module_root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            content = name.encode()
            path.write_bytes(content)

            relative = path.relative_to(self.modules).as_posix()
            module_lines.append(
                f"{sha256(content)}  {relative}"
            )

        (self.metadata / "kernel-modules.sha256").write_text(
            "\n".join(module_lines) + "\n"
        )

        (self.module_root / "build").symlink_to(
            self.candidate / "obj"
        )

    def verify(self):
        return subprocess.run(
            [
                sys.executable,
                "-B",
                str(VERIFIER),
                "--workspace",
                str(self.workspace),
                "--candidate-id",
                CANDIDATE_ID,
            ],
            capture_output=True,
            text=True,
            check=False,
        )

    def test_valid_candidate(self):
        result = self.verify()
        self.assertEqual(
            result.returncode,
            0,
            result.stdout + result.stderr,
        )
        self.assertIn(
            "SABLE_KERNEL_CANDIDATE_PASS",
            result.stdout,
        )

    def test_unmanifested_file_rejected(self):
        (self.module_root / "unexpected.ko").write_bytes(b"rogue")

        result = self.verify()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(
            "module manifest coverage mismatch",
            result.stderr,
        )

    def test_unexpected_symlink_rejected(self):
        (self.module_root / "other").symlink_to(
            self.candidate / "obj"
        )

        result = self.verify()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("unexpected symlink", result.stderr)

    def test_wrong_build_target_rejected(self):
        link = self.module_root / "build"
        link.unlink()
        link.symlink_to(self.workspace)

        result = self.verify()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(
            "unexpected kernel build-link target",
            result.stderr,
        )


if __name__ == "__main__":
    unittest.main()
