#!/usr/bin/env bash
# Install (or reinstall) CorporateMansLinux.saver into the user Screen Savers
# folder. Builds first if needed.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
NAME="CorporateMansLinux"
SRC="$HERE/build/$NAME.saver"
DEST_DIR="$HOME/Library/Screen Savers"
DEST="$DEST_DIR/$NAME.saver"

[ -d "$SRC" ] || { echo "» building first"; "$HERE/build.sh"; }

echo "» installing to $DEST"
mkdir -p "$DEST_DIR"
# Kill any running preview so the bundle isn't locked, then replace.
killall legacyScreenSaver ScreenSaverEngine >/dev/null 2>&1 || true
rm -rf "$DEST"
cp -R "$SRC" "$DEST"

echo
echo "✓ installed: $DEST"
echo
echo "Select it:  System Settings ▸ Screen Saver ▸ (scroll to 'Other') ▸ Corporate Man's Linux"
echo "Preview it: /System/Library/CoreServices/ScreenSaverEngine.app/Contents/MacOS/ScreenSaverEngine"
echo
echo "If it doesn't appear, log out/in (or 'killall cfprefsd') to refresh the saver list."
