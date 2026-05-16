#!/bin/bash
# Rebuild the .pkg installer.
# Run from project root: ./scripts/build-pkg.sh [VERSION]
set -euo pipefail

VERSION="${1:-0.1.0}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Refresh payload from vendor
mkdir -p "pkg-payload/Library/Screen Savers"
rm -rf "pkg-payload/Library/Screen Savers/WebViewScreenSaver.saver"
cp -R "vendor/WebViewScreenSaver.saver" "pkg-payload/Library/Screen Savers/"

mkdir -p build
OUT="build/ambient-art-screensaver-${VERSION}.pkg"

pkgbuild \
  --root pkg-payload \
  --identifier net.jada.ambient-art-screensaver \
  --version "$VERSION" \
  --install-location / \
  --scripts pkg-scripts \
  "$OUT"

echo ""
echo "✓ Built: $OUT ($(du -h "$OUT" | awk '{print $1}'))"
echo "  sha256: $(shasum -a 256 "$OUT" | awk '{print $1}')"
