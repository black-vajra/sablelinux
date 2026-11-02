"""Regression tests for candidate pointer publication ownership."""

import importlib.util
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch


REPO = Path("/home/pepper/sablelinux")
PUBLISHER = REPO / "scripts/release/publish-candidate-build.py"

spec = importlib.util.spec_from_file_location(
    "sable_candidate_publisher_ownership_test",
    PUBLISHER,
)
publication = importlib.util.module_from_spec(spec)
spec.loader.exec_module(publication)


class PublicationPointerOwnershipTests(unittest.TestCase):

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.pointer = Path(self.temp.name) / "current-build-id"
        self.pointer.write_text("previous-build\n")

    def test_root_sets_ownership_before_pointer_replacement(self):
        events = []
        original_replace = publication.os.replace

        def record_chown(path, uid, gid):
            self.assertEqual(uid, 0)
            self.assertEqual(gid, 1234)
            self.assertTrue(Path(path).exists())
            events.append("chown")

        def record_replace(source, destination):
            self.assertEqual(Path(destination), self.pointer)
            events.append("replace")
            return original_replace(source, destination)

        with (
            patch.object(publication.os, "geteuid", return_value=0),
            patch.object(
                publication.os,
                "chown",
                side_effect=record_chown,
            ),
            patch.object(
                publication.os,
                "replace",
                side_effect=record_replace,
            ),
        ):
            publication.atomic_write(
                self.pointer,
                "new-build\n",
                group=1234,
            )

        self.assertEqual(events, ["chown", "replace"])
        self.assertEqual(self.pointer.read_text(), "new-build\n")
        self.assertEqual(self.pointer.stat().st_mode & 0o777, 0o664)

    def test_chown_failure_preserves_existing_pointer(self):
        with (
            patch.object(publication.os, "geteuid", return_value=0),
            patch.object(
                publication.os,
                "chown",
                side_effect=PermissionError(
                    "INJECTED_OWNERSHIP_FAILURE"
                ),
            ) as chown,
            patch.object(publication.os, "replace") as replace,
        ):
            with self.assertRaisesRegex(
                PermissionError,
                "INJECTED_OWNERSHIP_FAILURE",
            ):
                publication.atomic_write(
                    self.pointer,
                    "new-build\n",
                    group=1234,
                )

            chown.assert_called_once()
            replace.assert_not_called()

        self.assertEqual(
            self.pointer.read_text(),
            "previous-build\n",
        )
        self.assertEqual(
            list(Path(self.temp.name).glob(".publish-*")),
            [],
        )

    def test_unprivileged_execution_skips_chown(self):
        with (
            patch.object(publication.os, "geteuid", return_value=1000),
            patch.object(publication.os, "chown") as chown,
        ):
            publication.atomic_write(
                self.pointer,
                "new-build\n",
                group=1234,
            )
            chown.assert_not_called()

        self.assertEqual(self.pointer.read_text(), "new-build\n")


if __name__ == "__main__":
    unittest.main()
