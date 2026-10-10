#!/bin/bash
set -e

# Change directory to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

APP_NAME="MediaGrab"
VERSION="1.0.0"
DIST_DIR="$PROJECT_ROOT/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
DMG_OUTPUT="$DIST_DIR/$APP_NAME-v$VERSION.dmg"
ZIP_OUTPUT="$DIST_DIR/$APP_NAME-v$VERSION.zip"

echo "=========================================="
echo " Building and Packaging $APP_NAME v$VERSION "
echo "=========================================="

# 1. Clean & Build Release binary
echo "==> Compiling Release binary via SwiftPM..."
swift build -c release

RELEASE_BIN="$(swift build -c release --show-bin-path)/$APP_NAME"
if [ ! -f "$RELEASE_BIN" ]; then
    echo "Error: Release binary not found at $RELEASE_BIN"
    exit 1
fi

# 2. Prepare Application Bundle Directory
echo "==> Creating $APP_NAME.app bundle structure..."
rm -rf "$DIST_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# 3. Copy Executable, Info.plist, and AppIcon
cp "$RELEASE_BIN" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

if [ -f "$PROJECT_ROOT/Resources/Info.plist" ]; then
    cp "$PROJECT_ROOT/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
else
    echo "Warning: Resources/Info.plist missing!"
fi

if [ -f "$PROJECT_ROOT/Resources/AppIcon.icns" ]; then
    cp "$PROJECT_ROOT/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
else
    echo "Warning: Resources/AppIcon.icns missing!"
fi

# 4. Ad-hoc Code Signing for macOS Gatekeeper
echo "==> Signing application bundle (ad-hoc)..."
codesign --force --deep --sign - "$APP_BUNDLE"

# 5. Create Distribution Zip Archive
echo "==> Creating distribution Zip archive..."
ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE" "$ZIP_OUTPUT"

# 6. Create Distribution DMG Disk Image
echo "==> Creating distribution DMG installer..."
DMG_STAGING="$DIST_DIR/dmg_staging"
mkdir -p "$DMG_STAGING"
cp -R "$APP_BUNDLE" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

hdiutil create \
    -volname "$APP_NAME Installer" \
    -srcfolder "$DMG_STAGING" \
    -ov \
    -format UDZO \
    "$DMG_OUTPUT"

rm -rf "$DMG_STAGING"

echo "=========================================="
echo " Packaging Completed Successfully! "
echo " Release Assets generated in: $DIST_DIR "
ls -lh "$DIST_DIR"
echo "=========================================="
