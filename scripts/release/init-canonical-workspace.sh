#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="/srv/sablelinux"
LAYOUT_VERSION="1"
MIN_FREE_GIB=200

die() {
    echo "ERROR: $*" >&2
    exit 1
}

if [ "$EUID" -ne 0 ]; then
    die "run this script through sudo"
fi

BUILD_USER="${SUDO_USER:-pepper}"
BUILD_GROUP="$(id -gn "$BUILD_USER")"

id "$BUILD_USER" >/dev/null 2>&1 ||
    die "build user does not exist: $BUILD_USER"

if [ -L "$ROOT" ]; then
    die "$ROOT must not be a symbolic link"
fi

install -d -o root -g "$BUILD_GROUP" -m 2775 /srv

FREE_BYTES="$(df -PB1 /srv | awk 'NR == 2 {print $4}')"
MINIMUM_BYTES=$((MIN_FREE_GIB * 1024 * 1024 * 1024))

case "$FREE_BYTES" in
    ''|*[!0-9]*)
        die "could not determine available workspace capacity"
        ;;
esac

if [ "$FREE_BYTES" -lt "$MINIMUM_BYTES" ]; then
    FREE_GIB=$((FREE_BYTES / 1024 / 1024 / 1024))
    die "only ${FREE_GIB} GiB available; ${MIN_FREE_GIB} GiB required"
fi

DIRECTORIES=(
    "$ROOT"
    "$ROOT/builds"
    "$ROOT/cache"
    "$ROOT/cache/downloads"
    "$ROOT/cache/packages"
    "$ROOT/releases"
    "$ROOT/releases/candidates"
    "$ROOT/releases/published"
    "$ROOT/reports"
    "$ROOT/state"
    "$ROOT/state/locks"
)

for directory in "${DIRECTORIES[@]}"; do
    install -d \
        -o root \
        -g "$BUILD_GROUP" \
        -m 2775 \
        "$directory"
done

REPO="/home/$BUILD_USER/sablelinux"
GIT_BRANCH="unknown"
GIT_COMMIT="unknown"

if [ -d "$REPO/.git" ]; then
    GIT_BRANCH="$(
        git -C "$REPO" branch --show-current 2>/dev/null ||
        echo unknown
    )"

    GIT_COMMIT="$(
        git -C "$REPO" rev-parse HEAD 2>/dev/null ||
        echo unknown
    )"
fi

cat > "$ROOT/state/workspace-metadata.txt" <<METADATA
layout_version=$LAYOUT_VERSION
canonical_host=$(hostname)
initialized_at=$(date --utc --iso-8601=seconds)
initialized_by=$BUILD_USER
build_group=$BUILD_GROUP
kernel_release=$(uname -r)
repository=$REPO
git_branch=$GIT_BRANCH
git_commit=$GIT_COMMIT
METADATA

printf '%s\n' "$LAYOUT_VERSION" \
    > "$ROOT/state/layout-version"

cat > "$ROOT/README.txt" <<'README'
SableLinux canonical generated-artifact workspace.

Maintained repository:

  /home/pepper/sablelinux

Generated builds:

  /srv/sablelinux/builds/<build-id>

Do not manually maintain live-root trees here.
Do not use secondary-system artifacts as canonical build inputs.
Do not build directly inside release directories.
README

chown root:"$BUILD_GROUP" \
    "$ROOT/README.txt" \
    "$ROOT/state/layout-version" \
    "$ROOT/state/workspace-metadata.txt"

chmod 0664 \
    "$ROOT/README.txt" \
    "$ROOT/state/layout-version" \
    "$ROOT/state/workspace-metadata.txt"

echo "Canonical workspace initialized: $ROOT"
echo "Build user: $BUILD_USER"
echo "Build group: $BUILD_GROUP"
echo "Layout version: $LAYOUT_VERSION"
