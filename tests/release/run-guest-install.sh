#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
umask 022

die() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

[ "$#" -eq 1 ] || die "usage: $0 /var/tmp/sable-m112-e2e-XXXXXXXX"
evidence="$1"
[[ "$evidence" =~ ^/var/tmp/sable-m112-e2e-[A-Za-z0-9]+$ ]] &&
    [ -d "$evidence" ] && [ ! -L "$evidence" ] ||
    die "expected a disposable integration evidence directory"
[ "$(id -u)" -ne 0 ] || die "run as an unprivileged user"

scripts="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/guest-install" && pwd)"
firmware=/opt/sablelinux/qemu/firmware/ovmf
for tool in qemu-system-x86_64 qemu-img grub-mkstandalone mkfs.fat \
            mkfs.ext4 sgdisk unsquashfs ldd cpio gzip python3 timeout; do
    command -v "$tool" >/dev/null || die "missing tool: $tool"
done
(exec 3<>/dev/kvm) 2>/dev/null || die "KVM is inaccessible"

build_id="$(cat "$evidence/workspace/state/current-build-id")"
[[ "$build_id" =~ ^[A-Za-z0-9][A-Za-z0-9._+-]*$ ]] || die "invalid build ID"
build="$evidence/workspace/builds/$build_id"
[ "$(cat "$build/BUILD_STATE")" = initramfs-generated ] ||
    die "expected initramfs-generated fixture"
release="$(sed -n 's/^KERNEL_RELEASE=//p' "$build/metadata/build.env")"
[[ "$release" =~ ^[A-Za-z0-9][A-Za-z0-9._+-]*$ ]] || die "invalid kernel release"

kernel="boot/vmlinuz-$release"
squash=squashfs/filesystem.squashfs
for input in "$kernel" "$squash"; do
    digest="$(awk -v name="/srv/sablelinux/builds/$build_id/$input" '
        $2 == name { count++; digest = $1 }
        END { if (count != 1) exit 1; print digest }
    ' "$build/metadata/live-boot-inputs.sha256")"
    [[ "$digest" =~ ^[0-9a-f]{64}$ ]] || die "invalid input hash"
    printf '%s  %s\n' "$digest" "$build/$input" | sha256sum -c -
done

run="$(mktemp -d "$evidence/guest-install-XXXXXXXX")"
printf 'Guest installation evidence: %s\n' "$run"
stage="$run/initramfs"
payload="$run/payload"
mkdir -p "$stage"/{bin,dev,etc,proc,sys,source,target,esp} "$payload"

# Copy the canonical tools and resolve their library closure on this host.
install -m755 /usr/bin/busybox "$stage/bin/busybox"
for name in sgdisk mkfs.fat mkfs.ext4 unsquashfs; do
    tool="$(command -v "$name")"
    install -m755 "$tool" "$stage/bin/$name"
    ldd "$tool" > "$run/$name.ldd"
    awk '
        $2 == "=>" && $3 == "not" { missing = 1 }
        $2 == "=>" && $3 ~ /^\// { print $3 }
        $1 ~ /^\// { print $1 }
        END { if (missing) exit 1 }
    ' "$run/$name.ldd" > "$run/$name.libs" || die "unresolved library for $name"
    while IFS= read -r lib; do
        install -Dm755 "$lib" "$stage$lib"
    done < "$run/$name.libs"
done
test -x "$stage/lib64/ld-linux-x86-64.so.2" || die "guest loader missing"
install -m644 /etc/mke2fs.conf "$stage/etc/mke2fs.conf"
install -m755 "$scripts/deploy-init.sh" "$stage/init"
install -m755 "$scripts/installed-init.sh" "$payload/installed-init"

if [ "${SABLE_INSTALL_METADATA:-0}" = 1 ]; then
    command -v cc >/dev/null || die "metadata check requires cc"
    cc -std=c11 -Wall -Wextra -Werror -O2 -static \
        "$scripts/check-metadata.c" -o "$stage/bin/check-install-metadata" ||
        die "could not build static metadata checker"
fi

root_guid="$(python3 -c 'import uuid; print(uuid.uuid4())')"
printf '%s\n' "$root_guid" > "$stage/root-partuuid"

cat > "$run/grub.cfg" <<GRUB
serial --unit=0 --speed=115200
terminal_input serial
terminal_output serial
echo SABLE_INSTALLED_EFI_GRUB_ENTERED
search --no-floppy --label SABLEINST --set=root
linux /vmlinuz console=ttyS0,115200 root=PARTUUID=$root_guid rootfstype=ext4 rootwait rw init=/sbin/init
boot
GRUB

grub-mkstandalone -O x86_64-efi \
    --modules="part_gpt fat serial terminal search search_label linux" \
    -o "$payload/BOOTX64.EFI" "boot/grub/grub.cfg=$run/grub.cfg"

