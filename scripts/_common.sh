#!/bin/bash

#=================================================
# COMMON VARIABLES AND HELPERS — Piped on YunoHost
# Targets YunoHost helpers_version 2.1.
#=================================================

# Version pins for the components built from source.
# Bump these in a future release of the YunoHost package.
PIPED_BACKEND_REPO="https://github.com/TeamPiped/Piped-Backend"
PIPED_BACKEND_REF="master"

PIPED_PROXY_REPO="https://github.com/TeamPiped/piped-proxy"
PIPED_PROXY_REF="main"

# Node.js for building the frontend (Vite 8 + Vue 3 happy on 22 LTS).
NODEJS_VERSION="22"

# Eclipse Temurin (Adoptium) JDK — required by piped-backend.
JAVA_VERSION="21"

# Rust toolchain version installed via rustup for piped-proxy.
RUST_VERSION="1.83.0"

#=================================================
# HELPERS
#=================================================

# Install Node.js as a standalone tarball into ${install_dir}/node.
# We deliberately avoid NodeSource APT: its nodejs package conflicts with the
# Debian-packaged libnode108, which would force apt to remove dozens of
# node-* system packages that other YunoHost apps depend on.
piped_install_nodejs() {
    local install_dir="$1"
    local node_dir="${install_dir}/node"

    if [ -x "${node_dir}/bin/node" ] \
        && "${node_dir}/bin/node" --version | grep -q "^v${NODEJS_VERSION}\."; then
        return 0
    fi

    local arch
    case "$(dpkg --print-architecture)" in
        amd64) arch="x64" ;;
        arm64) arch="arm64" ;;
        armhf) arch="armv7l" ;;
        *) ynh_die --message="No Node.js binary tarball is available for $(dpkg --print-architecture)." ;;
    esac

    ynh_print_info "Resolving the latest Node.js ${NODEJS_VERSION}.x release..."
    local latest
    latest="$(curl -fsSL "https://nodejs.org/dist/index.json" \
        | python3 -c "import json,sys
data=json.load(sys.stdin)
print(next(x['version'] for x in data if x['version'].startswith('v${NODEJS_VERSION}.')))")"
    if [ -z "$latest" ]; then
        ynh_die --message="Could not determine latest Node ${NODEJS_VERSION}.x version from nodejs.org."
    fi

    local tarball="node-${latest}-linux-${arch}.tar.xz"
    local url="https://nodejs.org/dist/${latest}/${tarball}"
    local tmp
    tmp="$(mktemp /tmp/piped-node-XXXXXX.tar.xz)"
    ynh_print_info "Downloading ${url}..."
    curl -fsSL -o "$tmp" "$url" || {
        rm -f "$tmp"
        ynh_die --message="Failed to download Node.js tarball from ${url}."
    }

    rm -rf "$node_dir"
    mkdir -p "$node_dir"
    tar -xJf "$tmp" -C "$node_dir" --strip-components=1
    rm -f "$tmp"
    chmod -R go+rX "$node_dir"
}

# Install Eclipse Temurin JDK from the Adoptium APT repository.
piped_install_java() {
    if command -v java >/dev/null 2>&1 \
        && java -version 2>&1 | grep -qE "version \"${JAVA_VERSION}(\.|\")"; then
        return 0
    fi
    ynh_print_info "Installing Eclipse Temurin JDK ${JAVA_VERSION} from Adoptium..."
    mkdir -p /etc/apt/keyrings
    wget -qO /etc/apt/keyrings/adoptium.asc \
        https://packages.adoptium.net/artifactory/api/gpg/key/public
    local codename
    codename="$(lsb_release -cs)"
    echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb ${codename} main" \
        > /etc/apt/sources.list.d/adoptium.list
    apt-get update -qq
    apt-get install -y "temurin-${JAVA_VERSION}-jdk"
}

# Resolve JAVA_HOME for the installed Temurin JDK (architecture-dependent).
piped_java_home() {
    local arch
    arch="$(dpkg --print-architecture)"
    echo "/usr/lib/jvm/temurin-${JAVA_VERSION}-jdk-${arch}"
}

# Install rustup + cargo into a per-app cargo_home so it doesn't pollute root.
piped_install_rust() {
    local app="$1"
    local cargo_home="$2"

    if [ -x "${cargo_home}/bin/cargo" ]; then
        return 0
    fi
    ynh_print_info "Installing Rust ${RUST_VERSION} via rustup for ${app}..."
    mkdir -p "$cargo_home"
    chown "$app:$app" "$cargo_home"
    sudo -u "$app" bash -c "
        export RUSTUP_HOME='${cargo_home}/rustup'
        export CARGO_HOME='${cargo_home}'
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
            | sh -s -- -y --default-toolchain ${RUST_VERSION} --profile minimal --no-modify-path
    "
}

