#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ "$(uname -s)" != "Darwin" || "$(uname -m)" != "arm64" ]]; then
  echo "Build AppLayout on an Apple Silicon Mac with Xcode 26 or later." >&2
  exit 1
fi

variant="${1:-local}"
case "$variant" in
  local) extra=(ENABLE_APP_SANDBOX=NO) ;;
  sandbox) extra=(ENABLE_APP_SANDBOX=YES CODE_SIGN_ENTITLEMENTS=Resources/Sandbox.entitlements) ;;
  *) echo "Usage: bash scripts/build.sh [local|sandbox]" >&2; exit 1 ;;
esac

xcodebuild -project AppLayout.xcodeproj -scheme AppLayout \
  -configuration Release -destination 'generic/platform=macOS' \
  -derivedDataPath "build/$variant" \
  CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= \
  "${extra[@]}" build

app="build/$variant/Build/Products/Release/AppLayout.app"
codesign --verify --deep --strict --verbose=2 "$app"
/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' "$app/Contents/Info.plist"
file "$app/Contents/MacOS/AppLayout"
echo "Built: $app"
echo "Local ad-hoc signature only. This build is not Developer ID signed or notarized."
