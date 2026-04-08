FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV MOZBUILD_STATE_PATH=/root/.mozbuild

WORKDIR /app

# All build dependencies — replaces mach bootstrap
RUN apt-get update && apt-get install -y \
    build-essential make clang lld llvm pkg-config m4 \
    wget curl git mercurial \
    python3 python3-dev python3-pip python3-venv \
    nasm yasm cbindgen \
    libstdc++-14-dev \
    libgtk-3-dev libdbus-glib-1-dev libpulse-dev libasound2-dev \
    libx11-xcb-dev libxt-dev libxrandr-dev libxcomposite-dev libxdamage-dev \
    p7zip-full golang-go aria2 rsync zip unzip \
    libsqlite3-dev nodejs npm \
    ca-certificates \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Rust
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Git identity for patch management
RUN git config --global user.email "build@camoufox-hydra" && \
    git config --global user.name "Camoufox Hydra Build"

# Copy repo contents
COPY . /app

# Fetch and extract Firefox source
RUN make fetch && make setup

# Fix mach logging bug (curly braces in file paths crash Python format())
RUN python3 -c "\
content = open('firefox-src/python/mach/mach/logging.py').read(); \
old = '        formatted_msg = record.msg.format(**getattr(record, \"params\", {}))'; \
new = '        try:\n            formatted_msg = record.msg.format(**getattr(record, \"params\", {}))\n        except (KeyError, ValueError, IndexError):\n            formatted_msg = record.msg'; \
content = content.replace(old, new); \
open('firefox-src/python/mach/mach/logging.py', 'w').write(content)"

# Apply patches, additions, and config
RUN make patch && make additions && make config

# Fix mozconfig for Docker:
# - Disable bootstrap (can't download Mozilla toolchains for patched forks)
# - Fix target arch to match container
# - Disable WASI sandboxed libraries (avoids missing wasi-sysroot headers)
RUN cd firefox-src && \
    sed -i 's/--enable-bootstrap/--disable-bootstrap/' mozconfig && \
    sed -i "s/--target=x86_64-pc-linux-gnu/--target=$(uname -m)-unknown-linux-gnu/" mozconfig && \
    printf '\nac_add_options --without-wasm-sandboxed-libraries\n' >> mozconfig

# Build extension
RUN make extension

# Build at runtime to avoid Docker BuildKit OOM on Rust LTO link
# CARGO_BUILD_JOBS=1 prevents the ~8GB Rust LTO link from running in parallel
CMD ["bash", "-c", "cd firefox-src && MOZ_MAKE_FLAGS='-j2' CARGO_BUILD_JOBS=1 ./mach build && echo '=== BUILD SUCCEEDED ===' && cp -r obj-*/dist/bin/* /app/dist/ && echo 'Output copied to /app/dist/'"]
