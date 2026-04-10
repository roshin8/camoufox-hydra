include upstream.sh
export

cf_source_dir := firefox-src
ff_source_tarball := firefox-$(version).source.tar.xz

.PHONY: help fetch setup setup-minimal clean distclean build package \
        patch unpatch dir run mozbootstrap bootstrap extension

help:
	@echo "Camoufox Hydra Build System"
	@echo ""
	@echo "  make fetch         Download Firefox source tarball"
	@echo "  make setup-minimal Extract source and copy additions (for CI/Docker)"
	@echo "  make setup         setup-minimal + git init (for development)"
	@echo "  make mozbootstrap  Bootstrap mach build environment"
	@echo "  make dir           Apply patches and prepare source"
	@echo "  make extension     Build Hydra Shield extension"
	@echo "  make build         Compile Firefox"
	@echo "  make run           Launch the built browser"
	@echo "  make clean         Remove build artifacts"
	@echo "  make distclean     Remove everything including source"
	@echo ""

fetch:
	scripts/fetch-firefox.sh $(version)

setup-minimal:
	if [ ! -f $(ff_source_tarball) ]; then \
		make fetch; \
	fi
	rm -rf $(cf_source_dir)
	mkdir -p $(cf_source_dir)
	tar -xJf $(ff_source_tarball) -C $(cf_source_dir) --strip-components=1
	cd $(cf_source_dir) && bash ../scripts/copy-additions.sh $(version) $(release)

setup: setup-minimal
	cd $(cf_source_dir) && \
		git init -b main && \
		git add -f -A && \
		git commit -m "Initial commit" && \
		git tag -a unpatched -m "Initial commit"

mozbootstrap:
	cd $(cf_source_dir) && MOZBUILD_STATE_PATH=$$HOME/.mozbuild ./mach --no-interactive bootstrap --application-choice=browser

bootstrap: dir
	make mozbootstrap

dir:
	@if [ ! -d $(cf_source_dir) ]; then \
		make setup; \
	fi
	# Fix mach logging bug
	python3 scripts/fix-mach-logging.py $(cf_source_dir)
	# Copy base mozconfig and set target
	cd $(cf_source_dir) && cp -v ../assets/base.mozconfig mozconfig
	# Apply all patches (sorted by basename, like Camoufox's list_patches)
	# Fail immediately if any patch fails — don't silently skip
	cd $(cf_source_dir) && \
		for p in $$(find ../patches -maxdepth 1 -name '*.patch' | sort -t/ -k3); do \
			echo "Applying: $$p"; \
			patch -p1 -i "$$p" || exit 1; \
		done
	touch $(cf_source_dir)/_READY

extension:
	cd extension && npm ci && npm run build:prod

build:
	@if [ ! -f $(cf_source_dir)/_READY ]; then \
		make dir; \
	fi
	cd $(cf_source_dir) && ./mach build

run:
	cd $(cf_source_dir) && ./mach run

package:
	scripts/package-dmg.sh $(cf_source_dir)

clean:
	rm -rf $(cf_source_dir)/obj-*
	rm -rf extension/dist
	rm -f *.dmg

distclean: clean
	rm -rf $(cf_source_dir)
	rm -rf extension/node_modules
	rm -f $(ff_source_tarball)

patch:
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "Usage: make patch ./patches/file.patch"; \
		exit 1; \
	fi
	cd $(cf_source_dir) && patch -p1 -i ../$(filter-out $@,$(MAKECMDGOALS))

unpatch:
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "Usage: make unpatch ./patches/file.patch"; \
		exit 1; \
	fi
	cd $(cf_source_dir) && patch -p1 -R -i ../$(filter-out $@,$(MAKECMDGOALS))
