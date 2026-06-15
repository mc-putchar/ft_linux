#!/usr/bin/env bash

set -euo pipefail

TARGET_DISK="/dev/vda"
LFS_ROOT="/mnt/lfs"

echo "========================================================"
echo " Starting Automated Disk Layout for ScamOS "
echo "========================================================"

echo "[*] Wiping partition table on $TARGET_DISK..."
dd if=/dev/zero of="$TARGET_DISK" bs=512 count=1000 status=none
wipefs -a "$TARGET_DISK"

# Layout specifications:
#   - Partition 1: /boot, Size: 1GiB, Type: Linux (83), Bootable
#   - Partition 2: Swap,  Size: 4GiB, Type: Linux Swap (82)
#   - Partition 3: Root,  Size: Rest, Type: Linux (83)
echo "[*] Allocating layout structure BOOT/SWAP/ROOT..."
sfdisk "$TARGET_DISK" <<EOF
label: dos
size=1GiB, type=83, bootable
size=4GiB, type=82
size=,     type=83
EOF

PART_BOOT="${TARGET_DISK}1"
PART_SWAP="${TARGET_DISK}2"
PART_ROOT="${TARGET_DISK}3"

echo "[*] Compiling target filesystems..."
mkfs.ext4 -F -q "$PART_BOOT"
mkswap -f "$PART_SWAP"
mkfs.btrfs -f -Q "$PART_ROOT"

echo "[*] Configuring BTRFS subvolume..."
mkdir -p /tmp/btrfs_setup
mount "$PART_ROOT" /tmp/btrfs_setup
btrfs subvolume create /tmp/btrfs_setup/@host
btrfs subvolume create /tmp/btrfs_setup/@lfs
umount /tmp/btrfs_setup

echo "[*] Engaging swap memory..."
swapon "$PART_SWAP"

echo "========================================================"
echo " Target Environment Layout Status "
echo "========================================================"
lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINTS "$TARGET_DISK"
echo "--------------------------------------------------------"
echo "Success! Framework layout completed."
