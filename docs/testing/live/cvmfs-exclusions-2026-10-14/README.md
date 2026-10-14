# CVMFS release scope and exclusion validation — 2026-10-14

Canonical Z890 documentation identifies BOINC/LHC ATLAS as the only
documented CVMFS consumer. Inspected autofs configuration contains only
the CVMFS map. CVMFS is excluded from the baseline ISO; autofs tooling
remains installed but its service is disabled in the generated live root.
Host packages, services and cache data remain untouched.

Validation: bash scripts/live/test-rootfs-excludes.sh

Passed: CVMFS package/configuration/cache and BOINC/guest fixture exclusions;
retention of QEMU/OVMF/GRUB components, autofs tooling and shared libraries;
unchanged repeat copy; source fixture content preservation; and execution
of the generator's actual service-link removal block against fixture data.
Generated autofs/sshd/llama-server enablement links were removed while
source links and the retained autofs unit remained unchanged.

Fixture: /tmp/sable-exclusions-bvjdcNvM
Inventory copies have trailing whitespace normalized; originals retained.

The review was bounded. No full rootfs capture, live-media boot,
installation or ISO reproducibility gate was executed.
