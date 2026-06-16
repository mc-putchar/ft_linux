#!/usr/bin/env bash

export LFS="/mnt/lfs"

cat > $LFS/tmp/compile_m4.sh << 'EOF'
cd /sources
tar -xf m4-1.4.19.tar.xz && cd m4-1.4.19
./configure --prefix=/usr
make -j$(nproc)
make install
cd /sources && rm -rf m4-1.4.19
echo "M4 Compilation complete!"
EOF

chroot "$LFS" /usr/bin/env -i \
    HOME=/root TERM="$TERM" PATH=/bin:/usr/bin:/sbin:/usr/sbin \
    /bin/bash --login /tmp/compile_m4.sh

rm -f $LFS/tmp/compile_m4.sh
