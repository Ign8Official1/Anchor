#!/bin/bash
set -euo pipefail

REPO="Ign8Official1/Anchor"
INSTALL_DIR="/Applications"
APP_NAME="Anchor.app"

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

echo "→ Opening Anchor…"
open "$INSTALL_DIR/$APP_NAME"

echo "Done. Anchor is in your Applications folder."
