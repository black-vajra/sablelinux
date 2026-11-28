# Pots Z890 — CPU Thermal Maintenance Journal

Date: 2026-11-28
Status: UNDER INVESTIGATION
Classification: Host-specific conditional hardware maintenance
Host: pots
Operating system: Kubuntu
Motherboard: Gigabyte Z890 AORUS ELITE X ICE
Processor: Intel Core Ultra 5 245K
Kernel: 6.17.0-40-generic

## Scope

This record concerns a localized CPU thermal anomaly observed
during sustained BOINC computation.

The frequency restriction described here is a local hardware
protection measure. It is not a general BOINC requirement,
a SableLinux default, or a recommendation for other hosts.

## Autonomous thermal shutdown

On 2026-11-28 at 05:20:47 EST, Thermal Guardian detected a
CPU thermal emergency during normal unattended operation.

The independent deadline guardian authenticated the monitor
and registered its seven-second shutdown deadline.

At 05:20:54 EST, the authorized poweroff service accepted
the real, non-simulated shutdown request.

The system subsequently shut down normally.

This establishes successful autonomous execution of the
production thermal shutdown path.

## Emergency temperature snapshot

Sensor       Linux CPU   Temperature
Core 8       CPU 0       90 C
Core 12      CPU 1       70 C
Core 16      CPU 2       70 C
Core 20      CPU 3       66 C
Core 24      CPU 4       64 C
Core 28      CPU 5       66 C
Core 0       CPU 6       74 C
Core 1       CPU 7       74 C
Core 2       CPU 8       74 C
Core 3       CPU 9       74 C
Core 4       CPU 10      70 C
Core 5       CPU 11      70 C
Core 6       CPU 12      70 C
Core 7       CPU 13      72 C

CPU package: 90 C
GPU edge: 52 C
GPU junction: 57 C
GPU memory: 54 C
Sensor faults: 0

Physical Core 8 corresponds to Linux CPU 0, a performance
core with an original maximum frequency of 5.2 GHz.

The affected core was 20 C hotter than the next hottest
performance core and 16 C hotter than any other CPU core.

## Preliminary hardware health assessment

The processor has undergone approximately seven months
of sustained computational service without the additional
Thermal Guardian production shutdown protection.

Intel's native thermal protection was not deliberately
disabled.

The available historical audit found:

- No recorded machine-check errors.
- No recorded cache hierarchy or internal parity errors.
- No recorded uncorrected hardware errors.
- No matching historical kernel thermal throttling messages.
- No matching BOINC computation errors in retained journals.
- Zero current-boot thermal throttling counters.
- Normal idle temperatures across all fourteen cores.

These findings are encouraging but are not a certification
of processor health.

The retained journal history extends only to 2026-11-23.
Current throttling counters do not cover previous boots.
Persistent rasdaemon error collection was not installed.

Historical thermal exposure and remaining processor lifespan
cannot presently be established.

## Suspected causes

The localized temperature disparity warrants investigation
of the following:

- Uneven thermal paste distribution.
- Uneven cooler mounting pressure.
- Cooler-to-heat-spreader contact.
- Core-specific workload distribution.
- Core-specific voltage, frequency and boost behavior.
- Possible processor degradation.

No physical cooling defect or silicon degradation has
yet been conclusively established.

## Conditional local mitigation

Linux CPU 0 maximum frequency reduced from:

    5200000 kHz to 4000000 kHz

All other CPU frequency ceilings remain unchanged.

CPU 1-5: 5200000 kHz
CPU 6-13: 4600000 kHz

This restricts the available frequency range without
disabling the core or modifying voltage settings.

There is no expected inherent increase in semiconductor
wear from this frequency restriction. Actual workload
redistribution and thermal effects remain to be evaluated.

Performance effects are workload-dependent. No measured
throughput regression has yet been established.

## Persistent frequency guard

Canonical implementation:

    scripts/cpu-frequency-guard.sh
    systemd/cpu-frequency-guard.service
    systemd/cpu-frequency-guard.timer

Production implementation:

    /usr/local/bin/cpu-frequency-guard.sh
    /etc/systemd/system/cpu-frequency-guard.service
    /etc/systemd/system/cpu-frequency-guard.timer

The guard verifies:

- Linux CPU number 0.
- Physical core identity 8.
- Physical package identity 0.
- Independent CPU frequency policy.
- intel_pstate scaling driver.

Both systemd units are enabled at boot.

The timer checks the frequency ceiling approximately
every ten seconds and restores it to 4000000 kHz if changed.

The guard enforces an exact configured ceiling, including
restoration from lower software-configured frequency limits.

It does not disable Intel hardware thermal throttling.

## Runtime validation — 2026-11-28

PASS: Bash syntax validation.
PASS: ShellCheck validation.
PASS: Systemd unit validation.
PASS: Production service and timer installation.
PASS: Both units enabled at boot.
PASS: CPU 0 restricted to 4000000 kHz.
PASS: Other thirteen CPU frequency ceilings unchanged
      during initial installation.

Downward override test:

    10:35:36 EST
    WARN: CPU 0 ceiling changed: 3900000 kHz
    PASS: CPU 0 restored to 4000000 kHz

Upward override test:

    10:37:54 EST — 4100000 kHz observed
    10:38:00 EST — 4100000 kHz observed
    10:38:01 EST — 4000000 kHz observed

    WARN: CPU 0 ceiling changed: 4100000 kHz
    PASS: CPU 0 restored to 4000000 kHz

PASS: Automatic restoration following an increased ceiling.
PASS: Observed correction interval approximately seven seconds.
PASS: No manual fallback required.

Pending: Actual reboot persistence validation.

## Known limitations

The frequency guard is periodic rather than instantaneous.
An external override may remain effective until the next
successful enforcement cycle.

Boot ordering is configured but does not constitute a
mandatory BOINC startup interlock.

Systemd currently emits routine service lifecycle messages
on each timer invocation.

The guard must not be automatically installed on another
host or incorporated into a generic distribution policy.

## Thermal Guardian recovery

The production shutdown mechanism successfully performed
a real autonomous shutdown.

Following reboot, both production guardian services
rejected persistent emergency records from the previous boot.

Administrator review and controlled recovery are required.

BOINC was inactive during the subsequent investigation
and frequency guard validation.

The frequency guard is not a replacement for Thermal Guardian.

## Pending maintenance and investigation

- Preserve and review persistent emergency records.
- Restore production Thermal Guardian protection.
- Inspect CPU cooler mounting and thermal paste coverage.
- Reseat and repaste the cooling assembly.
- Compare equivalent workloads across performance cores.
- Evaluate CPU computational integrity.
- Evaluate sustained thermal behavior.
- Review firmware and CPU power-management settings.
- Establish persistent hardware-error monitoring.
- Verify frequency guard persistence at a normal reboot.

The CPU 0 frequency restriction remains in effect until
explicitly reviewed and withdrawn.

## Evidence retained on Pots

    ~/shutdown-investigation-20261128-101243.log
    ~/thermal-guardian-recovery-20261128-101557.log
    ~/cpu-health-baseline-20261128-102226.log

Original emergency report:

    /var/log/thermal-guardian/thermal-event-20261128-052047-375510.json

Raw host diagnostic logs are retained locally and are not
included in this public repository commit.

## BOINC source revision

    e4832289694f26db4d72fa3077260cc7d467ab56
