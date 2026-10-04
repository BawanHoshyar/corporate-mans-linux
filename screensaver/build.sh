#!/usr/bin/env bash
# Build CorporateMansLinux.saver from the Swift sources.
# Produces ./build/CorporateMansLinux.saver — run ./install.sh to install it.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
NAME="CorporateMansLinux"
SAVER="$HERE/build/$NAME.saver"
CONTENTS="$SAVER/Contents"
TARGET="arm64-apple-macos12"          # Apple Silicon; change for Intel

echo "» cleaning build/"
rm -rf "$HERE/build"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"

echo "» compiling ($TARGET)"
xcrun swiftc \
    "$HERE/Sources/Scene.swift" \
    "$HERE/Sources/SaverView.swift" \
    -o "$CONTENTS/MacOS/$NAME" \
    -module-name "$NAME" \
    -target "$TARGET" \
    -O \
    -framework ScreenSaver -framework AppKit -framework CoreText \
    -emit-library

echo "» Info.plist"
cp "$HERE/Info.plist" "$CONTENTS/Info.plist"

echo "» bundling fonts"
FDIR="$HOME/Library/Fonts"
for f in JetBrainsMono-ExtraBold JetBrainsMono-Bold JetBrainsMono-Medium JetBrainsMono-Regular; do
    if [ -f "$FDIR/$f.ttf" ]; then
        cp "$FDIR/$f.ttf" "$CONTENTS/Resources/"
    else
        echo "  warn: $f.ttf not found in $FDIR (will fall back to Menlo)"
    fi
done

echo "» ad-hoc signing"
codesign --force --deep --sign - "$SAVER" >/dev/null 2>&1 \
    && echo "  signed (ad-hoc)" \
    || echo "  codesign skipped/failed (usually still loads locally)"

echo
echo "✓ built: $SAVER"
echo "  next:  ./install.sh"
