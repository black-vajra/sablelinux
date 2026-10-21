# Bounded inventory review — 2026-10-16

## Canonical checkpoint evidence

Operator-supplied `sable-inventory-preflight-nCTFS4Ww.txt`, collected at
2026-10-16T19:23:07Z, identifies SableLinux on Gigabyte Z890 AORUS ELITE X ICE,
running 6.16.1-sable-gpu-test2. Development HEAD and cached origin/development
both name ba2bc2ca3db12267254ecca2b9ba29e3425385bd. This batch did not fetch
the remote. Tracked changes were absent; scripts/boincctl was untracked.
The current build pointer still names the July 17 sable-compat build.

Root had 593 GiB available; /boot had 609 MiB available. /boot/efi was not
mounted. fstab still names 3745-AF41 while nvme1n1p1 reports 5F1D-6806.
The repeated /boot filesystem in df output for /boot/efi is the containing
filesystem, not evidence that the EFI partition is mounted. Do not edit fstab,
mount an assumed EFI device or reinstall GRUB as part of this inventory change.

## Trigger and bounded correction

The reviewed inventory script SHA256 was
2cda247bf100036ab4fbcb525a602c9fef3f5fe2522cdd2defe30f7540d1aa29.
It suppressed stderr/statuses, ignored failed repository cd, recursively ran
du/find over historical mount destinations, and could report success after
earlier failures. It must not be used as release evidence in that form.

The replacement preserves host/desktop/network/boot observations while:

- reporting each command, stderr and exit status, then continuing independent
  sections; missing tools and permission failures remain incomplete observations;
- imposing a 15-second timeout and two-second kill grace per probe;
- limiting displayed output to 250 lines and 2000 characters per line per
  probe, declaring omissions without head-induced SIGPIPE false failures;
- avoiding all historical mount-path access and recursive firmware traversal;
  find lists only immediate entries in /boot and the two firmware directory
  aliases. Child symlinks are not followed. These are not firmware inventories;
- using the mount table instead of du/find on /mnt or other historical roots;
- deriving the repository from the script location, reporting HEAD/status,
  cached remote revision and script hash without fetching or refreshing locks;
- creating a private new report, refusing existing report paths, and reporting
  output/setup failures. No root privileges are required.

Invocation from the canonical checkout:

```bash
bash tools/sable-inventory.sh /absolute/path/to/NEW-report.txt
```

Exit 0 means probes completed, with any declared display omissions; it does
not mean a complete host inventory or acceptance pass. Exit 1 means one or
more probes failed or timed out; preserve the partial report and review the
diagnostics. pgrep status 1 means no matching process and is expected. Exit 2
means setup or report-output failure. Missing optional configuration is still
reported as incomplete rather than silently discarded. Timeout is not a
guarantee against uninterruptible kernel I/O; do not repeat hung device probes.

## Validation and limits

Reviewer-environment Bash syntax checking and isolated CLI tests passed before
delivery. The fixture suite uses fake host commands with real Bash, GNU timeout,
awk and tee. It checks successful completion, output omissions, expected absent
processes, 0600 report creation, exact bounded find arguments, script-relative
repository selection, refusal to replace reports or follow an existing report
symlink, failed output setup, retained failure diagnostics, later-section
continuation, a real timeout of a TERM-ignoring probe, and fail-closed setup
when timeout is unavailable. It does not audit the reviewer's host.

Canonical fixture validation passed on Z890. Commands used:

```bash
bash -n tools/sable-inventory.sh
python3 tools/tests/test-sable-inventory.py
```

The canonical desktop-user report completed with two incomplete probes.
See canonical-validation.txt and canonical-tests.log for reviewed results. Keep tests and report
outside the source tree until reviewed; commit reviewed evidence and results
with the correction. Do not claim host validation based on fixture results.

This does not establish installed package ownership/provenance, firmware
coverage, functionality acceptance, input freeze, rootfs capture, or an ISO
gate. The next package baseline must reconcile runtime executable/library
paths and versions with canonical package records, source hashes, recipes,
activation records, manifests and unresolved ownership. Source-directory
names and matching version strings alone do not establish provenance.
