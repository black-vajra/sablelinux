#!/usr/bin/env bash
set -Eeuo pipefail

[ "$#" -eq 1 ] || {
    echo "Usage: $0 EMPTY_FIXTURE_DIRECTORY" >&2
    exit 1
}

ROOT="$1"

[ -d "$ROOT" ] && [ ! -L "$ROOT" ] ||
    { echo "Fixture directory missing or symlinked" >&2; exit 1; }

[ -z "$(find "$ROOT" -mindepth 1 -print -quit)" ] ||
    { echo "Fixture directory must be empty" >&2; exit 1; }

mkdir -p \
    "$ROOT/etc/ssh" \
    "$ROOT/etc/systemd/system" \
    "$ROOT/usr/lib/systemd" \
    "$ROOT/usr/bin" \
    "$ROOT/usr/lib/modules/host-test/kernel" \
    "$ROOT/home/sable" \
    "$ROOT/home/pepper" \
    "$ROOT/home/tester" \
    "$ROOT/var/log" \
    "$ROOT/var/cache" \
    "$ROOT/var/lib" \
    "$ROOT/root"

ln -s usr/lib "$ROOT/lib"
ln -s usr/bin "$ROOT/bin"
mkdir -p "$ROOT/usr/sbin"
ln -s usr/sbin "$ROOT/sbin"
ln -s ../lib/systemd/systemd "$ROOT/usr/sbin/init"
install -m 0755 /usr/bin/busybox "$ROOT/usr/bin/busybox"

cat > "$ROOT/etc/passwd" <<'PASSWD'
root:x:0:0:root:/root:/bin/bash
pepper:x:1000:1000:Build Host:/home/pepper:/bin/bash
tester:x:1001:1001:Test User:/home/tester:/bin/bash
sable:x:1002:1002:Sable Live:/home/sable:/bin/bash
PASSWD

cat > "$ROOT/etc/group" <<'GROUP'
root:x:0:
pepper:x:1000:
tester:x:1001:
sable:x:1002:
GROUP

cat > "$ROOT/etc/shadow" <<'SHADOW'
root:!:19000:0:99999:7:::
pepper:!:19000:0:99999:7:::
tester:!:19000:0:99999:7:::
sable:!:19000:0:99999:7:::
SHADOW

cat > "$ROOT/etc/gshadow" <<'GSHADOW'
root:!::
pepper:!::
tester:!::
sable:!::
GSHADOW

chmod 0600 "$ROOT/etc/shadow" "$ROOT/etc/gshadow"

cat > "$ROOT/usr/lib/systemd/systemd" <<'INIT'
#!/bin/busybox sh
exec >/dev/console 2>&1

if /bin/busybox awk '
    $2 == "/" && $3 == "overlay" { found = 1 }
    END { exit !found }
' /proc/mounts &&
   printf 'overlay write probe\n' > /.sable-tier1-write-probe &&
   /bin/busybox rm /.sable-tier1-write-probe
then
    echo "SABLE_TIER1_USERSPACE_PASS"
else
    echo "SABLE_TIER1_USERSPACE_FAIL"
fi

exec /bin/busybox poweroff -f
INIT

chmod 0755 "$ROOT/usr/lib/systemd/systemd"

cat > "$ROOT/usr/bin/agetty" <<'AGETTY'
#!/bin/sh
exit 0
AGETTY

chmod 0755 "$ROOT/usr/bin/agetty"

printf 'host kernel module fixture\n' \
    > "$ROOT/usr/lib/modules/host-test/kernel/host.ko"

printf 'host-secret-fixture\n' \
    > "$ROOT/home/pepper/private-test.txt"

printf 'fixture-host\n' > "$ROOT/etc/hostname"
printf 'UUID=fixture-host-uuid / ext4 defaults 0 1\n' \
    > "$ROOT/etc/fstab"

mkdir -p "$ROOT/usr/lib/systemd/user"
for unit in pipewire.socket pipewire-pulse.socket; do
    printf '%s\n' '[Install]' 'WantedBy=sockets.target' \
        > "$ROOT/usr/lib/systemd/user/$unit"
done
printf '%s\n' '[Install]' 'WantedBy=pipewire.service' \
    'Alias=pipewire-session-manager.service' \
    > "$ROOT/usr/lib/systemd/user/wireplumber.service"

printf 'PASS: synthetic rootfs fixture created\n'
