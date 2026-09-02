#!/bin/bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

readonly APP_NAME="brightness-util.app"

readonly CONFIGURATION="${CONFIGURATION:-Release}"
readonly DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$PROJECT_ROOT/build}"
readonly DIST_DIR="${DIST_DIR:-$PROJECT_ROOT/dist}"
readonly OUTPUT_DMG="${OUTPUT_DMG:-$DIST_DIR/brightness-util.dmg}"
readonly VOLUME_NAME="${VOLUME_NAME:-Brightness Util}"
readonly SKIP_BUILD="${SKIP_BUILD:-0}"
readonly APP_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/$APP_NAME"

for required_tool in ditto; do
    if ! command -v "$required_tool" >/dev/null 2>&1; then
        echo "error: required tool '$required_tool' was not found" >&2
        exit 1
    fi
done

if [[ "$SKIP_BUILD" == "1" ]]; then
    echo "Skipping app build; using $APP_PATH"
else
    "$SCRIPT_DIR/build-app.sh" "$@"
fi

if [[ ! -d "$APP_PATH" ]]; then
    echo "error: expected app bundle was not produced at $APP_PATH" >&2
    exit 1
fi

mkdir -p "$(dirname "$OUTPUT_DMG")"

staging_dir="$(mktemp -d "${TMPDIR:-/tmp}/brightness-util-dmg.XXXXXX")"
cleanup() {
    rm -rf "$staging_dir"
}
trap cleanup EXIT

echo "Staging disk image contents..."
ditto "$APP_PATH" "$staging_dir/$APP_NAME"
ln -s /Applications "$staging_dir/Applications"

echo "Creating $OUTPUT_DMG..."
rm -f "$OUTPUT_DMG"
if command -v diskutil >/dev/null 2>&1 && diskutil image create --help >/dev/null 2>&1; then
    diskutil image create from \
        --format UDZO \
        --volumeName "$VOLUME_NAME" \
        "$staging_dir" \
        "$OUTPUT_DMG"
elif command -v hdiutil >/dev/null 2>&1; then
    hdiutil create \
        -volname "$VOLUME_NAME" \
        -srcfolder "$staging_dir" \
        -format UDZO \
        "$OUTPUT_DMG"
else
    echo "error: neither diskutil image nor hdiutil is available" >&2
    exit 1
fi

echo "Created $OUTPUT_DMG"
