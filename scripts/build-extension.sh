#!/usr/bin/env bash
set -euo pipefail

EXTENSION_DIR="extension"

echo "Building Hydra Shield extension..."

cd "$EXTENSION_DIR"

if ! [[ -d "node_modules" ]]; then
    echo "Installing dependencies..."
    npm ci
fi

echo "Running production build..."
npm run build:prod

echo "Extension built successfully at $EXTENSION_DIR/dist/"
