#!/usr/bin/env bash

set -euo pipefail

LFS_PKGS_MIRROR="https://www.linuxfromscratch.org/lfs/view/13.0-systemd"

[ ! -e /etc/bash.bashrc ] || sudo mv -v /etc/bash.bashrc /etc/bash.bashrc.NOUSE

echo "[*] Creating working directories..."
sudo mkdir -v $LFS/sources
sudo chmod -v a+wt $LFS/sources

pushd $LFS/sources
    wget "$LFS_PKGS_MIRROR/wget-list-systemd"
    wget "$LFS_PKGS_MIRROR/md5sums"

    echo "[*] Downloading sources..."
    if ! wget --input-file=wget-list-systemd --continue --directory-prefix=$LFS/sources; then
        echo "Failed to download sources!"
        exit 1
    fi
    echo "[*] Verifying source integrity..."
    if ! md5sum -c md5sums; then
        echo "MD5 check failed!"
        exit 1
    fi
popd

echo "[*] Creating symlinks..."
sudo mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}

for i in bin lib sbin; do
  sudo ln -sv usr/$i $LFS/$i
done

case $(uname -m) in
  x86_64) sudo mkdir -pv $LFS/lib64 ;;
esac

sudo mkdir -pv $LFS/tools

sudo chown -v lfs $LFS/{usr{,/*},var,etc,tools}
case $(uname -m) in
  x86_64) sudo chown -v lfs $LFS/lib64 ;;
esac
