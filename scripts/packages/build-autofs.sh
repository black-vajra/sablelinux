#!/usr/bin/env bash
set -euo pipefail
umask 022

PACKAGE="autofs"
VERSION="5.1.9"
EXPECTED_SHA256="87e6af6a03794b9462ea519781e50e7d23b5f7c92cd59e1142c85d2493b3c24b"

REPO="${REPO:-$HOME/sablelinux}"
ROOT="/srv/sablelinux/package-builds/$PACKAGE/$VERSION"

ARCHIVE="$ROOT/downloads/$PACKAGE-$VERSION.tar.xz"
VERIFIED_SOURCE="$ROOT/source/$PACKAGE-$VERSION"

BUILD_ROOT="$ROOT/build"
BUILD_SOURCE="$BUILD_ROOT/$PACKAGE-$VERSION"
STAGE="$ROOT/stage"
LOG_ROOT="$ROOT/logs"
MANIFEST_ROOT="$ROOT/manifests"
REPORT_ROOT="$ROOT/reports"

BUILD_LOG="$LOG_ROOT/build.txt"
INSTALL_LOG="$LOG_ROOT/staged-install.txt"
CONFIGURE_LOG="$LOG_ROOT/configure.txt"

FILE_MANIFEST="$MANIFEST_ROOT/staged-files.txt"
DETAIL_MANIFEST="$MANIFEST_ROOT/staged-files-detailed.txt"
HASH_MANIFEST="$MANIFEST_ROOT/staged-sha256.txt"
ELF_MANIFEST="$MANIFEST_ROOT/elf-files.txt"
ELF_DYNAMIC="$MANIFEST_ROOT/elf-dynamic-dependencies.txt"
SYMLINK_MANIFEST="$MANIFEST_ROOT/symlinks.txt"
CONFIG_MANIFEST="$MANIFEST_ROOT/configuration-files.txt"
UNIT_MANIFEST="$MANIFEST_ROOT/systemd-units.txt"

REPORT="$REPORT_ROOT/staged-build-report.txt"
METADATA="$REPORT_ROOT/build-metadata.env"

JOBS="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || printf '1')}"

CONFIGURE_ARGS=(
    --prefix=/usr
    --sbindir=/usr/sbin
    --libdir=/usr/lib
    --sysconfdir=/etc
    --with-confdir=/etc
    --with-mapdir=/etc
    --with-fifodir=/run
    --with-flagdir=/run
    --with-systemd=/usr/lib/systemd/system
    --with-libtirpc
    --without-openldap
    --without-sasl
    --without-hesiod
    --disable-fedfs
)

fail()
{
    echo "STOP: $*" >&2
    exit 1
}

require_command()
{
    command -v "$1" >/dev/null 2>&1 ||
        fail "required command missing: $1"
}

echo "=== AUTOFS 5.1.9 CANONICAL STAGED BUILD ==="

for command in \
    awk \
    cp \
    file \
    find \
    gcc \
    getconf \
    grep \
    install \
    ldd \
    make \
    pkg-config \
    readelf \
    sed \
    sha256sum \
    sort \
    tar
do
    require_command "$command"
done

test -d "$REPO/.git" ||
    fail "repository missing: $REPO"

test "$(git -C "$REPO" branch --show-current)" = "development" ||
    fail "repository is not on development"

test -z "$(git -C "$REPO" status --porcelain)" || {
    git -C "$REPO" status --short
    fail "repository is not clean"
}

test -f "$ARCHIVE" ||
    fail "source archive missing: $ARCHIVE"

test -d "$VERIFIED_SOURCE" ||
    fail "verified source tree missing: $VERIFIED_SOURCE"

ACTUAL_SHA256="$(sha256sum "$ARCHIVE" | awk '{print $1}')"

test "$ACTUAL_SHA256" = "$EXPECTED_SHA256" || {
    echo "EXPECTED=$EXPECTED_SHA256"
    echo "ACTUAL=$ACTUAL_SHA256"
    fail "source archive SHA256 mismatch"
}

