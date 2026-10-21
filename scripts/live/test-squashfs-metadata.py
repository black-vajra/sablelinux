#!/usr/bin/env python3
"""Real metadata fixtures plus deliberately injected read errors; no image builds."""
import argparse
import importlib.util
import json
import os
from pathlib import Path
import struct
import subprocess
import sys
import tempfile
from unittest.mock import patch

sys.dont_write_bytecode = True
helper = Path(__file__).resolve().with_name('check-squashfs-metadata.py')
spec = importlib.util.spec_from_file_location('metadata_gate', helper)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--simulate-capability', action='store_true',
                        help='review environments without CAP_SETFCAP; not canonical acceptance')
    args = parser.parse_args()
    require(os.geteuid() == 0, 'run tests through sudo')
    with tempfile.TemporaryDirectory(prefix='sable-squashfs-gate-') as temporary:
        base = Path(temporary).resolve()
        root = base / 'root'
        root.mkdir()
        config = base / 'config'
        config.write_text('CONFIG_SQUASHFS_XATTR=y\n')
        target = root / 'file'
        target.write_text('metadata fixture\n')
        counter = 0

        def invoke(label, passed, fragment=None):
            nonlocal counter
            counter += 1
            report = base / f'report-{counter}.json'
            result = subprocess.run([sys.executable, str(helper), '--root', str(root),
                '--kernel-config', str(config), '--report', str(report)],
                stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=20)
            data = json.loads(report.read_text())
            require((result.returncode == 0) == passed and data['passed'] == passed,
                    f'{label}: {result.stdout.decode()}')
            if fragment:
                require(fragment in json.dumps(data), f'{label}: expected {fragment}')
            print('PASS:', label, flush=True)
            return data

        invoke('plain root', True)
        os.setxattr(target, 'user.sable_test', b'preserved')
        invoke('user xattr with selected kernel support', True)
        config.write_text('# CONFIG_SQUASHFS_XATTR is not set\n')
        invoke('reject user xattr with kernel support disabled', False,
               'selected kernel lacks')
        config.write_text('CONFIG_SQUASHFS_XATTR=y\n')
        os.removexattr(target, 'user.sable_test')
        capability = bytes.fromhex('0100000200040000000000000000000000000000')
        if args.simulate_capability:
            list_attrs, get_attr = os.listxattr, os.getxattr
            def simulated_list(path, **kwargs):
                return ['security.capability'] if path == target else list_attrs(path, **kwargs)
            def simulated_get(path, name, **kwargs):
                return capability if path == target and name == 'security.capability' else get_attr(path, name, **kwargs)
            with patch.object(module.os, 'listxattr', side_effect=simulated_list), \
                 patch.object(module.os, 'getxattr', side_effect=simulated_get):
                data = module.scan(root, config)
            require(data['passed'] and data['attribute_counts'] == {'security.capability': 1},
                    'simulated capability was not inventoried')
            require(data['records'][0]['attributes']['security.capability'] == capability.hex(),
                    'simulated capability bytes differ')
            print('PASS: simulated capability inventory; real capability NOT TESTED')
        else:
            os.setxattr(target, 'security.capability', capability)
            data = invoke('file capability inventoried', True, 'security.capability')
            require(data['attribute_counts'] == {'security.capability': 1},
                    'capability count differs')
            require(data['records'][0]['attributes']['security.capability'] == capability.hex(),
                    'capability bytes differ')
            config.write_text('# CONFIG_SQUASHFS_XATTR is not set\n')
            invoke('reject capability with kernel support disabled', False, 'selected kernel lacks')
            config.write_text('CONFIG_SQUASHFS_XATTR=y\n')
            os.removexattr(target, 'security.capability')

        # Linux POSIX ACL xattr: owner, named user, group, mask, other.
        acl = struct.pack('<I', 2) + b''.join(struct.pack('<HHI', *entry) for entry in (
            (1, 6, 0xffffffff), (2, 4, 0 if args.simulate_capability else 12345), (4, 0, 0xffffffff),
            (16, 4, 0xffffffff), (32, 0, 0xffffffff)))
        os.setxattr(target, 'system.posix_acl_access', acl)
        invoke('reject actual access ACL', False, 'system.posix_acl_access')
        os.removexattr(target, 'system.posix_acl_access')
        folder = root / 'folder'
        folder.mkdir()
        os.setxattr(folder, 'system.posix_acl_default', acl)
        invoke('reject actual default ACL', False, 'system.posix_acl_default')
        os.removexattr(folder, 'system.posix_acl_default')

        outside = base / 'outside'
        outside.write_text('external fixture\n')
        os.setxattr(outside, 'system.posix_acl_access', acl)
        (root / 'external-link').symlink_to(outside)
        invoke('do not follow symlinks outside root', True)
        with patch.object(module.os, 'listxattr', side_effect=OSError('injected read failure')):
            try:
                module.scan(root, config)
            except OSError:
                pass
            else:
                raise RuntimeError('metadata read failure was ignored')
        print('PASS: metadata read failure propagates')
        with patch.object(module, 'mounted_paths', return_value=[root / 'nested-mount']):
            try:
                module.scan(root, config)
            except ValueError:
                pass
            else:
                raise RuntimeError('nested mount was accepted')
        print('PASS: nested mount rejected')
        config.unlink()
        invoke('missing selected kernel configuration fails closed', False, 'FileNotFoundError')
    print('PASS: all metadata gate tests; full canonical builder not executed')


if __name__ == '__main__':
    main()
