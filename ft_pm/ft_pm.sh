#!/usr/bin/env bash

set -e

SRC_DIR="/sources"
FAKEROOT_BASE="/usr/fakeroot"
RECIPE_DIR="./recipes"

export PKG="$1"
export VER="$2"

if [ -z "$PKG" ] || [ -z "$VER" ]; then
    echo "Usage: $0 <package> <version>"
    exit 1
fi

export PKG_DIR="${PKG}-${VER}"
export FAKEROOT="${FAKEROOT_BASE}/${PKG_DIR}"

UPDATE_INFO=0
UPDATE_MIME=0
UPDATE_FONTS=0
UPDATE_GTK_IM=0
UPDATE_GTK_ICON=0
FIX_PERL=0

# --- Default Functions ---
unpack_source() {
    local tb="${TARBALL_NAME:-${PKG_DIR}.tar.xz}"
    tar -xvf "${SRC_DIR}/${tb}"
    cd "$PKG_DIR"
}

compile_source() {
    ./configure --prefix=/usr
    make
}

test_package() {
    echo "Skipping tests by default."
}

install_fakeroot() {
    mkdir -p "$FAKEROOT"
    make DESTDIR="$FAKEROOT" install
}

maintain_fakeroot() {
    echo "No standard maintenance required."
}

run_triggers() {
    echo "=== Running Post-Install Configuration ==="

    if [ "$FIX_PERL" -eq 1 ]; then
        echo "Fixing Perl .packlist and perllocal.pod..."
        find $FAKEROOT -name ".packlist" -exec sed -i "s@$FAKEROOT@@g" {} \;
        # Append perllocal.pod logic here, then remove the fakeroot copy
    fi

    if [ "$UPDATE_INFO" -eq 1 ]; then
        echo "Rebuilding Info directory..."
        pushd /usr/share/info
        rm -v dir
        for f in *; do install-info $f dir 2>/dev/null; done
        popd
    fi

    if [ "$UPDATE_FONTS" -eq 1 ]; then
        echo "Updating Font Cache..."
        fc-cache -v
    fi

    if [ "$UPDATE_MIME" -eq 1 ]; then
        echo "Updating MIME database..."
        update-mime-database /usr/share/mime
    fi

    if [ "$UPDATE_GTK_ICON" -eq 1 ]; then
        echo "Updating GTK Icon Cache..."
        gtk-update-icon-cache -qtf /usr/share/icons/hicolor
    fi

    ldconfig
}

main() {
    local recipe_file="${RECIPE_DIR}/${PKG}.sh"

    if [ ! -f "$recipe_file" ]; then
        echo "Error: Recipe $recipe_file not found."
        exit 1
    fi

    source "$recipe_file"

    echo "=== Building $PKG_DIR ==="

    unpack_source
    compile_source
    test_package
    install_fakeroot
    maintain_fakeroot

    echo "=== Relocating to / ==="
    cd "$FAKEROOT"
    tar cf - . | (cd / ; tar xvf - )

    run_triggers

    rm -rf "${FAKEROOT_BASE:?}/${PKG_DIR}"
    echo "=== Finished $PKG ==="
}

main
