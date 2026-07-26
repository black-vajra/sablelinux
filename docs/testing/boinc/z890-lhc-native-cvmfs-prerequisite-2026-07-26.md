# Z890 BOINC/LHC Native ATLAS Runtime Validation

Date: 2026-07-26
Canonical system: Z890 SableLinux
Kernel: 6.16.1-sable-lhc-test1
BOINC: 8.2.11

## Purpose

Validate the canonical Z890 platform through initial native LHC@home ATLAS execution and identify the first missing operating-system runtime dependency.

## Result

The canonical system successfully completed:

- BOINC client startup
- LHC@home scheduler communication
- project attachment
- task acquisition
- application and input downloads
- BOINC slot creation
- wrapper execution
- native ATLAS launcher execution
- seven-thread argument propagation
- controlled failed-result reporting
- scheduler acceptance
- work-fetch suspension

The single ATLAS task was launched as:

    wrapper_26015_x86_64-pc-linux-gnu --nthreads 7
    /bin/bash run_atlas --nthreads 7

The configured project concurrency limit of one task did not interfere with project initialization or task execution.

## Identified Dependency

Native ATLAS execution stopped at its CVMFS prerequisite check:

    No cvmfs_config command found
    /cvmfs/atlas.cern.ch/repo/sw: No such file or directory
    CVMFS is required to run ATLAS native tasks

Scientific payload execution was not reached.

The resulting missing output files were an expected consequence of the failed prerequisite check, not a separate BOINC defect.

## Platform Status

    BOINC installation             PASS
    BOINC service startup          PASS
    LHC project attachment         PASS
    Scheduler communication        PASS
    Task and input download        PASS
    Single-task concurrency        PASS
    Native wrapper launch          PASS
    Thread assignment              PASS
    Failure reporting              PASS
    No-new-work control            PASS
    CVMFS availability             FAIL
    ATLAS scientific execution     NOT REACHED

## Current Control State

LHC@home work fetching remains suspended. No additional work should be requested until CVMFS is installed and independently validated.

## Next Phase

Add and validate CVMFS on the canonical Z890.

The phase must include:

1. Determine the current supported CVMFS source release.
2. Verify all build and runtime dependencies.
3. Build and install CVMFS through a documented canonical procedure.
4. Configure atlas.cern.ch and atlas-condb.cern.ch.
5. Establish and document the cache location and size.
6. Validate FUSE and automount behavior.
7. Validate repository access as root and as the boinc service account.
8. Validate operation after service restart and reboot.
9. Record package version, source provenance, build metadata, configuration, and hashes.
10. Resume LHC work fetching only after independent CVMFS validation passes.
