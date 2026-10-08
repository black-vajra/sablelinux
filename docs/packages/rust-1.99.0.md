# Rust development toolchain — 1.99.0

Installed and validated on canonical Z890 SableLinux, October 7, 2026.

## Purpose

Support Freenet Backgammon development and SableLinux development work.

## Installation

Installed as pepper through official rustup, using the default profile
and stable channel. Tools reside beneath /home/pepper/.cargo and
/home/pepper/.rustup.

Installed versions:
- rustc 1.99.0 (b940084d7 2026-09-28)
- cargo 1.99.0 (5f94df478 2026-08-27)

Installed targets:
- x86_64-unknown-linux-gnu
- wasm32-unknown-unknown

## Validation

Native Rust smoke program compiled, linked and executed successfully.
Both targets appeared in rustup's installed-target listing.
WebAssembly compilation and full Backgammon builds remain untested.
New-session PATH persistence remains to be checked.

## Release policy

The stable channel can change. Reproducible builds must record and use
an exact toolchain version. This user-local installation does not add
Rust to live media: the current rootfs policy excludes pepper's home.
A release development-toolchain profile requires a separate documented
packaging decision.
