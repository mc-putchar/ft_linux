#!/usr/bin/env bash

export LFS="/mnt/lfs"

if [ ! -d "$LFS/proc/sys" ]; then
    echo "Mounting virtual kernel file systems..."
    mount -v --bind /dev "$LFS/dev"
    mount -v --bind /dev/pts "$LFS/dev/pts"
    mount -vt tmpfs shm "$LFS/dev/shm"
    mount -vt proc proc "$LFS/proc"
    mount -vt sysfs sysfs "$LFS/sys"
    mount -vt tmpfs tmpfs "$LFS/run"
fi

echo "Copying network configurations..."
cp -v /etc/resolv.conf "$LFS/etc/"

echo "Entering LFS Chroot Environment..."
chroot "$LFS" /usr/bin/env -i \
    HOME=/root \
    TERM="$TERM" \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin \
    /bin/bash --login
