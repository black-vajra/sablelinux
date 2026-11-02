#!/usr/bin/env python3
"""Verify release metadata against a canonical kernel candidate."""

import argparse
import re
import subprocess
import sys
from pathlib import Path


RELEASE_DIR = Path(__file__).resolve().parent
CANDIDATE_VERIFIER = RELEASE_DIR / "verify-kernel-candidate.py"
DEFAULT_WORKSPACE = Path("/srv/sablelinux/kernel-builds")
IDENTIFIER = re.compile(r"[A-Za-z0-9._-]+")
COMMIT = re.compile(r"[0-9a-f]{40}")


def require(condition, message):
    if not condition:
        raise ValueError(message)


def read_metadata(path):
    require(
        path.is_file() and not path.is_symlink(),
        f"invalid metadata file: {path}",
    )

    result = {}

    for line in path.read_text().splitlines():
        if not line or line.startswith("#"):
            continue

        require("=" in line, f"malformed metadata: {path}")
        key, value = line.split("=", 1)
        require(key not in result, f"duplicate metadata key: {key}")
        require(
            re.fullmatch(r"[A-Z][A-Z0-9_]*", key) is not None,
            f"invalid metadata key: {key}",
        )
        result[key] = value

    return result


def verify(build_root, workspace=DEFAULT_WORKSPACE):
    require(
        build_root.is_dir() and not build_root.is_symlink(),
        "invalid release build root",
    )
    require(
        workspace.is_dir() and not workspace.is_symlink(),
        "invalid candidate workspace",
    )

    release = read_metadata(build_root / "metadata/build.env")

    candidate_id = release.get("KERNEL_CANDIDATE_ID", "")
    kernel_release = release.get("KERNEL_RELEASE", "")

    require(
        IDENTIFIER.fullmatch(candidate_id) is not None,
        "invalid candidate ID",
    )
    require(
        IDENTIFIER.fullmatch(kernel_release) is not None,
        "invalid kernel release",
    )

    candidate = workspace / candidate_id

    require(
        candidate.is_dir() and not candidate.is_symlink(),
        "selected kernel candidate unavailable",
    )

    preparation = release.get("KERNEL_PREPARATION_COMMIT", "")
    compilation = release.get("KERNEL_BUILD_COMMIT", "")

    require(
        COMMIT.fullmatch(preparation) is not None,
        "invalid preparation commit",
    )
    require(
        COMMIT.fullmatch(compilation) is not None,
        "invalid compilation commit",
    )

    # Verify the actual source candidate BEFORE trusting its metadata.
    result = subprocess.run(
        [
            sys.executable,
            "-B",
            str(CANDIDATE_VERIFIER),
            "--candidate-id",
            candidate_id,
            "--workspace",
            str(workspace),
        ],
        capture_output=True,
        text=True,
        check=False,
    )

    require(
        result.returncode == 0
        and "SABLE_KERNEL_CANDIDATE_PASS" in result.stdout.splitlines(),
        "kernel candidate verification failed: "
        + (result.stderr.strip() or result.stdout.strip()),
    )

    source_build = read_metadata(
        candidate / "metadata/build.env"
    )
    source_compilation = read_metadata(
        candidate / "metadata/compilation.env"
    )

    require(
        source_build.get("CANDIDATE_ID") == candidate_id,
        "candidate identity mismatch",
    )
    require(
        source_build.get("CANONICAL_HOST") == "SableLinux",
        "noncanonical kernel candidate",
    )
    require(
        source_compilation.get("KERNEL_RELEASE") == kernel_release,
        "kernel release mismatch",
    )
    require(
        source_build.get("GIT_COMMIT") == preparation,
        "preparation commit mismatch",
    )
    require(
        source_compilation.get("BUILD_GIT_COMMIT") == compilation,
        "compilation commit mismatch",
    )

    source_manifest = candidate / "metadata/kernel-modules.sha256"
    release_manifest = (
        build_root / "metadata/candidate-kernel-modules.sha256"
    )

    for manifest in (source_manifest, release_manifest):
        require(
            manifest.is_file() and not manifest.is_symlink(),
            f"invalid module manifest: {manifest}",
        )

    require(
        source_manifest.read_bytes() == release_manifest.read_bytes(),
        "release module manifest differs from verified candidate",
    )

    print(f"PASS: Candidate identity: {candidate_id}")
    print(f"PASS: Kernel release: {kernel_release}")
    print("PASS: Preparation commit matches")
    print("PASS: Compilation commit matches")
    print("PASS: Verified module manifest matches")
    print("SABLE_RELEASE_KERNEL_PROVENANCE_PASS")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build-root", required=True)
    parser.add_argument(
        "--workspace",
        default=str(DEFAULT_WORKSPACE),
    )
    args = parser.parse_args()

    verify(Path(args.build_root), Path(args.workspace))


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        sys.exit(1)
