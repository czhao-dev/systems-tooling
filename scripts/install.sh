#!/usr/bin/env bash
# Installs SysDoctor by copying it into a prefix and symlinking the
# entrypoint onto PATH. Defaults to /usr/local; pass --prefix for a
# user-local install that doesn't require sudo (e.g. --prefix "$HOME/.local").
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PREFIX="/usr/local"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --prefix)
            PREFIX="$2"
            shift 2
            ;;
        --help|-h)
            cat <<EOF
Usage: install.sh [--prefix PATH]

Installs SysDoctor under PREFIX/lib/sysdoctor and symlinks
PREFIX/bin/sysdoctor to its entrypoint.

Default prefix: /usr/local
For a user-local install without sudo: install.sh --prefix "\$HOME/.local"
EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 2
            ;;
    esac
done

LIB_TARGET="$PREFIX/lib/sysdoctor"
BIN_TARGET="$PREFIX/bin/sysdoctor"

mkdir -p "$LIB_TARGET" "$PREFIX/bin"
cp -R "$ROOT_DIR/lib" "$LIB_TARGET/"
cp "$ROOT_DIR/sysdoctor.sh" "$LIB_TARGET/sysdoctor.sh"
chmod +x "$LIB_TARGET/sysdoctor.sh"

ln -sf "$LIB_TARGET/sysdoctor.sh" "$BIN_TARGET"

echo "Installed SysDoctor to $LIB_TARGET"
echo "Symlinked $BIN_TARGET -> $LIB_TARGET/sysdoctor.sh"

if ! command -v sysdoctor >/dev/null 2>&1; then
    echo "Note: $PREFIX/bin is not on your PATH. Add it to use the 'sysdoctor' command directly."
fi
