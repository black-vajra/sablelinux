#!/usr/bin/env bash
set -Eeuo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PRODUCTION_SCRIPT="$REPO/scripts/kernel/build-kernel.sh"

die() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

[[ -f "$PRODUCTION_SCRIPT" ]] ||
    die "production kernel-build script missing"

TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT

FIXTURE="$TMP/fixture"
mkdir -p \
    "$FIXTURE/repo/scripts/kernel" \
    "$FIXTURE/repo/docs/release-validation/gpu-test2-2026-10-08" \
    "$FIXTURE/workspace/state" \
    "$FIXTURE/workspace/kernel-builds" \
    "$FIXTURE/source/linux-6.16.1"

cp "$PRODUCTION_SCRIPT" \
    "$FIXTURE/repo/scripts/kernel/build-kernel.sh"

printf '1\n' > "$FIXTURE/workspace/state/layout-version"

cat > "$FIXTURE/source/linux-6.16.1/Makefile" <<'MAKEFILE'
.PHONY: olddefconfig

olddefconfig:
	@test -f "$(O)/.config"
MAKEFILE

cat > "$FIXTURE/repo/docs/release-validation/gpu-test2-2026-10-08/kernel.config" <<'CONFIG'
CONFIG_LOCALVERSION="-sable-gpu-test2"
# CONFIG_LOCALVERSION_AUTO is not set
CONFIG_SQUASHFS=y
# CONFIG_SQUASHFS_XATTR is not set
CONFIG

tar -cJf "$FIXTURE/source.tar.xz" \
    -C "$FIXTURE/source" linux-6.16.1

printf 'PASS: Disposable source fixture created\n'
printf 'PASS: Synthetic configuration created\n'
printf 'PASS: Test workspace created\n'

bash -n "$FIXTURE/repo/scripts/kernel/build-kernel.sh" ||
    die "copied script syntax invalid"

printf 'PASS: Copied script syntax valid\n'

# Redirect only the disposable copy to fixture inputs.
python3 - "$FIXTURE" <<'FIXTURE_PY'
from pathlib import Path
import hashlib
import sys

root = Path(sys.argv[1])
script = root / "repo/scripts/kernel/build-kernel.sh"
archive = root / "source.tar.xz"
workspace = root / "workspace"
config = root / "repo/docs/release-validation/gpu-test2-2026-10-08/kernel.config"

text = script.read_text()

replacements = {
    'WORKSPACE="/srv/sablelinux"':
        f'WORKSPACE="{workspace}"',
    'SOURCE_ARCHIVE="/sources/linux-6.16.1.tar.xz"':
        f'SOURCE_ARCHIVE="{archive}"',
}

for old, new in replacements.items():
    if text.count(old) != 1:
        raise SystemExit(f"STOP: Fixture substitution not unique: {old}")
    text = text.replace(old, new, 1)

for variable, source in (
    ("EXPECTED_SOURCE_SHA256", archive),
    ("EXPECTED_CONFIG_SHA256", config),
):
    import re
    digest = hashlib.sha256(source.read_bytes()).hexdigest()
    pattern = rf'^{variable}="[0-9a-f]{{64}}"$'
    replacement = f'{variable}="{digest}"'
    text, count = re.subn(
        pattern, lambda _: replacement, text, flags=re.MULTILINE
    )
    if count != 1:
        raise SystemExit(f"STOP: Hash substitution failed: {variable}")

# The disposable fixture does not require production build capacity.
# Change only the temporary script, never the canonical implementation.
old_limit = '(( free_bytes >= 200 * 1024 * 1024 * 1024 ))'
new_limit = '(( free_bytes >= 1 * 1024 * 1024 ))'

if text.count(old_limit) != 1:
    raise SystemExit("STOP: Expected disk-space check not found exactly once")

text = text.replace(old_limit, new_limit, 1)

script.write_text(text)
FIXTURE_PY

# Commit the synthetic inputs so Git provenance checks remain active.
git -C "$FIXTURE/repo" init -q -b development

git -C "$FIXTURE/repo" add -- \
    scripts/kernel/build-kernel.sh \
    docs/release-validation/gpu-test2-2026-10-08/kernel.config

git -C "$FIXTURE/repo" \
    -c user.name="SableLinux Test" \
    -c user.email="test@localhost" \
    commit -qm "test: establish disposable kernel fixture"

