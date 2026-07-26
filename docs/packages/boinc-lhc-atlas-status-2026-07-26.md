# BOINC/LHC@home ATLAS Status — 2026-07-26

## Current status

The canonical Z890 SableLinux system has successfully started a native
multithreaded ATLAS workload through BOINC 8.2.11.

This validates the complete startup path:

BOINC client → LHC@home scheduler → CVMFS → Apptainer → ATLAS Pilot 3

The active task is limited to one concurrent LHC@home job and uses seven CPU
threads.

## Validated components

- BOINC 8.2.11 runs under the dedicated `boinc` service account.
- The BOINC service is manually controlled and remains disabled at boot.
- Only LHC@home is attached.
- LHC@home may send any compatible project application.
- Project concurrency is limited to one job.
- AMD OpenCL GPU detection remains operational.
- CVMFS 2.13.3 is active through autofs.
- Required CERN and ATLAS repositories are readable by the `boinc` account.
- The ATLAS wrapper successfully probed `atlas.cern.ch`.
- The wrapper successfully probed `atlas-condb.cern.ch`.
- Apptainer supplied through CVMFS executed successfully.
- ATLAS Pilot 3 launched inside the CentOS 7 container.
- The CVMFS shared cache is active and growing as expected.

## Current workload

The first post-CVMFS validation task entered the executing state and launched
ATLAS Panda job `7234891001`.

The task uses the `native_mt` application path with seven CPU threads.

## Remaining acceptance criterion

Startup is validated, but the workload has not yet completed.

Final acceptance still requires:

1. Sustained Athena processing.
2. Creation of the expected ATLAS output files.
3. Successful BOINC task completion.
4. Successful upload and scheduler acknowledgement.
5. Increment of the successful-job count without another missing-output error.

The task should remain running after the engineering session ends.

## Service policy

`boinc-client.service` remains disabled at boot and is currently running only
because it was started manually.

`autofs.service` is enabled and active because CVMFS runtime validation passed.

## Evidence

See:

`docs/testing/lhc-atlas-startup-validation-2026-07-26.txt`
