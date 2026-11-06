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

    def test_merged_usr_layout(self):
        modules = self.root / "rootfs/lib/modules"
        modules.rmdir()
        (self.root / "rootfs/lib").rmdir()

        (self.root / "rootfs/usr/lib/modules").mkdir(
            parents=True
        )
        (self.root / "rootfs/lib").symlink_to("usr/lib")

        self.assertEqual(
            module.inspect(self.root),
            "CLEAN: nothing published"
        )

    def test_unsafe_lib_symlink_rejected(self):
        modules = self.root / "rootfs/lib/modules"
        modules.rmdir()
        (self.root / "rootfs/lib").rmdir()

        (self.root / "rootfs/lib").symlink_to("/tmp")

        with self.assertRaises(ValueError):
            module.inspect(self.root)

    def test_active_staging_lock_rejected(self):
        import fcntl
        import os

        parent = self.root / "rootfs/lib/modules"
        fd = os.open(
            parent,
            os.O_RDONLY | os.O_DIRECTORY
        )

        try:
            fcntl.flock(
                fd,
                fcntl.LOCK_EX | fcntl.LOCK_NB
            )

            with self.assertRaisesRegex(
                ValueError, "module staging lock is held"
            ):
                module.inspect(self.root)
        finally:
            os.close(fd)


    def prepare_verified_publication(self):
        import hashlib

        self.tree.mkdir()
        module_file = self.tree / "kernel/sample.ko"
        module_file.parent.mkdir()
        module_file.write_bytes(b"verified module")

        index_file = self.tree / "modules.dep"
        index_file.write_bytes(b"kernel/sample.ko:\n")

        def record(path, data):
            digest = hashlib.sha256(data).hexdigest()
            return f"{digest}  {path}\n"

        module_path = "lib/modules/6.16.1-test/kernel/sample.ko"
        index_path = "lib/modules/6.16.1-test/modules.dep"

        (self.root / "metadata/candidate-kernel-modules.sha256").write_text(
            record(module_path, module_file.read_bytes())
            + record(index_path, index_file.read_bytes())
        )

        self.manifest.write_text(
            record(index_path, index_file.read_bytes())
        )

        return module_file

    def test_verified_publication(self):
        self.prepare_verified_publication()

        self.assertEqual(
            module.inspect(self.root),
            "PUBLISHED_VERIFIED"
        )

    def test_directory_traversal_error_rejected(self):
        from unittest.mock import patch

        self.prepare_verified_publication()
        blocked = self.tree / "unreadable"
        blocked.mkdir()
        (blocked / "unlisted.ko").write_bytes(b"unexpected module")
        original_scandir = module.os.scandir

        def guarded_scandir(path):
            if Path(path) == blocked:
                raise PermissionError("injected traversal failure")
            return original_scandir(path)

        with patch.object(module.os, "scandir", side_effect=guarded_scandir):
            with self.assertRaisesRegex(
                OSError, "injected traversal failure"
            ):
                module.inspect(self.root)

    def test_corrupted_published_module(self):
        module_file = self.prepare_verified_publication()
        module_file.write_bytes(b"corrupted module")

        self.assertEqual(
            module.inspect(self.root),
            "REFUSE: published checksum mismatch"
        )

    def test_unsafe_manifest_path(self):
        self.prepare_verified_publication()

        manifest = self.root / "metadata/candidate-kernel-modules.sha256"
        contents = manifest.read_text()

        manifest.write_text(
            contents.replace(
                "lib/modules/6.16.1-test/kernel/sample.ko",
                "lib/modules/6.16.1-test/../../../../outside"
            )
        )

        self.assertEqual(
            module.inspect(self.root),
            "REFUSE: unsafe manifest path"
        )


    def test_missing_published_module(self):
        module_file = self.prepare_verified_publication()
        module_file.unlink()

        self.assertEqual(
            module.inspect(self.root),
            "REFUSE: published checksum mismatch"
        )

    def test_unlisted_published_module(self):
        self.prepare_verified_publication()
        extra = self.tree / "kernel/unlisted.ko"
        extra.write_bytes(b"untracked module")

        self.assertEqual(
            module.inspect(self.root),
            "REFUSE: unexpected published file"
        )

    def test_symlinked_module_directory(self):
        self.prepare_verified_publication()

        import shutil
        kernel = self.tree / "kernel"
        shutil.rmtree(kernel)
        kernel.symlink_to(self.root / "metadata", target_is_directory=True)

        self.assertEqual(
            module.inspect(self.root),
            "REFUSE: unsafe published file"
        )


    def test_duplicate_manifest_entry(self):
        self.prepare_verified_publication()

        manifest = (
            self.root / "metadata/candidate-kernel-modules.sha256"
        )
        lines = manifest.read_text().splitlines(keepends=True)
        manifest.write_text("".join(lines + [lines[0]]))

        self.assertEqual(
            module.inspect(self.root),
            "REFUSE: invalid manifest"
        )

    def test_inconsistent_index_manifest(self):
        self.prepare_verified_publication()

        self.manifest.write_text(
            "0" * 64
            + "  lib/modules/6.16.1-test/modules.dep\n"
        )

        self.assertEqual(
            module.inspect(self.root),
            "REFUSE: inconsistent module manifests"
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