printf 'PASS: Disposable Git repository initialized\n'

# Only the copied script is executed, and only in check mode.
"$FIXTURE/repo/scripts/kernel/build-kernel.sh" check \
    > "$TMP/fixture-check.log" 2>&1 ||
    {
        cat "$TMP/fixture-check.log"
        die "disposable preflight failed"
    }

grep -Fq 'PREFLIGHT PASS' "$TMP/fixture-check.log" ||
    die "fixture preflight did not report success"

printf 'PASS: Isolated fixture preflight\n'


# Exercise preparation exclusively inside the disposable fixture.
TEST_SCRIPT="$FIXTURE/repo/scripts/kernel/build-kernel.sh"

"$TEST_SCRIPT" prepare > "$TMP/prepare.log" 2>&1 || {
    cat "$TMP/prepare.log"
    die "disposable preparation failed"
}

grep -Fq 'PREPARE PASS' "$TMP/prepare.log" ||
    die "preparation did not report success"

printf 'PASS: Disposable preparation executed\n'

# Exactly one candidate must have been created.
mapfile -t candidates < <(
    find "$FIXTURE/workspace/kernel-builds" \
        -mindepth 1 -maxdepth 1 -type d -print
)

[[ "${#candidates[@]}" -eq 1 ]] ||
    die "expected exactly one candidate directory"

candidate="${candidates[0]}"
config="$candidate/obj/.config"

[[ "$(cat "$candidate/BUILD_STATE")" == "prepared" ]] ||
    die "candidate was not marked prepared"

printf 'PASS: Candidate state is prepared\n'

grep -qx 'CONFIG_LOCALVERSION="-sable-xattr-test1"' "$config" ||
    die "candidate kernel local version incorrect"

grep -qx 'CONFIG_SQUASHFS_XATTR=y' "$config" ||
    die "SquashFS XATTR was not enabled"

grep -qx 'CONFIG_SQUASHFS=y' "$config" ||
    die "SquashFS was not retained"

grep -qx '# CONFIG_LOCALVERSION_AUTO is not set' "$config" ||
    die "automatic local version unexpectedly enabled"

printf 'PASS: Candidate configuration verified\n'

for file in \
    "$candidate/metadata/build.env" \
    "$candidate/metadata/verified-inputs.sha256" \
    "$candidate/metadata/candidate-config.sha256" \
    "$candidate/logs/olddefconfig.log" \
    "$candidate/source/Makefile"; do
    [[ -f "$file" ]] ||
        die "missing preparation artifact: $file"
done

grep -Fxq \
    "GIT_COMMIT=$(git -C "$FIXTURE/repo" rev-parse HEAD)" \
    "$candidate/metadata/build.env" ||
    die "candidate Git provenance incorrect"

sha256sum -c \
    "$candidate/metadata/verified-inputs.sha256" \
    > "$TMP/input-check.log" ||
    die "candidate input checksums invalid"

sha256sum -c \
    "$candidate/metadata/candidate-config.sha256" \
    > "$TMP/config-check.log" ||
    die "candidate configuration checksum invalid"

printf 'PASS: Preparation metadata and checksums verified\n'


# Collision test: force the next disposable preparation to use
# the same timestamp and Git commit as the successful candidate.
# The existing candidate must remain unchanged.
candidate_name="$(basename "$candidate")"
candidate_timestamp="${candidate_name%%-*}"

python3 - "$TEST_SCRIPT" "$candidate_timestamp" <<'COLLISION_PY'
from pathlib import Path
import sys

script = Path(sys.argv[1])
timestamp = sys.argv[2]
text = script.read_text()

old = 'timestamp="$(date -u +%Y%m%dT%H%M%SZ)"'
new = f'timestamp="{timestamp}"'

if text.count(old) != 1:
    raise SystemExit("STOP: Timestamp substitution not unique")

script.write_text(text.replace(old, new, 1))
COLLISION_PY

git -C "$FIXTURE/repo" add -- scripts/kernel/build-kernel.sh
git -C "$FIXTURE/repo" \
    -c user.name="SableLinux Test" \
    -c user.email="test@localhost" \
    commit -qm "test: pin fixture candidate timestamp"