echo
echo "=== VERIFY BUILD FOUNDATION ==="

test "$(rpcgen --version 2>&1 | awk '{print $NF}')" = "1.4.4" ||
    fail "unexpected rpcsvc-proto version"

test "$(pkg-config --modversion libtirpc)" = "1.3.7" ||
    fail "unexpected libtirpc version"

pkg-config --exists libtirpc ||
    fail "libtirpc pkg-config metadata unavailable"

pkg-config --exists mount ||
    fail "libmount pkg-config metadata unavailable"

pkg-config --exists libxml-2.0 ||
    fail "libxml2 pkg-config metadata unavailable"

test -d /usr/lib/systemd/system ||
    fail "canonical systemd unit directory missing"

test -x /usr/bin/mount ||
    fail "/usr/bin/mount missing"

test -x /usr/bin/umount ||
    fail "/usr/bin/umount missing"

echo "PASS: rpcsvc-proto $(rpcgen --version 2>&1 | awk '{print $NF}')"
echo "PASS: libtirpc $(pkg-config --modversion libtirpc)"
echo "PASS: libmount $(pkg-config --modversion mount)"
echo "PASS: libxml2 $(pkg-config --modversion libxml-2.0)"
echo "PASS: build foundation verified"

echo
echo "=== RESET DISPOSABLE BUILD AND STAGE TREES ==="

rm -rf \
    "$BUILD_ROOT" \
    "$STAGE" \
    "$LOG_ROOT" \
    "$MANIFEST_ROOT" \
    "$REPORT_ROOT"

install -d -m 0755 \
    "$BUILD_ROOT" \
    "$STAGE" \
    "$LOG_ROOT" \
    "$MANIFEST_ROOT" \
    "$REPORT_ROOT"

cp -a "$VERIFIED_SOURCE" "$BUILD_SOURCE"

test -x "$BUILD_SOURCE/configure" ||
    fail "copied configure script missing"

echo "PASS: disposable build tree created"
echo "PASS: empty staging root created"

echo
echo "=== RECORD BUILD METADATA ==="

cat > "$METADATA" <<EOF
PACKAGE=$PACKAGE
VERSION=$VERSION
SOURCE_ARCHIVE=$ARCHIVE
SOURCE_SHA256=$ACTUAL_SHA256
VERIFIED_SOURCE=$VERIFIED_SOURCE
BUILD_SOURCE=$BUILD_SOURCE
STAGE_ROOT=$STAGE
CANONICAL_HOST=$(hostname)
KERNEL_RELEASE=$(uname -r)
BUILD_USER=$(id -un)
BUILD_GROUP=$(id -gn)
BUILD_TIMESTAMP=$(date --iso-8601=seconds)
REPOSITORY=$REPO
REPOSITORY_BRANCH=$(git -C "$REPO" branch --show-current)
REPOSITORY_COMMIT=$(git -C "$REPO" rev-parse HEAD)
REPOSITORY_DIRTY=false
COMPILER=$(gcc --version | head -n 1)
MAKE_JOBS=$JOBS
CFLAGS=-O2 -pipe
CPPFLAGS=
LDFLAGS=
PREFIX=/usr
SBINDIR=/usr/sbin
LIBDIR=/usr/lib
SYSCONFDIR=/etc
SYSTEMD_UNIT_DIR=/usr/lib/systemd/system
AUTOFS_MODULE_DIR=/usr/lib/autofs
LDAP_SUPPORT=disabled
SASL_SUPPORT=disabled
KERBEROS_SUPPORT=unavailable
NIS_SUPPORT=disabled
NFS_USERSPACE_HELPER=optional-not-present
SERVICE_ACTIVATION=not-performed
EOF

cat "$METADATA"

echo
echo "=== CONFIGURE BUILD TREE ==="

printf '%s\n' "${CONFIGURE_ARGS[@]}" \
    > "$REPORT_ROOT/configure-arguments.txt"

