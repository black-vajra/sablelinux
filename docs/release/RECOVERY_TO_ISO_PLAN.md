# SableLinux Release Engineering Plan

Updated October 7, 2026. Target release: December 31, 2026.
Current audited status: ../ENGINEERING_STATE.md.

## Objective and authority

Produce a documented, idempotent, reproducible ISO with live boot, a validated
non-LUKS installer and independent installed boot. Architecture and live boot are
already demonstrated; this is release engineering, not another proof of concept.

The running Z890 SableLinux installation alone supplies package selections,
versions, toolchain, kernels, rootfs, initramfs, SquashFS, installer and release
inputs. Other machines and VMs validate outputs. Import successful procedures
into the canonical repository; never import secondary-system binaries as inputs.

Maintain source in /home/pepper/sablelinux and generated state beneath
/srv/sablelinux using the established canonical-artifact-layout.md and
build-directory-lifecycle.md. Preserve physical installations, historical builds
and Git history. Do not manually rewrite staging trees.

## Engineering method

Understand -> verify -> document -> automate -> test -> commit.
Investigate before modifying. Make one bounded change at a time, retain evidence,
and document successful outcomes immediately. BUILDLOG.md is historical evidence;
current system inventory and maintained repository documents govern decisions.

## Package audit and upgrade cycle

Complete a general package audit and planned upgrade cycle before freezing the
release inputs. A source-directory name or old build log is not proof of the
installed version. Inspect tools/sable-inventory.sh before executing it.

1. Establish current versions and executable/library paths, package activation
   records, provenance, duplicate installations and unknown ownership. Record
   confidence and gaps rather than fabricating a complete package database.
2. Capture a pre-upgrade functionality baseline and verify backup/recovery
   coverage for affected files, configuration and service state.
3. Compare installed versions with official upstream releases, support status,
   security notices and compatibility requirements. Record retrieval dates.
4. Select dependency-aware upgrades, with special treatment for the toolchain,
   libc, PAM, systemd, kernel, graphics and other broad-impact components. A
   general upgrade cycle does not mean an indiscriminate latest-version rebuild.
5. Build from declared, verified canonical sources into isolated staged roots.
   Retain manifests, hashes, build options, tool versions and logs. Review the
   existing scripts/packages framework before extending it.
6. Validate in disposable environments before canonical activation. Verify
   collisions, dependency compatibility and recovery procedures. Activate one
   investigated package or coherent dependency group at a time.
7. Run affected checks after each change, then the full agreed functionality
   suite after the upgrade cycle. Commit recipes and results. Freeze versions
   and input content only after acceptance.

Functionality coverage must include installed boot/shutdown, authentication and
sudo, Sway/Waybar/terminal, graphics, audio/PipeWire, browser, DNS/network/TLS,
relevant WiFi hardware, storage and mounted boot filesystems, compilation/build
tools, QEMU/KVM and live-generation tools. Verify installed BOINC/CVMFS and local
AI where affected, while keeping optional workloads off the ISO critical path.
Record pass/fail/untested per check; service activity alone is not acceptance.

## Canonical release pipeline

Frozen canonical inputs -> approved package updates -> kernel -> staging root ->
SquashFS -> live initramfs -> live media/ISO -> validation -> release.

Current script interfaces inspected at c036dcf:

| Stage | Interface | Required input state |
| --- | --- | --- |
| Build initialization | sudo scripts/release/create-build.sh | Canonical host, clean development checkout; creates a new build |
| Rootfs | sudo scripts/live/generate-rootfs.sh --build-id BUILD_ID --dry-run or --execute | initialized; empty rootfs |
| SquashFS | sudo scripts/live/build-squashfs.sh --build-id BUILD_ID | rootfs-generated |
| Live initramfs stage | sudo scripts/live/build-live-initramfs-stage.sh --build-id BUILD_ID | squashfs-generated |
| ext4 Tier 1 media | sudo scripts/live/build-test-media.sh --build-id BUILD_ID | initramfs-generated |

This table documents inspected interfaces; it is not an instruction to execute
stages now. Each stage requires matching Git provenance and a clean worktree.
Existing stage guards do not establish rerun acceptance. Build initialization
currently records the running kernel and still lacks a current package manifest.
Verify exact kernel configuration and required built-in live-boot drivers.

Review and reconcile installer candidates before injecting an authoritative
installer. Rootfs generation currently does not inject one. Review installed
runtime state and service policies before capture, including CVMFS cache and
BOINC. Keep /opt/models excluded and llama-server disabled in live media under
the existing policy unless an explicit documented decision changes it.

