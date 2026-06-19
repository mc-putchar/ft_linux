#!/usr/bin/env bash

set -euo pipefail

function cleanup() {
    local pkg="$1"

    cd $LFS/sources
    rm -rf $(basename $pkg .tar.xz)
}

function compilation_wrap() {
    local pkg="$1"
    local compile_cmd="$2"
    local pre_hook="$3"
    local cleanup="$4"

    cd $LFS/sources
    echo "Extracting $pkg..."
    tar xf $pkg
    cd $(basename $pkg .tar.xz)

    if [ -n "$pre_hook" ]; then
        eval $pre_hook
    fi

    time eval $compile_cmd

    if [ -z "$cleanup" ]; then
        cleanup $pkg
    fi
}


# binutils
BINUTILS_TAR="binutils-2.46.1.tar.xz"
BINUTILS_PRE_HOOK="mkdir -v build && cd build;"
BINUTILS_CMP_CMD="../configure                      \
                   --prefix=$LFS/tools              \
                   --with-sysroot=$LFS              \
                   --target=$LFS_TGT                \
                   --disable-nls                    \
                   --enable-gprofng=no              \
                   --disable-werror                 \
                   --enable-new-dtags               \
                   --enable-default-hash-style=gnu  \
                 && make                            \
                 && make install;"

compilation_wrap "$BINUTILS_TAR" "$BINUTILS_CMP_CMD" "$BINUTILS_PRE_HOOK" ""

# GCC
GCC_VERSION="16.1.0"
GCC_TAR="gcc-$GCC_VERSION.tar.xz"
GCC_PRE_HOOK="tar -xf ../mpfr-4.2.2.tar.xz && mv -v mpfr-4.2.2 mpfr         \
             && tar -xf ../gmp-6.3.0.tar.xz && mv -v gmp-6.3.0 gmp          \
             && tar -xf ../mpc-1.4.1.tar.xz && mv -v mpc-1.4.1 mpc          \
             && if [ "$(uname -m)" = "x86_64" ]; then                       \
                 sed -e '/m64=/s/lib64/lib/' -i gcc/config/i386/t-linux64;  \
               else true;                                                   \
               fi                                                           \
             && mkdir -v build                                              \
             && cd build;"
GCC_CMP_CMD="../configure               \
              --target=$LFS_TGT         \
              --prefix=$LFS/tools       \
              --with-glibc-version=2.43 \
              --with-sysroot=$LFS       \
              --with-newlib             \
              --without-headers         \
              --enable-default-pie      \
              --enable-default-ssp      \
              --disable-fixincludes     \
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
            && make                     \
            && make install;"

compilation_wrap "$GCC_TAR" "$GCC_CMP_CMD" "$GCC_PRE_HOOK" "nocleanup"

GCC_POST_HOOK="tar xf $GCC_TAR                                                      \
            && cat $(basename $GCC_TAR .tar.xz)/gcc/{limitx,glimits,limity}.h  >    \
            $($LFS_TGT-gcc -print-file-name=include)/limits.h"
eval $GCC_POST_HOOK
rm -rf $(basename $GCC_TAR .tar.xz)

# Linux headers
LINUX_HEADERS_TAR="linux-7.0.12.tar.xz"
LINUX_HEADERS_CMP_CMD="make mrproper                                    \
                      && make headers                                   \
                      && find usr/include -type f ! -name '*.h' -delete \
                      && cp -rv usr/include $LFS/usr"

compilation_wrap "$LINUX_HEADERS_TAR" "$LINUX_HEADERS_CMP_CMD" ""

# TODO: fix this automation
GLIBC_TAR="glibc-2.43.tar.xz"
GLIBC_PATCH1="glibc-fhs-1.patch"
GLIBC_PATCH2="glibc-2.43-upstream_fixes-1.patch"
GLIBC_PRE_HOOK="if [ $(uname -m) = 'x86_64' ]; then                                     \
                  ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64                        \
                  && ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3; \
                fi                                                                      \
               && patch -Np1 -i ../$GLIBC_PATCH1                                        \
               && patch -Np1 -i ../$GLIBC_PATCH2                                        \
               && mkdir -v build                                                        \
               && cd build;"
# ../scripts/config.guess doesn't exist yet
GLIBC_CMP_CMD="echo "rootsbindir=/usr/sbin" > configparms       \
               && ../configure                                  \
                --prefix=/usr                                   \
                --host=$LFS_TGT                                 \
                --build=$(../scripts/config.guess)              \
                --disable-nscd                                  \
                libc_cv_slibdir=/usr/lib                        \
                --enable-kernel=5.4                             \
               && make                                          \
               && make DESTDIR=$LFS install                     \
               && sed '/RTLDLIST=/s@/usr@@g' -i $LFS/usr/bin/ldd;"

compilation_wrap "$GLIBC_TAR" "$GLIBC_CMP_CMD" "$GLIBC_PRE_HOOK" "nocleanup"

GLIBC_POST_HOOK="echo 'int main(){}' | $LFS_TGT-gcc -x c - -v -Wl,--verbose &> dummy.log    \
               && readelf -l a.out | grep ': /lib'                                          \
               && grep -E -o "$LFS/lib.*/S?crt[1in].*succeeded" dummy.log                   \
               && grep -B3 "^ $LFS/usr/include" dummy.log                                   \
               && grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'                        \
               && grep "/lib.*/libc.so.6 " dummy.log                                        \
               && grep found dummy.log                                                      \
               && rm -v a.out dummy.log;"
eval "$GLIBC_POST_HOOK"
cleanup "$GLIBC_TAR"

# TODO: fix this automation
LIBSTDCXX_PRE_HOOK="mkdir -v build && cd build;"
# ../config.guess doesn't exist yet
LIBSTDCXX_CMP_CMD="../libstdc++-v3/configure                                        \
                    --host=$LFS_TGT                                                 \
                    --build=$(../config.guess)                                      \
                    --prefix=/usr                                                   \
                    --disable-multilib                                              \
                    --disable-nls                                                   \
                    --disable-libstdcxx-pch                                         \
                    --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/$GCC_VERSION \
                  && make                                                           \
                  && make DESTDIR=$LFS install;"

compilation_wrap "$GCC_TAR" "$LIBSTDCXX_CMP_CMD" "$LIBSTDCXX_PRE_HOOK"

LIBSTDCXX_POST_HOOK="rm -v $LFS/usr/lib/lib{stdc++{,exp,fs},supc++}.la;"
eval "$LIBSTDCXX_POST_HOOK"
