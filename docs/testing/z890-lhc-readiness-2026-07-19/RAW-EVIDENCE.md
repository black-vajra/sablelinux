# Raw Evidence Preservation Policy

Files under `reports/`, `metadata/`, and `artifacts/`, together with
`final-system-state.txt`, contain machine-generated evidence.

These files are preserved byte-for-byte from the canonical Z890 build
workspace or captured directly from the running system. They are intentionally
not whitespace-normalized.

Some utilities emit trailing spaces or final blank lines. Examples include
GRUB, BusyBox tools, `ip`, `modprobe`, `newuidmap`, and `newgidmap`. Those bytes
remain part of the archived evidence.

Whitespace validation for this commit applies only to human-authored
documentation and the BUILDLOG entry. Generated evidence integrity is
validated through `SHA256SUMS`.
