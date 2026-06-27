#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

APP_NAME="Anchor"
APP_BUNDLE="$ROOT/dist/Anchor.app"
AURELIA_DIR="$ROOT/vendor/aurelia"
AURELIA_DIST="$ROOT/Anchor/Resources/aurelia"

echo "Building Aurelia ocean (WebGPU)..."
if [ -d "$AURELIA_DIR" ]; then
    pushd "$AURELIA_DIR" >/dev/null
    if [ ! -d node_modules ]; then
        npm install
    fi
    npm run build
    popd >/dev/null

    rm -rf "$AURELIA_DIST"
    mkdir -p "$AURELIA_DIST"
    cp -R "$AURELIA_DIR/dist/"* "$AURELIA_DIST/"
    echo "Aurelia bundle: $AURELIA_DIST"
else
    echo "Warning: vendor/aurelia not found — skipping ocean build"
fi

SOURCES=$(find "$ROOT/Anchor" -name '*.swift' -type f)

echo "Compiling $APP_NAME..."
rm -rf "$ROOT/dist"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

swiftc \
    -O \
    -target arm64-apple-macosx13.0 \
    -sdk "$(xcrun --show-sdk-path)" \
    -framework AppKit \
    -framework SwiftUI \
    -framework WebKit \
    -framework Combine \
    -framework UniformTypeIdentifiers \
    -framework AVFoundation \
    -framework Network \
    -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
    $SOURCES

cp "$ROOT/Anchor/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

if [ -d "$ROOT/Anchor/Resources" ]; then
    cp -R "$ROOT/Anchor/Resources/"* "$APP_BUNDLE/Contents/Resources/" 2>/dev/null || true
fi

if [ -f "$ROOT/Anchor/Resources/Lockedvid.mp4" ]; then
    cp "$ROOT/Anchor/Resources/Lockedvid.mp4" "$APP_BUNDLE/Contents/Resources/Lockedvid.mp4"
elif [ -f "$ROOT/Lockedvid.mp4" ]; then
    cp "$ROOT/Lockedvid.mp4" "$APP_BUNDLE/Contents/Resources/Lockedvid.mp4"
fi

ICON_MASTER="$ROOT/Anchor/Resources/AppIcon.source.png"
if [ -f "$ICON_MASTER" ]; then
    bash "$ROOT/scripts/fix-app-icon.sh"
fi
ICON_SRC="$ROOT/Anchor/Resources/AppIcon.png"
if [ -f "$ICON_SRC" ]; then
    sips --cropToHeightWidth 1024 1024 "$ICON_SRC" --out "$ICON_SRC" >/dev/null 2>&1 || true
    ICONSET="$ROOT/dist/AppIcon.iconset"
    rm -rf "$ICONSET"
    mkdir -p "$ICONSET"
    sips -z 16 16 "$ICON_SRC" --out "$ICONSET/icon_16x16.png" >/dev/null
    sips -z 32 32 "$ICON_SRC" --out "$ICONSET/icon_16x16@2x.png" >/dev/null
    sips -z 32 32 "$ICON_SRC" --out "$ICONSET/icon_32x32.png" >/dev/null
    sips -z 64 64 "$ICON_SRC" --out "$ICONSET/icon_32x32@2x.png" >/dev/null
    sips -z 128 128 "$ICON_SRC" --out "$ICONSET/icon_128x128.png" >/dev/null
    sips -z 256 256 "$ICON_SRC" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
    sips -z 256 256 "$ICON_SRC" --out "$ICONSET/icon_256x256.png" >/dev/null
    sips -z 512 512 "$ICON_SRC" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
    sips -z 512 512 "$ICON_SRC" --out "$ICONSET/icon_512x512.png" >/dev/null
    sips -z 1024 1024 "$ICON_SRC" --out "$ICONSET/icon_512x512@2x.png" >/dev/null
    if iconutil -c icns "$ICONSET" -o "$APP_BUNDLE/Contents/Resources/AppIcon.icns" 2>/dev/null; then
        rm -rf "$ICONSET"
    else
        echo "Warning: AppIcon.icns not generated — dock icon falls back to AppIcon.png"
        rm -rf "$ICONSET"
    fi
fi

chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

if [ -f "$ROOT/Anchor/Anchor.entitlements" ]; then
    codesign --force --deep --sign - \
        --entitlements "$ROOT/Anchor/Anchor.entitlements" \
        --options runtime \
        "$APP_BUNDLE" 2>/dev/null || echo "Warning: codesign failed — permissions may need re-granting after each build"
fi

echo ""
echo "Built: $APP_BUNDLE"
echo "Run:   open dist/Anchor.app"
