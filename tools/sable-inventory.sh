#!/usr/bin/env bash
# Read-only, bounded host observations; not a package ledger or release gate.
set -u
set -o pipefail
export LC_ALL=C
export GIT_OPTIONAL_LOCKS=0
umask 077

if [[ ${1:-} == --help ]]; then
    printf 'Usage: %s [NEW_REPORT_PATH]\n' "$0"
    printf 'Refuses existing reports. Exit 0: probes completed; 1: incomplete; 2: setup/output failure.\n'
    exit 0
fi
if (( $# > 1 )); then
    printf 'Expected at most one report path.\n' >&2
    exit 2
fi
for tool in timeout awk tee; do
    if ! command -v "$tool" >/dev/null; then
        printf 'Required tool unavailable: %s; no unbounded fallback.\n' "$tool" >&2
        exit 2
    fi
done
REPO=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P) || exit 2
OUT=${1:-sable-inventory-${HOSTNAME:-host}-${EPOCHSECONDS:-$$}-$$.txt}
# Exclusive creation also rejects symlinks to existing files.
set -o noclobber
if ! exec 3>"$OUT"; then
    printf 'Cannot create a new report: %s\n' "$OUT" >&2
    exit 2
fi
set +o noclobber

failures=0
probes=0
run_with_codes() {
    local label=$1 allowed=$2 rc filter_rc
    shift 2
    probes=$((probes + 1))
    printf '\n=== %s ===\n' "$label"
    printf 'Command:'
    printf ' %q' "$@"
    printf '\n'
    # The limiter consumes the entire stream: no head/SIGPIPE false failures.
    # Time bounds the producer; output is capped independently per probe.
    timeout --signal=TERM --kill-after=2s 15s "$@" 2>&1 |
        awk 'NR <= 250 { print substr($0, 1, 2000); if (length($0) > 2000) wide++ }
             END { if (NR > 250) printf "[OUTPUT LIMITED: %d additional lines omitted]\n", NR-250;
                   if (wide) printf "[OUTPUT LIMITED: %d displayed lines shortened]\n", wide }'
    local -a statuses=("${PIPESTATUS[@]}")
    rc=${statuses[0]}
    filter_rc=${statuses[1]}
    printf '[command exit: %s; output filter exit: %s]\n' "$rc" "$filter_rc"
    if [[ $filter_rc == 0 && " $allowed " == *" $rc "* ]]; then
        if [[ $rc != 0 ]]; then
            printf '[EXPECTED STATUS: no matching process]\n'
        fi
    else
        failures=$((failures + 1))
        if [[ $rc == 124 || $rc == 137 ]]; then
            printf '[INCOMPLETE: timeout/termination; inspect diagnostics]\n'
        else
            printf '[INCOMPLETE: probe failed; remaining probes continue]\n'
        fi
    fi
}
run() { local label=$1; shift; run_with_codes "$label" 0 "$@"; }

collect() {
    printf '=== SABLE INVENTORY ===\n'
    printf 'Observation only: no package ownership/completeness or release acceptance claim.\n'
    printf 'Each probe: 15s timeout + 2s kill grace; at most 250 lines, 2000 characters/line.\n'
    printf 'Output limits are declared omissions, not complete listings.\n'
    printf 'No recursive historical/model/guest/CVMFS/source/build-tree scans.\n'
    printf 'No network requests, version upgrades, mounts or service changes.\n'
    printf 'Run as the desktop user; permission/session failures remain visible.\n'
    printf 'Timeouts cannot guarantee recovery from uninterruptible kernel I/O.\n'

    run 'UTC time' date -u --iso-8601=seconds
    run 'Hostname' hostname
    run 'User' id
    run 'Kernel' uname -a
    run 'OS release' cat /etc/os-release
    run 'Kernel command line' cat /proc/cmdline
    run 'Board vendor' cat /sys/class/dmi/id/board_vendor
    run 'Board name' cat /sys/class/dmi/id/board_name
    # Mount table only: do not resolve or access historical mount destinations.
    run 'Mount table' findmnt -rn -o TARGET,SOURCE,FSTYPE,OPTIONS
    run 'Block topology (no filesystem signature probe requested)' lsblk -o NAME,TYPE,SIZE,MOUNTPOINTS
    run 'Canonical filesystem capacity' df -hT / /boot /srv/sablelinux
    run 'fstab (configuration, not proof of mounting)' cat /etc/fstab
    run 'Memory' free -h
    run 'CPU count' nproc
    run 'CPU details' lscpu
    run 'PCI devices' lspci -nn
    run 'USB devices' lsusb

    # maxdepth 1 never descends into EFI, GRUB, or other mounted subdirectories.
    run 'Boot directory entries only; no recursive traversal' \
        find -H /boot -maxdepth 1 -printf '%y %TY-%Tm-%Td %TH:%TM %s %p -> %l\n'
    # -H follows only command-line firmware-directory aliases, not child links.
    # /lib and /usr/lib may alias one another; duplicate observations are possible.
    run 'Firmware directory entries only; contents NOT inventoried' \
        find -H /lib/firmware /usr/lib/firmware -maxdepth 1 \
        -printf '%y %p -> %l\n'

    local file
    for file in /etc/pam.d/system-auth /etc/pam.d/system-session \
        /etc/security/limits.conf /etc/security/limits.d/99-filedesc.conf; do
        run "PAM/limits: $file (absence is reported)" cat -- "$file"
    done
    printf '\n=== Caller file descriptor limit ===\n'
    ulimit -n
    run 'Sway executable' bash -c 'command -v sway'
    run 'Waybar executable' bash -c 'command -v waybar'
    run 'Waybar version' waybar --version
    run_with_codes 'Sway processes' '0 1' pgrep -a -x sway
    run_with_codes 'Waybar processes' '0 1' pgrep -a -x waybar
    run_with_codes 'PipeWire processes' '0 1' pgrep -a -x pipewire
    run 'Audio session state' wpctl status
    run 'Network addresses' ip -br addr
    run 'Network routes' ip route
    run 'Resolver state' resolvectl status
    run 'resolv.conf' cat /etc/resolv.conf

    printf '\nRepository derived from this script location: %s\n' "$REPO"
    run 'Repository HEAD' git -C "$REPO" rev-parse HEAD
    run 'Repository status (normal untracked summary)' git -C "$REPO" status --short --branch
    run 'Repository recent commits' git -C "$REPO" log --oneline --decorate -n 8
    run 'Cached origin/development (no remote freshness claim)' \
        git -C "$REPO" rev-parse refs/remotes/origin/development
    run 'Tracked diff summary' git -C "$REPO" diff --stat HEAD --
    run 'Inventory script SHA256' sha256sum "$REPO/tools/sable-inventory.sh"
    run 'Canonical build pointer only; build contents not traversed' \
        cat /srv/sablelinux/state/current-build-id
    printf '\n=== Historical paths deliberately not accessed ===\n'
    printf '/mnt, /media, model weights, guest disks, CVMFS repositories, /sources and /srv build contents.\n'
    printf 'Use the mount table above; separate targeted audits must declare their scope.\n'
    run 'Recent boot warnings (journal query bounded to 250 entries)' \
        journalctl -b -p warning..alert -n 250 --no-pager
    printf '\n=== SUMMARY ===\n'
    printf 'Probes: %s; incomplete probes: %s\n' "$probes" "$failures"
    printf 'No matching desktop processes is an expected observation.\n'
    printf 'Missing configuration/tools, access errors and timeouts are incomplete probes.\n'
    printf 'Successful probes may still have declared output omissions.\n'
    if (( failures > 0 )); then
        printf 'RESULT: INCOMPLETE (exit 1); retain this report and review each diagnostic.\n'
        return 1
    fi
    printf 'RESULT: PROBES COMPLETED (exit 0); bounded observation, not a release gate.\n'
}

collect 2>&1 | tee /dev/fd/3
result=("${PIPESTATUS[@]}")
exec 3>&-
if [[ ${result[1]} != 0 ]]; then
    printf 'Report output failed: %s\n' "$OUT" >&2
    exit 2
fi
printf '\nInventory written to: %s\n' "$OUT"
exit "${result[0]}"
