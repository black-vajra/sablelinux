#!/bin/sh
set -eu

TARGET_ROOT="${1:-/}"
PROFILE="$TARGET_ROOT/etc/profile"

if [ ! -f "$PROFILE" ]; then
    echo "ERROR: missing $PROFILE" >&2
    exit 1
fi

if grep -q '/etc/profile.d' "$PROFILE"; then
    echo "profile.d support already present in $PROFILE"
    exit 0
fi

cp -a "$PROFILE" "$PROFILE.bak.$(date +%Y%m%d-%H%M%S)"

python3 - "$PROFILE" <<'PY'
from pathlib import Path
import sys

profile = Path(sys.argv[1])
text = profile.read_text()

block = '''
# Source system-wide profile fragments.
if [ -d /etc/profile.d ]; then
  for script in /etc/profile.d/*.sh; do
    if [ -r "$script" ]; then
      source "$script"
    fi
  done
  unset script
fi

'''

marker = "# End /etc/profile"
if marker in text:
    text = text.replace(marker, block + marker, 1)
else:
    text = text.rstrip() + "\n\n" + block

profile.write_text(text)
PY

echo "Installed profile.d support into $PROFILE"
