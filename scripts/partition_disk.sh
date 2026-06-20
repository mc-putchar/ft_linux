#!/usr/bin/env bash

set -euo pipefail

TARGET_DISK="/dev/vdb"
LFS="/mnt/lfs"

echo "========================================================"
echo " Starting Automated Disk Layout"
echo "========================================================"

echo "[*] Wiping partition table on $TARGET_DISK..."
sudo dd if=/dev/zero of="$TARGET_DISK" bs=512 count=1000 status=none
sudo wipefs -a "$TARGET_DISK"

# Layout specifications:
#   - Partition 1: /boot, Size: 400MiB, Type: Linux (83), Bootable
#   - Partition 2: Swap,  Size: 4GiB, Type: Linux Swap (82)
#   - Partition 3: Root,  Size: Rest, Type: Linux (83)
echo "[*] Allocating layout structure BOOT/SWAP/ROOT..."
sudo sfdisk "$TARGET_DISK" <<EOF
label: dos
size=400MiB, type=83, bootable
size=4GiB,   type=82
size=,       type=83
EOF

PART_BOOT="${TARGET_DISK}1"
PART_SWAP="${TARGET_DISK}2"
PART_ROOT="${TARGET_DISK}3"

echo "[*] Compiling target filesystems..."
sudo mkfs.ext4 -F -q "$PART_BOOT"
sudo mkswap -f "$PART_SWAP"
sudo mkfs.btrfs -f -L lfsroot "$PART_ROOT"

echo "[*] Configuring BTRFS subvolume..."
sudo mkdir -p /tmp/btrfs_setup
sudo mount "$PART_ROOT" /tmp/btrfs_setup
sudo btrfs subvolume create /tmp/btrfs_setup/@lfs
sudo umount /tmp/btrfs_setup

echo "[*] Engaging swap memory..."
sudo swapon "$PART_SWAP"

echo "[*] Mounting root subvolume..."
sudo mkdir -p "$LFS"
# sudo mount -o "subvol=@lfs" /dev/vda3 "$LFS"
sudo mount -o "subvol=@lfs" "$PART_ROOT" "$LFS"

echo "========================================================"
echo " Target Environment Layout Status "
echo "========================================================"
lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINTS "$TARGET_DISK"
echo "--------------------------------------------------------"
echo "Success! Framework layout completed."
