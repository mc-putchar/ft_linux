name=docbook-xsl
version=1.79.2
release=1
source=(https://github.com/docbook/xslt10-stylesheets/releases/download/release/$version/$name-nons-$version.tar.bz2
    https://www.linuxfromscratch.org/patches/blfs/svn/$name-nons-$version-stack_fix-1.patch)

build() {
    cd $name-nons-$version

    patch -Np1 -i /sources/$name-nons-$version-stack_fix-1.patch

    install -v -m755 -d $PKG/usr/share/xml/docbook/xsl-stylesheets-nons-$version

    cp -v -R -t $PKG/usr/share/xml/docbook/xsl-stylesheets-nons-$version \
	    VERSION assembly common eclipse epub epub3 extensions fo        \
         highlighting html htmlhelp images javahelp lib manpages params  \
         profiling roundtrip slides template tests tools webhelp website \
         xhtml xhtml-1_1 xhtml5

	ln -sf VERSION $PKG/usr/share/xml/docbook/xsl-stylesheets-nons-${version}/VERSION.xsl

    install -v -m644 -D README \
                    $PKG/usr/share/doc/docbook-xsl-nons-${version}/README.txt

    install -v -m644    RELEASE-NOTES* NEWS* \
                    $PKG/usr/share/doc/docbook-xsl-nons-${version}
}