## Validation hierarchy

Validate the same candidate artifact set in this order; never diagnose a higher
tier before its lower tier passes. Regenerate and repeat affected gates after
input changes. Protect physical installations throughout.

| Tier | Required evidence |
| --- | --- |
| 1: direct QEMU/KVM kernel boot | Matching kernel/initramfs/media; media discovery, SquashFS, tmpfs overlay, switch_root, userspace and shutdown; retained serial logs and unambiguous result |
| 2: generated media through OVMF/GRUB | EFI path, bootloader handoff and live startup; actual ISO discovery support rather than assuming the ext4-only test path works |
| 3: disposable qcow2 installation | Explicit disposable target, partition/deploy/bootloader; independent boot with live media removed; desktop/network/audio and documented upgrade/reinstall checks |
| 4: physical hardware | Candidate live-media and compatibility checks after VM passes; agree supported targets and record device results |

Retain non-LUKS installation as baseline. LUKS, Secure Boot and legacy BIOS support
remain outside acceptance unless scope is explicitly revised. Historical target
suggestions include Z890, EliteBook, Pavilion and ASUS; confirm which hardware is
available and supported before promising coverage.

## Idempotence and reproducibility acceptance

Idempotence and byte reproducibility are separate gates.

- Same-workspace reruns must not accumulate edits, duplicate configuration or
  accept stale inputs. Verified reuse or safe regeneration must have documented
  semantics. Failed stages must never be promoted as successful.
- Two fresh builds from identical frozen canonical inputs must match manifests
  and artifact hashes. Repeated capture of a changing running root is insufficient.
- Choose a fixed release epoch; normalize ordering and embedded metadata. Record
  actual invocation times and IDs externally. Current rootfs/media metadata embeds
  actual build identity and creation time and must be corrected before comparison.
- Byte-identical initramfs generation is recorded historically; it does not prove
  SquashFS, ext4 media or ISO reproducibility. Inspect filesystem UUIDs, timestamps
  and ISO boot/catalog metadata when measuring remaining differences.
- State the payload production method accurately. A complete rebuild of every
  LFS/BLFS package from source is a longer-term objective and must not be claimed
  merely because the captured payload has reproducible packaging.

## Schedule and exit conditions

| Window, 2026 | Work | Exit condition |
| --- | --- | --- |
| Oct 7-18 | Canonical audit, package inventory, pre-upgrade baseline, upgrade priorities and scope | Current-state checkpoint; declared audit gaps and first bounded change |
| Oct 19-Nov 1 | Validated package upgrades, input freeze and kernel/payload automation | Post-upgrade suite; declared inputs; fresh payload with provenance |
| Nov 2-15 | Tier 1, ISO packaging and Tier 2 automation | Generated ISO boots through OVMF; retained passing evidence |
| Nov 16-29 | Installer reconciliation and disposable qcow2 tests | Installation and independent boot; upgrade/reinstall policy |
| Nov 30-Dec 13 | Same-workspace reruns, fresh-build comparisons, hardware and docs | Idempotence and byte comparison pass; agreed hardware gates |
| Dec 14-23 | Candidate freeze and targeted regression fixes | Complete candidate evidence bundle |
| Dec 24-31 | Buffer and final release | Tagged source and versioned release bundle |

Adjust sequencing based on evidence without silently dropping acceptance gates.
The target is a planning commitment, not proof that all remaining work fits.

## Release deliverables

Release from tagged source. Deliver ISO, SHA256SUMS, package manifest, provenance,
validation logs/report, build and installation instructions, known issues and
release notes. Provenance records source commit, kernel/config, script/tool
versions, source and input hashes, release epoch and timestamp policy. Keep actual
run logs outside immutable payload metadata. Published releases are immutable.

## Future user-controlled agent package management

Build the future local-AI agent on the same package records, recipes, staging,
validation and activation mechanisms. It should support selective inspection,
explain version/dependency changes and prepare reviewable upgrade plans. The user
controls package selection and activation; model text alone cannot authorize a
privileged operation. Record provenance, affected files, results and recovery
instructions. Agent execution must pass through deterministic validated tooling.
This is a future product milestone, not a dependency of the December ISO.

## Immediate checkpoint

Recommend D for the release baseline after the package audit, validated upgrades
and frozen inputs. Preserve July artifacts for evidence and optional diagnostic
validation after hash verification. Do not mix current HEAD with older build
provenance or bypass clean-tree guards. Complete tools/sable-inventory.sh review
and current inventory next; commit this plan and ENGINEERING_STATE.md on Z890.
