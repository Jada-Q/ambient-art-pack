#!/bin/bash
# Build Ambient.app from main.swift
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

APP_NAME="Ambient"
BUNDLE_ID="net.jada.ambient"
VERSION="${1:-0.1.0}"

APP_DIR="build/$APP_NAME.app"
CONTENTS="$APP_DIR/Contents"

# Clean
rm -rf "$APP_DIR"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"

# Compile Swift
echo "→ compiling..."
swiftc -O \
  -o "$CONTENTS/MacOS/$APP_NAME" \
  -framework Cocoa \
  -framework WebKit \
  src/main.swift

# Info.plist
cat > "$CONTENTS/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>Ambient</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
    <key>NSHumanReadableCopyright</key>
    <string>Made with Claude Code · github.com/Jada-Q/ambient-art-pack</string>
</dict>
</plist>
EOF

# Sign ad-hoc
echo "→ ad-hoc signing..."
codesign --force --deep --sign - "$APP_DIR"

# Verify
echo ""
echo "✓ Built: $APP_DIR"
du -sh "$APP_DIR"
echo ""
codesign -dv "$APP_DIR" 2>&1 | head -3
