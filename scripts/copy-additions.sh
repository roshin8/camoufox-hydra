#!/bin/bash

# Copies additions and settings into the Firefox source directory.
# Must be run from within the source directory.
# Matches Camoufox's copy-additions.sh flow.

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <version> <release>"
    exit 1
fi

version="$1"
release="$2"

run() {
    echo "$ $1"
    eval "$1"
    if [ $? -ne 0 ]; then
        echo "Command failed: $1"
        exit 1
    fi
}

# Copy settings into lw/ directory
run 'mkdir -p lw'
pushd lw > /dev/null
run 'cp -v ../../settings/hydra.cfg camoufox.cfg'
[ -f ../../settings/policies.json ] && run 'cp -v ../../settings/policies.json .'
[ -f ../../settings/local-settings.js ] && run 'cp -v ../../settings/local-settings.js .'
[ -f ../../settings/chrome.css ] && run 'cp -v ../../settings/chrome.css .'
[ -f ../../settings/properties.json ] && run 'cp -v ../../settings/properties.json .'
run 'touch moz.build'
popd > /dev/null

# Copy librewolf pack_vs.py (referenced by build system)
run 'cp -v ../patches/librewolf/pack_vs.py build/vs/' || true

# Copy ALL new files/folders from additions to source
run 'cp -r ../additions/* .'

# Override the firefox version
for file in "browser/config/version.txt" "browser/config/version_display.txt"; do
    echo "${version}-${release}" > "$file"
done

echo "Additions and settings copied successfully."
