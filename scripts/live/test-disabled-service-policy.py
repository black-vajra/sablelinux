#!/usr/bin/env python3
"""Regression tests for release disabled-service sanitization."""

import importlib.util
import tempfile
import unittest
from pathlib import Path

script = Path(__file__).with_name("disabled-service-policy.py")
spec = importlib.util.spec_from_file_location("service_policy", script)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class ServicePolicyTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        root = Path(temporary.name)
        self.units = root / "etc/systemd/system"
        self.wants = self.units / "multi-user.target.wants"
        self.wants.mkdir(parents=True)
        self.policy = root / "policy"
        self.policy.write_text(
            "sshd.service\nwg-quick@*.service\n"
        )
        self.root = root


    def test_actual_release_policy(self):
        repository_policy = (
            Path(__file__).resolve().parents[2]
            / "configs/live/disabled-services.list"
        )

        instance = self.wants / "wg-quick@wg-z890.service"
        instance.symlink_to(
            "/usr/lib/systemd/system/wg-quick@.service"
        )

        template = self.units / "wg-quick@.service"
        template.write_text("[Unit]\nDescription=WireGuard\n")

        with self.assertRaisesRegex(ValueError, "prohibited"):
            module.process(
                "validate", self.root, repository_policy
            )

        module.process(
            "sanitize", self.root, repository_policy
        )
        module.process(
            "validate", self.root, repository_policy
        )

        self.assertFalse(instance.is_symlink())
        self.assertTrue(template.is_file())

    def test_named_wireguard_instance_removed(self):
        link = self.wants / "wg-quick@wg-z890.service"
        link.symlink_to("/usr/lib/systemd/system/wg-quick@.service")
        with self.assertRaisesRegex(ValueError, "prohibited"):
            module.process("validate", self.root, self.policy)
        module.process("sanitize", self.root, self.policy)
        self.assertFalse(link.is_symlink())
        module.process("validate", self.root, self.policy)

    def test_other_named_wireguard_instance_removed(self):
        link = self.wants / "wg-quick@private-site.service"
        link.symlink_to("/usr/lib/systemd/system/wg-quick@.service")
        module.process("sanitize", self.root, self.policy)
        self.assertFalse(link.is_symlink())

    def test_generic_template_and_unrelated_units_preserved(self):
        template = self.units / "wg-quick@.service"
        template.write_text("[Unit]\\nDescription=WireGuard\\n")
        unrelated = self.wants / "systemd-networkd.service"
        unrelated.symlink_to(
            "/usr/lib/systemd/system/systemd-networkd.service"
        )
        module.process("sanitize", self.root, self.policy)
        self.assertTrue(template.is_file())
        self.assertTrue(unrelated.is_symlink())

    def test_existing_disabled_service_removed(self):
        link = self.wants / "sshd.service"
        link.symlink_to("/usr/lib/systemd/system/sshd.service")
        module.process("sanitize", self.root, self.policy)
        self.assertFalse(link.is_symlink())

    def test_regular_wireguard_instance_fails_closed(self):
        unit = self.units / "wg-quick@private-site.service"
        unit.write_text("[Unit]\\n")
        with self.assertRaisesRegex(ValueError, "prohibited"):
            module.process("sanitize", self.root, self.policy)
        self.assertTrue(unit.exists())


if __name__ == "__main__":
    unittest.main(verbosity=2)
