# SableLinux Networking Capability Validation

Established: 2026-11-26

Status: Test specification; automated implementation pending.

## Purpose

Validate actual networking behavior rather than infer functionality
from installed packages or kernel configuration symbols.

Integrate executable tests with the existing capability framework
defined by configs/release/capabilities.yaml.

## Test Environment

- Canonical kernel and module artifacts produced on Z890.
- Disposable QEMU/KVM guests.
- Isolated virtual networks and controlled WireGuard relay.
- Disposable SSH and WireGuard credentials.
- No dependency on private production infrastructure.
- Retained serial logs, test results and artifact hashes.

## Test Matrix

| ID | Test | Acceptance criterion |
| --- | --- | --- |
| SSH-01 | Package availability | Required client and server binaries execute |
| SSH-02 | Release configuration | No private username, port or host-specific override |
| SSH-03 | Credential isolation | No inherited host keys, user keys or authorized client keys |
| SSH-04 | Service composition | Referenced SSH service units exist |
| SSH-05 | Initial service policy | Network SSH daemon disabled by default |
| SSH-06 | Host-key provisioning | Fresh target generates valid unique host keys |
| SSH-07 | Host-key persistence | Existing host identities survive reboot |
| SSH-08 | Key authentication | Authorized client successfully authenticates |
| SSH-09 | Unauthorized client | Unauthorized key rejected |
| SSH-10 | Authentication policy | Configured private key-only policy enforced |
| SSH-11 | Startup persistence | Enabled daemon starts after reboot |
| NET-01 | Kernel provenance | Exact running kernel configuration retained |
| NET-02 | Module integrity | Required module files match selected kernel |
| NET-03 | IPv4 policy routing | Alternate tables and policy rules operate |
| NET-04 | IPv6 policy routing | Alternate tables and policy rules operate |
| NET-05 | Netfilter comment | Required comment extension functions |
| NET-06 | Netfilter connection mark | CONNMARK operations function |
| NET-07 | Netfilter address type | Required addrtype matching functions |
| NET-08 | Netfilter packet mark | Required mark operations function |
| NET-09 | Netfilter tables | Required IPv4 and IPv6 tables operate |
| WG-01 | Credential isolation | No inherited private WireGuard material |
| WG-02 | Service isolation | No inherited enabled tunnel instances |
| WG-03 | Interface creation | WireGuard interface creates successfully |
| WG-04 | Split tunnel | Private subnet routes and handshake succeed |
| WG-05 | IPv4 full tunnel | Default routing and firewall setup succeed |
| WG-06 | Dual-stack activation | IPv4 and IPv6 policy setup succeeds |
| WG-07 | IPv4 forwarding | Controlled relay forwards IPv4 traffic |
| WG-08 | IPv6 forwarding | Controlled relay forwards IPv6 traffic where provisioned |
| WG-09 | DNS | Resolution follows the declared DNS policy |
| WG-10 | Peer forwarding | Only authorized peer traffic passes |
| WG-11 | VPN SSH | Authenticated SSH succeeds over tunnel |
| WG-12 | Teardown | Interface and generated rules removed |
| WG-13 | Failure cleanup | Failed activation leaves no unintended state |
| WG-14 | Repeated activation | Multiple activation/teardown cycles succeed |
| WG-15 | Reboot persistence | Configured tunnel starts and reconnects |
| WG-16 | IPv6 leak policy | Actual packet behavior matches declared policy |
| WG-17 | LAN access | Declared local-network access policy is preserved |

## Canonical Kernel Review

Audit these configuration symbols and their dependencies:

    CONFIG_IKCONFIG
    CONFIG_IKCONFIG_PROC
    CONFIG_IPV6
    CONFIG_IPV6_MULTIPLE_TABLES
    CONFIG_IP_MULTIPLE_TABLES
    CONFIG_FIB_RULES
    CONFIG_WIREGUARD
    CONFIG_NETFILTER
    CONFIG_NETFILTER_XTABLES
    CONFIG_NETFILTER_XT_MATCH_COMMENT
    CONFIG_NETFILTER_XT_MATCH_ADDRTYPE
    CONFIG_NETFILTER_XT_MARK
    CONFIG_NETFILTER_XT_CONNMARK
    CONFIG_NF_CONNTRACK
    CONFIG_IP_NF_IPTABLES
    CONFIG_IP_NF_RAW
    CONFIG_IP_NF_MANGLE
    CONFIG_IP_NF_FILTER
    CONFIG_IP6_NF_IPTABLES
    CONFIG_IP6_NF_RAW
    CONFIG_IP6_NF_MANGLE
    CONFIG_IP6_NF_FILTER

This is an audit checklist, not a prescribed kernel configuration.

Verify symbols against the exact Linux source version and installed
userspace implementation. Review all necessary dependencies.

Distinguish built-in support, installed loadable modules, unavailable
modules and actual runtime operation.

## Negative Regression Fixtures

Reproduce the following Beta 1 findings in disposable environments:

1. Missing SSH host-key generation service dependency.
2. Private SSH configuration inherited by release staging.
3. Historical administrative configuration backup included in release.
4. IPv6 policy-rule creation unavailable.
5. Missing Netfilter comment extension.
6. Missing Netfilter connection-mark extension.
7. Kernel configuration unavailable to runtime diagnostics.
8. Failed full-tunnel activation and incomplete rollback detection.
9. Unauthorized peer-to-peer forwarding.
10. Interface-specific IPv6 settings inconsistent after reboot.

Each fixture must have an explicit expected result and fail if the
validation mechanism does not detect the defect.

## Validation Order

1. Inspect canonical kernel configuration and module manifest.
2. Validate kernel runtime functionality in disposable QEMU guests.
3. Exercise generated live userspace and networking tools.
4. Exercise OVMF/GRUB boot.
5. Validate installation into disposable qcow2 targets.
6. Validate installed-system first boot.
7. Validate provisioned services and reboot persistence.
8. Repeat relevant tests on physical hardware.

Use the same candidate artifact set throughout the applicable gates.

## Evidence Requirements

Record:

- Git revision.
- Kernel release and configuration hash.
- Kernel and module artifact hashes.
- Userspace package versions.
- Test script revision.
- Guest or hardware profile.
- Test timestamp.
- Expected and observed result.
- Exit status and relevant diagnostic output.
- PASS, FAIL, BLOCKED or NOT RUN classification.

Never publish private test credentials or production VPN
configuration in evidence bundles.

## Initial Evidence

The HP Pavilion Beta 1 installation passed SSH and administrative
WireGuard split-tunnel reboot validation on 2026-11-26.

IPv6 policy routing and IPv4 full-tunnel WireGuard activation failed.
The installed kernel lacked accessible xt_comment and xt_connmark
support.

See docs/journal/2026-11-26.md.

These physical observations are regression inputs, not evidence that
the proposed automated test suite has been implemented or passed.
