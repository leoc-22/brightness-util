#!/bin/bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

readonly APP_NAME="brightness-util.app"
readonly EXECUTABLE_NAME="brightness-util"
readonly CONFIGURATION="${CONFIGURATION:-Release}"
readonly DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$PROJECT_ROOT/build}"
readonly PRODUCTS_DIR="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION"
readonly APP_PATH="$PRODUCTS_DIR/$APP_NAME"
readonly INFO_PLIST_SOURCE="$PROJECT_ROOT/packaging/Info.plist"
readonly DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET:-27.0}"
readonly TARGET_ARCH="${ARCH:-$(uname -m)}"
readonly BUNDLE_VERSION="${BUNDLE_VERSION:-1}"
readonly MARKETING_VERSION="${MARKETING_VERSION:-1.0}"
readonly SIGNING_IDENTITY="${SIGNING_IDENTITY:--}"

for required_tool in xcode-select ditto plutil codesign; do
    if ! command -v "$required_tool" >/dev/null 2>&1; then
        echo "error: required tool '$required_tool' was not found" >&2
        exit 1
    fi
done

readonly ACTIVE_DEVELOPER_DIR="${DEVELOPER_DIR:-$(xcode-select -p)}"
readonly SWIFTC="$ACTIVE_DEVELOPER_DIR/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc"
readonly SDK_PATH="$ACTIVE_DEVELOPER_DIR/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"

if [[ ! -x "$SWIFTC" ]]; then
    echo "error: Swift compiler was not found at $SWIFTC" >&2
    exit 1
fi

if [[ ! -d "$SDK_PATH" ]]; then
    echo "error: macOS SDK was not found at $SDK_PATH" >&2
    exit 1
fi

if [[ ! -f "$INFO_PLIST_SOURCE" ]]; then
    echo "error: Info.plist template was not found at $INFO_PLIST_SOURCE" >&2
    exit 1
fi

mkdir -p "$PRODUCTS_DIR" "$DERIVED_DATA_PATH/ModuleCache.noindex"
staging_root="$(mktemp -d "$PRODUCTS_DIR/.brightness-util-build.XXXXXX")"
cleanup() {
    rm -rf "$staging_root"
}
trap cleanup EXIT

readonly STAGED_APP="$staging_root/$APP_NAME"
mkdir -p "$STAGED_APP/Contents/MacOS" "$STAGED_APP/Contents/Resources"
ditto "$INFO_PLIST_SOURCE" "$STAGED_APP/Contents/Info.plist"

plutil -replace CFBundleShortVersionString -string "$MARKETING_VERSION" "$STAGED_APP/Contents/Info.plist"
plutil -replace CFBundleVersion -string "$BUNDLE_VERSION" "$STAGED_APP/Contents/Info.plist"
plutil -replace LSMinimumSystemVersion -string "$DEPLOYMENT_TARGET" "$STAGED_APP/Contents/Info.plist"

compiler_flags=(
    -parse-as-library
    -target "$TARGET_ARCH-apple-macosx$DEPLOYMENT_TARGET"
    -sdk "$SDK_PATH"
    -module-cache-path "$DERIVED_DATA_PATH/ModuleCache.noindex"
    -module-name brightness_util
)

if [[ "$CONFIGURATION" == "Debug" ]]; then
    compiler_flags+=( -Onone -g -D DEBUG )
else
    compiler_flags+=( -O -whole-module-optimization )
fi

swift_sources=( "$PROJECT_ROOT"/brightness-util/*.swift )

echo "Building $APP_NAME ($CONFIGURATION, $TARGET_ARCH)..."
"$SWIFTC" \
    "${compiler_flags[@]}" \
    "${swift_sources[@]}" \
    -o "$STAGED_APP/Contents/MacOS/$EXECUTABLE_NAME" \
    "$@"

echo "Signing $APP_NAME with identity '$SIGNING_IDENTITY'..."
codesign --force --sign "$SIGNING_IDENTITY" --timestamp=none "$STAGED_APP"
codesign --verify --strict "$STAGED_APP"

rm -rf "$APP_PATH"
mv "$STAGED_APP" "$APP_PATH"

echo "Created $APP_PATH"
