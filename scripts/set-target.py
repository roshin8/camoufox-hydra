#!/usr/bin/env python3
"""Set the cross-compile target in mozconfig based on BUILD_TARGET env var."""

import os
import sys

TARGETS = {
    ("linux", "x86_64"): "x86_64-pc-linux-gnu",
    ("linux", "arm64"): "aarch64-unknown-linux-gnu",
    ("linux", "i686"): "i686-pc-linux-gnu",
    ("macos", "x86_64"): "x86_64-apple-darwin",
    ("macos", "arm64"): "aarch64-apple-darwin",
    ("windows", "x86_64"): "x86_64-pc-mingw32",
    ("windows", "i686"): "i686-pc-mingw32",
}

src_dir = sys.argv[1] if len(sys.argv) > 1 else "firefox-src"
build_target = os.environ.get("BUILD_TARGET", "")

if not build_target:
    print("No BUILD_TARGET set, using default (host platform)")
    sys.exit(0)

parts = build_target.split(",")
if len(parts) != 2:
    print(f"Invalid BUILD_TARGET: {build_target} (expected 'platform,arch')")
    sys.exit(1)

target, arch = parts
moz_target = TARGETS.get((target, arch))
if not moz_target:
    print(f"Unknown target: {target},{arch}")
    sys.exit(1)

mozconfig = os.path.join(src_dir, "mozconfig")

# Create mozconfig from base.mozconfig if it doesn't exist (like patch.py does)
base_mozconfig = os.path.join(os.path.dirname(src_dir), "assets", "base.mozconfig")
if not os.path.exists(mozconfig) and os.path.exists(base_mozconfig):
    import shutil
    shutil.copy2(base_mozconfig, mozconfig)

# Read existing mozconfig and remove any prior --target line
if os.path.exists(mozconfig):
    with open(mozconfig, "r") as f:
        lines = [l for l in f.readlines() if "--target=" not in l]
else:
    lines = []

lines.append(f"ac_add_options --target={moz_target}\n")

with open(mozconfig, "w") as f:
    f.writelines(lines)

print(f"Set target: {moz_target}")
