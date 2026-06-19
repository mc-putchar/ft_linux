compile_source() {
    mkdir -v build
    cd build
    ../configure --prefix=/usr \
                 --disable-werror
    make
}

install_fakeroot() {
    mkdir -p "$FAKEROOT"
    cd build
    make install_root="$FAKEROOT" install
}

UPDATE_INFO=1
