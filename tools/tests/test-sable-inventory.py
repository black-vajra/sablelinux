#!/usr/bin/env python3
"""Isolated CLI checks: fake probes, real Bash/timeout/awk/tee; no host audit."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


SOURCE = Path(__file__).resolve().parents[1] / "sable-inventory.sh"
PROBES = "date hostname id uname cat findmnt lsblk df free nproc lscpu lspci lsusb find sway waybar pgrep wpctl ip resolvectl git sha256sum journalctl".split()
STUB = r'''#!/usr/bin/env python3
import json, os, signal, sys, time
from pathlib import Path
name = Path(sys.argv[0]).name
with open(os.environ['PROBE_LOG'], 'a') as f:
    f.write(json.dumps([name, *sys.argv[1:]]) + '\n')
mode = os.environ.get('PROBE_MODE', '')
if name == 'pgrep':
    sys.exit(1)
if mode == 'failure' and name == 'wpctl':
    print('fixture audio access failure', file=sys.stderr)
    sys.exit(23)
if mode == 'timeout' and name == 'lsusb':
    print('fixture USB probe ignores TERM', flush=True)
    signal.signal(signal.SIGTERM, signal.SIG_IGN)
    time.sleep(60)
if name == 'find':
    print('x' * 2100)
    for i in range(300):
        print('fixture entry', i)
else:
    print('fixture:', name, *sys.argv[1:])
'''


def main():
    for tool in ("bash", "timeout", "awk", "tee", "python3"):
        if shutil.which(tool) is None:
            raise SystemExit(f"Required test tool unavailable: {tool}")
    import json
    with tempfile.TemporaryDirectory(prefix="sable-inventory-test-") as directory:
        root = Path(directory)
        tools = root / "repo" / "tools"
        tools.mkdir(parents=True)
        script = tools / SOURCE.name
        shutil.copyfile(SOURCE, script)
        bin_dir = root / "bin"
        bin_dir.mkdir()
        for name in PROBES:
            path = bin_dir / name
            path.write_text(STUB)
            path.chmod(0o755)
        log = root / "probes.jsonl"
        env = dict(os.environ, PATH=f"{bin_dir}:{os.environ['PATH']}",
                   PROBE_LOG=str(log))

        def invoke(report, mode=""):
            return subprocess.run(["bash", str(script), str(report)], cwd=root,
                                  env=dict(env, PROBE_MODE=mode),
                                  capture_output=True, text=True, timeout=45)

        report = root / "report with spaces.txt"
        result = invoke(report)
        assert result.returncode == 0, result.stderr + result.stdout
        text = report.read_text()
        assert "PROBES COMPLETED" in text and "incomplete probes: 0" in text
        assert "EXPECTED STATUS" in text and "OUTPUT LIMITED" in text
        assert "additional lines omitted" in text and "lines shortened" in text
        assert report.stat().st_mode & 0o777 == 0o600
        calls = [json.loads(line) for line in log.read_text().splitlines()]
        finds = [call for call in calls if call[0] == "find"]
        assert finds == [
            ["find", "-H", "/boot", "-maxdepth", "1", "-printf", "%y %TY-%Tm-%Td %TH:%TM %s %p -> %l\\n"],
            ["find", "-H", "/lib/firmware", "/usr/lib/firmware", "-maxdepth", "1", "-printf", "%y %p -> %l\\n"],
        ], finds
        assert not any(call[0] == "du" for call in calls)
        assert any(call[0] == "git" and call[1:3] == ["-C", str(root / "repo")]
                   for call in calls)
        print("PASS: bounded probes, truncation notices, expected no-process status, private report, script-relative repo")

        original = report.read_bytes()
        assert invoke(report).returncode == 2
        assert report.read_bytes() == original
        link = root / "symlink-report"
        link.symlink_to(report)
        assert invoke(link).returncode == 2
        assert report.read_bytes() == original
        assert invoke(root / "missing" / "report").returncode == 2
        print("PASS: existing report and symlink protected; output setup errors rejected")

        report = root / "failed.txt"
        result = invoke(report, "failure")
        text = report.read_text()
        assert result.returncode == 1
        assert "fixture audio access failure" in text and "command exit: 23" in text
        assert "incomplete probes: 1" in text and "Recent boot warnings" in text
        print("PASS: failed probe retains diagnostics, continues and returns incomplete")

        report = root / "timeout.txt"
        result = invoke(report, "timeout")
        text = report.read_text()
        assert result.returncode == 1
        assert "timeout/termination" in text and "incomplete probes: 1" in text
        assert "Recent boot warnings" in text
        print("PASS: real timeout kills TERM-ignoring probe; later probes continue")

        # Isolate setup PATH to verify missing timeout never runs unbounded probes.
        setup_bin = root / "setup-bin"
        setup_bin.mkdir()
        for name in ("awk", "tee"):
            (setup_bin / name).symlink_to(shutil.which(name))
        report = root / "no-timeout.txt"
        result = subprocess.run([shutil.which("bash"), str(script), str(report)],
                                env=dict(env, PATH=str(setup_bin)),
                                capture_output=True, text=True, timeout=5)
        assert result.returncode == 2 and not report.exists()
        assert "no unbounded fallback" in result.stderr
        print("PASS: missing timeout fails setup without creating a report")


if __name__ == "__main__":
    main()