# The commit changed, so use the new commit identifier in the
# occupied candidate directory name.
collision_commit="$(git -C "$FIXTURE/repo" rev-parse --short=7 HEAD)"
collision_name="${candidate_timestamp}-${collision_commit}-linux-6.16.1-xattr-test1"
collision_path="$FIXTURE/workspace/kernel-builds/$collision_name"

mkdir "$collision_path"
printf 'collision-sentinel\n' > "$collision_path/BUILD_STATE"

if "$TEST_SCRIPT" prepare > "$TMP/collision.log" 2>&1; then
    echo "=== EXPECTED COLLISION ==="
    printf '%s\n' "$collision_path"

    echo "=== ACTUAL PREPARATION OUTPUT ==="
    cat "$TMP/collision.log"

    echo "=== FIXTURE CANDIDATES ==="
    find "$FIXTURE/workspace/kernel-builds" \
        -mindepth 1 -maxdepth 1 -printf '%f\n' | sort

    die "candidate collision was unexpectedly accepted"
fi

grep -Fq 'candidate already exists' "$TMP/collision.log" ||
    die "collision rejected for unexpected reason"

[[ "$(cat "$collision_path/BUILD_STATE")" == "collision-sentinel" ]] ||
    die "existing candidate was modified during collision test"

printf 'PASS: Existing candidate collision rejected\n'
printf 'PASS: Existing candidate contents preserved\n'

# Remove only the artificial collision fixture, not the
# successful candidate.
rm -r -- "$collision_path"

# Negative lifecycle test: deliberately fail Kconfig processing.
# Restore the tracked fixture source to a clean committed state;
# only the disposable archive changes for this test.
cat > "$FIXTURE/source/linux-6.16.1/Makefile" <<'BROKEN_MAKEFILE'
.PHONY: olddefconfig

olddefconfig:
	@echo "intentional fixture Kconfig failure" >&2
	@exit 42
BROKEN_MAKEFILE

tar -cJf "$FIXTURE/source.tar.xz" \
    -C "$FIXTURE/source" linux-6.16.1

# Update only the fixture's expected source hash and commit the
# modified test executable so provenance checks remain active.
python3 - "$FIXTURE" <<'HASH_PY'
from pathlib import Path
import hashlib
import re
import sys

root = Path(sys.argv[1])
script = root / "repo/scripts/kernel/build-kernel.sh"
archive = root / "source.tar.xz"

text = script.read_text()
digest = hashlib.sha256(archive.read_bytes()).hexdigest()

text, count = re.subn(
    r'^EXPECTED_SOURCE_SHA256="[0-9a-f]{64}"$',
    lambda _: f'EXPECTED_SOURCE_SHA256="{digest}"',
    text,
    flags=re.MULTILINE,
)

if count != 1:
    raise SystemExit("STOP: Fixture source-hash substitution failed")

script.write_text(text)
HASH_PY

git -C "$FIXTURE/repo" add -- scripts/kernel/build-kernel.sh
git -C "$FIXTURE/repo" \
    -c user.name="SableLinux Test" \
    -c user.email="test@localhost" \
    commit -qm "test: introduce failing Kconfig fixture"

# This must fail, and the failure must be Kconfig-specific.
if "$TEST_SCRIPT" prepare > "$TMP/prepare-failure.log" 2>&1; then
    die "broken Kconfig preparation unexpectedly succeeded"
fi

grep -Fq 'candidate Kconfig validation failed' \
    "$TMP/prepare-failure.log" ||
    die "preparation failed for an unexpected reason"

mapfile -t failed_candidates < <(
    find "$FIXTURE/workspace/kernel-builds" \
        -mindepth 1 -maxdepth 1 -type d \
        ! -path "$candidate" -print
)

[[ "${#failed_candidates[@]}" -eq 1 ]] ||
    die "expected exactly one failed candidate"

failed="${failed_candidates[0]}"

[[ "$(cat "$failed/BUILD_STATE")" == "failed" ]] ||
    die "failed preparation did not record BUILD_STATE=failed"

grep -Fq 'intentional fixture Kconfig failure' \
    "$failed/logs/olddefconfig.log" ||
    die "Kconfig failure log missing expected diagnostic"

printf 'PASS: Kconfig failure correctly rejected\n'
printf 'PASS: Failed candidate retained with BUILD_STATE=failed\n'

printf 'Fixture creation: PASS\n'
