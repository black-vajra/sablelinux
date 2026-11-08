#!/bin/busybox sh
BB=/bin/busybox

fail() {
    echo SABLE_INSTALLED_ROOT_FAIL
    "$BB" sync
    exec "$BB" poweroff -f
}

# Direct kernel boot may already have mounted devtmpfs.
"$BB" mount -t proc proc /proc || fail
if "$BB" awk '
    $2 == "/dev" { found = 1 }
    END { exit !found }
' /proc/mounts; then
    "$BB" awk '
        $2 == "/dev" && $3 == "devtmpfs" { found = 1 }
        END { exit !found }
    ' /proc/mounts || fail
else
    "$BB" mount -t devtmpfs devtmpfs /dev || fail
fi
exec >/dev/console 2>&1
"$BB" mount -t sysfs sysfs /sys || fail

"$BB" awk '
    $2 == "/" && $3 == "ext4" {
        n = split($4, options, ",")
        for (i = 1; i <= n; i++)
            if (options[i] == "rw") found = 1
    }
    END { exit !found }
' /proc/mounts || fail

checker=/usr/lib/systemd/sable-check-install-metadata
if [ -e "$checker" ]; then
    "$checker" "" installed-boot || fail
fi

if [ -e /.sable-fresh-install-probe ]; then
    phase=verify
else
    phase=write
fi

case "$phase" in
    write)
        [ ! -e /.sable-fresh-install-probe ] || fail
        printf '%s\n' 'sable-fresh-install-v1' \
            > /.sable-fresh-install-probe || fail
        "$BB" sync || fail
        echo SABLE_INSTALLED_ROOT_WRITE_PASS
        ;;
    verify)
        [ -f /.sable-fresh-install-probe ] || fail
        [ "$("$BB" cat /.sable-fresh-install-probe)" = \
            sable-fresh-install-v1 ] || fail
        echo SABLE_INSTALLED_ROOT_PERSISTENCE_PASS
        ;;
    *) fail ;;
esac

"$BB" sync || fail
"$BB" mount -o remount,ro / || fail
echo SABLE_INSTALLED_ROOT_SHUTDOWN_READY
exec "$BB" poweroff -f
