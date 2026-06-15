#!/usr/bin/env bash

VERSION="7.0.10"
LOGIN="$USER"
KERNEL_DIR="/usr/src/kernel-$VERSION"

cd "$KERNEL_DIR"

echo "[*] Generating default configuration"
make defconfig

echo "[*] Configuring kernel local version suffix..."
./scripts/config --set-str LOCALVERSION "-$LOGIN"

echo "[*] Compiling Linux Kernel..."
make -j$(nproc)

echo "[*] Installing modules and kernel images..."
make modules_install

cp -v arch/x86/boot/bzImage "/boot/vmlinuz-$VERSION-$LOGIN"