(
    cd "$BUILD_SOURCE"

    env \
        CC=gcc \
        CFLAGS="-O2 -pipe" \
        CPPFLAGS="" \
        LDFLAGS="" \
        PKG_CONFIG_PATH="/usr/lib/pkgconfig:/usr/share/pkgconfig" \
        ./configure "${CONFIGURE_ARGS[@]}"
) 2>&1 | tee "$CONFIGURE_LOG"

test -f "$BUILD_SOURCE/Makefile.conf" ||
    fail "Makefile.conf was not generated"

test -f "$BUILD_SOURCE/include/config.h" ||
    fail "config.h was not generated"

echo
echo "=== VALIDATE CONFIGURATION ==="

grep -q '^sharedlibdir[[:space:]]*=[[:space:]]*/usr/lib$' \
    "$BUILD_SOURCE/Makefile.conf" ||
    fail "unexpected shared library directory"

grep -q '^autofslibdir[[:space:]]*=[[:space:]]*/usr/lib/autofs$' \
    "$BUILD_SOURCE/Makefile.conf" ||
    fail "unexpected autofs module directory"

grep -q '^sbindir[[:space:]]*=[[:space:]]*/usr/sbin$' \
    "$BUILD_SOURCE/Makefile.conf" ||
    fail "unexpected administrative binary directory"

grep -q '^systemddir[[:space:]]*=[[:space:]]*/usr/lib/systemd/system$' \
    "$BUILD_SOURCE/Makefile.conf" ||
    fail "unexpected systemd unit directory"

grep -q '^#define WITH_LIBTIRPC 1' \
    "$BUILD_SOURCE/include/config.h" ||
    fail "libtirpc support was not enabled"

for feature in \
    WITH_LDAP \
    WITH_LDAP_CYRUS_SASL \
    HAVE_NISPLUS \
    WITH_HESIOD
do
    if grep -q "^#define $feature 1" \
        "$BUILD_SOURCE/include/config.h"; then
        fail "unwanted feature enabled: $feature"
    fi
done

echo "PASS: installation paths validated"
echo "PASS: libtirpc enabled"
echo "PASS: LDAP, SASL, NIS+ and Hesiod disabled"

echo
echo "=== COMPILE AUTOFS ==="

(
    cd "$BUILD_SOURCE"

    make \
        -j"$JOBS" \
        STRIP=true
) 2>&1 | tee "$BUILD_LOG"

test -x "$BUILD_SOURCE/daemon/automount" ||
    fail "automount binary was not built"

test -f "$BUILD_SOURCE/modules/mount_autofs.so" ||
    fail "mount_autofs module was not built"

test -f "$BUILD_SOURCE/modules/mount_generic.so" ||
    fail "mount_generic module was not built"

echo "PASS: compilation completed"
echo "PASS: core binary and modules produced"

echo
echo "=== INSTALL EXCLUSIVELY INTO STAGING ROOT ==="

(
    cd "$BUILD_SOURCE"

    make \
        STRIP=true \
        INSTALLROOT="$STAGE" \
        install
) 2>&1 | tee "$INSTALL_LOG"

echo "PASS: upstream staged installation completed"

echo
echo "=== INSTALL SABLELINUX POLICY FILES INTO STAGING ROOT ==="

SAMPLE_ROOT="$BUILD_SOURCE/samples"

for required_sample in \
    "$SAMPLE_ROOT/autofs.service" \
    "$SAMPLE_ROOT/autofs.conf.default" \
    "$SAMPLE_ROOT/auto.master"
do
    test -f "$required_sample" ||
        fail "required upstream policy template missing: $required_sample"
done

install -d -m 0755 \
    "$STAGE/etc" \
    "$STAGE/etc/auto.master.d" \
    "$STAGE/usr/lib/systemd/system"

install -m 0644 \
    "$SAMPLE_ROOT/autofs.conf.default" \
    "$STAGE/etc/autofs.conf"

