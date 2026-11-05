#!/usr/bin/env python3
"""Disposable regression tests for module-staging inspection."""
import importlib.util
from pathlib import Path
import tempfile
import unittest

PATH = Path(__file__).with_name("inspect-module-staging.py")
spec = importlib.util.spec_from_file_location("module_inspector", PATH)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class InspectorTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(
            prefix="sable-m113-inspect-"
        )
        self.addCleanup(self.tmp.cleanup)

        self.root = Path(self.tmp.name)
        (self.root / "metadata").mkdir()
        (self.root / "rootfs/lib/modules").mkdir(parents=True)

        self.env = self.root / "metadata/build.env"
        self.env.write_text(
            "BUILD_STATE=initialized\n"
            "KERNEL_MODULES_STAGED=false\n"
            "KERNEL_RELEASE=6.16.1-test\n"
        )

        self.tree = self.root / "rootfs/lib/modules/6.16.1-test"
        self.manifest = (
            self.root
            / "metadata/staged-kernel-module-indexes.sha256"
        )

    def test_clean(self):
        self.assertEqual(
            module.inspect(self.root),
            "CLEAN: nothing published"
        )

    def test_orphan_manifest(self):
        self.manifest.write_text("fixture\n")
        self.assertEqual(
            module.inspect(self.root),
            "ORPHAN_MANIFEST: interrupted publication suspected"
        )

    def test_tree_without_manifest(self):
        self.tree.mkdir()
        self.assertEqual(
            module.inspect(self.root),
            "REFUSE: module tree exists without manifest"
        )

    def test_both_present(self):
        self.tree.mkdir()
        self.manifest.write_text("fixture\n")
        self.assertEqual(
            module.inspect(self.root),
            "PUBLISHED_UNVERIFIED: verify both artifacts before recovery"
        )

    def test_noninitialized_build(self):
        self.env.write_text(
            "BUILD_STATE=rootfs-generated\n"
            "KERNEL_MODULES_STAGED=true\n"
            "KERNEL_RELEASE=6.16.1-test\n"
        )
        self.assertEqual(
            module.inspect(self.root),
            "REFUSE: build is not initialized"
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
