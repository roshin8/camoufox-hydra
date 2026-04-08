#!/usr/bin/env bash
set -euo pipefail

FIREFOX_SRC="${1:-firefox-src}"
EXTENSION_DIR="extension"
XPI_NAME="hydra-shield@camoufox-hydra.xpi"
DIST_EXTENSIONS="$FIREFOX_SRC/distribution/extensions"

if ! [[ -d "$EXTENSION_DIR/dist" ]]; then
    echo "Error: Extension not built. Run 'make extension' first."
    exit 1
fi

echo "Packaging extension as XPI..."
mkdir -p "$DIST_EXTENSIONS"

cd "$EXTENSION_DIR/dist"
zip -r "../../$DIST_EXTENSIONS/$XPI_NAME" . -x '*.map'

echo "Extension bundled at $DIST_EXTENSIONS/$XPI_NAME"
