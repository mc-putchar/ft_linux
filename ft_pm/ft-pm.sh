#!/usr/bin/env bash
set -e

# Lazy mode, on the shoulders of giants
#
# This basic package manager aims to be minimalistic scripted way
# that can plug into existing community recipes in the CRUX Ports Database
# Also, simple PKGBUILDs from AUR should be relatively easy to convert
#
# In a nutshell:
#   - read the variables from Pkgfile (name, version, source)
#   - prepare it in fakeroot,
#   - run the defined build steps,
#   - build manifest to keep track of changes to the system,
#   - install
#   - TODO: post-install
#
# To uninstall pkgs run:
# while read -r file; do
#     rm -v "$file" 2>/dev/null || true
# done < "/var/lib/packages/package_name.files"

SRC_DIR="/sources"
RECIPE_DIR="/recipes"
VAR_DB="/var/lib/packages"
mkdir -p "$VAR_DB"

PACKAGE="$1"
if [ -z "$PACKAGE" ]; then
    echo "Usage: $0 package"
    exit 1
fi

if [ ! -f "${RECIPE_DIR}/${PACKAGE}/Pkgfile" ]; then
    echo "Error: ${RECIPE_DIR}/${PACKAGE}/Pkgfile not found"
    read -p "Enter URL of Pkgfile: " pkgfile_url
    wget -P "${RECIPE_DIR}/${PACKAGE}" "$pkgfile_url"
    if [ ! -f "${RECIPE_DIR}/${PACKAGE}/Pkgfile" ]; then
        echo "Error: ${RECIPE_DIR}/${PACKAGE}/Pkgfile not found"
        exit 1
    fi
fi

echo "=== Pkgfile ==="
cat "${RECIPE_DIR}/${PACKAGE}/Pkgfile"
echo "=== END ==="
read -p "Continue [y/N]? " -n 1 -r REPLY
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    vim "${RECIPE_DIR}/${PACKAGE}/Pkgfile"
    exit 1
fi

export JOBS=$(nproc)
source "${RECIPE_DIR}/${PACKAGE}/Pkgfile"

export WORK_DIR="/tmp/build-${name}"
export PKG="/tmp/fakeroot-${name}"

rm -rf "$WORK_DIR" "$PKG"
mkdir -p "$WORK_DIR" "$PKG"

cd "$WORK_DIR"
for src in "${source[@]}"; do
    filename=$(basename "$src")
    if [ ! -f "${SRC_DIR}/${filename}" ]; then
        echo "=== Downloading ${filename} ==="
        wget -P "${SRC_DIR}" "$src"
    fi
    echo "=== Unpacking ${filename} ==="
    if [[ "$filename" == *.tar.gz || "$filename" == *.tgz ]]; then
        tar -xzf "${SRC_DIR}/${filename}"
    elif [[ "$filename" == *.tar.xz || "$filename" == *.tar.bz2 ]]; then
        tar -xf "${SRC_DIR}/${filename}"
    elif [[ "$filename" == *.tar.lz ]]; then
        tar --lzip -xf "${SRC_DIR}/${filename}"
    elif [[ "$filename" == *.zip ]]; then
        mkdir -p "$name-$version"
        unzip -q "${SRC_DIR}/${filename}" -d "$name-$version"
    fi
done

echo "=== Compiling ${name} ==="
build

echo "=== Generating Package Manifest ==="
cd "$PKG"
find . -not -type d | sed 's|^\.||' > "${VAR_DB}/${name}.files"

echo "=== Installing ${name} to Live System ==="
tar -c . | tar -x -C /

# TODO: evaluate post-install actions/triggers
# like ldconfig, fc-cache, etc.
ldconfig

echo "Successfully installed ${name}-${version}!"
