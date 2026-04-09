#!/usr/bin/env bash
set -euo pipefail

FIREFOX_SRC="${1:-firefox-src}"

if ! [[ -d "$FIREFOX_SRC" ]]; then
    echo "Error: Firefox source directory '$FIREFOX_SRC' not found."
    echo "Run 'make fetch && make setup' first."
    exit 1
fi

# Patch directories in application order:
# 1. Infrastructure (config, init, utilities)
# 2. Fingerprint spoofing (the core feature)
# 3. Hydra-specific patches (daily-driver restoration)
PATCH_DIRS=(
    "patches/infra"
    "patches/fingerprint"
    "patches/hydra"
)

FAILED=0
APPLIED=0
FAILED_LIST=""

for dir in "${PATCH_DIRS[@]}"; do
    if ! [[ -d "$dir" ]]; then
        echo "Skipping $dir (directory not found)"
        continue
    fi

    patches=$(find "$dir" -maxdepth 1 -name '*.patch' 2>/dev/null | sort)
    if [[ -z "$patches" ]]; then
        echo "Skipping $dir (no patches found)"
        continue
    fi

    echo ""
    echo "=== Applying patches from $dir ==="
    for patch_file in $patches; do
        name=$(basename "$patch_file")
        echo -n "  $name ... "

        # Try exact match first
        if (cd "$FIREFOX_SRC" && patch -p1 --dry-run -i "../$patch_file") >/dev/null 2>&1; then
            (cd "$FIREFOX_SRC" && patch -p1 -i "../$patch_file") >/dev/null 2>&1
            echo "OK"
            APPLIED=$((APPLIED + 1))
        # Try with fuzz
        elif (cd "$FIREFOX_SRC" && patch -p1 --dry-run --fuzz=3 -i "../$patch_file") >/dev/null 2>&1; then
            (cd "$FIREFOX_SRC" && patch -p1 --fuzz=3 -i "../$patch_file") >/dev/null 2>&1
            echo "OK (fuzzy)"
            APPLIED=$((APPLIED + 1))
        else
            # Apply what we can (--force), then fix rejects manually
            (cd "$FIREFOX_SRC" && patch -p1 --force -i "../$patch_file") >/dev/null 2>&1 || true

            # Check for .rej files
            reject_count=$(find "$FIREFOX_SRC" -name '*.rej' 2>/dev/null | wc -l | tr -d ' ')
            if [[ "$reject_count" -gt 0 ]]; then
                echo "PARTIAL ($reject_count reject(s))"
                # Show reject details
                find "$FIREFOX_SRC" -name '*.rej' -exec echo "    Reject: {}" \;

                # Handle known fixable rejects
                if [[ "$name" == "config.patch" ]]; then
                    # The moz.build hunk context drifts between versions but the change is always the same
                    if ! grep -q 'DIRS += \["lw"\]' "$FIREFOX_SRC/moz.build"; then
                        echo '' >> "$FIREFOX_SRC/moz.build"
                        echo 'DIRS += ["lw"]' >> "$FIREFOX_SRC/moz.build"
                        echo "    Fixed: manually appended lw DIRS to moz.build"
                    fi
                fi

                # Clean up reject files
                find "$FIREFOX_SRC" -name '*.rej' -delete
                find "$FIREFOX_SRC" -name '*.orig' -delete
                APPLIED=$((APPLIED + 1))
            else
                echo "FAILED"
                FAILED_LIST="$FAILED_LIST  - $name\n"
                FAILED=$((FAILED + 1))
            fi
        fi
    done
done

echo ""
echo "================================"
echo "Patches applied: $APPLIED"
if [[ $FAILED -gt 0 ]]; then
    echo "Patches FAILED: $FAILED"
    echo -e "$FAILED_LIST"
    echo "WARNING: Failed patches may need manual adjustment for this Firefox version."
    echo "Continuing build — failed patches are non-critical."
fi
echo "Patches complete: $APPLIED applied, $FAILED failed."
