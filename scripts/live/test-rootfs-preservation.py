#!/usr/bin/env python3
"""Positive and deliberate-failure tests; writes only fresh disposable fixtures."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--workspace", required=True, type=Path)
    args = parser.parse_args()
    if os.geteuid() != 0:
        raise RuntimeError("root required")
    helper = Path(__file__).resolve().with_name("check-rootfs-preservation.py")
    rsync = str(Path(shutil.which("rsync")).resolve())
    run = Path(tempfile.mkdtemp(prefix="rootfs-preservation-tests-", dir=args.workspace))
    print(f"Retained tests: {run}", flush=True)
    for case in ("installed", "drop-acls", "drop-xattrs", "copy-failure"):
        workspace = run / case
        workspace.mkdir()
        executable = rsync
        if case != "installed":
            wrapper = workspace / "rsync-wrapper"
            wrapper.write_text(f"#!{sys.executable}\n" +
                "import os, sys\n" +
                f"real = {rsync!r}\ncase = {case!r}\n" +
                "args = sys.argv[1:]\n" +
                "if '--version' not in args:\n" +
                "    if case == 'copy-failure': sys.exit(42)\n" +
                "    replacement = '-aHX' if case == 'drop-acls' else '-aHA'\n" +
                "    args = [replacement if a == '-aHAX' else a for a in args]\n" +
                "os.execv(real, [real, *args])\n")
            wrapper.chmod(0o755)
            executable = str(wrapper)
        result = subprocess.run([sys.executable, str(helper),
            "--workspace", str(workspace), "--destination-root", str(workspace),
            "--rsync", executable], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        (workspace / "result.log").write_bytes(result.stdout)
        passed = b"PASS: rootfs preservation prerequisite" in result.stdout
        if case == "installed":
            if result.returncode != 0 or not passed:
                raise RuntimeError(f"installed rsync failed; see {workspace / 'result.log'}")
        else:
            expected = b"command failed (42)" if case == "copy-failure" else b"metadata, ACL or xattr mismatch"
            if result.returncode == 0 or passed or expected not in result.stdout:
                raise RuntimeError(f"negative case did not fail as expected: {workspace / 'result.log'}")
        print(f"PASS: {case}; exit {result.returncode}", flush=True)
    generator = helper.with_name("generate-rootfs.sh").read_text()
    probe = generator.index('python3 "$PRESERVATION_CHECK"')
    capture = generator.index('rsync "${RSYNC_OPTIONS[@]}" / "$ROOTFS/"')
    if probe >= capture or 'RSYNC_OPTIONS+=(-A)' in generator or 'RSYNC_OPTIONS+=(-X)' in generator:
        raise RuntimeError("generator source integration check failed")
    print("PASS: generator source orders mandatory prerequisite before capture")
    print("PASS: preservation tests; full generator not executed")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(f"FAIL: {error}", file=sys.stderr)
        sys.exit(1)
