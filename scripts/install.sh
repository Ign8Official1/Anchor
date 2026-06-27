#!/bin/bash
set -euo pipefail

REPO="Ign8Official1/Anchor"
INSTALL_DIR="/Applications"
APP_NAME="Anchor.app"

ARCH=$(uname -m)
if [ "$ARCH" != "arm64" ]; then
  echo "⚠  Pre-built Anchor is for Apple Silicon Macs (M1 or newer) only."
  echo "   This Mac reports: $ARCH"
  echo "   Intel Mac? Build from source: https://github.com/Ign8Official1/Anchor#build-from-source"
  exit 1
fi

MACOS_MAJOR=$(sw_vers -productVersion | cut -d. -f1)
if [ "$MACOS_MAJOR" -lt 13 ]; then
  echo "⚠  Anchor requires macOS 13 Ventura or later."
  echo "   You're on macOS $(sw_vers -productVersion)"
  exit 1
fi

echo "→ Downloading Anchor…"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

ZIP_URL="https://github.com/${REPO}/releases/latest/download/Anchor-macOS.zip"
curl -fsSL -o "$TMP/Anchor.zip" "$ZIP_URL"
unzip -q "$TMP/Anchor.zip" -d "$TMP"

APP_SRC="$TMP/$APP_NAME"
if [ ! -d "$APP_SRC" ]; then
  echo "Download failed — Anchor.app not found in the release."
  exit 1
fi

xattr -cr "$APP_SRC"

if [ -d "$INSTALL_DIR/$APP_NAME" ]; then
  echo "→ Replacing existing Anchor in Applications…"
  rm -rf "$INSTALL_DIR/$APP_NAME"
fi

echo "→ Installing to Applications…"
cp -R "$APP_SRC" "$INSTALL_DIR/"

echo ""
echo "⚠  macOS may block the first launch (Anchor isn't from the App Store)."
echo "   If Anchor doesn't open:"
echo "   1. Go to Applications"
echo "   2. Right-click Anchor → Open"
echo "   3. Click Open again in the dialog"
echo "   Or check System Settings → Privacy & Security → Open Anyway"
echo ""

echo "→ Opening Anchor…"
if ! open "$INSTALL_DIR/$APP_NAME" 2>/dev/null; then
  echo "Couldn't launch automatically — use right-click → Open in Applications."
else
  echo "Done. Anchor is in your Applications folder."
fi
