#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

mkdir -p "$SCRIPT_DIR/.build/cache"
export CLANG_MODULE_CACHE_PATH="$SCRIPT_DIR/.build/cache"

echo "🔨 Building GHelperMac (Release)..."
DEVELOPER_DIR="/Applications/Xcode-beta.app/Contents/Developer" \
swift build -c release --disable-sandbox -Xswiftc -module-cache-path -Xswiftc "$SCRIPT_DIR/.build/cache"

APP_NAME="GHelperMac.app"
APP_DIR="$SCRIPT_DIR/$APP_NAME"
MACOS_DIR="$APP_DIR/Contents/MacOS"
RESOURCES_DIR="$APP_DIR/Contents/Resources"

echo "📦 Packaging $APP_NAME..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy binary and resources
cp .build/release/GHelperMac "$MACOS_DIR/GHelperMac"
if [ -d "$SCRIPT_DIR/Sources/Resources" ]; then
    cp -r "$SCRIPT_DIR/Sources/Resources/"* "$RESOURCES_DIR/" 2>/dev/null || true
fi

# Write Info.plist
cat <<EOF > "$APP_DIR/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>GHelperMac</string>
    <key>CFBundleIdentifier</key>
    <string>com.ghelper.mac</string>
    <key>CFBundleName</key>
    <string>GHelper Mac</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "🔏 Code signing $APP_NAME..."
codesign --force --deep -s - "$APP_DIR"

echo "✅ Successfully built and packaged: $APP_DIR"
