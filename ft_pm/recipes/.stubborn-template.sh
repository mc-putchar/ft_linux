compile_source() {
    make
}

install_fakeroot() {
    # Missing destination dirs
    install -d "$FAKEROOT/usr/bin"
    install -d "$FAKEROOT/usr/share/man/man1"

    # Manual prefix installation
    make prefix="$FAKEROOT/usr" install

    # if 'make install' is broken:
    # install -v -m755 mybinary "$FAKEROOT/usr/bin/"
}