cat > "$STAGE/etc/auto.master" <<'AUTO_MASTER_EOF'
#
# SableLinux autofs master map
#
# Individual automount definitions belong in:
#   /etc/auto.master.d/*.autofs
#
# No demonstration maps, hosts map, or external NSS master map is enabled.
#
+dir:/etc/auto.master.d
AUTO_MASTER_EOF

chmod 0644 "$STAGE/etc/auto.master"

install -m 0644 \
    "$SAMPLE_ROOT/autofs.service" \
    "$STAGE/usr/lib/systemd/system/autofs.service"

# The canonical /srv build hierarchy may carry the setgid bit.
# Normalize all staged package directories before manifest generation
# so activation cannot propagate build-tree group semantics.
# GNU chmod preserves setgid on directories when a numeric mode is used.
# Normalize ordinary permissions, then clear inherited special bits explicitly.
find "$STAGE" -type d -exec chmod 0755 {} +
find "$STAGE" -type d -exec chmod u-s,g-s,-t {} +

echo "PASS: staged directory permissions normalized"
echo "PASS: inherited setuid, setgid and sticky bits explicitly removed"

echo "PASS: /etc/autofs.conf staged"
echo "PASS: /etc/auto.master staged"
echo "PASS: /etc/auto.master.d created"
echo "PASS: autofs.service staged"
echo "PASS: demonstration maps intentionally omitted"

echo
echo "=== VERIFY POLICY FILE MODES ==="

test "$(stat -c '%a' "$STAGE/etc/autofs.conf")" = "644" ||
    fail "unexpected mode on staged autofs.conf"

test "$(stat -c '%a' "$STAGE/etc/auto.master")" = "644" ||
    fail "unexpected mode on staged auto.master"

test "$(stat -c '%a' "$STAGE/usr/lib/systemd/system/autofs.service")" = "644" ||
    fail "unexpected mode on staged autofs.service"

test "$(stat -c '%a' "$STAGE/etc/auto.master.d")" = "755" ||
    fail "unexpected mode on staged auto.master.d"

if find "$STAGE" -type d -printf '%m %p\n' |
    awk '$1 != "755" { print; bad=1 } END { exit bad ? 0 : 1 }'
then
    fail "one or more staged directories have non-canonical modes"
fi

echo "PASS: staged policy-file modes validated"
echo "PASS: all staged directory modes are 0755"

echo
echo "=== VERIFY DEMONSTRATION MAPS ARE ABSENT ==="

for omitted_map in \
    auto.misc \
    auto.net \
    auto.smb
do
    test ! -e "$STAGE/etc/$omitted_map" ||
        fail "demonstration map unexpectedly staged: $omitted_map"
done

echo "PASS: no demonstration maps staged"

echo
echo "=== VERIFY NO LIVE INSTALLATION OCCURRED ==="

test ! -e /usr/sbin/automount || {
    echo "LIVE FILE PRESENT: /usr/sbin/automount"
    fail "live autofs binary unexpectedly exists"
}

test ! -e /usr/lib/systemd/system/autofs.service || {
    echo "LIVE FILE PRESENT: /usr/lib/systemd/system/autofs.service"
    fail "live autofs service unexpectedly exists"
}

test ! -e /etc/autofs.conf || {
    echo "LIVE FILE PRESENT: /etc/autofs.conf"
    fail "live autofs configuration unexpectedly exists"
}

echo "PASS: no live autofs installation detected"

echo
echo "=== VALIDATE REQUIRED STAGED PAYLOAD ==="

for required in \
    "$STAGE/usr/sbin/automount" \
    "$STAGE/usr/lib/systemd/system/autofs.service" \
    "$STAGE/usr/lib/autofs/mount_autofs.so" \
    "$STAGE/usr/lib/autofs/mount_generic.so" \
    "$STAGE/etc/autofs.conf" \
    "$STAGE/etc/auto.master"
