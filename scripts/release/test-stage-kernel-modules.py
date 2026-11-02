#!/usr/bin/env python3
"""Isolated fixture tests for stage-kernel-modules.py (no canonical paths)."""
import hashlib
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

HELPER = Path(__file__).with_name('stage-kernel-modules.py')


class ModuleStagingTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='sable-m111-test-')
        self.addCleanup(self.tmp.cleanup)
        base = Path(self.tmp.name)
        self.repo = base / 'repo'
        self.script = self.repo / 'scripts/release/stage-kernel-modules.py'
        self.script.parent.mkdir(parents=True)
        self.script.write_bytes(HELPER.read_bytes())
        verifier = self.script.parent / 'verify-kernel-candidate.py'
        verifier.write_text('import sys\nsys.exit(0)\n')  # local fixture only
        self.workspace = base / 'candidates'
        self.candidate = self.workspace / 'candidate-1'
        self.build = base / 'build'
        self.module_path = 'lib/modules/6.16.1-test/kernel/sample.ko'
        src = self.candidate / 'modules' / self.module_path
        src.parent.mkdir(parents=True)
        src.write_bytes(b'test module payload')
        self.manifest = hashlib.sha256(src.read_bytes()).hexdigest() + '  ' + self.module_path + '\n'
        (self.candidate / 'metadata').mkdir()
        (self.candidate / 'metadata/compilation.env').write_text('KERNEL_RELEASE=6.16.1-test\n')
        (self.candidate / 'metadata/kernel-modules.sha256').write_text(self.manifest)
        (self.candidate / 'modules/lib/modules/6.16.1-test/modules.dep').write_text('kernel/sample.ko:\n')
        (self.build / 'metadata').mkdir(parents=True)
        (self.build / 'rootfs/lib/modules').mkdir(parents=True)
        (self.build / 'metadata/build.env').write_text('BUILD_STATE=initialized\nKERNEL_RELEASE=6.16.1-test\nKERNEL_CANDIDATE_ID=candidate-1\nKERNEL_MODULES_STAGED=false\n')
        (self.build / 'metadata/candidate-kernel-modules.sha256').write_text(self.manifest)

    def run_stage(self):
        return subprocess.run([sys.executable, '-B', str(self.script), '--workspace', str(self.workspace), '--build-root', str(self.build)], text=True, capture_output=True)

    def test_success(self):
        result = self.run_stage()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.build / 'rootfs' / self.module_path).read_bytes(), b'test module payload')
        self.assertIn('KERNEL_MODULES_STAGED=false', (self.build / 'metadata/build.env').read_text())
        self.assertEqual((self.build / 'rootfs/lib/modules/6.16.1-test/modules.dep').read_text(), 'kernel/sample.ko:\n')
        self.assertTrue((self.build / 'metadata/staged-kernel-module-indexes.sha256').exists())

    def test_source_corruption_rejected(self):
        (self.candidate / 'modules' / self.module_path).write_bytes(b'corruption')
        self.assertNotEqual(self.run_stage().returncode, 0)
        self.assertFalse((self.build / 'rootfs' / self.module_path).exists())

    def test_build_manifest_mismatch_rejected(self):
        (self.build / 'metadata/candidate-kernel-modules.sha256').write_text('invalid\n')
        self.assertNotEqual(self.run_stage().returncode, 0)
        self.assertFalse((self.build / 'rootfs' / self.module_path).exists())

    def test_publication_failure_rolls_back_manifest(self):
        source = self.script.read_text()
        marker = "os.rename(temp_root, destination)"
        self.assertEqual(source.count(marker), 1)
        self.script.write_text(
            source.replace(
                marker,
                'raise OSError("injected publication failure")'
            )
        )

        result = self.run_stage()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("injected publication failure", result.stderr)
        self.assertFalse(
            (self.build / "rootfs/lib/modules/6.16.1-test").exists()
        )
        self.assertFalse(
            (self.build / "metadata/staged-kernel-module-indexes.sha256").exists()
        )

    def test_published_directory_permissions(self):
        result = self.run_stage()
        self.assertEqual(result.returncode, 0, result.stderr)

        tree = (
            self.build / "rootfs/usr/lib/modules/6.16.1-test"
        )

        if not tree.is_dir():
            tree = (
                self.build / "rootfs/lib/modules/6.16.1-test"
            )

        self.assertTrue(tree.is_dir())
        self.assertEqual(tree.stat().st_mode & 0o777, 0o755)

    def test_existing_tree_rejected(self):
        (self.build / 'rootfs/lib/modules/6.16.1-test').mkdir()
        self.assertNotEqual(self.run_stage().returncode, 0)


    def test_merged_usr_layout(self):
        rootfs = self.build / 'rootfs'
        (rootfs / 'lib/modules').rmdir()
        (rootfs / 'lib').rmdir()
        (rootfs / 'usr/lib/modules').mkdir(parents=True)
        (rootfs / 'lib').symlink_to('usr/lib', target_is_directory=True)
        result = self.run_stage()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((rootfs / self.module_path).is_file())
        self.assertTrue((rootfs / 'usr/lib/modules/6.16.1-test/modules.dep').is_file())

    def test_unsafe_lib_symlink_rejected(self):
        rootfs = self.build / 'rootfs'
        (rootfs / 'lib/modules').rmdir()
        (rootfs / 'lib').rmdir()
        (rootfs / 'lib').symlink_to(str(self.workspace), target_is_directory=True)
        self.assertNotEqual(self.run_stage().returncode, 0)

    def test_candidate_build_symlink_omitted(self):
        obj = self.candidate / "obj"
        obj.mkdir()
        tree = self.candidate / "modules/lib/modules/6.16.1-test"
        (tree / "build").symlink_to(obj, target_is_directory=True)

        result = self.run_stage()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(
            (self.build / "rootfs/lib/modules/6.16.1-test/build").exists()
        )

    def test_unsafe_build_symlink_rejected(self):
        tree = self.candidate / "modules/lib/modules/6.16.1-test"
        (tree / "build").symlink_to(
            "/etc", target_is_directory=True
        )
        self.assertNotEqual(self.run_stage().returncode, 0)
        self.assertFalse(
            (self.build / "rootfs/lib/modules/6.16.1-test").exists()
        )

    def test_metadata_symlink_rejected(self):
        index = self.candidate / 'modules/lib/modules/6.16.1-test/modules.dep'
        index.unlink()
        index.symlink_to('/etc/passwd')
        self.assertNotEqual(self.run_stage().returncode, 0)

    def test_symlink_destination_parent_rejected(self):
        parent = self.build / 'rootfs/lib/modules'
        parent.rmdir()
        parent.symlink_to(self.workspace, target_is_directory=True)
        self.assertNotEqual(self.run_stage().returncode, 0)


if __name__ == '__main__':
    unittest.main(verbosity=2)
