#!/usr/bin/env bash

set -euo pipefail

compilation_wrap() {
    local pkg="$1"
    local compile_cmd="$2"

    cd $LFS/sources
    tar -xf $pkg
    cd $(basename $pkg .tar.xz)

    time eval $compile_cmd

    cd $LFS/sources
    rm -rf $(basename $pkg .tar.xz)
}


# binutils
BINUTILS_TAR="binutils-2.46.0.tar.xz"
BINUTILS_CMP_CMD="mkdir -v build && cd build && ../configure --prefix=$LFS/tools \
             --with-sysroot=$LFS \
             --target=$LFS_TGT   \
             --disable-nls       \
             --enable-gprofng=no \
             --disable-werror    \
             --enable-new-dtags  \
             --enable-default-hash-style=gnu && make && make install;"

compilation_wrap "$BINUTILS_TAR" "$BINUTILS_CMP_CMD"

# GCC
GCC_TAR="gcc-15.2.0.tar.xz"
GCC_CMP_CMD="tar -xf ../mpfr-4.2.2.tar.xz && mv -v mpfr-4.2.2 mpfr \
            && tar -xf ../gmp-6.3.0.tar.xz && mv -v gmp-6.3.0 gmp \
            && tar -xf ../mpc-1.3.1.tar.gz && mv -v mpc-1.3.1 mpc \
            && sed -e '/m64=/s/lib64/lib/' -i gcc/config/i386/t-linux64 \
            && mkdir -v build && cd build \
            && ../configure            \
             --target=$LFS_TGT         \
             --prefix=$LFS/tools       \
             --with-glibc-version=2.43 \
             --with-sysroot=$LFS       \
             --with-newlib             \
             --without-headers         \
             --enable-default-pie      \
             --enable-default-ssp      \
             --disable-nls             \
             --disable-shared          \
             --disable-multilib        \
             --disable-threads         \
             --disable-libatomic       \
             --disable-libgomp         \
             --disable-libquadmath     \
             --disable-libssp          \
             --disable-libvtv          \
             --disable-libstdcxx       \
             --enable-languages=c,c++  \
            && make \
            && make install;"
GCC_POST_HOOK="cd .. && cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
            `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include/limits.h"

compilation_wrap "$GCC_TAR" "$GCC_CMP_CMD"