cp "$build/$kernel" "$payload/vmlinuz"
cp "$build/$squash" "$payload/filesystem.squashfs"
(
    cd "$payload"
    sha256sum filesystem.squashfs BOOTX64.EFI vmlinuz installed-init \
        > payload.sha256
)
(
    cd "$stage"
    find . -print0 | sort -z |
        cpio --null -o -H newc --owner=0:0 | gzip -n > "$run/install.img"
)

payload_bytes="$(du -sb "$payload" | awk '{print $1}')"
truncate -s "$((payload_bytes + 64 * 1024 * 1024))" "$run/source.ext4"
mkfs.ext4 -q -F -d "$payload" "$run/source.ext4"
qemu-img create -f qcow2 "$run/target.qcow2" 640M
sha256sum "${BASH_SOURCE[0]}" "$scripts/"*.sh \
    "$run/grub.cfg" "$run/install.img" "$run/source.ext4" "$run/target.qcow2" \
    "$firmware/OVMF_CODE_4M.fd" "$firmware/OVMF_VARS_4M.template.fd" \
    > "$run/before-install.sha256"

qemu=(
    qemu-system-x86_64 -machine q35 -accel kvm -m 1024 -smp 2
    -display none -monitor none -nic none -no-reboot
)

run_vm() {
    local phase="$1" status=0
    shift
    printf '\n=== %s ===\n' "$phase"
    timeout --kill-after=5s 180s "${qemu[@]}" \
        -serial "file:$run/$phase.serial.log" "$@" \
        > "$run/$phase.qemu.log" 2>&1 || status=$?
    printf '%s\n' "$status" > "$run/$phase.exit-status"
    cat "$run/$phase.qemu.log"
    test -f "$run/$phase.serial.log" || die "$phase serial log missing"
    tr -d '\r' < "$run/$phase.serial.log" > "$run/$phase.serial.txt"
    tail -n 20 "$run/$phase.serial.txt"
    test "$status" = 0 || die "$phase QEMU exit status $status"
    if grep -Exq 'SABLE_GUEST_INSTALL_FAIL|SABLE_INSTALLED_ROOT_FAIL' \
        "$run/$phase.serial.txt"; then
        die "$phase guest reported failure"
    fi
}

run_vm install \
    -kernel "$build/$kernel" -initrd "$run/install.img" \
    -append 'console=ttyS0,115200 rdinit=/init' \
    -drive "file=$run/source.ext4,format=raw,if=virtio,readonly=on" \
    -drive "file=$run/target.qcow2,format=qcow2,if=virtio"
grep -Fxq SABLE_GUEST_INSTALL_PASS "$run/install.serial.txt" ||
    die "installation pass marker missing"

for phase in write verify; do
    cp "$firmware/OVMF_VARS_4M.template.fd" "$run/$phase.OVMF_VARS.fd"
    run_vm "$phase" \
        -drive "if=pflash,format=raw,unit=0,readonly=on,file=$firmware/OVMF_CODE_4M.fd" \
        -drive "if=pflash,format=raw,unit=1,file=$run/$phase.OVMF_VARS.fd" \
        -drive "file=$run/target.qcow2,format=qcow2,if=virtio"
    grep -Fq SABLE_INSTALLED_EFI_GRUB_ENTERED "$run/$phase.serial.txt" ||
        die "$phase GRUB entry marker missing"
    grep -Fxq SABLE_INSTALLED_ROOT_SHUTDOWN_READY "$run/$phase.serial.txt" ||
        die "$phase shutdown marker missing"
    case "$phase" in
        write) marker=SABLE_INSTALLED_ROOT_WRITE_PASS ;;
        verify) marker=SABLE_INSTALLED_ROOT_PERSISTENCE_PASS ;;
    esac
    grep -Fxq "$marker" "$run/$phase.serial.txt" ||
        die "$phase expected marker missing"
done

if [ "${SABLE_INSTALL_METADATA:-0}" = 1 ]; then
    for checkpoint in squashfs extracted; do
        grep -Fxq "SABLE_INSTALL_METADATA_PASS $checkpoint" "$run/install.serial.txt" ||
            die "$checkpoint metadata marker missing"
    done
    for phase in write verify; do
        grep -Fxq 'SABLE_INSTALL_METADATA_PASS installed-boot' "$run/$phase.serial.txt" ||
            die "$phase installed metadata marker missing"
    done
fi

qemu-img check -f qcow2 "$run/target.qcow2" | tee "$run/qcow2-check.log"
sha256sum "$run/target.qcow2" > "$run/installed-target.sha256"
printf 'SABLE_GUEST_INSTALL_AND_EFI_BOOT_PASS\nEvidence: %s\n' "$run"
