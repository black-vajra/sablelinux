#!/usr/bin/env python3
"""Reject unqualified image metadata before SquashFS generation; read-only scan."""
import argparse
from collections import Counter
import json
import os
from pathlib import Path
import re
import stat
import sys


def mounted_paths():
    def decode(value):
        return re.sub(r"\\([0-7]{3})", lambda m: chr(int(m[1], 8)), value)
    return [Path(decode(line.split()[4])) for line in
            Path('/proc/self/mountinfo').read_text().splitlines()]


def scan(root, config):
    if root.is_symlink() or root.resolve(strict=True) != root or not root.is_dir():
        raise ValueError('root must be an absolute directory without symlink components')
    for mount in mounted_paths():
        if mount == root or root in mount.parents:
            raise ValueError(f'mount at or beneath root: {mount}')
    settings = config.read_text().splitlines()
    enabled = 'CONFIG_SQUASHFS_XATTR=y' in settings
    counts = Counter()
    records = []
    problems = []
    pending = [root]
    device = root.stat().st_dev
    scanned = 0
    while pending:
        path = pending.pop()
        info = path.lstat()
        if info.st_dev != device:
            raise ValueError(f'filesystem boundary: {path}')
        scanned += 1
        # Never follow symlinks, and never treat unreadable metadata as absent.
        attrs = {name: os.getxattr(path, name, follow_symlinks=False).hex()
                 for name in sorted(os.listxattr(path, follow_symlinks=False))}
        if attrs:
            relative = str(path.relative_to(root))
            records.append({'path': relative, 'attributes': attrs})
            counts.update(attrs.keys())
            for name in attrs:
                # Only namespaces qualified by the canonical fixture are allowed.
                # ACL/system, trusted and unknown namespaces require separate design
                # or qualification, rather than silent omission by the builder.
                if not name.startswith(('user.', 'security.')):
                    problems.append(f'{relative}: unqualified attribute {name}')
        if stat.S_ISDIR(info.st_mode):
            with os.scandir(path) as entries:
                pending.extend(sorted((Path(e.path) for e in entries), reverse=True))
    if counts and not enabled:
        problems.append('selected kernel lacks CONFIG_SQUASHFS_XATTR=y')
    return {'entries_scanned': scanned, 'attribute_counts': dict(sorted(counts.items())),
            'kernel_squashfs_xattr': enabled, 'records': records, 'problems': problems,
            'scan_complete': True, 'passed': not problems}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', required=True, type=Path)
    parser.add_argument('--kernel-config', required=True, type=Path)
    parser.add_argument('--report', required=True, type=Path)
    args = parser.parse_args()
    root = args.root.absolute()
    report = args.report.absolute()
    if report.resolve() == root.resolve() or root.resolve() in report.resolve().parents:
        raise ValueError('report must be outside the inspected root')
    result = {'root': str(root), 'kernel_config': str(args.kernel_config),
              'scan_complete': False, 'passed': False}
    # Refuse to overwrite an earlier result; retain diagnostic evidence on failure.
    with report.open('x') as output:
        try:
            if os.geteuid() != 0:
                raise PermissionError('root required for complete metadata inspection')
            result.update(scan(root, args.kernel_config))
        except Exception as error:
            result['error'] = f'{type(error).__name__}: {error}'
        json.dump(result, output, indent=2, sort_keys=True)
        output.write('\n')
    print(('PASS' if result['passed'] else 'FAIL') + ': SquashFS metadata preflight')
    print('Report:', report)
    if not result['passed']:
        for problem in result.get('problems', []):
            print(problem)
        if 'error' in result:
            print(result['error'])
        return 1
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except Exception as error:
        print(f'FAIL: SquashFS metadata preflight: {error}', file=sys.stderr)
        sys.exit(1)
