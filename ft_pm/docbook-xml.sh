# Depends on: libxml2 libarchive

name=docbook-xml
version=4.5
release=8
source=(https://archive.docbook.org/xml/$version/$name-$version.zip)

build() {
    cd $name-$version
    install -v -d -m755 "$PKG/usr/share/xml/docbook/xml-dtd-4.5"
    install -v -d -m755 "$PKG/etc/xml"
    cp -v -af --no-preserve=ownership                      \
        catalog.xml docbook.cat *.dtd ent/ *.mod           \
        "$PKG/usr/share/xml/docbook/xml-dtd-4.5"

    xmlcatalog --noout --add "rewriteSystem"        \
        "http://www.oasis-open.org/docbook/xml/4.5" \
        "file:///usr/share/xml/docbook/xml-dtd-4.5" \
        "$PKG/usr/share/xml/docbook/xml-dtd-4.5/catalog.xml"

    xmlcatalog --noout --add "rewriteURI"           \
        "http://www.oasis-open.org/docbook/xml/4.5" \
        "file:///usr/share/xml/docbook/xml-dtd-4.5" \
        "$PKG/usr/share/xml/docbook/xml-dtd-4.5/catalog.xml"

    if [ ! -e /etc/xml/catalog ]; then
        xmlcatalog --noout --create "$PKG/etc/xml/catalog"
    fi

    xmlcatalog --noout --add "delegatePublic"                   \
        "-//OASIS//ENTITIES DocBook XML"                        \
        "file:///usr/share/xml/docbook/xml-dtd-4.5/catalog.xml" \
        "$PKG/etc/xml/catalog"

    xmlcatalog --noout --add "delegatePublic"                   \
        "-//OASIS//DTD DocBook XML"                             \
        "file:///usr/share/xml/docbook/xml-dtd-4.5/catalog.xml" \
        "$PKG/etc/xml/catalog"

    xmlcatalog --noout --add "delegateSystem"                   \
        "http://www.oasis-open.org/docbook/"                    \
        "file:///usr/share/xml/docbook/xml-dtd-4.5/catalog.xml" \
        "$PKG/etc/xml/catalog"

    xmlcatalog --noout --add "delegateURI"                      \
        "http://www.oasis-open.org/docbook/"                    \
        "file:///usr/share/xml/docbook/xml-dtd-4.5/catalog.xml" \
        "$PKG/etc/xml/catalog"

    for DTDVERSION in 4.1.2 4.2 4.3 4.4
    do
    xmlcatalog --noout --add "public"                                  \
        "-//OASIS//DTD DocBook XML V$DTDVERSION//EN"                     \
        "http://www.oasis-open.org/docbook/xml/$DTDVERSION/docbookx.dtd" \
        "$PKG/usr/share/xml/docbook/xml-dtd-4.5/catalog.xml"

    xmlcatalog --noout --add "rewriteSystem"              \
        "http://www.oasis-open.org/docbook/xml/$DTDVERSION" \
        "file:///usr/share/xml/docbook/xml-dtd-4.5"         \
        "$PKG/usr/share/xml/docbook/xml-dtd-4.5/catalog.xml"

    xmlcatalog --noout --add "rewriteURI"                 \
        "http://www.oasis-open.org/docbook/xml/$DTDVERSION" \
        "file:///usr/share/xml/docbook/xml-dtd-4.5"         \
        "$PKG/usr/share/xml/docbook/xml-dtd-4.5/catalog.xml"
    done

	# fix permissions and delete junk files
	find $PKG -type f  \( -perm -g=r -o -perm -g=w \) -exec chmod -g=rw '{}' +
	find $PKG \( -name "README" -o -name "ChangeLog" \) -delete
}
