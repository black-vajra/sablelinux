#!/usr/bin/env python3
"""End-to-end regression tests for release kernel provenance."""

import hashlib
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[2]
CHECKER = (
    REPO / "scripts/release/verify-release-kernel-provenance.py"
)


def write_metadata(path, values):
    path.write_text(
        "".join(f"{key}={value}\n" for key, value in values.items())
    )


def write_manifest(root, files, destination):
    entries = []

    for name, content in sorted(files.items()):
        path = root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(content)

        checksum = hashlib.sha256(content).hexdigest()
        entries.append(f"{checksum}  {name}\n")

    destination.write_text("".join(entries))


class ReleaseKernelProvenanceTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(
            prefix="sable-release-provenance-"
        )
        self.addCleanup(temporary.cleanup)

        self.base = Path(temporary.name)
        self.workspace = self.base / "kernel-builds"
        self.workspace.mkdir()

        self.candidate_id = "test-candidate-001"
        self.release = "6.16.1-sable-provenance-test"

        self.preparation_commit = "a" * 40
        self.compilation_commit = "b" * 40

        self.candidate = self.workspace / self.candidate_id
        candidate_meta = self.candidate / "metadata"
        candidate_meta.mkdir(parents=True)

        (self.candidate / "BUILD_STATE").write_text("built\n")

        write_metadata(
            candidate_meta / "build.env",
            {
                "CANDIDATE_ID": self.candidate_id,
                "CANONICAL_HOST": "SableLinux",
                "GIT_COMMIT": self.preparation_commit,
            },
        )

        write_metadata(
            candidate_meta / "compilation.env",
            {
                "KERNEL_RELEASE": self.release,
                "BUILD_GIT_COMMIT": self.compilation_commit,
            },
        )

        write_manifest(
            self.candidate / "artifacts",
            {
                f"vmlinuz-{self.release}": b"test-kernel",
                f"System.map-{self.release}": b"test-map",
                f"config-{self.release}": b"test-config",
            },
            candidate_meta / "kernel-artifacts.sha256",
        )

        prefix = f"lib/modules/{self.release}"

        write_manifest(
            self.candidate / "modules",
            {
                f"{prefix}/modules.dep": b"test.ko:\n",
                f"{prefix}/modules.alias": b"# aliases\n",
                f"{prefix}/kernel/test.ko": b"test-module",
            },
            candidate_meta / "kernel-modules.sha256",
        )

        obj = self.candidate / "obj"
        obj.mkdir()

        module_root = (
            self.candidate / "modules/lib/modules" / self.release
        )

        os.symlink(obj, module_root / "build")

        self.build_root = self.base / "build-001"
        release_meta = self.build_root / "metadata"
        release_meta.mkdir(parents=True)

        self.env_path = release_meta / "build.env"
        self.manifest = (
            release_meta / "candidate-kernel-modules.sha256"
        )

        self.values = {
            "BUILD_ID": "build-001",
            "BUILD_STATE": "initializing",
            "KERNEL_CANDIDATE_ID": self.candidate_id,
            "KERNEL_RELEASE": self.release,
            "KERNEL_PREPARATION_COMMIT": self.preparation_commit,
            "KERNEL_BUILD_COMMIT": self.compilation_commit,
            "KERNEL_MODULES_STAGED": "false",
        }

        write_metadata(self.env_path, self.values)

        self.manifest.write_bytes(
            (candidate_meta / "kernel-modules.sha256").read_bytes()
        )

        self.marker = self.build_root / "BUILD_STATE"
        self.marker.write_text("initializing\n")

        self.pointer = self.base / "current-build-id"
        self.pointer.write_text("previous-build\n")

    def modify_release(self, key, value):
        self.values[key] = value
        write_metadata(self.env_path, self.values)

    def check(self, expected_success):
        tracked = (
            self.env_path,
            self.manifest,
            self.marker,
            self.pointer,
        )

        before = {path: path.read_bytes() for path in tracked}

        result = subprocess.run(
            [
                sys.executable,
                "-B",
                str(CHECKER),
                "--build-root",
                str(self.build_root),
                "--workspace",
                str(self.workspace),
            ],
            capture_output=True,
            text=True,
            check=False,
        )

        success = (
            result.returncode == 0
            and "SABLE_RELEASE_KERNEL_PROVENANCE_PASS"
            in result.stdout.splitlines()
        )

        self.assertEqual(
            success,
            expected_success,
            msg=(
                f"stdout:\n{result.stdout}\n"
                f"stderr:\n{result.stderr}"
            ),
        )

        for path in tracked:
            self.assertEqual(
                path.read_bytes(),
                before[path],
                f"Verifier modified {path}",
            )

    def test_valid_candidate(self):
        self.check(True)

    def test_wrong_kernel_release(self):
        self.modify_release("KERNEL_RELEASE", "6.16.1-wrong")
        self.check(False)

    def test_wrong_preparation_commit(self):
        self.modify_release(
            "KERNEL_PREPARATION_COMMIT", "0" * 40
        )
        self.check(False)

    def test_wrong_compilation_commit(self):
        self.modify_release("KERNEL_BUILD_COMMIT", "0" * 40)
        self.check(False)

    def test_wrong_candidate_identity(self):
        self.modify_release(
            "KERNEL_CANDIDATE_ID", "missing-candidate"
        )
        self.check(False)

    def test_altered_release_module_manifest(self):
        with self.manifest.open("ab") as output:
            output.write(b"UNEXPECTED\n")
        self.check(False)

    def test_modified_source_module(self):
        source = (
            self.candidate / "modules/lib/modules"
            / self.release / "kernel/test.ko"
        )
        source.write_bytes(b"corrupted-module")
        self.check(False)

    def test_noncanonical_candidate(self):
        path = self.candidate / "metadata/build.env"
        content = path.read_text().replace(
            "CANONICAL_HOST=SableLinux",
            "CANONICAL_HOST=OtherHost",
        )
        path.write_text(content)
        self.check(False)

    def test_missing_candidate_module_index(self):
        path = (
            self.candidate / "modules/lib/modules"
            / self.release / "modules.dep"
        )
        path.unlink()
        self.check(False)

    def test_unexpected_module_symlink(self):
        path = (
            self.candidate / "modules/lib/modules"
            / self.release / "unexpected"
        )
        path.symlink_to(self.candidate / "obj")
        self.check(False)


if __name__ == "__main__":
    unittest.main()
