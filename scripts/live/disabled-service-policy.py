#!/usr/bin/env python3
"""Sanitize and validate enabled services in a staged live rootfs."""

import fnmatch
import os
import sys
from pathlib import Path


def process(action, root, policy):
    units = root / "etc/systemd/system"
    if units.is_symlink() or not units.is_dir():
        raise ValueError("unsafe systemd configuration directory")

    rules = [
        line.strip()
        for line in policy.read_text().splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    ]
    if not rules or len(rules) != len(set(rules)):
        raise ValueError("empty or duplicate disabled-service policy")

    def prohibited(path):
        target = os.readlink(path) if path.is_symlink() else ""
        for rule in rules:
            if "*" in rule:
                # WireGuard requires a nonempty instance name.
                # Preserve the generic wg-quick@.service template.
                if (
                    rule == "wg-quick@*.service"
                    and path.name == "wg-quick@.service"
                ):
                    continue
                if fnmatch.fnmatchcase(path.name, rule):
                    return True
            elif path.is_symlink() and target.endswith(rule):
                return True
        return False

    violations = []
    for directory, dirs, files in os.walk(units, followlinks=False):
        for name in files + dirs:
            path = Path(directory) / name
            if not prohibited(path):
                continue
            if action == "sanitize" and path.is_symlink():
                path.unlink()
            else:
                violations.append(str(path))
        dirs[:] = [
            name for name in dirs
            if not (Path(directory) / name).is_symlink()
        ]

    if violations:
        raise ValueError(
            "prohibited service remains: " + ", ".join(violations)
        )

    print("PASS: disabled-service policy " + action)


if __name__ == "__main__":
    try:
        if len(sys.argv) != 4 or sys.argv[1] not in (
            "sanitize", "validate"
        ):
            raise ValueError(
                "usage: disabled-service-policy.py "
                "sanitize|validate ROOTFS POLICY"
            )
        process(sys.argv[1], Path(sys.argv[2]), Path(sys.argv[3]))
    except (OSError, ValueError) as error:
        print("FAIL: " + str(error), file=sys.stderr)
        sys.exit(1)
