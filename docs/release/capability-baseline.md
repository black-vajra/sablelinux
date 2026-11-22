# SableLinux Capability Baseline

Established: 2026-11-22
Canonical build authority: Z890 SableLinux
Target release: SableLinux 1.0 Beta 1

## Authoritative manifest

configs/release/capabilities.yaml

The manifest defines required system capabilities and their
acceptance-test obligations. It does not assert that the current
installation or generated release satisfies those requirements.

## Capability profiles

- core: required for standard installations
- desktop: required for graphical installations
- hardware: required when supported hardware is detected
- optional: independently provisioned capabilities
- canonical: required on the authoritative Z890 build host

## Validation states

A capability must be distinguished as:

1. Required by the capability contract
2. Provisioned in the target system
3. Functionally tested
4. Validated against release acceptance criteria

A configured package or enabled kernel option does not establish
operational functionality.

## Release acceptance

Required capabilities must be validated in the generated release
and again following installation and reboot.

Hardware-specific capabilities must be validated on applicable
test hardware.

Optional components must not silently become mandatory dependencies.

## Security requirements

The distributed release must not contain personal home data,
private SSH or WireGuard keys, browser profiles, API credentials,
personal AI configuration, or unapproved model data.

Host-specific credentials must be provisioned independently
after installation.

## Local AI and multimedia

The release must distinguish baseline multimedia functionality
from optional codecs and hardware-specific acceleration.

Local inference runtimes, model files, ROCm, GPU compute backends,
and AI automation require explicit provisioning and validation
policies.

A functioning AI stack on the canonical host does not establish
that the same functionality exists in the generated release.

## Canonical KVM baseline

The Z890 build host must provide:

- Intel virtualization support
- Functional KVM kernel support
- /dev/kvm with appropriate permissions
- Authorized build-user membership in the kvm group
- Working QEMU/KVM acceleration
- OVMF for Tier 2 validation

Observed 2026-11-22:

- /dev/kvm exists, owned by root:kvm
- sable added to the kvm group
- Read/write device access confirmed using sg kvm
- modprobe kvm_intel exited successfully
- lsmod did not list KVM modules
- Functional QEMU/KVM execution remains unverified

These host provisioning requirements must eventually be enforced
by automated capability audits, not undocumented manual setup.

## Release engineering requirement

Every declared capability must eventually map to:

- Provisioning mechanism
- Executable acceptance test
- Evidence location
- Applicable hardware or installation profile
- Release qualification result

BUILDLOG.md and prior successful installations are historical
evidence, not proof of current functionality.
