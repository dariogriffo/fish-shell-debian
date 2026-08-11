fish_VERSION=$1
BUILD_VERSION=$2
ARCH=${3:-amd64}  # Default to amd64 if no architecture specified

if [ -z "$fish_VERSION" ] || [ -z "$BUILD_VERSION" ]; then
    echo "Usage: $0 <fish_version> <build_version> [architecture]"
    echo "Example: $0 4.8.1 1 arm64"
    echo "Example: $0 4.8.1 1 all    # Build for all architectures"
    echo "Supported architectures: amd64, arm64, all"
    exit 1
fi

BUILD_DATE="$(date -R)"
SRC_TARBALL="fish-${fish_VERSION}.tar.xz"

# Function to map Debian architecture to the upstream release target.
# Upstream publishes Linux binaries only for these two, both statically
# linked against musl.
get_fish_target() {
    local arch=$1
    case "$arch" in
        "amd64") echo "x86_64" ;;
        "arm64") echo "aarch64" ;;
        *)       echo "" ;;
    esac
}

# The source tarball is needed for the man pages (sphinx builds them in the
# Dockerfile's docs stage) and is shared across every arch and distribution.
fetch_source() {
    if [ ! -f "$SRC_TARBALL" ]; then
        echo "Downloading upstream source ${SRC_TARBALL} (for man pages)..."
        if ! wget -q "https://github.com/fish-shell/fish-shell/releases/download/${fish_VERSION}/${SRC_TARBALL}"; then
            echo "❌ Failed to download $SRC_TARBALL"
            return 1
        fi
    fi
    return 0
}

# Function to build for a specific architecture
build_architecture() {
    local build_arch=$1
    local target
    local fish_release

    target=$(get_fish_target "$build_arch")
    if [ -z "$target" ]; then
        echo "❌ Unsupported architecture: $build_arch"
        echo "Supported architectures: amd64, arm64"
        return 1
    fi

    fish_release="fish-$build_arch"
    local asset="fish-${fish_VERSION}-linux-${target}.tar.xz"

    echo "Building for architecture: $build_arch using $asset"

    # Clean up any previous downloads for this architecture
    rm -rf "$fish_release" || true
    rm -f "$asset" || true

    # Upstream ships a bare, flat `fish` executable (no top-level directory),
    # so extract it into a per-arch folder the Dockerfile can COPY from.
    if ! wget "https://github.com/fish-shell/fish-shell/releases/download/${fish_VERSION}/${asset}"; then
        echo "❌ Failed to download fish binary for $build_arch"
        return 1
    fi

    mkdir -p "$fish_release"
    if ! tar -xf "$asset" -C "$fish_release"; then
        echo "❌ Failed to extract fish binary for $build_arch"
        return 1
    fi

    rm -f "$asset"

    # amd64/arm64 are release architectures on every supported Debian.
    declare -a arr=("bookworm" "trixie" "forky" "sid")

    for dist in "${arr[@]}"; do
        FULL_VERSION="$fish_VERSION-${BUILD_VERSION}~${dist}_${build_arch}"
        echo "  Building $FULL_VERSION"

        if ! docker build . -t "fish-$dist-$build_arch" \
            --build-arg DEBIAN_DIST="$dist" \
            --build-arg fish_VERSION="$fish_VERSION" \
            --build-arg BUILD_VERSION="$BUILD_VERSION" \
            --build-arg FULL_VERSION="$FULL_VERSION" \
            --build-arg ARCH="$build_arch" \
            --build-arg FISH_RELEASE="$fish_release" \
            --build-arg BUILD_DATE="$BUILD_DATE"; then
            echo "❌ Failed to build Docker image for $dist on $build_arch"
            return 1
        fi

        id="$(docker create "fish-$dist-$build_arch")"
        if ! docker cp "$id:/fish_$FULL_VERSION.deb" - > "./fish_$FULL_VERSION.deb"; then
            echo "❌ Failed to extract .deb package for $dist on $build_arch"
            return 1
        fi

        if ! tar -xf "./fish_$FULL_VERSION.deb"; then
            echo "❌ Failed to extract .deb contents for $dist on $build_arch"
            return 1
        fi
    done

    # Clean up extracted directory
    rm -rf "$fish_release" || true

    echo "✅ Successfully built for $build_arch"
    return 0
}

if ! fetch_source; then
    exit 1
fi

# Main build logic
if [ "$ARCH" = "all" ]; then
    echo "🚀 Building fish $fish_VERSION-$BUILD_VERSION for all supported architectures..."
    echo ""

    ARCHITECTURES=("amd64" "arm64")

    for build_arch in "${ARCHITECTURES[@]}"; do
        echo "==========================================="
        echo "Building for architecture: $build_arch"
        echo "==========================================="

        if ! build_architecture "$build_arch"; then
            echo "❌ Failed to build for $build_arch"
            exit 1
        fi

        echo ""
    done

    echo "🎉 All architectures built successfully!"
    echo "Generated packages:"
    ls -la fish_*.deb
else
    # Build for single architecture
    if ! build_architecture "$ARCH"; then
        exit 1
    fi
fi
