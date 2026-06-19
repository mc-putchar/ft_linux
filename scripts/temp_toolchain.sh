#!/usr/bin/env bash

set -euo pipefail

function enter_pkg() {
    local tarball="$1"
    local dir="$(basename $tarball .tar.xz)"

    cd $LFS/sources
    tar xf $tarball
    cd $dir
}

function exit_pkg() {
    local tarball="$1"

    cd $LFS/sources
    rm -rf $(basename $tarball .tar.xz)
}


M4_TAR="m4-1.4.21.tar.xz" # base
NCURSES_TAR="ncurses-6.6.tar.gz"
BASH_TAR="bash-5.3.tar.gz"
COREUTILS_TAR="coreutils-9.11.tar.xz"
DIFF_TAR="diffutils-3.12.tar.xz"
FILE_TAR="file-5.48.tar.xz"
FIND_TAR="findutils-4.10.0.tar.xz"
GAWK_TAR="gawk-5.4.0.tar.xz"
GREP_TAR="grep-3.12.tar.xz" # base
GZIP_TAR="gzip-1.14.tar.xz"
MAKE_TAR="make-4.4.1.tar.xz" # base
PATCH_TAR="patch-2.8.tar.xz" # base
SED_TAR="sed-4.10.tar.xz" # base
TAR_TAR="tar-1.35.tar.xz" # base
XZ_TAR="xz-5.8.3.tar.xz"

BINUTILS_TAR="binutils-2.46.1.tar.xz" # Pass 2
GCC_TAR="gcc-16.1.0.tar.xz" # Pass 2

BASE_CMP_CMD="./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess) \
            && make && make DESTDIR=$LFS install"
