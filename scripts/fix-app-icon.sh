#!/bin/bash
# Remove pure-black matte from AppIcon using sips + pngcrush, or compiled fix-icon tool.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MASTER="$ROOT/Anchor/Resources/AppIcon.source.png"
OUT="$ROOT/Anchor/Resources/AppIcon.png"
TOOL="$ROOT/dist/fix-icon"

if [ ! -f "$MASTER" ]; then
  echo "Missing AppIcon.source.png"
  exit 0
fi

cp "$MASTER" "$OUT"

if [ ! -x "$TOOL" ]; then
  swiftc -O "$ROOT/scripts/fix-icon.swift" -o "$TOOL" 2>/dev/null || true
fi

if [ -x "$TOOL" ]; then
  "$TOOL" "$OUT"
  echo "Fixed: $OUT"
fi
