#!/usr/bin/env python3
"""Verify release-home validation blocks generator progression."""

import shlex
import subprocess
import tempfile
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
GENERATOR = REPO / "scripts/live/generate-rootfs.sh"

START = 'validation_log "=== VALIDATE RELEASE HOME SECURITY ==="'
END = 'validation_log "PASS: generated rootfs validation completed"'
PROMOTION = 'FINAL_ENV="$BUILD_ROOT/tmp/rootfs-build.env.final"'


class RootfsHomeGateTests(unittest.TestCase):

    def test_validation_failure_blocks_progression(self):
        source = GENERATOR.read_text()

        self.assertEqual(source.count(START), 1)
        self.assertEqual(source.count(END), 1)
        self.assertEqual(source.count(PROMOTION), 1)

        start = source.index(START)
        end = source.index(END) + len(END)

        self.assertLess(end, source.index(PROMOTION))

        # Exercise the actual generator validation block.
        gate = source[start:end]

        with tempfile.TemporaryDirectory(
            prefix="sable-rootfs-gate-"
        ) as temporary:
            base = Path(temporary)
            rootfs = base / "rootfs"
            rootfs.mkdir()

            report = base / "validation.log"
            progressed = base / "progressed"

            script = f"""#!/usr/bin/env bash
set -Eeuo pipefail

REPO={shlex.quote(str(REPO))}
ROOTFS={shlex.quote(str(rootfs))}
VALIDATION_REPORT={shlex.quote(str(report))}

validation_log() {{
    printf '%s\\n' "$*" >> "$VALIDATION_REPORT"
}}

die() {{
    printf 'ERROR: %s\\n' "$*" >&2
    exit 1
}}

{gate}

printf '%s\\n' "UNEXPECTED PROGRESSION" > {shlex.quote(str(progressed))}
"""

            result = subprocess.run(
                ["bash"],
                input=script,
                text=True,
                capture_output=True,
            )

            self.assertNotEqual(result.returncode, 0)
            self.assertFalse(
                progressed.exists(),
                "Generator continued after security failure",
            )
            self.assertIn(
                "release-home security validation failed",
                result.stderr,
            )
            self.assertIn(
                "release-home validation failed",
                report.read_text(),
            )


if __name__ == "__main__":
    unittest.main(verbosity=2)
