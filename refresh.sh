#!/usr/bin/env bash
# Refresh the decompiled vanilla Celeste source tree.
#
# Idempotent: hashes orig/Celeste.exe and only re-decompiles when the game
# binary changed. Serialized via flock so concurrent agents don't collide.
# The resulting source/ tree is made read-only on purpose (see AGENT.md).
#
# Prints the absolute path to source/ on the LAST line of stdout, so other
# tooling can capture it:  SOURCE_DIR="$(./refresh.sh | tail -n 1)"
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$REPO_DIR/source"
TMP_DIR="$REPO_DIR/source.tmp"
OLD_DIR="$REPO_DIR/source.old"
STAMP_FILE="$SOURCE_DIR/.stamp"
LOCK_FILE="$REPO_DIR/.lock"

die()  { printf '[refresh] error: %s\n' "$*" >&2; exit 1; }
info() { printf '[refresh] %s\n' "$*" >&2; }

# --- Resolve the Celeste install directory -------------------------------
# Priority: $CELESTE_DIR env var, then .celeste-path, then the default
# Debian-style Steam path.
CONFIG_FILE="$REPO_DIR/.celeste-path"
if [[ -n "${CELESTE_DIR:-}" ]]; then
    :
elif [[ -f "$CONFIG_FILE" ]]; then
    CELESTE_DIR="$(head -n 1 "$CONFIG_FILE" \
        | sed -e '1s/^\xEF\xBB\xBF//' -e 's/\r$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    CELESTE_DIR="${CELESTE_DIR%\"}"
    CELESTE_DIR="${CELESTE_DIR#\"}"
    CELESTE_DIR="${CELESTE_DIR/#\~/$HOME}"
else
    CELESTE_DIR="$HOME/.steam/debian-installation/steamapps/common/Celeste"
fi
[[ -n "$CELESTE_DIR" ]] || die "Celeste directory is empty"
[[ "$CELESTE_DIR" == /* ]] || die "Celeste path must be absolute: $CELESTE_DIR"

ASSEMBLY="$CELESTE_DIR/orig/Celeste.exe"
[[ -f "$ASSEMBLY" ]] || die "No orig/Celeste.exe under '$CELESTE_DIR' (Everest keeps the vanilla Windows build there)"

command -v ilspycmd   >/dev/null 2>&1 || die "ilspycmd not found (install: dotnet tool install -g ilspycmd)"
command -v sha256sum  >/dev/null 2>&1 || die "sha256sum not found"
command -v flock      >/dev/null 2>&1 || die "flock not found"

# --- Fast path: unchanged game binary ------------------------------------
CUR_HASH="$(sha256sum "$ASSEMBLY" | awk '{print $1}')"
if [[ -f "$STAMP_FILE" ]]; then
    OLD_HASH="$(head -n 1 "$STAMP_FILE" | awk '{print $1}')"
    if [[ -n "$OLD_HASH" && "$OLD_HASH" == "$CUR_HASH" ]]; then
        info "up to date ($ASSEMBLY unchanged)"
        printf '%s\n' "$SOURCE_DIR"
        exit 0
    fi
fi

# --- Serialize concurrent refreshes --------------------------------------
exec 9>"$LOCK_FILE"
flock 9

info "decompiling $ASSEMBLY -> $TMP_DIR"
rm -rf "$TMP_DIR" "$OLD_DIR"
mkdir -p "$TMP_DIR"

if ! ilspycmd -p -o "$TMP_DIR" -r "$CELESTE_DIR" "$ASSEMBLY" >&2; then
    info "decompile failed; keeping existing source/"
    rm -rf "$TMP_DIR"
    exit 1
fi

printf '%s\n' "$CUR_HASH" > "$TMP_DIR/.stamp"
chmod -R a-w "$TMP_DIR"

# --- Swap: make the old tree writable again so it can be deleted ---------
if [[ -d "$SOURCE_DIR" ]]; then
    mv "$SOURCE_DIR" "$OLD_DIR"
fi
mv "$TMP_DIR" "$SOURCE_DIR"
if [[ -d "$OLD_DIR" ]]; then
    chmod -R u+w "$OLD_DIR"
    rm -rf "$OLD_DIR"
fi

info "done"
printf '%s\n' "$SOURCE_DIR"
