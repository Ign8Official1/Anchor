#!/bin/bash
# Place your own clips in the repo root, then run this script:
#   Video 2160p 60fps.mp4      → public/videos/surface.mp4 (web-optimized)
#   Underwater Video 13704.mp4 → public/videos/underwater.mp4
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO="$(cd "$ROOT/.." && pwd)"
OUT="$ROOT/public/videos"
mkdir -p "$OUT"

SURFACE_SRC="$REPO/Video 2160p 60fps.mp4"
UNDER_SRC="$REPO/Underwater Video 13704.mp4"

if [ ! -f "$UNDER_SRC" ]; then
  echo "Missing: $UNDER_SRC"
  exit 1
fi

cp "$UNDER_SRC" "$OUT/underwater.mp4"
echo "Installed underwater.mp4"

if [ -f "$SURFACE_SRC" ] && command -v ffmpeg >/dev/null; then
  ffmpeg -y -i "$SURFACE_SRC" \
    -vf "scale=-2:1920" -r 30 -c:v libx264 -preset fast -crf 24 -an -movflags +faststart \
    "$OUT/surface.mp4" 2>/dev/null
  echo "Built surface.mp4 from 2160p source"
elif [ -f "$SURFACE_SRC" ]; then
  cp "$SURFACE_SRC" "$OUT/surface.mp4"
  echo "Copied surface (install ffmpeg to compress)"
else
  echo "Missing surface source: $SURFACE_SRC"
  exit 1
fi

ls -lh "$OUT"
