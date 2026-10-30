#!/usr/bin/env python3
"""Validate an isolated SableLinux kernel candidate before release staging."""

import argparse
import hashlib
import re
import sys
from pathlib import Path

ID_PATTERN = re.compile(r"[A-Za-z0-9][A-Za-z0-9._-]*")
SHA256_PATTERN = re.compile(r"([0-9a-f]{64})  (.+)")


def die(message):
    raise ValueError(message)


def metadata(path):
    if not path.is_file():
        die(f"missing metadata: {path}")

    result = {}
    for line in path.read_text().splitlines():
        if not line.strip():
            continue
        if "=" not in line:
            die(f"malformed metadata: {path}")
        key, value = line.split("=", 1)
        if key in result:
            die(f"duplicate metadata key: {key}")
        result[key] = value
    return result


def verify_manifest(base, manifest, expected_count):
    if not manifest.is_file():
        die(f"missing manifest: {manifest}")

    entries = manifest.read_text().splitlines()

    if not entries:
        die(f"empty SHA256 manifest: {manifest}")

    if expected_count is not None and len(entries) != expected_count:
        die(
            f"{manifest.name}: expected {expected_count} entries, "
            f"found {len(entries)}"
        )

    seen = set()

    for entry in entries:
        match = SHA256_PATTERN.fullmatch(entry)
        if not match:
            die(f"invalid SHA256 entry: {entry}")

        expected, name = match.groups()
        relative = Path(name)

        if (
            relative.is_absolute()
            or ".." in relative.parts
            or "." in relative.parts
            or name in seen
        ):
            die(f"unsafe or duplicate manifest path: {name}")

        seen.add(name)
        target = base / relative

        if not target.is_file() or target.is_symlink():
            die(f"missing or symlinked artifact: {target}")

        digest = hashlib.sha256()

        with target.open("rb") as stream:
            for block in iter(lambda: stream.read(1024 * 1024), b""):
                digest.update(block)

        if digest.hexdigest() != expected:
            die(f"SHA256 mismatch: {target}")

    return seen


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--candidate-id", required=True)
    parser.add_argument(
        "--workspace",
        default="/srv/sablelinux/kernel-builds",
    )
    args = parser.parse_args()

    if not ID_PATTERN.fullmatch(args.candidate_id):
        die("invalid candidate ID")

    candidate = Path(args.workspace) / args.candidate_id

    if not candidate.is_dir() or candidate.is_symlink():
        die(f"candidate directory unavailable: {candidate}")

    state = candidate / "BUILD_STATE"

    if not state.is_file() or state.read_text().strip() != "built":
        die("candidate must be in built state")

    build = metadata(candidate / "metadata/build.env")
    compilation = metadata(candidate / "metadata/compilation.env")

    if build.get("CANDIDATE_ID") != args.candidate_id:
        die("candidate identity mismatch")

    if build.get("CANONICAL_HOST") != "SableLinux":
        die("candidate was not prepared on canonical host")

    release = compilation.get("KERNEL_RELEASE", "")

    if not ID_PATTERN.fullmatch(release):
        die("invalid kernel release")

    artifacts = verify_manifest(
        candidate / "artifacts",
        candidate / "metadata/kernel-artifacts.sha256",
        3,
    )

    required = {
        f"config-{release}",
        f"System.map-{release}",
        f"vmlinuz-{release}",
    }

    if artifacts != required:
        die("kernel artifact names do not match release")

    modules = verify_manifest(
        candidate / "modules",
        candidate / "metadata/kernel-modules.sha256",
        None,
    )

    prefix = f"lib/modules/{release}/"

    if not all(name.startswith(prefix) for name in modules):
        die("module manifest references another kernel release")

    module_root = candidate / "modules" / "lib/modules" / release

    for filename in ("modules.dep", "modules.alias"):
        relative = f"lib/modules/{release}/{filename}"

        if relative not in modules:
            die(f"unverified module index: {filename}")

    actual_files = set()
    allowed_build_link = module_root / "build"
    expected_build_target = candidate / "obj"
    build_link_seen = False

    for entry in (candidate / "modules").rglob("*"):
        if entry.is_symlink():
            if entry != allowed_build_link:
                die(f"unexpected symlink in module tree: {entry}")

            if entry.readlink() != expected_build_target:
                die(f"unexpected kernel build-link target: {entry}")

            if not expected_build_target.is_dir():
                die("kernel build directory is missing")

            build_link_seen = True
            continue

        if entry.is_file():
            actual_files.add(
                entry.relative_to(candidate / "modules").as_posix()
            )

    if not build_link_seen:
        die("expected kernel build symlink is missing")

    if actual_files != modules:
        missing = sorted(actual_files - modules)
        unexpected = sorted(modules - actual_files)

        die(
            "module manifest coverage mismatch: "
            f"unlisted={missing}, absent={unexpected}"
        )

    print(f"PASS: Candidate identity: {args.candidate_id}")
    print(f"PASS: Kernel release: {release}")
    print(f"PASS: Kernel artifacts verified: {len(artifacts)}")
    print(f"PASS: Module files verified: {len(modules)}")
    print(f"PASS: Preparation commit: {build.get('GIT_COMMIT')}")
    print(f"PASS: Compilation commit: {compilation.get('BUILD_GIT_COMMIT')}")
    print("SABLE_KERNEL_CANDIDATE_PASS")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        sys.exit(1)
