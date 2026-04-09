SHELL := /bin/bash

# Versions — sourced from UPSTREAM_VERSION
include UPSTREAM_VERSION

FIREFOX_SRC := firefox-src
FF_TARBALL := firefox-$(FIREFOX_VERSION).source.tar.xz
EXTENSION_DIR := extension
DIST_DIR := $(FIREFOX_SRC)/distribution

.PHONY: all fetch setup patch config additions extension build package run \
        clean distclean help

all: fetch setup patch additions config extension build

help:
	@echo "Camoufox Hydra Build System"
	@echo ""
	@echo "  Native build (requires toolchain):"
	@echo "    make fetch      Download Firefox source tarball"
	@echo "    make setup      Extract tarball and init git repo"
	@echo "    make patch      Apply C++ patches"
	@echo "    make additions  Copy Camoufox additions (MaskConfig, branding)"
	@echo "    make config     Copy Hydra config (policies, prefs, mozconfig)"
	@echo "    make extension  Build Hydra Shield extension"
	@echo "    make build      Compile Firefox (45-90 min on Apple Silicon)"
	@echo "    make package    Create macOS DMG"
	@echo "    make run        Launch the built browser"
	@echo "    make all        Full pipeline (fetch → build)"
	@echo ""
	@echo "  Cleanup:"
	@echo "    make clean      Remove build artifacts"
	@echo "    make distclean  Remove everything including source"
	@echo ""

# Download Firefox source tarball
fetch:
	scripts/fetch-firefox.sh $(FIREFOX_VERSION)

# Extract tarball into firefox-src and init a git repo for patch management
setup: $(FF_TARBALL)
	@if [ -d $(FIREFOX_SRC) ]; then \
		echo "$(FIREFOX_SRC) already exists. Run 'make distclean' to start fresh."; \
		exit 0; \
	fi
	mkdir -p $(FIREFOX_SRC)
	tar -xJf $(FF_TARBALL) -C $(FIREFOX_SRC) --strip-components=1
	cd $(FIREFOX_SRC) && git init -b main && git add -f -A && git commit -m "Initial Firefox $(FIREFOX_VERSION)"
	@echo "Firefox source ready at $(FIREFOX_SRC)"

# Apply all C++ patches (infra first, then fingerprint, then hydra)
patch: $(FIREFOX_SRC)
	scripts/apply-patches.sh $(FIREFOX_SRC)

# Copy Camoufox additions into source tree (MaskConfig, branding, etc.)
additions: $(FIREFOX_SRC)
	cp -r additions/* $(FIREFOX_SRC)/
	@echo "Additions copied into $(FIREFOX_SRC)"

# Copy Hydra-specific config files into Firefox source tree
# The lw/ directory is referenced by config.patch's moz.build and needs all these files
config: $(FIREFOX_SRC)
	mkdir -p $(DIST_DIR)
	cp config/policies.json $(DIST_DIR)/policies.json
	mkdir -p $(FIREFOX_SRC)/lw
	cp config/hydra.cfg $(FIREFOX_SRC)/lw/camoufox.cfg
	cp config/policies.json $(FIREFOX_SRC)/lw/policies.json
	cp config/local-settings.js $(FIREFOX_SRC)/lw/local-settings.js
	cp config/chrome.css $(FIREFOX_SRC)/lw/chrome.css
	cp config/properties.json $(FIREFOX_SRC)/lw/properties.json
	cp mozconfig $(FIREFOX_SRC)/mozconfig

# Build and bundle the Hydra Shield extension
extension:
	cd $(EXTENSION_DIR) && npm ci && npm run build:prod
	scripts/bundle-extension.sh $(FIREFOX_SRC)

# Bootstrap build environment (first-time only)
bootstrap: $(FIREFOX_SRC)
	cd $(FIREFOX_SRC) && MOZBUILD_STATE_PATH=$$HOME/.mozbuild ./mach --no-interactive bootstrap --application-choice=browser

# Compile Firefox with applied patches
build: $(FIREFOX_SRC)
	cd $(FIREFOX_SRC) && ./mach build

# Launch the built browser
run:
	cd $(FIREFOX_SRC) && ./mach run

# Create macOS DMG
package:
	scripts/package-dmg.sh $(FIREFOX_SRC)

# Remove build artifacts (keeps source and patches)
clean:
	rm -rf $(FIREFOX_SRC)/obj-*
	rm -rf $(EXTENSION_DIR)/dist
	rm -f *.dmg

# Full clean including Firefox source
distclean: clean
	rm -rf $(FIREFOX_SRC)
	rm -rf $(EXTENSION_DIR)/node_modules

$(FF_TARBALL):
	@echo "Firefox tarball not found. Run 'make fetch' first."
	@exit 1

$(FIREFOX_SRC):
	@echo "Firefox source not found. Run 'make fetch && make setup' first."
	@exit 1