# Build the frontend SPA with Vite, baking in the user's domain.
piped_build_frontend() {
    local install_dir="$1"
    local app="$2"
    local domain="$3"
    local source_dir="$4"  # cloned-by-yunohost repo with manifest.toml

    local fe="${install_dir}/frontend-src"
    rm -rf "$fe"
    mkdir -p "$fe"

    # Copy frontend source from the YunoHost-cloned repo, skipping packaging files.
    (cd "$source_dir" && tar --exclude='./scripts' --exclude='./conf' \
        --exclude='./doc' --exclude='./mockups' --exclude='./.git' \
        --exclude='./manifest.toml' -cf - .) | (cd "$fe" && tar -xf -)

    # Per-instance API endpoints (Vite bakes these into the bundle at build time).
    cat > "${fe}/.env" <<EOF
VITE_PIPED_API=https://${domain}/api
VITE_PIPED_PROXY=https://${domain}/proxy
VITE_PIPED_INSTANCES=https://piped-instances.kavin.rocks/
EOF

    piped_install_nodejs "$install_dir"
    chown -R "$app:$app" "$fe" "${install_dir}/node"

    ynh_print_info "Building Piped frontend with Vite (~2 min)..."
    # --legacy-peer-deps: vite-plugin-pwa@1.2.0 declares peer support up to vite@7
    # but Piped pins vite@8. Skipping the strict peer-deps check is the upstream-
    # recommended workaround (npm itself prints this hint when it fails).
    sudo -u "$app" bash -c "
        cd '${fe}'
        export PATH='${install_dir}/node/bin:\$PATH'
        npm install --no-audit --no-fund --legacy-peer-deps
        npm run build
    "

    rm -rf "${install_dir}/dist"
    mv "${fe}/dist" "${install_dir}/dist"
    rm -rf "$fe"
}

# Build piped-backend (gradle shadowJar) into ${install_dir}/backend.
piped_build_backend() {
    local install_dir="$1"
    local app="$2"
    local src="${install_dir}/backend-src"

    piped_install_java

    ynh_print_info "Cloning piped-backend (${PIPED_BACKEND_REF})..."
    rm -rf "$src"
    sudo -u "$app" git clone --depth 1 \
        --branch "$PIPED_BACKEND_REF" "$PIPED_BACKEND_REPO" "$src"

    ynh_print_info "Building piped-backend with Gradle (~5-10 min)..."
    local java_home
    java_home="$(piped_java_home)"
    sudo -u "$app" bash -c "
        cd '${src}'
        export JAVA_HOME='${java_home}'
        export PATH='${java_home}/bin:\$PATH'
        chmod +x ./gradlew
        ./gradlew --no-daemon shadowJar
    "

    local jar
    jar="$(find "${src}/build/libs" -maxdepth 1 -name '*-all.jar' 2>/dev/null | head -n1)"
    if [ -z "$jar" ]; then
        ynh_die --message="piped-backend build did not produce a *-all.jar in ${src}/build/libs/"
    fi

    install -d -o "$app" -g "$app" "${install_dir}/backend"
    install -m 0644 -o "$app" -g "$app" "$jar" "${install_dir}/backend/piped-backend.jar"
    rm -rf "$src"
}

# Build piped-proxy (cargo --release) into ${install_dir}/piped-proxy.
piped_build_proxy() {
    local install_dir="$1"
    local app="$2"
    local cargo_home="${install_dir}/.cargo"
    local src="${install_dir}/proxy-src"

    piped_install_rust "$app" "$cargo_home"

    ynh_print_info "Cloning piped-proxy (${PIPED_PROXY_REF})..."
    rm -rf "$src"
    sudo -u "$app" git clone --depth 1 \
        --branch "$PIPED_PROXY_REF" "$PIPED_PROXY_REPO" "$src"

    ynh_print_info "Building piped-proxy with Cargo (~3-7 min)..."
    sudo -u "$app" bash -c "
        cd '${src}'
        export RUSTUP_HOME='${cargo_home}/rustup'
        export CARGO_HOME='${cargo_home}'
        export PATH='${cargo_home}/bin:\$PATH'
        cargo build --release --locked
    "

    install -m 0755 -o "$app" -g "$app" \
        "${src}/target/release/piped-proxy" "${install_dir}/piped-proxy"
    rm -rf "$src" "${cargo_home}/registry/cache"
}