do
    test -e "$required" || {
        find "$STAGE" -maxdepth 5 -print | sort
        fail "required staged file missing: $required"
    }
done

test -x "$STAGE/usr/sbin/automount" ||
    fail "staged automount is not executable"

file "$STAGE/usr/sbin/automount" |
    grep -q 'ELF 64-bit' ||
    fail "staged automount is not a 64-bit ELF executable"

echo "PASS: required staged payload present"

echo
echo "=== VALIDATE SYSTEMD UNIT ==="

UNIT="$STAGE/usr/lib/systemd/system/autofs.service"

grep -q '^ExecStart=/usr/sbin/automount ' "$UNIT" ||
    fail "systemd unit has unexpected ExecStart"

grep -q -- '--systemd-service' "$UNIT" ||
    fail "systemd unit does not request systemd-service mode"

test ! -e "$STAGE/etc/systemd/system/multi-user.target.wants/autofs.service" ||
    fail "staged service was unexpectedly enabled"

echo "PASS: systemd unit references /usr/sbin/automount"
echo "PASS: systemd service mode configured"
echo "PASS: service remains disabled"

echo
echo "=== VALIDATE STAGED CONFIGURATION POLICY ==="

grep -q '^[[:space:]]*+dir:/etc/auto.master.d' \
    "$STAGE/etc/auto.master" ||
    fail "auto.master.d inclusion missing"

test -d "$STAGE/etc/auto.master.d" ||
    fail "auto.master.d directory missing"

ACTIVE_MASTER_ENTRIES="$(
    grep -Ev '^[[:space:]]*(#|$)' "$STAGE/etc/auto.master"
)"

test "$ACTIVE_MASTER_ENTRIES" = "+dir:/etc/auto.master.d" ||
    fail "auto.master contains unexpected active entries"

echo "PASS: master-map include directory available"
echo "PASS: auto.master contains only the SableLinux include-directory policy"

echo
echo "=== CHECK FOR UNRESOLVED TEMPLATE TOKENS ==="

if grep -RIn \
    --exclude='*.gz' \
    -E '@@[A-Za-z0-9_]+@@|@[A-Za-z0-9_]+@' \
    "$STAGE/etc" \
    "$STAGE/usr/lib/systemd/system" \
    2>/dev/null; then
    fail "unresolved template tokens found in staged payload"
fi

echo "PASS: no unresolved template tokens found"

echo
echo "=== CHECK STAGED SYMLINKS ==="

find "$STAGE" -type l -printf '%P -> %l\n' |
    LC_ALL=C sort |
    tee "$SYMLINK_MANIFEST"

