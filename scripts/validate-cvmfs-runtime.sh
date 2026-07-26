#!/bin/bash
set -euo pipefail

REPOSITORIES=(
    cvmfs-config.cern.ch
    atlas.cern.ch
    atlas-condb.cern.ch
    grid.cern.ch
    unpacked.cern.ch
)

fail()
{
    echo "FAIL: $*" >&2
    exit 1
}

echo "=== CVMFS RUNTIME VALIDATION ==="

test -x /usr/bin/cvmfs2 ||
    fail "cvmfs2 missing"

test -x /usr/bin/cvmfs_config ||
    fail "cvmfs_config missing"

test -x /sbin/mount.cvmfs ||
    fail "mount.cvmfs missing"

test "$(systemctl is-active autofs.service)" = "active" ||
    fail "autofs inactive"

test "$(systemctl is-enabled autofs.service)" = "enabled" ||
    fail "autofs disabled"

test "$(stat -c '%U:%G' /var/lib/cvmfs)" = "cvmfs:cvmfs" ||
    fail "cache ownership incorrect"

/usr/bin/cvmfs2 --version
/usr/bin/cvmfs_config chksetup

for repository in "${REPOSITORIES[@]}"
do
    echo
    echo "=== PROBE $repository ==="

    timeout 240 \
        /usr/bin/cvmfs_config probe "$repository"

    test -d "/cvmfs/$repository" ||
        fail "mountpoint absent: $repository"

    timeout 60 \
        find "/cvmfs/$repository" \
            -mindepth 1 \
            -maxdepth 1 \
            -print -quit |
        grep -q . ||
        fail "repository unreadable: $repository"

    su -s /bin/bash boinc -c \
        "cd / && timeout 60 test -r '/cvmfs/$repository'" ||
        fail "boinc cannot read $repository"

    su -s /bin/bash boinc -c \
        "cd / && timeout 60 find '/cvmfs/$repository' -mindepth 1 -maxdepth 1 -print -quit | grep -q ." ||
        fail "boinc cannot traverse $repository"

    echo "PASS: $repository"
done

echo
echo "=== MOUNTS ==="
findmnt -rn |
    grep '/cvmfs/' ||
    fail "no CVMFS mounts found"

echo
echo "=== CACHE ==="
du -sh /var/lib/cvmfs

echo
echo "PASS: CVMFS runtime validation complete"
