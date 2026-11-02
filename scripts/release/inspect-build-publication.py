#!/usr/bin/env python3
"""Read-only classification of SableLinux build publication state."""

import argparse
import json
import re
import sys
from pathlib import Path


IDENTIFIER = re.compile(r"[A-Za-z0-9._-]+")
STATES = {"initializing", "initialized"}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def read_single_line(path):
    require(
        path.is_file() and not path.is_symlink(),
        f"invalid state file: {path}",
    )
    lines = path.read_text().splitlines()
    require(len(lines) == 1, f"invalid state contents: {path}")
    return lines[0]


def read_metadata(path):
    require(
        path.is_file() and not path.is_symlink(),
        "invalid build metadata",
    )

    values = {}

    for line in path.read_text().splitlines():
        require("=" in line, "malformed build metadata")
        key, value = line.split("=", 1)
        require(
            key and key not in values,
            "invalid or duplicate metadata key",
        )
        values[key] = value

    return values


def inspect(build_root, state_dir):
    require(
        build_root.is_dir() and not build_root.is_symlink(),
        "invalid build directory",
    )
    require(
        state_dir.is_dir() and not state_dir.is_symlink(),
        "invalid state directory",
    )

    build_id = build_root.name

    require(
        IDENTIFIER.fullmatch(build_id) is not None,
        "invalid build ID",
    )

    marker = read_single_line(build_root / "BUILD_STATE")
    metadata = read_metadata(
        build_root / "metadata" / "build.env"
    )

    require(
        metadata.get("BUILD_ID") == build_id,
        "build identity mismatch",
    )

    metadata_state = metadata.get("BUILD_STATE")

    require(marker in STATES, "invalid completion marker")
    require(
        metadata_state in STATES,
        "invalid metadata state",
    )

    pointer_path = state_dir / "current-build-id"

    require(
        not pointer_path.is_symlink(),
        "current-build pointer is a symlink",
    )

    current_build = None

    if pointer_path.exists():
        current_build = read_single_line(pointer_path)
        require(
            IDENTIFIER.fullmatch(current_build) is not None,
            "invalid current-build pointer",
        )

    selected = current_build == build_id

    if marker == "initializing":
        require(
            not selected,
            "incomplete build selected as current",
        )

        if metadata_state == "initializing":
            classification = "initializing"
        else:
            classification = "interrupted"

    else:
        require(
            metadata_state == "initialized",
            "completion marker contradicts metadata",
        )

        classification = (
            "initialized-selected"
            if selected
            else "initialized-unselected"
        )

    return {
        "build_id": build_id,
        "classification": classification,
        "metadata_state": metadata_state,
        "completion_marker": marker,
        "current_build_id": current_build,
        "selected": selected,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--build-root",
        type=Path,
        required=True,
    )
    parser.add_argument(
        "--state-dir",
        type=Path,
        required=True,
    )
    args = parser.parse_args()

    result = inspect(args.build_root, args.state_dir)
    print(json.dumps(result, indent=2, sort_keys=True))


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        sys.exit(1)