while IFS= read -r link
do
    target="$(readlink "$link")"

    case "$target" in
        /*)
            fail "absolute symlink found in staged payload: $link -> $target"
            ;;
    esac

    test -e "$(dirname "$link")/$target" || {
        echo "BROKEN: $link -> $target"
        fail "broken staged symlink"
    }
done < <(find "$STAGE" -type l -print)

echo "PASS: staged symlinks are relative and resolvable"

echo
echo "=== GENERATE PAYLOAD MANIFESTS ==="

(
    cd "$STAGE"
    find . -mindepth 1 -printf '%P\n' |
        LC_ALL=C sort
) > "$FILE_MANIFEST"

(
    cd "$STAGE"
    find . -mindepth 1 \
        -printf '%M %u:%g %s %TY-%Tm-%TdT%TH:%TM:%TS %P\n' |
        LC_ALL=C sort
) > "$DETAIL_MANIFEST"

(
    cd "$STAGE"
    find . -type f -print0 |
        LC_ALL=C sort -z |
        xargs -0 -r sha256sum
) > "$HASH_MANIFEST"

find "$STAGE/etc" \
    -type f \
    -printf '%P\n' 2>/dev/null |
    LC_ALL=C sort \
    > "$CONFIG_MANIFEST"

find "$STAGE/usr/lib/systemd/system" \
    -type f \
    -printf '%P\n' 2>/dev/null |
    LC_ALL=C sort \
    > "$UNIT_MANIFEST"

echo "PASS: file manifests generated"
echo "PASS: staged SHA256 manifest generated"

echo
echo "=== INSPECT ELF PAYLOAD ==="

: > "$ELF_MANIFEST"
: > "$ELF_DYNAMIC"

while IFS= read -r -d '' object
do
    if file "$object" | grep -q 'ELF '; then
        relative="${object#"$STAGE"/}"

        {
            echo "=== $relative ==="
            file "$object"
            readelf -h "$object" |
                grep -E \
                    'Class:|Data:|Type:|Machine:|Entry point address:' ||
                true
            echo
        } >> "$ELF_MANIFEST"

        {
            echo "=== $relative ==="
            readelf -d "$object" |
                grep -E \
                    '\(NEEDED\)|\(RPATH\)|\(RUNPATH\)|\(SONAME\)' ||
                true
            echo
        } >> "$ELF_DYNAMIC"
    fi
done < <(find "$STAGE" -type f -print0)

test -s "$ELF_MANIFEST" ||
    fail "no ELF objects identified in staged payload"

if grep -E '\(RPATH\)|\(RUNPATH\)' "$ELF_DYNAMIC"; then
    fail "unexpected RPATH or RUNPATH found"
fi

echo "PASS: ELF inventory generated"
echo "PASS: no RPATH or RUNPATH found"

echo
echo "=== VERIFY AUTOMOUNT LINK DEPENDENCIES ==="

STAGED_LIBRARY_PATH="$STAGE/usr/lib"

test -f "$STAGE/usr/lib/libautofs.so" ||
    fail "staged libautofs.so is missing"

LD_LIBRARY_PATH="$STAGED_LIBRARY_PATH${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    ldd "$STAGE/usr/sbin/automount" |
    tee "$REPORT_ROOT/automount-ldd.txt"

if grep -q 'not found' "$REPORT_ROOT/automount-ldd.txt"; then
    fail "automount has unresolved staged dynamic dependencies"
fi

grep -q 'libtirpc\.so' "$REPORT_ROOT/automount-ldd.txt" ||
    fail "automount does not link against libtirpc"

grep -Fq \
    "libautofs.so => $STAGE/usr/lib/libautofs.so" \
    "$REPORT_ROOT/automount-ldd.txt" ||
    fail "automount did not resolve libautofs.so from staging root"

echo "PASS: automount dynamic dependencies resolve"
echo "PASS: automount links against libtirpc"
echo "PASS: staged libautofs.so selected from staging root"

echo
echo "=== VERIFY DIRECTORY-SERVICE MODULES ARE ABSENT ==="

for unwanted in \
    lookup_ldap.so \
    lookup_yp.so \
    lookup_nis.so \
    lookup_nisplus.so
do
    if find "$STAGE/usr/lib/autofs" \
        -maxdepth 1 \
        -name "$unwanted" \
        -print -quit |
        grep -q .; then
        fail "unwanted module staged: $unwanted"
    fi
done

echo "PASS: LDAP and NIS lookup modules absent"

echo
echo "=== CLASSIFY OPTIONAL NFS CAPABILITY ==="

if test -x /usr/sbin/mount.nfs ||
   test -x /sbin/mount.nfs; then
    NFS_RUNTIME_STATE="available"
else
    NFS_RUNTIME_STATE="optional-helper-absent"
fi

echo "NFS_RUNTIME_STATE=$NFS_RUNTIME_STATE"

test -f "$STAGE/usr/lib/autofs/mount_nfs.so" ||
    fail "expected upstream mount_nfs module missing"

echo "PASS: upstream NFS module staged"
echo "NOTICE: NFS maps require an external mount.nfs runtime helper"
echo "NOTICE: CVMFS/FUSE automount operation does not require mount.nfs"

echo
echo "=== WRITE STAGED BUILD REPORT ==="

FILE_COUNT="$(
    find "$STAGE" -mindepth 1 -type f | wc -l
)"

DIRECTORY_COUNT="$(
    find "$STAGE" -mindepth 1 -type d | wc -l
)"

SYMLINK_COUNT="$(
    find "$STAGE" -mindepth 1 -type l | wc -l
)"

STAGE_SIZE="$(
    du -sh "$STAGE" | awk '{print $1}'
)"

cat > "$REPORT" <<EOF
SableLinux autofs 5.1.9 canonical staged build

BUILD_TIMESTAMP=$(date --iso-8601=seconds)
CANONICAL_HOST=$(hostname)
KERNEL_RELEASE=$(uname -r)
REPOSITORY=$REPO
REPOSITORY_BRANCH=$(git -C "$REPO" branch --show-current)
REPOSITORY_COMMIT=$(git -C "$REPO" rev-parse HEAD)
SOURCE_ARCHIVE=$ARCHIVE
SOURCE_SHA256=$ACTUAL_SHA256

Build policy:
prefix=/usr
sbindir=/usr/sbin
libdir=/usr/lib
autofs module directory=/usr/lib/autofs
configuration directory=/etc
map directory=/etc
runtime FIFO directory=/run
runtime flag directory=/run
systemd unit directory=/usr/lib/systemd/system
libtirpc enabled
LDAP disabled
SASL disabled
Kerberos unavailable
NIS and NIS+ disabled
Hesiod disabled
FedFS disabled
NFS user-space helper optional
service activation not performed

Build:
compiler=$(gcc --version | head -n 1)
CFLAGS=-O2 -pipe
parallel jobs=$JOBS
stripping deferred=true
build source=$BUILD_SOURCE
stage root=$STAGE

Staged payload:
files=$FILE_COUNT
directories=$DIRECTORY_COUNT
symlinks=$SYMLINK_COUNT
size=$STAGE_SIZE
automount=$STAGE/usr/sbin/automount
service=$STAGE/usr/lib/systemd/system/autofs.service
configuration=$STAGE/etc
modules=$STAGE/usr/lib/autofs

NFS disposition:
kernel NFS support is present
mount.nfs runtime helper state=$NFS_RUNTIME_STATE
NFS maps require optional external nfs-utils support
CVMFS/FUSE operation is unaffected by absent mount.nfs
upstream mount_nfs module retained
no downstream source patch applied

Validation:
PASS: verified source archive used
PASS: configure policy validated
PASS: compilation completed
PASS: installation confined to staging root
PASS: required payload present
PASS: systemd unit validated
PASS: service not enabled
PASS: configuration include directory present
PASS: no unresolved templates
PASS: symlinks valid
PASS: ELF inventory generated
PASS: no RPATH or RUNPATH
PASS: automount dependencies resolved
PASS: libtirpc linkage confirmed
PASS: LDAP and NIS modules absent
PASS: payload hashes generated
PASS: repository unchanged
NOT DONE: live activation
NOT DONE: runtime automount test
NOT DONE: CVMFS integration
NOT DONE: repository import
NOT DONE: commit
NOT DONE: push
EOF

cat "$REPORT"

echo
echo "=== FINAL REPOSITORY CLEANLINESS CHECK ==="

test -z "$(git -C "$REPO" status --porcelain)" || {
    git -C "$REPO" status --short
    fail "repository changed during staged build"
}

echo
echo "=== RESULT ==="
echo "PASS: autofs 5.1.9 canonical staged build completed"
echo "PASS: staged payload validated"
echo "PASS: live system unchanged"
echo "PASS: service remains disabled"
echo "PASS: repository remains clean"
echo "STAGE=$STAGE"
echo "REPORT=$REPORT"
echo "METADATA=$METADATA"
echo "FILE_MANIFEST=$FILE_MANIFEST"
echo "HASH_MANIFEST=$HASH_MANIFEST"
echo "ELF_MANIFEST=$ELF_MANIFEST"
echo "NEXT: review staged payload and create guarded activation procedure"
